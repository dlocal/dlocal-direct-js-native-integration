//
//  WebViewManager.swift
//  DirectTest
//
//  Created by Adrian DeLeon on 21/8/25.
//

import SwiftUI
import WebKit

// WebView Manager
class WebViewManager: NSObject, ObservableObject {
    @Published var webViewStatus = "Initializing"
    @Published var responseText = "Response will appear here..."
    private var webView: WKWebView?
    
    func initializeWebView() {
        // Create WebView programmatically
        let contentController = WKUserContentController()
        contentController.add(self, name: "iosBridge")
        
        let config = WKWebViewConfiguration()
        config.userContentController = contentController
        
        let webView = WKWebView(frame: .zero, configuration: config)
        self.webView = webView
        
        // Load the HTML content
        webView.loadHTMLString(htmlContent, baseURL: nil)
        
        // Update status
        DispatchQueue.main.async {
            self.webViewStatus = "Ready"
        }
        
        print("WebView initialized successfully")
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
        sendMessageToWebView(message)
    }
    
    func sendGetBinInformation(publicKey: String, bin: String, country: String) {
        let args: [Any] = [bin, country]
        let message: [String: Any] = [
            "action": "getBinInformation",
            "key": publicKey,
            "args": args
        ]
        sendMessageToWebView(message)
    }
    
    func sendGetInstallmentsPlan(publicKey: String, amount: Int, currency: String, country: String, bin: String) {
        let args: [Any] = [amount, currency, country, bin]
        let message: [String: Any] = [
            "action": "getInstallmentsPlan",
            "key": publicKey,
            "args": args
        ]
        sendMessageToWebView(message)
    }
    
    private func sendMessageToWebView(_ message: [String: Any]) {
        guard let webView = webView else { 
            print("WebView not available yet")
            return 
        }
        
        do {
            let data = try JSONSerialization.data(withJSONObject: message, options: [])
            let json = String(data: data, encoding: .utf8)!
            
            // Properly escape the JSON for JavaScript
            let escapedJson = json.replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "\"", with: "\\\"")
                .replacingOccurrences(of: "\n", with: "\\n")
                .replacingOccurrences(of: "\r", with: "\\r")
                .replacingOccurrences(of: "\t", with: "\\t")
            
            let js = "window.handleMessageFromNative(\"\(escapedJson)\");"
            
            DispatchQueue.main.async {
                webView.evaluateJavaScript(js) { result, error in
                    if let error = error {
                        print("JavaScript evaluation error: \(error)")
                    } else {
                        print("JavaScript executed successfully for action: \(message["action"] ?? "unknown")")
                    }
                }
            }
        } catch {
            print("JSON serialization error: \(error)")
        }
    }
    
    private var htmlContent: String {
        return """
        <!doctype html>
        <html>
          <head>
            <meta charset="utf-8" />
            <meta name="viewport" content="width=device-width, initial-scale=1" />
            <title>dLocal Direct Bridge</title>
            <script src="https://js.dlocal.com/direct"></script>
            <style>
              body { font-family: -apple-system, -apple-system, Helvetica, Arial, sans-serif; padding: 12px; }
              pre { white-space: pre-wrap; word-break: break-word; background: #f6f8fa; padding: 8px; border-radius: 6px; }
            </style>
          </head>
          <body>
            <div>dLocal SDK loaded in WKWebView</div>
            <pre id="out">Waiting...</pre>
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

// Make WebViewManager conform to WKScriptMessageHandler
extension WebViewManager: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "iosBridge" else { return }
        if let json = message.body as? String {
            print("dLocalBridge:", json)
            
            // Parse JSON and update UI
            DispatchQueue.main.async {
                do {
                    if let data = json.data(using: .utf8),
                       let jsonObj = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        
                        let type = jsonObj["type"] as? String ?? "unknown"
                        let payload = jsonObj["payload"] as? [String: Any] ?? [:]
                        
                        switch type {
                        case "success":
                            if let action = payload["action"] as? String,
                               let result = payload["result"] {
                                self.responseText = "SUCCESS:\nAction: \(action)\nResult: \(result)"
                            }
                        case "error":
                            if let message = payload["message"] as? String {
                                self.responseText = "ERROR:\n\(message)"
                            }
                        default:
                            self.responseText = "Response:\n\(json)"
                        }
                    }
                } catch {
                    self.responseText = "Error parsing response:\n\(json)"
                }
            }
        }
    }
}
