## Spike Report: Integrating dLocal Direct JS SDK in React Native via WebView

This spike explored integrating the dLocal Direct JavaScript SDK inside a React Native app using a WebView and a bi-directional message bridge. The goal was to enable three core operations from native UI:

- createToken(name, cvv, expirationMonth, expirationYear, pan, country)
- getBinInformation(bin, country)
- getInstallmentsPlan(amount, currency, country, bin)

SDK reference: [dLocal Direct JS SDK](https://js.dlocal.com/direct)

### Approach

- Embed an invisible WebView that loads a minimal HTML page.
- Load the dLocal Direct SDK from the official CDN within that page.
- Implement a simple JSON message protocol between React Native and the WebView using `postMessage`.
- Expose imperative methods to the RN layer so the WebView can be reused like a drop-in bridge component.

### Architecture

- Reusable component: `src/components/DLocalDirectWebView.js`
  - Props: `publicKey`, `onEvent`, `debug`, `style`
  - Methods (via ref):
    - `createToken(payload)`
    - `getBinInformation(bin, country)`
    - `getInstallmentsPlan(amount, currency, country, bin)`
  - Internals:
    - Injected HTML loads the SDK and listens for RN messages
    - Executes `window.dlocal(publicKey)` then the requested action
    - Sends results or errors back to RN as JSON

### Bridge protocol

- RN → WebView: a single JSON message
  - `{ action: string, key: string, payload?: object, args?: any[] }`
  - Examples:
    - `createToken`: `{ action: "createToken", key, payload }`
    - `getBinInformation`: `{ action: "getBinInformation", key, args: [bin, country] }`
    - `getInstallmentsPlan`: `{ action: "getInstallmentsPlan", key, args: [amount, currency, country, bin] }`
- WebView → RN: result envelope
  - Success: `{ type: "success", payload: { action, result } }`
  - Error: `{ type: "error", payload: { ...serializedError } }`

### Operations implemented

- createToken
  - Expected payload: `{ name, cvv, expirationMonth, expirationYear, pan, country }`
- getBinInformation
  - Args: `[bin, country]`
- getInstallmentsPlan
  - Args: `[amount:number, currency:string, country:string, bin:string]`

### Error handling

- The HTML page serializes errors into readable JSON to avoid "[object Object]" issues.
- Serializer includes: `name`, `message`, `code`, `status`, `stack`, plus optional `data`, `details`, `errors`, `response`.
- RN layer passes these through to the UI, ensuring detailed diagnostics.

### Security considerations

- Only the public key is used on-device. No secret keys are bundled.
- WebView is set to hidden by default; `debug` prop can reveal it for troubleshooting.
- Consider CSP and allowed origins if loading additional remote resources.

### Platform notes

- React Native: uses `react-native-webview` for Android/iOS.
- The WebView is mounted headlessly (`height: 1`, nearly transparent) and acts as a bridge.
- The solution is compatible with Expo-managed workflow.

### Limitations and trade-offs

- Requires network access to the SDK CDN (`https://js.dlocal.com/direct`).
- Debugging inside the WebView is less convenient than native SDKs.
- If dLocal changes the SDK API, the bridge must be updated accordingly.

### Packaging and reuse

- The component is isolated under `src/components/DLocalDirectWebView.js` with a small, stable API.
- To publish:
  - Add an `src/index.js` that re-exports the component.
  - Configure `package.json` with proper `name`, `version`, and `main`.
  - Publish to a private registry or npm as needed.

### Outcome

- The spike confirms feasibility: React Native can invoke dLocal Direct JS operations through a WebView bridge with robust error handling and clean native-facing APIs.
