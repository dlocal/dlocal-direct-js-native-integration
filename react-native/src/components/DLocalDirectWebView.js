import React, {
  forwardRef,
  useImperativeHandle,
  useMemo,
  useRef,
  useCallback,
} from "react";
import { StyleSheet } from "react-native";
import { WebView } from "react-native-webview";

// Reusable WebView bridge component for dLocal Direct SDK
// Exposes imperative methods via ref: createToken, getBinInformation, getInstallmentsPlan

const DLocalDirectWebView = forwardRef(function DLocalDirectWebView(
  { publicKey, onEvent, debug = false, style },
  ref
) {
  const webViewRef = useRef(null);

  const html = useMemo(() => {
    return `<!doctype html>
<html>
  <head>
    <meta charset=\"utf-8\" />
    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\" />
    <title>dLocal Direct Bridge</title>
    <style>
      html, body { margin: 0; padding: 0; font-family: -apple-system, Roboto, Helvetica, Arial, sans-serif; }
      .root { padding: 12px; }
      pre { white-space: pre-wrap; word-break: break-word; background: #f6f8fa; padding: 8px; border-radius: 6px; }
      .muted { color: #666; }
    </style>
    <script src=\"https://js.dlocal.com/direct\"></script>
  </head>
  <body>
    <div class=\"root\">
      <div class=\"muted\">dLocal Direct JS loaded inside WebView</div>
      <pre id=\"out\">Waiting for messages from React Native...</pre>
    </div>
    <script>
      const out = document.getElementById('out');

      function log(msg) {
        try { out.textContent = typeof msg === 'string' ? msg : JSON.stringify(msg, null, 2); } catch (e) { out.textContent = String(msg); }
      }

      function sendToRN(type, payload) {
        window.ReactNativeWebView && window.ReactNativeWebView.postMessage(JSON.stringify({ type, payload }));
      }

      function safeStringify(value) {
        try {
          const seen = new WeakSet();
          return JSON.stringify(value, function(_, v) {
            if (typeof v === 'object' && v !== null) {
              if (seen.has(v)) return '[Circular]';
              seen.add(v);
            }
            return v;
          });
        } catch (e) {
          try { return String(value); } catch (_) { return '[Unserializable]'; }
        }
      }

      function toReadableString(v) {
        if (typeof v === 'string') return v;
        try { return safeStringify(v); } catch (_) { return String(v); }
      }

      function serializeError(err) {
        const base = {
          name: err && err.name,
          message: err && typeof err.message !== 'undefined' ? toReadableString(err.message) : toReadableString(err),
          code: err && err.code,
          status: (err && (err.status || err.statusCode)) || undefined,
          stack: err && err.stack,
        };
        if (err && typeof err === 'object') {
          if (err.data !== undefined) base.data = err.data;
          if (err.details !== undefined) base.details = err.details;
          if (err.errors !== undefined) base.errors = err.errors;
          if (err.error !== undefined) base.error = err.error;
          if (err.response) {
            const r = err.response;
            base.response = {
              status: r.status,
              statusText: r.statusText,
              data: r.data,
              headers: r.headers,
              url: r.url
            };
          }
          try { Object.keys(err).forEach((k) => { if (!(k in base)) base[k] = err[k]; }); } catch (_) {}
        }
        return base;
      }

      async function handleMessage(raw) {
        let data;
        try { data = JSON.parse(raw); } catch (e) { return sendToRN('error', { message: 'Invalid JSON from RN', raw }); }
        const { action, key, payload, args } = data || {};
        if (!action) { return sendToRN('error', { message: 'Missing action' }); }
        if (!key) { return sendToRN('error', { message: 'Missing public key' }); }
        try {
          const direct = window.dlocal(key);
          let result;
          switch (action) {
            case 'createToken': {
              result = await direct.createToken(payload);
              break;
            }
            case 'getBinInformation': {
              result = await direct.getBinInformation.apply(null, Array.isArray(args) ? args : []);
              break;
            }
            case 'getInstallmentsPlan': {
              result = await direct.getInstallmentsPlan.apply(null, Array.isArray(args) ? args : []);
              break;
            }
            default: {
              return sendToRN('error', { message: 'Unknown action: ' + action });
            }
          }
          sendToRN('success', { action, result });
          log({ action, result });
        } catch (err) {
          const serialized = serializeError(err);
          sendToRN('error', serialized);
          log(serialized);
        }
      }

      function onMessageEvent(e) { handleMessage(e && (e.data || e.message || e.detail)); }
      document.addEventListener('message', onMessageEvent);
      window.addEventListener('message', onMessageEvent);
    </script>
  </body>
</html>`;
  }, []);

  const postToWeb = useCallback((message) => {
    if (!webViewRef.current) return;
    webViewRef.current.postMessage(JSON.stringify(message));
  }, []);

  useImperativeHandle(
    ref,
    () => ({
      createToken(payload) {
        postToWeb({ action: "createToken", key: publicKey, payload });
      },
      getBinInformation(bin, country) {
        postToWeb({
          action: "getBinInformation",
          key: publicKey,
          args: [bin, country],
        });
      },
      getInstallmentsPlan(amount, currency, country, bin) {
        postToWeb({
          action: "getInstallmentsPlan",
          key: publicKey,
          args: [Number(amount), currency, country, bin],
        });
      },
    }),
    [postToWeb, publicKey]
  );

  const handleMessage = useCallback(
    (event) => {
      try {
        const data = JSON.parse(event.nativeEvent.data);
        onEvent && onEvent(data);
      } catch (e) {
        onEvent &&
          onEvent({
            type: "error",
            payload: {
              message: String(event.nativeEvent.data || "Unknown message"),
            },
          });
      }
    },
    [onEvent]
  );

  return (
    <WebView
      ref={webViewRef}
      originWhitelist={["*"]}
      source={{ html }}
      onMessage={handleMessage}
      javaScriptEnabled
      style={[styles.webview, debug ? styles.debug : null, style]}
    />
  );
});

const styles = StyleSheet.create({
  webview: {
    position: "absolute",
    bottom: 0,
    left: 0,
    right: 0,
    height: 1,
    opacity: 0.01,
  },
  debug: {
    position: "relative",
    height: 300,
    opacity: 1,
  },
});

export default DLocalDirectWebView;
