ARCHS = armv7 arm64
TARGET = iphone:clang:8.4:7.0
PACKAGE_VERSION = $(THEOS_PACKAGE_BASE_VERSION)
SYSROOT = /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS8.4.sdk

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = PPTPFix
PPTPFix_FILES = Tweak.xm
PPTPFix_CFLAGS = -fobjc-arc -O3

include $(THEOS_MAKE_PATH)/tweak.mk
