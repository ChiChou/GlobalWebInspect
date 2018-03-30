#include <substrate.h>

#define TAG "[Tweak] "
#define kWebInspectPrefix CFSTR("com.apple.private.webinspector.allow-")

CFTypeRef (*original_SecTaskCopyValueForEntitlement)(
  void *task,
  CFStringRef entitlement,
  CFErrorRef _Nullable *error);

CFTypeRef hooked_SecTaskCopyValueForEntitlement(
  void *task,
  CFStringRef entitlement,
  CFErrorRef _Nullable *error)
{
  NSLog(@TAG"check entitlement: %@", (__bridge NSString *)entitlement);

  if (CFStringCompareWithOptions(
      entitlement,
      kWebInspectPrefix,
      CFRangeMake(0, CFStringGetLength(kWebInspectPrefix)),
      kCFCompareCaseInsensitive) == kCFCompareEqualTo) {
    NSLog(@TAG"patch to enable remote inspect");
    return @(YES);
  } else {
    NSLog(@TAG"skipping");
    return original_SecTaskCopyValueForEntitlement(task, entitlement, error);
  }
}


%ctor {
  MSImageRef image = MSGetImageByName("/System/Library/Frameworks/Security.framework/Security");
  void *SecTaskCopyValueForEntitlement = MSFindSymbol(image, "_SecTaskCopyValueForEntitlement");
  NSLog(@TAG"address: %p %p", image, SecTaskCopyValueForEntitlement);

  MSHookFunction(SecTaskCopyValueForEntitlement,
    (void *)hooked_SecTaskCopyValueForEntitlement,
    (void **)&original_SecTaskCopyValueForEntitlement);
}
