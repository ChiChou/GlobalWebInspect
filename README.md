# GlobalWebinspect

Enable WebView inspector for all iOS apps, requires jailbreak

[ElleKit](https://ellekit.space/) is required to install the tweak.

## Technical Details

For iOS >= 16.4, WebKit allows the app to decide whether to enable WebInspector or not.

https://webkit.org/blog/13936/enabling-the-inspection-of-web-content-in-apps/

This tweak injects to all processes and hook the creation of `JSContext` and `WKWebView` to enable WebInspector.

For older systems, `webinspectord` validates entitlements for each process that has `JSContext` or `WKWebView`.

If any of the following is found, the process will be added to inspector list:

* com.apple.security.get-task-allow
* com.apple.webinspector.allow
* com.apple.private.webinspector.allow-remote-inspection
* com.apple.private.webinspector.allow-carrier-remote-inspection

This tweak injects to `webinspectord` to bypass the entitlement check.

## Build

Assume you already have iproxy and ssh configured

```bash
export ROOTLESS=1  # if built for rootless jailbreak
make package
THEOS_DEVICE_IP=localhost THEOS_DEVICE_PORT=2222 make install
```

## Usage

* Enable WebInspector in Preferences
* Build and install the tweak
* Re-plug the USB cable and restart target app
