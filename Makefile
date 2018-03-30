include $(THEOS)/makefiles/common.mk

TWEAK_NAME = webinspect
webinspect_FILES = Tweak.xm

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard webinspectord; /usr/libexec/webinspectord &"
	echo "\033[1;31mafter respring, you need to re-plug the device to get it conncted to desktop Safari"
