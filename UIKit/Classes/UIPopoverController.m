/*
 * Copyright (c) 2011, The Iconfactory. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * 3. Neither the name of The Iconfactory nor the names of its contributors may
 *    be used to endorse or promote products derived from this software without
 *    specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE ICONFACTORY BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 * OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "UIPopoverController+UIPrivate.h"
#import "UIViewController.h"
#import "UIWindow.h"
#import "UIScreen+UIPrivate.h"
#import "UIScreenAppKitIntegration.h"
#import "UIKitView.h"
#import "UITouch.h"
#import "UIApplication+UIPrivate.h"
#import "UIPopoverView.h"
#import "UIPopoverNSWindow.h"
#import "UIPopoverOverlayNSView.h"
#import "UIImage+UIPrivate.h"
#import "UIBarButtonItem+UIPrivate.h"
#import "UIToolbarItem.h"
#include <tgmath.h>

static BOOL SizeIsLessThanOrEqualSize(NSSize size1, NSSize size2)
{
    return (size1.width <= size2.width) && (size1.height <= size2.height);
}

static NSPoint PopoverWindowOrigin(NSWindow *inWindow, NSRect fromRect, NSSize *popoverSize, UIPopoverArrowDirection arrowDirections, NSPoint *pointTo, UIPopoverArrowDirection *arrowDirection)
{
    // 1) define a set of possible quads around fromRect that the popover could appear in
    // 2) eliminate quads based on arrow direction restrictions and sizes
    // 3) the first quad that is large enough "wins"
    
    NSRect screenRect = [[inWindow screen] visibleFrame];
    
    NSSize bottomQuad = NSMakeSize(screenRect.size.width, fromRect.origin.y - screenRect.origin.y);
    NSSize topQuad = NSMakeSize(screenRect.size.width, screenRect.size.height - (fromRect.origin.y - screenRect.origin.y + fromRect.size.height));
	NSSize leftQuad = NSMakeSize(fromRect.origin.x - screenRect.origin.x, screenRect.size.height);
    NSSize rightQuad = NSMakeSize(screenRect.size.width - (fromRect.origin.x - screenRect.origin.x + fromRect.size.width), screenRect.size.height);
    
    pointTo->x = fromRect.origin.x + (fromRect.size.width/2.f);
    pointTo->y = fromRect.origin.y + (fromRect.size.height/2.f);    
    
    NSPoint origin;
    origin.x = fromRect.origin.x + (fromRect.size.width/2.f) - (popoverSize->width/2.f);
    origin.y = fromRect.origin.y + (fromRect.size.height/2.f) - (popoverSize->height/2.f);
    
    const CGFloat minimumPadding = 40;
    const BOOL allowTopOrBottom = (pointTo->x >= NSMinX(screenRect)+minimumPadding && pointTo->x <= NSMaxX(screenRect)-minimumPadding);
    const BOOL allowLeftOrRight = (pointTo->y >= NSMinY(screenRect)+minimumPadding && pointTo->y <= NSMaxY(screenRect)-minimumPadding);
    
    const BOOL allowTopQuad = ((arrowDirections & UIPopoverArrowDirectionDown) != 0) && topQuad.width > 0 && topQuad.height > 0 && allowTopOrBottom;
    const BOOL allowBottomQuad = ((arrowDirections & UIPopoverArrowDirectionUp) != 0) && bottomQuad.width > 0 && bottomQuad.height > 0 && allowTopOrBottom;
    const BOOL allowLeftQuad = ((arrowDirections & UIPopoverArrowDirectionRight) != 0) && leftQuad.width > 0 && leftQuad.height > 0 && allowLeftOrRight;
    const BOOL allowRightQuad = ((arrowDirections & UIPopoverArrowDirectionLeft) != 0) && rightQuad.width > 0 && rightQuad.height > 0 && allowLeftOrRight;
    
    const CGFloat arrowPadding = 8;		// the arrow images are slightly larger to account for shadows, but the arrow point needs to be up against the rect exactly so this helps with that
    
    if (allowBottomQuad && SizeIsLessThanOrEqualSize(*popoverSize,bottomQuad)) {
        pointTo->y = fromRect.origin.y;
        origin.y = fromRect.origin.y - popoverSize->height + arrowPadding;
        *arrowDirection = UIPopoverArrowDirectionUp;
    } else if (allowRightQuad && SizeIsLessThanOrEqualSize(*popoverSize,rightQuad)) {
        pointTo->x = fromRect.origin.x + fromRect.size.width;
        origin.x = pointTo->x - arrowPadding;
        *arrowDirection = UIPopoverArrowDirectionLeft;
    } else if (allowLeftQuad && SizeIsLessThanOrEqualSize(*popoverSize,leftQuad)) {
        pointTo->x = fromRect.origin.x;
        origin.x = fromRect.origin.x - popoverSize->width + arrowPadding;
        *arrowDirection = UIPopoverArrowDirectionRight;
    } else if (allowTopQuad && SizeIsLessThanOrEqualSize(*popoverSize,topQuad)) {
        pointTo->y = fromRect.origin.y + fromRect.size.height;
        origin.y = pointTo->y - arrowPadding;
        *arrowDirection = UIPopoverArrowDirectionDown;
    } else {
        CGFloat maxArea = -1;
        CGFloat popoverWidthDelta = -1;
        
        if (allowBottomQuad) {
            // TODO: need to handle bottom quad
        }
        if (allowRightQuad) {
            CGFloat area = rightQuad.height * rightQuad.width;
            if (area > maxArea) {
                popoverWidthDelta = -1;
                maxArea = area;
                NSInteger quadWidth = rightQuad.width + fromRect.size.width/2.f;
                NSInteger popoverWidth = popoverSize->width + arrowPadding;
                if (popoverWidth <= quadWidth) {
                    pointTo->x = fromRect.origin.x + fromRect.size.width/2.f + (quadWidth - popoverWidth);
                } else {
                    popoverWidthDelta = popoverWidth - quadWidth;
                }
                origin.x = pointTo->x - arrowPadding;
                *arrowDirection = UIPopoverArrowDirectionLeft;
            }
        }
        if (allowLeftQuad) {
            CGFloat area = leftQuad.height * leftQuad.width;
            if (area > maxArea) {
                popoverWidthDelta = -1;
                maxArea = area;
                NSInteger quadWidth = leftQuad.width + fromRect.size.width/2.f;
                NSInteger popoverWidth = popoverSize->width + arrowPadding;
                if (popoverWidth <= quadWidth) {
                    pointTo->x = fromRect.origin.x + fromRect.size.width/2.f - (quadWidth - popoverWidth);
                } else {
                    popoverWidthDelta = popoverWidth - quadWidth;
                }
                origin.x = pointTo->x - popoverSize->width + arrowPadding;
                *arrowDirection = UIPopoverArrowDirectionRight;
            }
        }
        if (allowTopQuad) {
            // TODO: need to handle top quad
        }
        if (-1 != popoverWidthDelta) {
            popoverSize->width -= popoverWidthDelta;
        }
        if (-1 == maxArea) {
            *arrowDirection = UIPopoverArrowDirectionUnknown;
        }
    }
    
    NSRect windowRect;
    windowRect.origin = origin;
    windowRect.size = *popoverSize;
    
    if (NSMaxX(windowRect) > NSMaxX(screenRect)) {
        windowRect.origin.x = NSMaxX(screenRect) - popoverSize->width;
    }
    if (NSMinX(windowRect) < NSMinX(screenRect)) {
        windowRect.origin.x = NSMinX(screenRect);
    }
    if (NSMaxY(windowRect) > NSMaxY(screenRect)) {
        windowRect.origin.y = NSMaxY(screenRect) - popoverSize->height;
    }
    if (NSMinY(windowRect) < NSMinY(screenRect)) {
        windowRect.origin.y = NSMinY(screenRect);
    }
    
    windowRect.origin.x = round(windowRect.origin.x);
    windowRect.origin.y = round(windowRect.origin.y);
    
    return windowRect.origin;
}

@interface UIPopoverController ()
- (void)_destroyPopover;
@end

@implementation UIPopoverController

@synthesize delegate = _delegate;
@synthesize contentViewController = _contentViewController;
@synthesize passthroughViews = _passthroughViews;
@synthesize popoverArrowDirection = _popoverArrowDirection;
@synthesize popoverContentSize = _popoverContentSize;

- (id)init
{
    if ((self=[super init])) {
        _popoverArrowDirection = UIPopoverArrowDirectionUnknown;
        _popoverContentSize = CGSizeZero;
    }
    return self;
}


- (id)initWithContentViewController:(UIViewController *)viewController
{
    if ((self=[self init])) {
        self.contentViewController = viewController;
    }
    return self;
}

- (void)dealloc
{
    [self _destroyPopover];
    [self setContentViewController:nil];
    [_passthroughViews release];
    [_overlayWindows release];
    [super dealloc];
}

- (void)setDelegate:(id<UIPopoverControllerDelegate>)newDelegate
{
    _delegate = newDelegate;
    _delegateHas.popoverControllerDidDismissPopover = [_delegate respondsToSelector:@selector(popoverControllerDidDismissPopover:)];
    _delegateHas.popoverControllerShouldDismissPopover = [_delegate respondsToSelector:@selector(popoverControllerShouldDismissPopover:)];
}

- (void)setContentViewController:(UIViewController *)controller animated:(BOOL)animated
{
    if (controller != _contentViewController) {
        if ([self isPopoverVisible]) {
            [_popoverView setContentView:controller.view animated:animated];
        }
        [_contentViewController release];
        _contentViewController = [controller retain];
    }
}

- (void)setContentViewController:(UIViewController *)viewController
{
    [self setContentViewController:viewController animated:NO];
}

- (void)presentPopoverFromRect:(CGRect)rect inView:(UIView *)view permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections animated:(BOOL)animated
{
    [self presentPopoverFromRect:rect inView:view permittedArrowDirections:arrowDirections animated:animated makeKey:YES];
}

- (void)presentPopoverFromRect:(CGRect)rect inView:(UIView *)view permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections animated:(BOOL)animated makeKey:(BOOL)shouldMakeKey
{
    assert(_isDismissing == NO);
    assert(view != nil);
    assert(arrowDirections != UIPopoverArrowDirectionUnknown);
    assert(!CGRectIsNull(rect));
    assert(!CGRectEqualToRect(rect,CGRectZero));
    assert([[view.window.screen UIKitView] window] != nil);
    
    // only create new stuff if the popover isn't already visible
    if (![self isPopoverVisible]) {
        assert(_overlayWindows == nil);
        assert(_popoverView == nil);
        assert(_popoverWindow == nil);

        // build an overlay window which will capture any clicks on the main window the popover is being presented from and then dismiss it.
        // this overlay can also be used to implement the pass-through views of the popover, but I'm not going to do that right now since
        // we don't need it. attach the overlay window to the "main" window.
        
        // We actualy create several overlays since we might need to overlay several windows as we might be presenting the popover
        // from a popover window and the first popover window might be offset from the main window
        _overlayWindows = [[NSMutableArray alloc] init];
      
        NSWindow *currentParent = [[view.window.screen UIKitView] window];;
        do {
            NSRect windowFrame =[currentParent frame]; //[[UIScreen mainScreen] applicationFrame];
            NSRect overlayContentRect = NSMakeRect(0,0,windowFrame.size.width,windowFrame.size.height);
            
            NSWindow *_overlayWindow = [[NSWindow alloc] initWithContentRect:overlayContentRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:YES];
            [_overlayWindow setIgnoresMouseEvents:NO];
            [_overlayWindow setOpaque:NO];
            [(NSWindow *)_overlayWindow setBackgroundColor:[NSColor clearColor]];
            [_overlayWindow setFrameOrigin:windowFrame.origin];
            [_overlayWindow setContentView:[[[UIPopoverOverlayNSView alloc] initWithFrame:overlayContentRect popoverController:self] autorelease]];
            [currentParent addChildWindow:_overlayWindow ordered:NSWindowAbove];
            [_overlayWindows addObject:_overlayWindow];
            currentParent = [currentParent parentWindow];
        } while (currentParent != nil);
            
        //bitrzr: set the content view frame to the size of the chosen content for the popover
        _contentViewController.view.frame = CGRectMake(_contentViewController.view.frame.origin.x, _contentViewController.view.frame.origin.y, _contentViewController.contentSizeForViewInPopover.width, _contentViewController.contentSizeForViewInPopover.height);
        
		[_contentViewController viewWillAppear:animated];
		
        // now build the actual popover view which represents the popover's chrome, and since it's a UIView, we need to build a UIKitView 
        // as well to put it in our NSWindow...
        _popoverView = [[UIPopoverView alloc] initWithContentView:_contentViewController.view size:_contentViewController.contentSizeForViewInPopover popoverController:self];
        _popoverView.theme = _theme;
        
        UIKitView *hostingView = [[UIKitView alloc] initWithFrame:NSRectFromCGRect([_popoverView bounds])];
        [[hostingView UIScreen] _setPopoverController:self];
        [[hostingView UIWindow] addSubview:_popoverView];
        [[hostingView UIWindow] setHidden:NO];
        if (shouldMakeKey) {
            [[hostingView UIWindow] makeKeyAndVisible];
        }
        
        // this prevents a visible flash from sometimes occuring due to the fact that the window is created and added as a child before it has the
        // proper origin set. this means it it ends up flashing at the bottom left corner of the screen sometimes before it
        // gets down farther in this method where the actual origin is calculated and set. since the window is transparent, simply setting the UIView
        // hidden gets around the problem since you then can't see any of the actual content that's in the window :)
        _popoverView.hidden = YES;
        
        // now finally make the actual popover window itself and attach it to the overlay window
        _popoverWindow = [[UIPopoverNSWindow alloc] initWithContentRect:[hostingView bounds] styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:YES];
        [_popoverWindow setPopoverController:self];
        [_popoverWindow setOpaque:NO];
        [(NSWindow *)_popoverWindow setBackgroundColor:[NSColor clearColor]];
        [_popoverWindow setContentView:hostingView];
        [[_overlayWindows lastObject] addChildWindow:_popoverWindow ordered:NSWindowAbove];
        [_popoverWindow makeFirstResponder:hostingView];
        
        [hostingView release];
    }
    
    if (!CGSizeEqualToSize(_popoverView.contentSize, _contentViewController.contentSizeForViewInPopover)) {
        _popoverView.hidden = YES;
        [_popoverView removeFromSuperview];
        CGSize newContentSize = _contentViewController.contentSizeForViewInPopover;
        CGRect newPopoverBounds = _popoverView.bounds;
        newPopoverBounds.size = [[self class] frameSizeForContentSize:newContentSize withNavigationBar:NO];
        UIKitView* hostingView = (UIKitView*)[(NSWindow *)_popoverWindow contentView];
        [hostingView setFrame:NSRectFromCGRect(newPopoverBounds)];
        [[hostingView UIWindow] addSubview:_popoverView];
        [(NSWindow *)_popoverWindow setContentSize:hostingView.bounds.size];
        [_popoverView setContentSize:newContentSize];
    }
    
    // cancel current touches (if any) to prevent the main window from losing track of events (such as if the user was holding down the mouse
    // button and a timer triggered the appearance of this popover. the window would possibly then not receive the mouseUp depending on how
    // all this works out... I first ran into this problem with NSMenus. A NSWindow is a bit different, but I think this makes sense here
    // too so premptively doing it to avoid potential problems.)
    [[UIApplication sharedApplication] _cancelTouches];
    
    // now position the popover window according to the passed in parameters.
    CGRect windowRect = [view convertRect:rect toView:nil];
    CGRect screenRect = [view.window convertRect:windowRect toWindow:nil];
    CGRect desktopScreenRect = [view.window.screen convertRect:screenRect toScreen:nil];
    NSPoint pointTo = NSMakePoint(0,0);
    
    // finally, let's show it!
    NSSize popoverSize = NSSizeFromCGSize(_popoverView.frame.size);
    [_popoverWindow setFrameOrigin:PopoverWindowOrigin([_overlayWindows lastObject], NSRectFromCGRect(desktopScreenRect), &popoverSize, arrowDirections, &pointTo, &_popoverArrowDirection)];
    CGRect popoverFrame = _popoverView.frame;
    popoverFrame.size = popoverSize;
    _popoverView.frame = popoverFrame;
    _popoverView.hidden = NO;
    if (shouldMakeKey) {
        [_popoverWindow makeKeyWindow];
    }
    
    [_contentViewController viewDidAppear:animated];
    
    // the window has to be visible before these coordinate conversions will work correctly (otherwise the UIScreen isn't attached to anything
    // and blah blah blah...)
    // finally, set the arrow position so it points to the right place and looks all purty.
    if (_popoverArrowDirection != UIPopoverArrowDirectionUnknown) {
        CGPoint screenPointTo = [_popoverView.window.screen convertPoint:NSPointToCGPoint(pointTo) fromScreen:nil];
        CGPoint windowPointTo = [_popoverView.window convertPoint:screenPointTo fromWindow:nil];
        CGPoint viewPointTo = [_popoverView convertPoint:windowPointTo fromView:nil];
        [_popoverView pointTo:viewPointTo inView:_popoverView];
    }
    
    if (animated) {
        _popoverView.transform = CGAffineTransformMakeScale(0.98f,0.98f);
        _popoverView.alpha = 0.4f;
        
        [UIView animateWithDuration:0.08 
                         animations:^{
                             _popoverView.transform = CGAffineTransformIdentity;
                         }
         ];
        
        [UIView animateWithDuration:0.1
                         animations:^{
                             _popoverView.alpha = 1.f;
                         }
         ];
    }
}


- (void)setPopoverContentSize:(CGSize)size animated:(BOOL)animated {
    //TODO: animate
    self.popoverContentSize = size;
}


- (void)presentPopoverFromBarButtonItem:(UIBarButtonItem *)item permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections animated:(BOOL)animated
{
    UIToolbarItem *barItem = [item _getToolbarItem];
    [self presentPopoverFromRect:[[barItem view] frame] inView:[barItem performSelector:@selector(_getToolbar)] permittedArrowDirections:arrowDirections animated:animated makeKey:YES];
}

- (BOOL)isPopoverVisible
{
    return (_popoverView || _popoverWindow || _overlayWindows);
}

- (void)_destroyPopover
{
    int i=0;
    for(NSWindow *_overlayWindow in _overlayWindows) {
        NSWindow *parentWindow = [[_overlayWindow parentWindow] retain];
        
        [_overlayWindow removeChildWindow:_popoverWindow];
        [parentWindow removeChildWindow:_overlayWindow];
        
        //The popover is tied to the first window in _overlayWindows
        if(i==0) {
            [_popoverView release];
            _popoverView = nil;
            
            [_popoverWindow close];
            _popoverWindow = nil;
            
            [parentWindow makeKeyAndOrderFront:self];
            _popoverArrowDirection = UIPopoverArrowDirectionUnknown;
        }
        
        [parentWindow release];
        [_overlayWindow close];
        
        i++;
    }
    [_overlayWindows release];
    _overlayWindows = nil;
    _isDismissing = NO;
}

- (void)dismissPopoverAnimated:(BOOL)animated
{
    if ([self isPopoverVisible]) {
        id popoverWindow = _popoverWindow;
        UIView* popoverView = _popoverView;
        
        _popoverWindow = nil;
        _popoverView = nil;
        _popoverArrowDirection = UIPopoverArrowDirectionUnknown;
        
        void(^animationBlock)(void) = ^{
            popoverView.alpha = 0;
        };
        void(^completionBlock)(BOOL) = ^(BOOL finished) {
            int i=0;
            for(NSWindow *_overlayWindow in _overlayWindows) {
                NSWindow *parentWindow = [_overlayWindow parentWindow];
                
                [_overlayWindow orderOut:nil];
                [parentWindow removeChildWindow:_overlayWindow];
                
                if(i==0) {
                    [popoverWindow orderOut:nil];
                    
                    [parentWindow removeChildWindow:popoverWindow];
                    [popoverView removeFromSuperview];
                    [parentWindow makeKeyWindow];
                    
                    [popoverView release];
                    [popoverWindow release];
                }
                
                i++;
            }
            [_overlayWindows release];
            _overlayWindows = nil;
        };
        
        if (animated) {
            [UIView animateWithDuration:0.2 
                             animations:animationBlock
                             completion:completionBlock
             ];
        } else {
            animationBlock();
            completionBlock(YES);
        }
    }
}

- (void)_closePopoverWindowIfPossible
{
    if (!_isDismissing && [self isPopoverVisible]) {
        const BOOL shouldDismiss = _delegateHas.popoverControllerShouldDismissPopover? [_delegate popoverControllerShouldDismissPopover:self] : YES;

        if (shouldDismiss) {
            [self dismissPopoverAnimated:YES];
            
            if (_delegateHas.popoverControllerDidDismissPopover) {
                [_delegate popoverControllerDidDismissPopover:self];
            }
        }
    }
}

+ (UIEdgeInsets)insetForArrows
{
    return UIEdgeInsetsMake(17,12,8,12);
}

+ (CGRect)backgroundRectForBounds:(CGRect)bounds
{
    return UIEdgeInsetsInsetRect(bounds, [self insetForArrows]);
}

+ (CGRect)contentRectForBounds:(CGRect)bounds withNavigationBar:(BOOL)hasNavBar
{
    const CGFloat navBarOffset = hasNavBar? 32 : 0;
    return UIEdgeInsetsInsetRect(CGRectMake(14,9+navBarOffset,bounds.size.width-28,bounds.size.height-28-navBarOffset), [self insetForArrows]);
}

+ (CGSize)frameSizeForContentSize:(CGSize)contentSize withNavigationBar:(BOOL)hasNavBar
{
    UIEdgeInsets insets = [self insetForArrows];
    CGSize frameSize;
    
    frameSize.width = contentSize.width + 28 + insets.left + insets.right;
    frameSize.height = contentSize.height + 28 + (hasNavBar? 32 : 0) + insets.top + insets.bottom;
    
    return frameSize;
}

- (void)setPopoverContentSize:(CGSize)popoverContentSize
{
    assert(_contentViewController != nil);
    if(CGSizeEqualToSize(_contentViewController.contentSizeForViewInPopover, popoverContentSize)) return;
    
    _contentViewController.contentSizeForViewInPopover = popoverContentSize;
    
    if ([self isPopoverVisible])
    {
        // if the popover is visible, show the animation
        [_popoverView setContentSize:popoverContentSize animated:YES];
    }
    else
    {
        [_popoverView setContentSize:popoverContentSize animated:NO];
    }
}


+ (UIImage *)backgroundImageForTheme:(UIPopoverTheme)theme {
    switch (theme) {
        case UIPopoverThemeDefault:
            return [UIImage _popoverBackgroundImage];
            break;
        case UIPopoverThemeLion:
            return [UIImage _popoverLionBackgroundImage];
            break;
    }
    return nil;
}

+ (UIImage *)leftArrowImageForTheme:(UIPopoverTheme)theme {
    switch (theme) {
        case UIPopoverThemeDefault:
            return [UIImage _leftPopoverArrowImage];
            break;
        case UIPopoverThemeLion:
            return [UIImage _leftLionPopoverArrowImage];
            break;
    }
    return nil;
}

+ (UIImage *)rightArrowImageForTheme:(UIPopoverTheme)theme {
    switch (theme) {
        case UIPopoverThemeDefault:
            return [UIImage _rightPopoverArrowImage];
            break;
        case UIPopoverThemeLion:
            return [UIImage _rightLionPopoverArrowImage];
            break;
    }
    return nil;
	
}

+ (UIImage *)topArrowImageForTheme:(UIPopoverTheme)theme {
    switch (theme) {
        case UIPopoverThemeDefault:
            return [UIImage _topPopoverArrowImage];
            break;
        case UIPopoverThemeLion:
            return [UIImage _topLionPopoverArrowImage];
            break;
    }
    return nil;
}

+ (UIImage *)bottomArrowImageForTheme:(UIPopoverTheme)theme {
    switch (theme) {
        case UIPopoverThemeDefault:
            return [UIImage _bottomPopoverArrowImage];
            break;
        case UIPopoverThemeLion:
            return [UIImage _bottomLionPopoverArrowImage];
            break;
    }
    return nil;
}

- (void) setTheme:(UIPopoverTheme)theme
{
    if (_theme != theme) {
        _theme = theme;
        _popoverView.theme = _theme;
    }
}

- (UIPopoverTheme) theme
{
    return _theme;
}

@end
