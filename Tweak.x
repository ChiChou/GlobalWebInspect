#include <substrate.h>
#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import <WebKit/WebKit.h>
#import <Security/Security.h>
#include <dlfcn.h>

#define LOG(fmt, ...) NSLog(@"[WebInspect] " fmt "\n", ##__VA_ARGS__)

void hook_webinspectord(void);
void hook_jsc(void);

typedef struct CF_BRIDGED_TYPE(id) __SecTask *SecTaskRef;
__nullable CFStringRef SecTaskCopySigningIdentifier(SecTaskRef task, CFErrorRef *error);

JSGlobalContextRef hooked_JSGlobalContextCreateInGroup(JSContextGroupRef group, JSClassRef globalObjectClass);

// dynamically resolved symbols
typedef void (jsc_set_inspectable_t)(JSGlobalContextRef ctx, bool inspectable);
jsc_set_inspectable_t *jsc_set_inspectable = NULL;

CFTypeRef (*original_SecTaskCopyValueForEntitlement)(SecTaskRef task, CFStringRef entitlement, CFErrorRef _Nullable *error);

CFTypeRef hooked_SecTaskCopyValueForEntitlement(SecTaskRef task, CFStringRef entitlement, CFErrorRef _Nullable *error);

CFTypeRef hooked_SecTaskCopyValueForEntitlement(SecTaskRef task, CFStringRef entitlement, CFErrorRef _Nullable *error) {
  static CFSetRef set = NULL;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    CFStringRef set_values[] = {
      CFSTR("com.apple.security.get-task-allow"),
      CFSTR("com.apple.webinspector.allow"),
      // CFSTR("com.apple.private.webinspector.proxy-application"),
      CFSTR("com.apple.private.webinspector.allow-remote-inspection"),
      CFSTR("com.apple.private.webinspector.allow-carrier-remote-inspection"),
    };

    set = CFSetCreate(NULL, (const void **)set_values, sizeof(set_values) / sizeof(set_values[0]), &kCFTypeSetCallBacks);
  });

  CFStringRef identifier = SecTaskCopySigningIdentifier(task, NULL);
  if (CFSetContainsValue(set, entitlement)) {
    LOG("check entitlement: %@ for %@", entitlement, identifier);
    return kCFBooleanTrue;
  }
  return original_SecTaskCopyValueForEntitlement(task, entitlement, error);
}

%ctor {
  const char *name = getprogname();
  LOG(@"loaded in %s (%d)", name, getpid());

  if (strcmp(name, "webinspectord") == 0) {
    hook_webinspectord();
  } else {
    hook_jsc();
  }
}

void hook_webinspectord() {
  MSImageRef security = MSGetImageByName("/System/Library/Frameworks/Security.framework/Security");
  if (!security) {
    LOG("Security framework not loaded, bail out");
    return;
  }

  MSHookFunction(
    MSFindSymbol(security, "_SecTaskCopyValueForEntitlement"),
    (void *)hooked_SecTaskCopyValueForEntitlement,
    (void **)&original_SecTaskCopyValueForEntitlement
  );
}

JSGlobalContextRef (*original_JSGlobalContextCreateInGroup)(JSContextGroupRef group, JSClassRef globalObjectClass);

JSGlobalContextRef hooked_JSGlobalContextCreateInGroup(JSContextGroupRef group, JSClassRef globalObjectClass) {
  JSGlobalContextRef ctx = original_JSGlobalContextCreateInGroup(group, globalObjectClass);
  if (!ctx) return NULL;
  LOG("set inspectable for %p (JSGlobalContextCreateInGroup)", ctx);
  jsc_set_inspectable(ctx, true);
  return ctx;
}

#if 0
JSContext *(*original_JSC_initWithVM)(id self, SEL sel, JSVirtualMachine *vm);

JSContext *hooked_JSC_initWithVM(JSContext *self, SEL sel, JSVirtualMachine *vm) {
  JSContext *ctx = original_JSC_initWithVM(self, sel, vm);
  [ctx performSelector:@selector(setInspectable:) withObject:@1];
  LOG("set inspectable for %p %@ (initWithVirtualMachine:)", self.JSGlobalContextRef, self);
  return ctx;
}
#endif

void (*original_webview_initWithConf)(id self, SEL sel, WKWebViewConfiguration *conf);

void hooked_webview_initWithConf(id self, SEL sel, WKWebViewConfiguration *conf) {
  original_webview_initWithConf(self, sel, conf);
  LOG("set inspectable for %@ (WKWebView _initializeWithConfiguration:)", self);
  // the correct type shoule be bool YES. However any non-zero value works
  [self performSelector:@selector(setInspectable:) withObject:@1];
}

void hook_jsc() {
  MSImageRef jsc = MSGetImageByName("/System/Library/Frameworks/JavaScriptCore.framework/JavaScriptCore");
  if (!jsc) {
    LOG("JavaScriptCore framework not found, bail out");
    return;
  }

  jsc_set_inspectable = (jsc_set_inspectable_t *)MSFindSymbol(jsc, "_JSGlobalContextSetInspectable");
  if (!jsc_set_inspectable) {
    LOG("iOS < 16.4, bail out");
    return;
  }
  
  void *symbol = MSFindSymbol(jsc, "_JSGlobalContextCreateInGroup");
  if (!symbol) {
    LOG("JSGlobalContextCreateInGroup not found");
    return;
  }

  MSHookFunction(symbol, (void *)hooked_JSGlobalContextCreateInGroup, (void **)&original_JSGlobalContextCreateInGroup);

  MSImageRef webkit = MSGetImageByName("/System/Library/Frameworks/WebKit.framework/WebKit");
  if (!webkit) return ;
  
  LOG("hook -[WKWebView _initializeWithConfiguration:]");
  MSHookMessageEx(
    objc_getClass("WKWebView"),
    @selector(_initializeWithConfiguration:),
    (IMP)hooked_webview_initWithConf,
    (IMP*)&original_webview_initWithConf
  );

#if 0
  // this method will reach to JSGlobalContextCreateInGroup eventually

  MSHookMessageEx(
    objc_getClass("JSContext"),
    @selector(initWithVirtualMachine:),
    (IMP)hooked_JSC_initWithVM,
    (IMP *)&original_JSC_initWithVM
  );
#endif

}
