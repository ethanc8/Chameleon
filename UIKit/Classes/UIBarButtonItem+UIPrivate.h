#import "UIBarButtonItem.h"

@class UIToolbarItem;

@interface UIBarButtonItem (UIPrivate)
- (void) _setToolbarItem:(UIToolbarItem*) item;
- (UIToolbarItem*) _getToolbarItem;
@end