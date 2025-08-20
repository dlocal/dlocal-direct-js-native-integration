## Android (Kotlin) WebView + dLocal Direct SDK: createToken, getBinInformation, getInstallmentsPlan

This guide shows how to build a minimal native Android app (Kotlin) that embeds a WebView, loads the dLocal Direct JS SDK, and bridges three operations to native UI:

- createToken(name, cvv, expirationMonth, expirationYear, pan, country)
- getBinInformation(bin, country)
- getInstallmentsPlan(amount, currency, country, bin)

Reference: dLocal Direct JS SDK `https://js.dlocal.com/direct`

### 1) Prerequisites

- Android Studio (Giraffe or newer)
- Min SDK 24+

### 2) Create a new Android project

- New Project → Empty Activity (Kotlin)
- Package name as desired
- Finish

### 3) AndroidManifest: Internet permission

Add to `app/src/main/AndroidManifest.xml` inside the `<manifest>`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

### 4) Activity layout (optional UI)

For brevity, this example sends hardcoded sample data from Kotlin. You can later add `EditText`/`Button` inputs.

### 5) MainActivity.kt – WebView + JS bridge

Create or replace `app/src/main/java/.../MainActivity.kt` with:

```kotlin
package your.package.name

import android.annotation.SuppressLint
import android.os.Bundle
import android.webkit.JavascriptInterface
import android.webkit.WebChromeClient
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.activity.ComponentActivity
import androidx.activity.enableEdgeToEdge
import org.json.JSONObject

class MainActivity : ComponentActivity() {
  private lateinit var webView: WebView

  @SuppressLint("SetJavaScriptEnabled")
  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    enableEdgeToEdge()

    webView = WebView(this)
    setContentView(webView)

    webView.settings.javaScriptEnabled = true
    webView.settings.domStorageEnabled = true
    webView.webViewClient = WebViewClient()
    webView.webChromeClient = WebChromeClient()

    // Bridge for messages from JS → Kotlin
    webView.addJavascriptInterface(object : Any() {
      @JavascriptInterface
      fun postMessage(message: String) {
        // message is a JSON string: { type: 'success'|'error', payload: {...} }
        runOnUiThread {
          // TODO: Display in UI/Logcat
          android.util.Log.d("dLocalBridge", message)
        }
      }
    }, "AndroidBridge")

    // Load the HTML that includes dLocal SDK and the bridge
    webView.loadDataWithBaseURL(
      /* baseUrl = */ null,
      /* data = */ html,
      /* mimeType = */ "text/html",
      /* encoding = */ "utf-8",
      /* historyUrl = */ null
    )

    // EXAMPLES: trigger operations after load (use your real public key and inputs)
    webView.postDelayed({
      sendCreateToken(
        publicKey = "YOUR_PUBLIC_KEY",
        name = "JOHN DOE",
        cvv = "123",
        expirationMonth = "12",
        expirationYear = "30",
        pan = "4111111111111111",
        country = "AR"
      )
    }, 1000)

    webView.postDelayed({
      sendGetBinInformation(publicKey = "YOUR_PUBLIC_KEY", bin = "411111", country = "AR")
    }, 2000)

    webView.postDelayed({
      sendGetInstallmentsPlan(publicKey = "YOUR_PUBLIC_KEY", amount = 100, currency = "USD", country = "AR", bin = "411111")
    }, 3000)
  }

  // Native → JS: Send a JSON message the page understands
  private fun postToWeb(message: JSONObject) {
    val js = "window.handleMessageFromNative(" + JSONObject.quote(message.toString()) + ");"
    webView.evaluateJavascript(js, null)
  }

  private fun sendCreateToken(
    publicKey: String,
    name: String,
    cvv: String,
    expirationMonth: String,
    expirationYear: String,
    pan: String,
    country: String
  ) {
    val payload = JSONObject()
      .put("name", name)
      .put("cvv", cvv)
      .put("expirationMonth", expirationMonth)
      .put("expirationYear", expirationYear)
      .put("pan", pan)
      .put("country", country)

    val message = JSONObject()
      .put("action", "createToken")
      .put("key", publicKey)
      .put("payload", payload)

    postToWeb(message)
  }

  private fun sendGetBinInformation(publicKey: String, bin: String, country: String) {
    val args = org.json.JSONArray().put(bin).put(country)
    val message = JSONObject()
      .put("action", "getBinInformation")
      .put("key", publicKey)
      .put("args", args)
    postToWeb(message)
  }

  private fun sendGetInstallmentsPlan(publicKey: String, amount: Int, currency: String, country: String, bin: String) {
    // Required order: amount, currency, country, bin
    val args = org.json.JSONArray().put(amount).put(currency).put(country).put(bin)
    val message = JSONObject()
      .put("action", "getInstallmentsPlan")
      .put("key", publicKey)
      .put("args", args)
    postToWeb(message)
  }

  private val html: String by lazy {
    """
    <!doctype html>
    <html>
      <head>
        <meta charset=\"utf-8\" />
        <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\" />
        <title>dLocal Direct Bridge</title>
        <script src=\"https://js.dlocal.com/direct\"></script>
        <style>
          body { font-family: -apple-system, Roboto, Helvetica, Arial, sans-serif; padding: 12px; }
          pre { white-space: pre-wrap; word-break: break-word; background: #f6f8fa; padding: 8px; border-radius: 6px; }
        </style>
      </head>
      <body>
        <div>dLocal SDK loaded in WebView</div>
        <pre id=\"out\">Waiting...</pre>
        <script>
          const out = document.getElementById('out');
          function log(x){ try{ out.textContent = typeof x==='string'? x : JSON.stringify(x, null, 2);}catch(e){ out.textContent=String(x);} }

          function postToAndroid(obj){
            if (window.AndroidBridge && window.AndroidBridge.postMessage) {
              window.AndroidBridge.postMessage(JSON.stringify(obj));
            }
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
            let data; try{ data = JSON.parse(raw); }catch(e){ return postToAndroid({ type:'error', payload:{ message:'Invalid JSON from native', raw } }); }
            const { action, key, payload, args } = data||{};
            if (!action) return postToAndroid({ type:'error', payload:{ message:'Missing action' } });
            if (!key) return postToAndroid({ type:'error', payload:{ message:'Missing public key' } });
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
                  return postToAndroid({ type:'error', payload:{ message:'Unknown action: '+action } });
              }
              postToAndroid({ type:'success', payload:{ action, result } });
              log({ action, result });
            }catch(err){
              const serialized = serializeError(err);
              postToAndroid({ type:'error', payload: serialized });
              log(serialized);
            }
          }

          // Expose globally for native evaluateJavascript
          window.handleMessageFromNative = handleMessageFromNative;
        </script>
      </body>
    </html>
    """.trimIndent()
  }
}
```

### 6) How to use

- Replace `YOUR_PUBLIC_KEY` with your dLocal public key.
- Run the app. Check Logcat for messages from the JS bridge.
- Wire the `sendCreateToken`, `sendGetBinInformation`, and `sendGetInstallmentsPlan` to UI buttons as needed.

### 7) Notes

- Only use your PUBLIC key on-device; never store secrets in the app.
- Handle errors from the bridge (they return `{ type: 'error', payload: {...} }`).
- You can move the HTML to `android_asset` or serve it from a local file if preferred.

Reference: dLocal Direct JS SDK `https://js.dlocal.com/direct`
