include $(THEOS)/makefiles/common.mk

TWEAK_NAME = webinspect
webinspect_FILES = Tweak.xm

webinspect_CFLAGS = -std=c++11 -stdlib=libc++
webinspect_LDFLAGS = -stdlib=libc++

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "launchctl stop com.apple.webinspectord; launchctl start com.apple.webinspectord"
	echo "you need to re-plug the USB wire and kill the target App to make it work"
