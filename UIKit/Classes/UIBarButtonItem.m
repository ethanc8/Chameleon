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

#import "UIBarButtonItem.h"
#import "UIBarButtonItem+UIPrivate.h"
#import "UIImage+UIPrivate.h"
#import "UIToolbar.h"

__attribute__((annotate("returns_localized_nsstring")))
static inline NSString *LocalizationNotNeeded(NSString *s) {
    return s;
}


@implementation UIBarButtonItem 
@synthesize width = _width;
@synthesize customView = _customView;
@synthesize action = _action;
@synthesize target = _target;
@synthesize style = _style;

- (id)init
{
    if ((self=[super init])) {
        _isSystemItem = NO;
        self.style = UIBarButtonItemStylePlain;
    }
    return self;
}

- (id)initWithBarButtonSystemItem:(UIBarButtonSystemItem)systemItem target:(id)target action:(SEL)action
{
	if ((self=[self init])) {
		_isSystemItem = YES;
		_systemItem = systemItem;
		
		self.target = target;
		self.action = action;
		
		switch (systemItem) {
			case UIBarButtonSystemItemDone:
				self.title = LocalizationNotNeeded(@"Done");
				self.style = UIBarButtonItemStyleDone;
				break;
			case UIBarButtonSystemItemSave:
				self.title = LocalizationNotNeeded(@"Save");
				self.style = UIBarButtonItemStyleDone;
				break;
			case UIBarButtonSystemItemCancel:
				self.title = LocalizationNotNeeded(@"Cancel");
				self.style = UIBarButtonItemStylePlain;
				break;
			case UIBarButtonSystemItemEdit:
				self.title = LocalizationNotNeeded(@"Edit");
				self.style = UIBarButtonItemStylePlain;
				break;
			case UIBarButtonSystemItemUndo:
				self.title = LocalizationNotNeeded(@"Undo");
				self.style = UIBarButtonItemStylePlain;
				break;
			case UIBarButtonSystemItemRedo:
				self.title = LocalizationNotNeeded(@"Redo");
				self.style = UIBarButtonItemStylePlain;
				break;
			case UIBarButtonSystemItemAdd:
				self.image = [UIImage _buttonBarSystemItemAdd];
				self.style = UIBarButtonItemStylePlain;
				break;
			case UIBarButtonSystemItemAction:
				self.image = [UIImage _buttonBarSystemItemAction];
				self.style = UIBarButtonItemStylePlain;
				break;
			case UIBarButtonSystemItemCompose:
				self.image = [UIImage _buttonBarSystemItemCompose];
				self.style = UIBarButtonItemStylePlain;
				break;
			case UIBarButtonSystemItemReply:
				self.image = [UIImage _buttonBarSystemItemReply];
				self.style = UIBarButtonItemStylePlain;
				break;
            case UIBarButtonSystemItemOrganize:
                self.image = [UIImage _buttonBarSystemItemOrganize];
				self.style = UIBarButtonItemStylePlain;
                break;
            case UIBarButtonSystemItemBookmarks:
                self.image = [UIImage _buttonBarSystemItemBookmarks];
				self.style = UIBarButtonItemStylePlain;
                break;
            case UIBarButtonSystemItemSearch:
                self.image = [UIImage _buttonBarSystemItemSearch];
				self.style = UIBarButtonItemStylePlain;
                break;
            case UIBarButtonSystemItemRefresh:
                self.image = [UIImage _buttonBarSystemItemRefresh];
				self.style = UIBarButtonItemStylePlain;
                break;
            case UIBarButtonSystemItemStop:
                self.image = [UIImage _buttonBarSystemItemStop];
				self.style = UIBarButtonItemStylePlain;
                break;
            case UIBarButtonSystemItemCamera:
                self.image = [UIImage _buttonBarSystemItemCamera];
				self.style = UIBarButtonItemStylePlain;
                break;
            case UIBarButtonSystemItemTrash:
                self.image = [UIImage _buttonBarSystemItemTrash];
				self.style = UIBarButtonItemStylePlain;
                break;
            case UIBarButtonSystemItemPlay:
                self.image = [UIImage _buttonBarSystemItemPlay];
				self.style = UIBarButtonItemStylePlain;
                break;
            case UIBarButtonSystemItemPause:
                self.image = [UIImage _buttonBarSystemItemPause];
				self.style = UIBarButtonItemStylePlain;
                break;
            case UIBarButtonSystemItemRewind:
                self.image = [UIImage _buttonBarSystemItemRewind];
				self.style = UIBarButtonItemStylePlain;
                break;
            case UIBarButtonSystemItemFastForward:
                self.image = [UIImage _buttonBarSystemItemFastForward];
				self.style = UIBarButtonItemStylePlain;
                break;
                //TODO: Implement these
            case UIBarButtonSystemItemFixedSpace:
            case UIBarButtonSystemItemFlexibleSpace:
                break;
		}
		
		
	}
	return self;
}

- (id)initWithCustomView:(UIView *)customView
{
    if ((self=[self init])) {
        self.customView = customView;
    }
    return self;
}

- (id)initWithTitle:(NSString *)title style:(UIBarButtonItemStyle)style target:(id)target action:(SEL)action
{
    if ((self=[self init])) {
        self.title = title;
        self.style = style;
        self.target = target;
        self.action = action;
    }
    return self;
}

- (id)initWithImage:(UIImage *)image style:(UIBarButtonItemStyle)style target:(id)target action:(SEL)action
{
    if ((self=[self init])) {
        self.image = image;
        self.style = style;
        self.target = target;
        self.action = action;
    }
    return self;
}

- (void)dealloc
{
    [_customView release];
    [super dealloc];
}

- (UIView *)customView
{
    return _isSystemItem? nil : _customView;
}


- (void) _setToolbarItem:(UIToolbarItem*) item
{
    _toolbarItem = item;
}

- (UIToolbarItem*) _getToolbarItem
{
    return _toolbarItem;
}

@end
