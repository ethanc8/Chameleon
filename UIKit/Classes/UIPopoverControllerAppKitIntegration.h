#import "UIPopoverController.h"



@interface UIPopoverController (AppKitIntegration)
@property (assign, nonatomic) UIPopoverTheme theme;

- (void)presentPopoverFromRect:(CGRect)rect inView:(UIView *)view permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections animated:(BOOL)animated makeKey:(BOOL)shouldMakeKey;
@end