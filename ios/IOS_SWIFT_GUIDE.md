## iOS (Swift) WKWebView + dLocal Direct SDK: createToken, getBinInformation, getInstallmentsPlan

This guide shows how to build a minimal native iOS app (Swift) using `WKWebView` to load the dLocal Direct JS SDK and bridge three operations to native:

- createToken(name, cvv, expirationMonth, expirationYear, pan, country)
- getBinInformation(bin, country)
- getInstallmentsPlan(amount, currency, country, bin)

Reference: dLocal Direct JS SDK `https://js.dlocal.com/direct`

### 1) Prerequisites

- Xcode 15+
- iOS 13+

### 2) Create a new iOS project

- App → Swift → Storyboard or SwiftUI (sample uses programmatic UI)

### 3) Info.plist: App Transport Security (if needed)

To load `https://js.dlocal.com/direct` you typically don’t need special ATS rules. If you test non-HTTPS content, add ATS exceptions accordingly.

### 4) ViewController with WKWebView and bridge

Create `ViewController.swift`:

```swift
import UIKit
import WebKit

class ViewController: UIViewController, WKScriptMessageHandler {
  private var webView: WKWebView!

  override func viewDidLoad() {
    super.viewDidLoad()

    let contentController = WKUserContentController()
    // Receive messages from JS → Swift
    contentController.add(self, name: "iosBridge")

    let config = WKWebViewConfiguration()
    config.userContentController = contentController

    webView = WKWebView(frame: self.view.bounds, configuration: config)
    webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    view.addSubview(webView)

    webView.loadHTMLString(html, baseURL: nil)

    // Examples: send messages after a small delay (replace YOUR_PUBLIC_KEY)
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
      self.sendCreateToken(
        publicKey: "YOUR_PUBLIC_KEY",
        name: "JOHN DOE",
        cvv: "123",
        expirationMonth: "12",
        expirationYear: "30",
        pan: "4111111111111111",
        country: "AR"
      )
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
      self.sendGetBinInformation(publicKey: "YOUR_PUBLIC_KEY", bin: "411111", country: "AR")
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
      self.sendGetInstallmentsPlan(publicKey: "YOUR_PUBLIC_KEY", amount: 100, currency: "USD", country: "AR", bin: "411111")
    }
  }

  // Receive messages from JS
  func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
    guard message.name == "iosBridge" else { return }
    if let json = message.body as? String {
      print("dLocalBridge:", json)
      // TODO: Parse JSON and update UI as desired
    }
  }

  // Native → JS: evaluate a function with a JSON string
  private func postToWeb(json: String) {
    let js = "window.handleMessageFromNative(" + json.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"") + ");"
    webView.evaluateJavaScript(js, completionHandler: nil)
  }

  func sendCreateToken(publicKey: String, name: String, cvv: String, expirationMonth: String, expirationYear: String, pan: String, country: String) {
    let payload: [String: Any] = [
      "name": name,
      "cvv": cvv,
      "expirationMonth": expirationMonth,
      "expirationYear": expirationYear,
      "pan": pan,
      "country": country
    ]
    let message: [String: Any] = [
      "action": "createToken",
      "key": publicKey,
      "payload": payload
    ]
    let data = try! JSONSerialization.data(withJSONObject: message, options: [])
    let json = String(data: data, encoding: .utf8)!
    postToWeb(json: json)
  }

  func sendGetBinInformation(publicKey: String, bin: String, country: String) {
    let args: [Any] = [bin, country]
    let message: [String: Any] = [
      "action": "getBinInformation",
      "key": publicKey,
      "args": args
    ]
    let data = try! JSONSerialization.data(withJSONObject: message, options: [])
    let json = String(data: data, encoding: .utf8)!
    postToWeb(json: json)
  }

  func sendGetInstallmentsPlan(publicKey: String, amount: Int, currency: String, country: String, bin: String) {
    let args: [Any] = [amount, currency, country, bin] // required order
    let message: [String: Any] = [
      "action": "getInstallmentsPlan",
      "key": publicKey,
      "args": args
    ]
    let data = try! JSONSerialization.data(withJSONObject: message, options: [])
    let json = String(data: data, encoding: .utf8)!
    postToWeb(json: json)
  }

  private var html: String {
    return """
    <!doctype html>
    <html>
      <head>
        <meta charset=\"utf-8\" />
        <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\" />
        <title>dLocal Direct Bridge</title>
        <script src=\"https://js.dlocal.com/direct\"></script>
        <style>
          body { font-family: -apple-system, -apple-system, Helvetica, Arial, sans-serif; padding: 12px; }
          pre { white-space: pre-wrap; word-break: break-word; background: #f6f8fa; padding: 8px; border-radius: 6px; }
        </style>
      </head>
      <body>
        <div>dLocal SDK loaded in WKWebView</div>
        <pre id=\"out\">Waiting...</pre>
        <script>
          const out = document.getElementById('out');
          function log(x){ try{ out.textContent = typeof x==='string'? x : JSON.stringify(x, null, 2);}catch(e){ out.textContent=String(x);} }

          function postToiOS(obj){
            try {
              window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.iosBridge && window.webkit.messageHandlers.iosBridge.postMessage(JSON.stringify(obj));
            } catch (e) {}
          }

          function safeStringify(v){
            try{ const seen=new WeakSet(); return JSON.stringify(v, (_,val)=>{
              if (typeof val==='object' && val){ if(seen.has(val)) return '[Circular]'; seen.add(val);} return val;
            }); } catch(e){ try{ return String(v);}catch(_){return '[Unserializable]';} }
          }

          function serializeError(err){
            const base = {
              name: err && err.name,
              message: err && typeof err.message!=='undefined' ? (typeof err.message==='string'? err.message : safeStringify(err.message)) : String(err),
              code: err && err.code,
              status: err && (err.status || err.statusCode),
              stack: err && err.stack,
            };
            if (err && typeof err==='object'){
              if (err.data!==undefined) base.data=err.data;
              if (err.details!==undefined) base.details=err.details;
              if (err.errors!==undefined) base.errors=err.errors;
              if (err.error!==undefined) base.error=err.error;
              if (err.response) base.response = {status: err.response.status, statusText: err.response.statusText, data: err.response.data};
              try{ Object.keys(err).forEach(k=>{ if(!(k in base)) base[k]=err[k]; }); }catch(_){ }
            }
            return base;
          }

          async function handleMessageFromNative(raw){
            let data; try{ data = JSON.parse(raw); }catch(e){ return postToiOS({ type:'error', payload:{ message:'Invalid JSON from native', raw } }); }
            const { action, key, payload, args } = data||{};
            if (!action) return postToiOS({ type:'error', payload:{ message:'Missing action' } });
            if (!key) return postToiOS({ type:'error', payload:{ message:'Missing public key' } });
            try{
              const direct = window.dlocal(key);
              let result;
              switch(action){
                case 'createToken':
                  result = await direct.createToken(payload);
                  break;
                case 'getBinInformation':
                  result = await direct.getBinInformation.apply(null, Array.isArray(args)? args : []);
                  break;
                case 'getInstallmentsPlan':
                  result = await direct.getInstallmentsPlan.apply(null, Array.isArray(args)? args : []);
                  break;
                default:
                  return postToiOS({ type:'error', payload:{ message:'Unknown action: '+action } });
              }
              postToiOS({ type:'success', payload:{ action, result } });
              log({ action, result });
            }catch(err){
              const serialized = serializeError(err);
              postToiOS({ type:'error', payload: serialized });
              log(serialized);
            }
          }

          window.handleMessageFromNative = handleMessageFromNative;
        </script>
      </body>
    </html>
    """
  }
}
```

### 5) How to use

- Replace `YOUR_PUBLIC_KEY` with your dLocal public key.
- Run the app and observe console logs from the bridge.
- Wire `sendCreateToken`, `sendGetBinInformation`, `sendGetInstallmentsPlan` to buttons or other UI.

### 6) Notes

- Only use your PUBLIC key on-device; never store secrets in the app.
- The bridge returns JSON strings like `{ type: 'success'|'error', payload: {...} }`.
- You can move the HTML to a local file or bundle as needed.

Reference: dLocal Direct JS SDK `https://js.dlocal.com/direct`
