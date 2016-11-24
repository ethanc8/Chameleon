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

#import "UIPageControl.h"
#import "UIFont.h"
#import "UIStringDrawing.h"
#import "UIColor.h"
#import "UITouch.h"

#define kDotWidth 15

@implementation UIPageControl
@synthesize currentPage = _currentPage;
@synthesize numberOfPages = _numberOfPages;
@synthesize currentPageIndicatorTintColor = _currentPageIndicatorTintColor;
@synthesize pageIndicatorTintColor = _pageIndicatorTintColor;

__attribute__((annotate("returns_localized_nsstring")))
static inline NSString *LocalizationNotNeeded(NSString *s) {
    return s;
}



- (void)commonInit
{
    self.autoresizingMask = UIViewAutoresizingNone;
}

- (id)init
{
    if ((self=[super init])) {
        [self commonInit];
    }
    return self;
}

-(void)dealloc
{
    [_currentPageIndicatorTintColor release];
    [_pageIndicatorTintColor release];
    
    [super dealloc];
}

- (id)initWithFrame:(CGRect)frame
{
    if ((self=[super initWithFrame:frame])) {
        [self commonInit];
    }
    return self;
}

- (void)setCurrentPage:(NSInteger)page
{
    if (page != _currentPage) {
        _currentPage = MIN(MAX(0,page), self.numberOfPages-1);
        [self setNeedsDisplay];
    }
}

- (void) touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event
{
	[super touchesBegan:touches withEvent:event];
    
    UITouch* touch = [touches anyObject];
    CGPoint point = [touch locationInView:self];
	if ([self pointInside:point withEvent:event]) {
        if(point.x < self.frame.size.width/2) {
            [self setCurrentPage:_currentPage - 1];
        } else {
            [self setCurrentPage:_currentPage + 1];
        }
        [self sendActionsForControlEvents:UIControlEventValueChanged]; 
    }
}


- (void)drawRect:(CGRect)frame {
    int drawSize = (int) (kDotWidth*self.numberOfPages/2);
    
    UIColor *inactiveColor = self.pageIndicatorTintColor? : [UIColor colorWithRed:135/255.f green:135/255.f blue:135/255.f alpha:0.7];
    
    for(int i=0;i<self.numberOfPages;i++) {
        if(i==_currentPage) {
            [(self.currentPageIndicatorTintColor ? : [UIColor whiteColor]) set];
        } else {
            [inactiveColor set];
        }
        
        [LocalizationNotNeeded(@"•") drawAtPoint:CGPointMake(frame.size.width/2 - drawSize + i*kDotWidth, frame.origin.y) forWidth:frame.size.width
                 withFont:[UIFont boldSystemFontOfSize:12] minFontSize:12 actualFontSize:NULL
            lineBreakMode:(NSLineBreakMode) UILineBreakModeTailTruncation baselineAdjustment:UIBaselineAdjustmentAlignBaselines];
    }
}

@end
