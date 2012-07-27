//
//  UIToolbarItem.h
//  UIKit
//
//  Created by Sérgio Silva on 27/07/12.
//
//

#import <Foundation/Foundation.h>
@class  UIToolbar, UIView, UIBarButtonItem;

@interface UIToolbarItem : NSObject {
    UIBarButtonItem *item;
    UIView *view;
    UIToolbar *_toolbar;
}

- (id)initWithBarButtonItem:(UIBarButtonItem *)anItem;
- (void)_setToolbar:(UIToolbar*) toolbar;
- (UIToolbar*)_getToolbar;

@property (nonatomic, readonly) UIView *view;
@property (nonatomic, readonly) UIBarButtonItem *item;
@property (nonatomic, readonly) CGFloat width;

@end