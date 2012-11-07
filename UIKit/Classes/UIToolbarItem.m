//
//  UIToolbarItem.m
//  UIKit
//
//  Created by Sérgio Silva on 27/07/12.
//
//

#import "UIToolbarItem.h"
#import "UIBarButtonItem.h"
#import "UIBarButtonItem+UIPrivate.h"
#import "UIToolbarButton.h"
#import "UIColor.h"
#import "UIGraphics.h"
#import "UIToolbar.h"

@implementation UIToolbarItem
@synthesize item, view;

- (id)initWithBarButtonItem:(UIBarButtonItem *)anItem
{
    if ((self=[super init])) {
        NSAssert((anItem != nil), @"the bar button item must not be nil");
        
        item = [anItem retain];
        
        if (!item->_isSystemItem && item.customView) {
            view = [item.customView retain];
        } else if (!item->_isSystemItem || (item->_systemItem != UIBarButtonSystemItemFixedSpace && item->_systemItem != UIBarButtonSystemItemFlexibleSpace)) {
            view = [[UIToolbarButton alloc] initWithBarButtonItem:item];
        }
        
        if ([item respondsToSelector:@selector(_setToolbarItem:)]) {
            [item _setToolbarItem:self];
            if ([view respondsToSelector:@selector(_setToolbarItem:)]) {
                [(UIToolbarButton*) view _setToolbarItem:self];
            }
        }
    }
    
    return self;
}

- (void)dealloc
{
    [item release];
    [view release];
    [super dealloc];
}

- (CGFloat)width
{
    if (view) {
        return view.frame.size.width;
    } else if (item->_isSystemItem && item->_systemItem == UIBarButtonSystemItemFixedSpace) {
        return item.width;
    } else {
        return -1;
    }
}

- (void)_setToolbar:(UIToolbar*) toolbar
{
    _toolbar = toolbar;
}

- (UIToolbar*) _getToolbar
{
    return _toolbar;
}

@end