package com.dlocal.directwebview

import android.annotation.SuppressLint
import android.os.Bundle
import android.webkit.JavascriptInterface
import android.webkit.WebChromeClient
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.Button
import android.widget.Toast
import androidx.activity.enableEdgeToEdge
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import org.json.JSONObject

class MainActivity : AppCompatActivity() {
    private lateinit var webView: WebView
    private var isSDKReady = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContentView(R.layout.activity_main)
        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.main)) { v, insets ->
            val systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars())
            v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom)
            insets
        }

        setupWebView()
        setupButtonClickListeners()
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
                // message is a JSON string: { type: 'success'|'error', payload: {...} }
                runOnUiThread {
                    // Display in UI/Logcat
                    android.util.Log.d("dLocalBridge", message)
                    Toast.makeText(this@MainActivity, "JS Response: $message", Toast.LENGTH_LONG).show()
                }
            }

            @JavascriptInterface
            fun onSDKReady() {
                runOnUiThread {
                    isSDKReady = true
                    android.util.Log.d("dLocalBridge", "SDK is ready!")
                    Toast.makeText(this@MainActivity, "dLocal SDK is ready!", Toast.LENGTH_SHORT).show()
                }
            }
        }, "AndroidBridge")

        // Load a minimal HTML page that includes the dLocal SDK
        val html = """
            <!DOCTYPE html>
            <html>
            <head>
                <meta charset="utf-8">
                <title>dLocal Bridge</title>
            </head>
            <body>
                <script>
                    // Load the dLocal SDK
                    const script = document.createElement('script');
                    script.src = 'https://js.dlocal.com/direct';
                    script.onload = function() {
                        // Check if dlocal function is available
                        if (typeof window.dlocal === 'function') {
                            console.log('dLocal SDK loaded successfully');
                            if (window.AndroidBridge && window.AndroidBridge.onSDKReady) {
                                window.AndroidBridge.onSDKReady();
                            }
                        } else {
                            console.error('dLocal SDK failed to load properly');
                        }
                    };
                    script.onerror = function() {
                        console.error('Failed to load dLocal SDK');
                    };
                    document.head.appendChild(script);
                </script>
            </body>
            </html>
        """.trimIndent()

        webView.loadDataWithBaseURL(
            /* baseUrl = */ null,
            /* data = */ html,
            /* mimeType = */ "text/html",
            /* encoding = */ "utf-8",
            /* historyUrl = */ null
        )
    }

    private fun injectBridgeFunctions() {
        val bridgeScript = """
            function postToAndroid(obj) {
                if (window.AndroidBridge && window.AndroidBridge.postMessage) {
                    window.AndroidBridge.postMessage(JSON.stringify(obj));
                }
            }

            function safeStringify(v) {
                try {
                    const seen = new WeakSet();
                    return JSON.stringify(v, (_, val) => {
                        if (typeof val === 'object' && val) {
                            if (seen.has(val)) return '[Circular]';
                            seen.add(val);
                        }
                        return val;
                    });
                } catch (e) {
                    try {
                        return String(v);
                    } catch (_) {
                        return '[Unserializable]';
                    }
                }
            }

            function serializeError(err) {
                const base = {
                    name: err && err.name,
                    message: err && typeof err.message !== 'undefined' ? (typeof err.message === 'string' ? err.message : safeStringify(err.message)) : String(err),
                    code: err && err.code,
                    status: err && (err.status || err.statusCode),
                    stack: err && err.stack,
                };
                if (err && typeof err === 'object') {
                    if (err.data !== undefined) base.data = err.data;
                    if (err.details !== undefined) base.details = err.details;
                    if (err.errors !== undefined) base.errors = err.errors;
                    if (err.error !== undefined) base.error = err.error;
                    if (err.response) base.response = { status: err.response.status, statusText: err.response.statusText, data: err.response.data };
                    try {
                        Object.keys(err).forEach(k => { if (!(k in base)) base[k] = err[k]; });
                    } catch (_) { }
                }
                return base;
            }

            async function handleMessageFromNative(raw) {
                // Check if SDK is ready
                if (typeof window.dlocal !== 'function') {
                    return postToAndroid({ 
                        type: 'error', 
                        payload: { 
                            message: 'dLocal SDK not ready. Please wait for SDK to load.' 
                        } 
                    });
                }

                let data;
                try {
                    data = JSON.parse(raw);
                } catch (e) {
                    return postToAndroid({ type: 'error', payload: { message: 'Invalid JSON from native', raw } });
                }
                const { action, key, payload, args } = data || {};
                if (!action) return postToAndroid({ type: 'error', payload: { message: 'Missing action' } });
                if (!key) return postToAndroid({ type: 'error', payload: { message: 'Missing public key' } });
                try {
                    const direct = window.dlocal(key);
                    let result;
                    switch (action) {
                        case 'createToken':
                            result = await direct.createToken(payload);
                            break;
                        case 'getBinInformation':
                            result = await direct.getBinInformation.apply(null, Array.isArray(args) ? args : []);
                            break;
                        case 'getInstallmentsPlan':
                            result = await direct.getInstallmentsPlan.apply(null, Array.isArray(args) ? args : []);
                            break;
                        default:
                            return postToAndroid({ type: 'error', payload: { message: 'Unknown action: ' + action } });
                    }
                    postToAndroid({ type: 'success', payload: { action, result } });
                } catch (err) {
                    const serialized = serializeError(err);
                    postToAndroid({ type: 'error', payload: serialized });
                }
            }

            // Expose globally for native evaluateJavascript
            window.handleMessageFromNative = handleMessageFromNative;
        """.trimIndent()

        webView.evaluateJavascript(bridgeScript, null)
    }

    private fun setupButtonClickListeners() {
        findViewById<Button>(R.id.btnCreateToken).setOnClickListener {
            if (isSDKReady) {
                onCreateTokenClick()
            } else {
                Toast.makeText(this, "Please wait for dLocal SDK to load...", Toast.LENGTH_SHORT).show()
            }
        }

        findViewById<Button>(R.id.btnGetBinInfo).setOnClickListener {
            if (isSDKReady) {
                onGetBinInfoClick()
            } else {
                Toast.makeText(this, "Please wait for dLocal SDK to load...", Toast.LENGTH_SHORT).show()
            }
        }

        findViewById<Button>(R.id.btnGetInstallments).setOnClickListener {
            if (isSDKReady) {
                onGetInstallmentsClick()
            } else {
                Toast.makeText(this, "Please wait for dLocal SDK to load...", Toast.LENGTH_SHORT).show()
            }
        }
    }

    private fun onCreateTokenClick() {
        // Call sendCreateToken with sample data
        sendCreateToken(
            publicKey = "YOUR_PUBLIC_KEY", // Replace with your actual public key
            name = "JOHN DOE",
            cvv = "123",
            expirationMonth = "12",
            expirationYear = "30",
            pan = "4111111111111111",
            country = "AR"
        )
        Toast.makeText(this, "Create Token requested!", Toast.LENGTH_SHORT).show()
    }

    private fun onGetBinInfoClick() {
        // Call sendGetBinInformation with sample data
        sendGetBinInformation(
            publicKey = "YOUR_PUBLIC_KEY", // Replace with your actual public key
            bin = "411111",
            country = "AR"
        )
        Toast.makeText(this, "Get Bin Information requested!", Toast.LENGTH_SHORT).show()
    }

    private fun onGetInstallmentsClick() {
        // Call sendGetInstallmentsPlan with sample data
        sendGetInstallmentsPlan(
            publicKey = "YOUR_PUBLIC_KEY", // Replace with your actual public key
            amount = 100,
            currency = "USD",
            country = "AR",
            bin = "411111"
        )
        Toast.makeText(this, "Get Installments Plan requested!", Toast.LENGTH_SHORT).show()
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
}