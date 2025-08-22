package com.dlocal.directwebview

import android.annotation.SuppressLint
import android.os.Bundle
import android.webkit.JavascriptInterface
import android.webkit.WebChromeClient
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.Button
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.appcompat.widget.Toolbar
import com.google.android.material.textfield.TextInputEditText
import org.json.JSONObject

class CreateTokenActivity : AppCompatActivity() {
    private lateinit var webView: WebView
    private var isSDKReady = false
    private lateinit var tvResponse: TextView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_create_token)

        setupToolbar()
        initializeViews()
        setupWebView()
        setupButtonClickListener()
    }

    private fun setupToolbar() {
        val toolbar = findViewById<Toolbar>(R.id.toolbar)
        setSupportActionBar(toolbar)
        supportActionBar?.title = "Create Token"
        supportActionBar?.setDisplayHomeAsUpEnabled(true)
    }

    override fun onSupportNavigateUp(): Boolean {
        finish()
        return true
    }

    private fun initializeViews() {
        tvResponse = findViewById(R.id.tvResponse)
    }

    @SuppressLint("SetJavaScriptEnabled")
    private fun setupWebView() {
        webView = WebView(this)
        webView.settings.javaScriptEnabled = true
        webView.webViewClient = object : WebViewClient() {
            override fun onPageFinished(view: WebView?, url: String?) {
                super.onPageFinished(view, url)
                // Inject the bridge functions after the page loads
                injectBridgeFunctions()
            }
        }
        webView.webChromeClient = WebChromeClient()

        // Bridge for messages from JS → Kotlin
        webView.addJavascriptInterface(object : Any() {
            @JavascriptInterface
            fun postMessage(message: String) {
                runOnUiThread {
                    try {
                        val jsonMessage = JSONObject(message)
                        val type = jsonMessage.getString("type")
                        val payload = jsonMessage.getJSONObject("payload")
                        
                        when (type) {
                            "success" -> {
                                tvResponse.text = "SUCCESS:\n${payload.toString(2)}"
                                Toast.makeText(this@CreateTokenActivity, "Token created successfully!", Toast.LENGTH_SHORT).show()
                            }
                            "error" -> {
                                tvResponse.text = "ERROR:\n${payload.toString(2)}"
                                Toast.makeText(this@CreateTokenActivity, "Error: ${payload.optString("message", "Unknown error")}", Toast.LENGTH_LONG).show()
                            }
                        }
                    } catch (e: Exception) {
                        tvResponse.text = "ERROR parsing response:\n$message"
                        Toast.makeText(this@CreateTokenActivity, "Error parsing response", Toast.LENGTH_SHORT).show()
                    }
                }
            }
        }, "AndroidBridge")

        // Load the HTML content
        webView.loadDataWithBaseURL(null, getHtmlContent(), "text/html", "UTF-8", null)
    }

    private fun setupButtonClickListener() {
        findViewById<Button>(R.id.btnCreateToken).setOnClickListener {
            if (isSDKReady) {
                onCreateTokenClick()
            } else {
                Toast.makeText(this, "Please wait for dLocal SDK to load...", Toast.LENGTH_SHORT).show()
            }
        }
    }

    private fun onCreateTokenClick() {
        val publicKey = findViewById<TextInputEditText>(R.id.etPublicKey).text.toString()
        val name = findViewById<TextInputEditText>(R.id.etName).text.toString()
        val cvv = findViewById<TextInputEditText>(R.id.etCvv).text.toString()
        val expirationMonth = findViewById<TextInputEditText>(R.id.etExpirationMonth).text.toString()
        val expirationYear = findViewById<TextInputEditText>(R.id.etExpirationYear).text.toString()
        val pan = findViewById<TextInputEditText>(R.id.etPan).text.toString()
        val country = findViewById<TextInputEditText>(R.id.etCountry).text.toString()

        // Validate inputs
        if (publicKey.isBlank() || name.isBlank() || cvv.isBlank() || 
            expirationMonth.isBlank() || expirationYear.isBlank() || 
            pan.isBlank() || country.isBlank()) {
            Toast.makeText(this, "Please fill all fields", Toast.LENGTH_SHORT).show()
            return
        }

        sendCreateToken(publicKey, name, cvv, expirationMonth, expirationYear, pan, country)
        Toast.makeText(this, "Create Token requested!", Toast.LENGTH_SHORT).show()
    }

    private fun injectBridgeFunctions() {
        val js = """
            // SDK loaded callback
            window.onSdkReady = function() {
                AndroidBridge.postMessage(JSON.stringify({
                    type: 'sdk_ready',
                    payload: { message: 'SDK loaded successfully' }
                }));
            };
            
            // Check if SDK is already loaded
            if (typeof window.dlocal !== 'undefined') {
                AndroidBridge.postMessage(JSON.stringify({
                    type: 'sdk_ready',
                    payload: { message: 'SDK already loaded' }
                }));
            }
        """.trimIndent()
        
        webView.evaluateJavascript(js) { result ->
            isSDKReady = true
        }
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

    // Native → JS: Send a JSON message the page understands
    private fun postToWeb(message: JSONObject) {
        val js = "window.handleMessageFromNative(" + JSONObject.quote(message.toString()) + ");"
        webView.evaluateJavascript(js, null)
    }

    private fun getHtmlContent(): String {
        return """
        <!doctype html>
        <html>
          <head>
            <meta charset="utf-8" />
            <meta name="viewport" content="width=device-width, initial-scale=1" />
            <title>dLocal Direct Bridge</title>
            <script src="https://js.dlocal.com/direct"></script>
          </head>
          <body>
            <div>dLocal SDK loaded in WebView</div>
            <script>
              function postToAndroid(obj){
                try {
                  AndroidBridge.postMessage(JSON.stringify(obj));
                } catch (e) {
                  console.error('Error posting to Android:', e);
                }
              }

              function safeStringify(v){
                try{ 
                  const seen=new WeakSet(); 
                  return JSON.stringify(v, (_,val)=>{
                    if (typeof val==='object' && val){ 
                      if(seen.has(val)) return '[Circular]'; 
                      seen.add(val);
                    } 
                    return val;
                  }); 
                } catch(e){ 
                  try{ return String(v);}catch(_){return '[Unserializable]';} 
                }
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
                let data; 
                try{ data = JSON.parse(raw); }catch(e){ 
                  return postToAndroid({ type:'error', payload:{ message:'Invalid JSON from native', raw } }); 
                }
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
                    default:
                      return postToAndroid({ type:'error', payload:{ message:'Unknown action: '+action } });
                  }
                  postToAndroid({ type:'success', payload:{ action, result } });
                }catch(err){
                  const serialized = serializeError(err);
                  postToAndroid({ type:'error', payload: serialized });
                }
              }

              window.handleMessageFromNative = handleMessageFromNative;
              
              // Notify when SDK is ready
              if (window.onSdkReady) {
                window.onSdkReady();
              }
            </script>
          </body>
        </html>
        """.trimIndent()
    }
}
