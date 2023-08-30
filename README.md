# GlobalWebinspect

Enable WebView inspector for all iOS apps, requires jailbreak

## Important note after Safari 16.4

From Safari 16.4, the webinspector works differently. This tweak does not apply to such versions.
https://webkit.org/blog/13936/enabling-the-inspection-of-web-content-in-apps/

## Usage

* Enable WebInspector in Preferences
* Build and install the tweak `THEOS_DEVICE_IP=localhost THEOS_DEVICE_PORT=2222 make package install`
* Re-plug the USB cable and restart target app
