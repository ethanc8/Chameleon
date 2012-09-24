//
//  UIRuntimeAccessibilityConfiguration.m
//  UIKit
//
//  Created by Sérgio Silva on 23/04/12.
//  Copyright (c) 2012 bitrzr. All rights reserved.
//

#import "UIRuntimeAccessibilityConfiguration.h"

@implementation UIRuntimeAccessibilityConfiguration
@synthesize accessibilityConfigurationHint;
@synthesize accessibilityConfigurationLabel;
@synthesize accessibilityConfigurationTraits;
@synthesize isAccessibilityConfigurationElement;
@synthesize object = _object;

-(id)initWithObject:(id)object label:(id)label hint:(id)hint traits:(id)traits andIsAccessibilityElement:(id)element {
    
     if ((self = [super init])) {
         self.object = object;
         self.accessibilityConfigurationLabel = label;
         self.accessibilityConfigurationHint = hint;
         self.isAccessibilityConfigurationElement = element;
     }
    return self;
}

-(id)initWithCoder:(id)coder {
    return nil;
}

-(void)encodeWithCoder:(id)coder {
    //TODO: stub
}
-(void)dealloc {
    [_object release];
    [accessibilityConfigurationLabel release];
    [accessibilityConfigurationHint release];
    [accessibilityConfigurationTraits release];
    [isAccessibilityConfigurationElement release];
    
    [super dealloc];
}
-(void)applyConfiguration {
    //TODO: stub
}

@end
