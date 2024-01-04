ifdef ROOTLESS
$(info Build as a ROOTLESS Substrate Tweak)
THEOS_PACKAGE_SCHEME=rootless
PACKAGE_BUILDNAME := rootless
else ifdef ROOTHIDE
$(info Build as a ROOTHIDE Substrate Tweak)
# THEOS_PACKAGE_ARCH := iphoneos-arm64e # must set afterwards if using original theos
THEOS_PACKAGE_SCHEME=roothide
PACKAGE_BUILDNAME := roothide
else # ROOTLESS / ROOTHIDE
$(info Build as a ROOTFUL Substrate Tweak)
PACKAGE_BUILDNAME := rootful
endif # ROOTLESS / ROOTHIDE


include $(THEOS)/makefiles/common.mk

TWEAK_NAME = webinspect
webinspect_FILES = Tweak.x

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "launchctl kickstart -k -p system/com.apple.webinspectord"
	echo you need to kill the target App and restart Safari to make it work
