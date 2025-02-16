# iOS WebView 调试插件

在研究设备上全局开启 Safari F12

依赖 [ElleKit](https://ellekit.space/) 框架，请先安装

## 技术细节

iOS >= 16.4 后，WebView 的调试开关由 app 自主控制：

https://webkit.org/blog/13936/enabling-the-inspection-of-web-content-in-apps/

本插件注入所有 app 进程，在 `JSContext` 和 `WKWebView` 初始化的方法当中调用对应的 setInspectable 方法。

而在之前的 iOS，`webinspectord` 检查每个用到 JavaScriptCore 或者 WebKit 的进程是否包含如下任一 entitlements:

* com.apple.security.get-task-allow
* com.apple.webinspector.allow
* com.apple.private.webinspector.allow-remote-inspection
* com.apple.private.webinspector.allow-carrier-remote-inspection

满足条件则会开启调试。本插件注入 `webinspectord` 修改检查逻辑来全局开启调试功能。

## 构建

需要配置 iproxy/inetcat 和 ssh

```bash
export ROOTLESS=1  # 是否为 rootless
make package
THEOS_DEVICE_IP=localhost THEOS_DEVICE_PORT=2222 make install
```

## 使用

* 需要在系统设置里打开“网页检查器”功能
* 构建和安装插件
* 可能需要重新插拔设备以及重启对应的应用

## 链接

![wechat.webp](wechat.webp)
