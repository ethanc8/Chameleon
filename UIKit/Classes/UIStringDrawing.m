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

#import "UIStringDrawing.h"
#import "UIFont.h"
#import "UIFont+UIPrivate.h"
#import "UIGraphics.h"
#include <tgmath.h>


NSString *const UITextAttributeFont = @"UITextAttributeFont";
NSString *const UITextAttributeTextColor = @"UITextAttributeTextColor";
NSString *const UITextAttributeTextShadowColor = @"UITextAttributeTextShadowColor";
NSString *const UITextAttributeTextShadowOffset = @"UITextAttributeTextShadowOffset";

static CGFloat CalculateCTFontLineHeight(CTFontRef font) {
	return ceil(CTFontGetAscent(font)) - floor(-CTFontGetDescent(font)) + ceil(CTFontGetLeading(font));
}

static CTFontRef GetPrimaryFontForAttributedString(NSAttributedString *string) {
	NSDictionary *attributes = [string attributesAtIndex:0 effectiveRange:NULL];
	return (CTFontRef) [attributes objectForKey:(id) kCTFontAttributeName];
}

static CFArrayRef CreateCTLinesForAttributedString(NSAttributedString *attributedString, CGSize constrainedToSize, NSLineBreakMode lineBreakMode, CGSize *renderSize)
{
    CFMutableArrayRef lines = CFArrayCreateMutable(NULL, 0, &kCFTypeArrayCallBacks);
    CGSize drawSize = CGSizeZero;

	if(attributedString.length < 1) {
		if (renderSize) {
			*renderSize = drawSize;
		}
        
		return lines;
	}
        
	NSDictionary *attributes = [attributedString attributesAtIndex:0 effectiveRange:NULL];
	CTFontRef font = (CTFontRef) [attributes objectForKey:(id) kCTFontAttributeName];
        
    if (font) {        
        CTTypesetterRef typesetter = CTTypesetterCreateWithAttributedString((CFAttributedStringRef) attributedString);
        
        const CFIndex stringLength = CFAttributedStringGetLength((CFAttributedStringRef) attributedString);
        const CGFloat lineHeight = CalculateCTFontLineHeight(font);
        const CGFloat capHeight = CTFontGetCapHeight(font);
        
        CFIndex start = 0;
        BOOL isLastLine = NO;
        
        while (start < stringLength && !isLastLine) {
            drawSize.height += lineHeight;
            isLastLine = (drawSize.height+capHeight >= constrainedToSize.height);
            
            CFIndex usedCharacters = 0;
            CTLineRef line = NULL;
            
            if (isLastLine && (lineBreakMode != NSLineBreakByWordWrapping && lineBreakMode != NSLineBreakByCharWrapping)) {
                if (lineBreakMode == NSLineBreakByClipping) {
                    usedCharacters = CTTypesetterSuggestClusterBreak(typesetter, start, constrainedToSize.width);
                    line = CTTypesetterCreateLine(typesetter, CFRangeMake(start, usedCharacters));
                } else {
                    CTLineTruncationType truncType;
                    
                    if (lineBreakMode == NSLineBreakByTruncatingHead) {
                        truncType = kCTLineTruncationStart;
                    } else if (lineBreakMode == NSLineBreakByTruncatingTail) {
                        truncType = kCTLineTruncationEnd;
                    } else {
                        truncType = kCTLineTruncationMiddle;
                    }
                    
                    usedCharacters = stringLength - start;
                    CFAttributedStringRef ellipsisString = CFAttributedStringCreate(NULL, CFSTR("…"), (CFDictionaryRef) attributes);
                    CTLineRef ellipsisLine = CTLineCreateWithAttributedString(ellipsisString);
                    CTLineRef tempLine = CTTypesetterCreateLine(typesetter, CFRangeMake(start, usedCharacters));
                    line = CTLineCreateTruncatedLine(tempLine, constrainedToSize.width, truncType, ellipsisLine);
                    CFRelease(tempLine);
                    CFRelease(ellipsisLine);
                    CFRelease(ellipsisString);
                }
            } else {
                if (lineBreakMode == NSLineBreakByCharWrapping) {
                    usedCharacters = CTTypesetterSuggestClusterBreak(typesetter, start, constrainedToSize.width);
                } else {
                    usedCharacters = CTTypesetterSuggestLineBreak(typesetter, start, constrainedToSize.width);
                }
                line = CTTypesetterCreateLine(typesetter, CFRangeMake(start, usedCharacters));
            }
            
            if (line) {
                drawSize.width = MAX(drawSize.width, ceil(CTLineGetTypographicBounds(line,NULL,NULL,NULL)));
                
                CFArrayAppendValue(lines, line);
                CFRelease(line);
            }
            
            start += usedCharacters;
        }
        
        CFRelease(typesetter);
    }
    
    if (renderSize) {
        *renderSize = drawSize;
    }
    
    return lines;
}

static CFArrayRef CreateCTLinesForString(NSString *string, CGSize constrainedToSize, UIFont *font, NSLineBreakMode lineBreakMode, CGSize *renderSize)
{
	// this is to keep the original behavior where a nil font returns an empty array
    if(font == nil) {
		return CFArrayCreateMutable(NULL, 0, &kCFTypeArrayCallBacks);
	}
	
	CFMutableDictionaryRef attributes = CFDictionaryCreateMutable(NULL, 2, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
	CFDictionarySetValue(attributes, kCTFontAttributeName, [font _CTFont]);
	CFDictionarySetValue(attributes, kCTForegroundColorFromContextAttributeName, kCFBooleanTrue);
	
	CFAttributedStringRef attributedString = CFAttributedStringCreate(NULL, (CFStringRef)string, attributes);
	
	CFArrayRef lines = CreateCTLinesForAttributedString((NSAttributedString *) attributedString, constrainedToSize, lineBreakMode, renderSize);
    
	CFRelease(attributedString);
	CFRelease(attributes);
    
    return lines;
}


@implementation NSString (UIStringDrawing)

- (CGSize)sizeWithFont:(UIFont *)font
{
    return [self sizeWithFont:font constrainedToSize:CGSizeMake(CGFLOAT_MAX,CGFLOAT_MAX)];
}

- (CGSize)sizeWithFont:(UIFont *)font forWidth:(CGFloat)width lineBreakMode:(NSLineBreakMode)lineBreakMode
{
    return [self sizeWithFont:font constrainedToSize:CGSizeMake(width,font.lineHeight) lineBreakMode:lineBreakMode];
}

- (CGSize)sizeWithFont:(UIFont *)font minFontSize:(CGFloat)minFontSize actualFontSize:(CGFloat *)actualFontSize forWidth:(CGFloat)width lineBreakMode:(NSLineBreakMode)lineBreakMode
{
    return CGSizeZero;
}

- (CGSize)sizeWithFont:(UIFont *)font constrainedToSize:(CGSize)size lineBreakMode:(NSLineBreakMode)lineBreakMode
{
    CGSize resultingSize = CGSizeZero;
    
    CFArrayRef lines = CreateCTLinesForString(self, size, font, lineBreakMode, &resultingSize);
    if (lines) CFRelease(lines);
    
    return resultingSize;
}

- (CGSize)sizeWithFont:(UIFont *)font constrainedToSize:(CGSize)size
{
    return [self sizeWithFont:font constrainedToSize:size lineBreakMode:NSLineBreakByWordWrapping];
}

- (CGSize)drawAtPoint:(CGPoint)point withFont:(UIFont *)font
{
    return [self drawAtPoint:point forWidth:CGFLOAT_MAX withFont:font lineBreakMode:NSLineBreakByWordWrapping];
}

- (CGSize)drawAtPoint:(CGPoint)point forWidth:(CGFloat)width withFont:(UIFont *)font minFontSize:(CGFloat)minFontSize actualFontSize:(CGFloat *)actualFontSize lineBreakMode:(NSLineBreakMode)lineBreakMode baselineAdjustment:(UIBaselineAdjustment)baselineAdjustment
{
    //This is not *right* but beats not doing nothing
    CGFloat fontSize = [font pointSize];
    
    UIFont *adjustedFont = (fontSize!= minFontSize)? [font fontWithSize: MAX(minFontSize, fontSize)] : font;
    return [self drawInRect:CGRectMake(point.x,point.y,width,adjustedFont.lineHeight) withFont:adjustedFont lineBreakMode:lineBreakMode];
}

- (CGSize)drawAtPoint:(CGPoint)point forWidth:(CGFloat)width withFont:(UIFont *)font fontSize:(CGFloat)fontSize lineBreakMode:(NSLineBreakMode)lineBreakMode baselineAdjustment:(UIBaselineAdjustment)baselineAdjustment
{
    UIFont *adjustedFont = ([font pointSize] != fontSize)? [font fontWithSize:fontSize] : font;
    return [self drawInRect:CGRectMake(point.x,point.y,width,adjustedFont.lineHeight) withFont:adjustedFont lineBreakMode:lineBreakMode];
}

- (CGSize)drawAtPoint:(CGPoint)point forWidth:(CGFloat)width withFont:(UIFont *)font lineBreakMode:(NSLineBreakMode)lineBreakMode
{
    return [self drawAtPoint:point forWidth:width withFont:font fontSize:[font pointSize] lineBreakMode:lineBreakMode baselineAdjustment:UIBaselineAdjustmentNone];
}
 
- (CGSize)drawInRect:(CGRect)rect withFont:(UIFont *)font lineBreakMode:(NSLineBreakMode)lineBreakMode alignment:(NSTextAlignment)alignment
{
    CGSize actualSize = CGSizeZero;
    CFArrayRef lines = CreateCTLinesForString(self,rect.size,font,lineBreakMode,&actualSize);

    if (lines) {
        const CFIndex numberOfLines = CFArrayGetCount(lines);
        const CGFloat fontLineHeight = font.lineHeight;
        CGFloat textOffset = 0;

        CGContextRef ctx = UIGraphicsGetCurrentContext();
        CGContextSaveGState(ctx);
        CGContextTranslateCTM(ctx, rect.origin.x, rect.origin.y+font.ascender);
        CGContextSetTextMatrix(ctx, CGAffineTransformMakeScale(1,-1));
        
        for (CFIndex lineNumber=0; lineNumber<numberOfLines; lineNumber++) {
            CTLineRef line = CFArrayGetValueAtIndex(lines, lineNumber);
            CGFloat flush;
            switch (alignment) {
                case NSTextAlignmentCenter:	flush = 0.5;	break;
                case NSTextAlignmentRight:	flush = 1;		break;
                case NSTextAlignmentLeft:
                default:					flush = 0;		break;
            }
            
            CGFloat penOffset = CTLineGetPenOffsetForFlush(line, flush, rect.size.width);
            CGContextSetTextPosition(ctx, penOffset, textOffset);
            CTLineDraw(line, ctx);
            textOffset += fontLineHeight;
        }

        CGContextRestoreGState(ctx);

        CFRelease(lines);
    }

    // the real UIKit appears to do this.. so shall we.
    actualSize.height = MIN(actualSize.height, rect.size.height);

    return actualSize;
}

- (CGSize)drawInRect:(CGRect)rect withFont:(UIFont *)font
{
    return [self drawInRect:rect withFont:font lineBreakMode:NSLineBreakByWordWrapping alignment:UITextAlignmentLeft];
}

- (CGSize)drawInRect:(CGRect)rect withFont:(UIFont *)font lineBreakMode:(NSLineBreakMode)lineBreakMode
{
    return [self drawInRect:rect withFont:font lineBreakMode:lineBreakMode alignment:UITextAlignmentLeft];
}

@end


@implementation NSAttributedString (UIStringDrawing)

@end
