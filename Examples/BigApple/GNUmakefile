include $(GNUSTEP_MAKEFILES)/common.make

APP_NAME = BigApple
BigApple_OBJC_FILES = main.m AppKitClasses/BigAppleAppDelegate.m ChameleonClasses/ChameleonAppDelegate.m
BigApple_INCLUDE_DIRS += -I$(GNUSTEP_HEADERS)/Chameleon -IAppKitClasses -IChameleonClasses
BigApple_OBJC_LIBS += -lChameleonUIKit -lopal -lCoreFoundation -lQuartzCore -lGL -lCoreData -lgnustep-boron

include $(GNUSTEP_MAKEFILES)/application.make
