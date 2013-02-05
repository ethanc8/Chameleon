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

#import "UIFont.h"
#import <Cocoa/Cocoa.h>

static NSString *UIFontSystemFontName = nil;
static NSString *UIFontBoldSystemFontName = nil;
static NSString *UIFontItalicSystemFontName = @"Optima Bold Italic";

static NSString* const kUIFontNameKey = @"UIFontName";
static NSString* const kUIFontPointSizeKey = @"UIFontPointSize";
static NSString* const kUIFontTraitsKey = @"UIFontTraits";
static NSString* const kUISystemFontKey = @"UISystemFont";


@implementation UIFont 

+ (void)setSystemFontName:(NSString *)aName
{
    [UIFontSystemFontName release];
    UIFontSystemFontName = [aName copy];
}

+ (void)setBoldSystemFontName:(NSString *)aName
{
    [UIFontBoldSystemFontName release];
    UIFontBoldSystemFontName = [aName copy];
}

+ (void)setItalicSystemFontName:(NSString *)aName
{
    [UIFontItalicSystemFontName release];
    UIFontItalicSystemFontName = [aName copy];
}

+ (UIFont *)_fontWithCTFont:(CTFontRef)aFont
{
    UIFont *theFont = [[UIFont alloc] init];
    theFont->_font = CFRetain(aFont);
    return [theFont autorelease];
}

+ (UIFont *)fontWithNSFont:(NSFont *)aFont
{
    if (aFont) {
        CTFontRef newFont = CTFontCreateWithName((__bridge CFStringRef)[aFont fontName], [aFont pointSize], NULL);
        if (newFont) {
            UIFont *theFont = [self _fontWithCTFont:newFont];
            CFRelease(newFont);
            return theFont;
        }
    }
    return nil;
}

+ (UIFont *)fontWithName:(NSString *)fontName size:(CGFloat)fontSize
{
    return [self fontWithNSFont:[NSFont fontWithName:fontName size:fontSize]];
}

- (id) initWithCoder:(NSCoder*)coder
{
    if (nil != (self = [super init])) {
        NSString* fontName = [coder decodeObjectForKey:kUIFontNameKey];
        CGFloat fontPointSize = [coder decodeFloatForKey:kUIFontPointSizeKey];

        _font = CTFontCreateWithName((CFStringRef)fontName, fontPointSize, NULL);
        if (!_font) {
            return nil;
        }
    }
    return self;
}

- (void) encodeWithCoder:(NSCoder*)coder
{
    [self doesNotRecognizeSelector:_cmd];
}

static NSArray *_getFontCollectionNames(CTFontCollectionRef collection, CFStringRef nameAttr)
{
    NSMutableSet *names = [NSMutableSet set];
    if (collection) {
        CFArrayRef descriptors = CTFontCollectionCreateMatchingFontDescriptors(collection);
        if (descriptors) {
            NSInteger count = CFArrayGetCount(descriptors);
            for (NSInteger i = 0; i < count; i++) {
                CTFontDescriptorRef descriptor = (CTFontDescriptorRef) CFArrayGetValueAtIndex(descriptors, i);
                CFTypeRef name = CTFontDescriptorCopyAttribute(descriptor, nameAttr);
                if(name) {
                    if (CFGetTypeID(name) == CFStringGetTypeID()) {
                        [names addObject:(__bridge NSString*)name];
                    }
                    CFRelease(name);
                }
            }
            CFRelease(descriptors);
        }
    }
    return [names allObjects];
}

+ (NSArray *)familyNames
{
    CTFontCollectionRef collection = CTFontCollectionCreateFromAvailableFonts(NULL);
    NSArray* names = _getFontCollectionNames(collection, kCTFontFamilyNameAttribute);
    if (collection) {
        CFRelease(collection);
    }
    return names;
}

+ (NSArray *)fontNamesForFamilyName:(NSString *)familyName
{
    NSArray *names = nil;
    CTFontDescriptorRef descriptor = CTFontDescriptorCreateWithAttributes((__bridge CFDictionaryRef)
        [NSDictionary dictionaryWithObjectsAndKeys: familyName, (NSString*)kCTFontFamilyNameAttribute, nil, nil]);
    if (descriptor) {
        CFArrayRef descriptors = CFArrayCreate(NULL, (CFTypeRef*) &descriptor, 1, &kCFTypeArrayCallBacks);
        if (descriptors) {
            CTFontCollectionRef collection = CTFontCollectionCreateWithFontDescriptors(descriptors, NULL);
            names = _getFontCollectionNames(collection, kCTFontNameAttribute);
            if (collection) {
                CFRelease(collection);
            }
            CFRelease(descriptors);
        }
        CFRelease(descriptor);
    }
    return names;
}

+ (UIFont *)systemFontOfSize:(CGFloat)fontSize
{
    NSFont *systemFont = UIFontSystemFontName? [NSFont fontWithName:UIFontSystemFontName size:fontSize] : [NSFont systemFontOfSize:fontSize];
    return (systemFont ? [self fontWithNSFont:systemFont] : [self fontWithNSFont:[NSFont systemFontOfSize: fontSize]]);
}

+ (UIFont *)boldSystemFontOfSize:(CGFloat)fontSize
{
    NSFont *systemFont = UIFontBoldSystemFontName
                ? [NSFont fontWithName:UIFontBoldSystemFontName size:fontSize] 
                : [NSFont boldSystemFontOfSize:fontSize];
    return (systemFont ? [self fontWithNSFont:systemFont] :[self fontWithNSFont:[NSFont boldSystemFontOfSize: fontSize]]);
}

+ (UIFont *)italicSystemFontOfSize:(CGFloat)fontSize {
    NSFont *systemFont = UIFontItalicSystemFontName
                                ? [NSFont fontWithName:UIFontItalicSystemFontName size:fontSize] 
                                : [NSFont systemFontOfSize:fontSize];
    
    return (systemFont ? [self fontWithNSFont:systemFont] : [self fontWithNSFont:[NSFont boldSystemFontOfSize: fontSize]]);
}

- (void)dealloc
{
    if (_font) CFRelease(_font);
    [super dealloc];
}

- (NSString *)fontName
{
	return [(id)CTFontCopyFullName(_font) autorelease];
}

- (CGFloat)ascender
{
    return CTFontGetAscent(_font);
}

- (CGFloat)descender
{
    return -CTFontGetDescent(_font);
}

- (CGFloat)pointSize
{
    return CTFontGetSize(_font);
}

- (CGFloat)xHeight
{
    return CTFontGetXHeight(_font);
}

- (CGFloat)capHeight
{
    return CTFontGetCapHeight(_font);
}

- (CGFloat)lineHeight
{
    // this seems to compute heights that are very close to what I'm seeing on iOS for fonts at
    // the same point sizes. however there's still subtle differences between fonts on the two
    // platforms (iOS and Mac) and I don't know if it's ever going to be possible to make things
    // return exactly the same values in all cases.
    return ceilf(self.ascender) - floorf(self.descender) + ceilf(CTFontGetLeading(_font));
}

- (NSString *)familyName
{
	return [(id)CTFontCopyFamilyName(_font) autorelease];
}

- (UIFont *)fontWithSize:(CGFloat)fontSize
{
    CTFontRef newFont = CTFontCreateCopyWithAttributes(_font, fontSize, NULL, NULL);
    if (newFont) {
        UIFont *theFont = [isa _fontWithCTFont:newFont];
        CFRelease(newFont);
        return theFont;
    } else {
        return nil;
    }
}

- (NSFont *)NSFont
{
    return [NSFont fontWithName:self.fontName size:self.pointSize];
}

- (CTFontRef) _CTFont
{
    return _font;
}

@end
