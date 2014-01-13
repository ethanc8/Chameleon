/*
 * Copyright (c) 2011, Casey Marshall. All rights reserved.
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

#import "UIDatePicker.h"


@implementation UIDatePicker 
@synthesize calendar = _calendar;
@synthesize date = _date;
@synthesize locale = _locale;
@synthesize timeZone = _timeZone;
@synthesize datePickerMode = _datePickerMode;
@synthesize minimumDate = _minimumDate;
@synthesize maximumDate = _maximumDate;
@synthesize minuteInterval = _minuteInterval;
@synthesize countDownDuration = _countDownDuration;

static NSString* const kUIDatePickerMode = @"UIDatePickerMode";
static NSString* const KUICalendar = @"UICalendar";
static NSString* const kUILocale = @"UILocale";
static NSString* const kUITimeZone = @"UITimeZone";
static NSString* const kUIMinimumDate = @"UIMinimumDate";
static NSString* const kUIMaximumDate = @"UIMaximumDate";
//static NSString* const kUIMinuteInterval = @"UIMinuteInterval";
static NSString* const kUICountDownDuration = @"UICountDownDuration";

- (void)setDate:(NSDate *)date animated:(BOOL)animated {
    self.date = date;
}

- (id) initWithCoder:(NSCoder*)coder
{
    if (nil != (self = [super initWithCoder:coder])) {
        if ([coder containsValueForKey:kUIDatePickerMode]) {
            self.datePickerMode = [coder decodeIntegerForKey:kUIDatePickerMode];
        } 
        if ([coder containsValueForKey:KUICalendar]) {
            self.calendar = [coder decodeObjectForKey:KUICalendar];
        } 
        if ([coder containsValueForKey:kUILocale]) {
            self.locale = [coder decodeObjectForKey:kUILocale];
        } 
        if ([coder containsValueForKey:kUITimeZone]) {
            self.timeZone = [coder decodeObjectForKey:kUITimeZone];
        } 
        if ([coder containsValueForKey:kUIMinimumDate]) {
            self.minimumDate = [coder decodeObjectForKey:kUIMinimumDate];
        } 
        if ([coder containsValueForKey:kUIMaximumDate]) {
            self.maximumDate = [coder decodeObjectForKey:kUIMaximumDate];
        } 
        if ([coder containsValueForKey:kUICountDownDuration]) {
            self.countDownDuration = [coder decodeFloatForKey:kUICountDownDuration];
        } 
    }
    return self;
}

- (void) dealloc
{
    [_calendar release];
    [_date release];
    [_locale release];
    [_timeZone release];
    [_minimumDate release];
    [_maximumDate release];
    [super dealloc];
}

@end
