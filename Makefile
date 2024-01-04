include $(THEOS)/makefiles/common.mk

TWEAK_NAME = webinspect
webinspect_FILES = Tweak.x

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "launchctl kickstart -k -p system/com.apple.webinspectord"
	echo you need to kill the target App and restart Safari to make it work
