//
//  UIRuntimeAccessibilityConfiguration.h
//  UIKit
//
//  Created by Sérgio Silva on 23/04/12.
//  Copyright (c) 2012 bitrzr. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UIRuntimeAccessibilityConfiguration : NSObject {
@private
	NSString* accessibilityConfigurationHint;
	NSString* accessibilityConfigurationLabel;
	NSNumber* accessibilityConfigurationTraits;
	NSNumber* isAccessibilityConfigurationElement;
	NSObject* _object;
}
@property(retain, nonatomic) NSString* accessibilityConfigurationHint;
@property(retain, nonatomic) NSString* accessibilityConfigurationLabel;
@property(retain, nonatomic) NSNumber* accessibilityConfigurationTraits;
@property(retain, nonatomic) NSNumber* isAccessibilityConfigurationElement;
@property(retain, nonatomic) NSObject* object;

-(id)initWithObject:(id)object label:(id)label hint:(id)hint traits:(id)traits andIsAccessibilityElement:(id)element;
-(id)initWithCoder:(id)coder;
-(void)encodeWithCoder:(id)coder;
-(void)dealloc;
-(void)applyConfiguration;

@end
