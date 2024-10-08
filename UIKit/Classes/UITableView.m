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

#import "UITableView.h"
#import "UITableView+UIPrivate.h"
#import "UITableViewCell+UIPrivate.h"
#import "UIColor.h"
#import "UITouch.h"
#import "UITableViewSection.h"
#import "UITableViewSectionLabel.h"
#import "UIScreenAppKitIntegration.h"
#import "UIWindow.h"
#import "UIKitView.h"
#import "UIApplication+UIPrivate.h"
#import "UIKey.h"
#import "UIResponderAppKitIntegration.h"
#import "UITableViewAppKitIntegration.h"
#import <AppKit/NSMenu.h>
#import <AppKit/NSMenuItem.h>
#import <AppKit/NSEvent.h>

// http://stackoverflow.com/questions/235120/whats-the-uitableview-index-magnifying-glass-character
NSString *const UITableViewIndexSearch = @"{search}";

const CGFloat _UITableViewDefaultRowHeight = 44;

static NSString* const kUIAllowsSelectionDuringEditingKey = @"UIAllowsSelectionDuringEditing";
static NSString* const kUIRowHeightKey = @"UIRowHeight";
static NSString* const kUISectionFooterHeightKey = @"UISectionFooterHeight";
static NSString* const kUISectionHeaderHeightKey = @"UISectionHeaderHeight";
static NSString* const kUISeparatorColorKey = @"UISeparatorColor";
static NSString* const kUISeparatorStyleKey = @"UISeparatorStyle";
static NSString* const kUIStyleKey = @"UIStyle";

__attribute__((annotate("returns_localized_nsstring")))
static inline NSString *LocalizationNotNeeded(NSString *s) {
    return s;
}


@interface UITableView ()
- (void)_setNeedsReload;
- (NSIndexPath *)_selectRowAtIndexPath:(NSIndexPath *)indexPath exclusively:(BOOL)exclusively sendDelegateMessages:(BOOL)sendDelegateMessage animated:(BOOL)animated scrollPosition:(UITableViewScrollPosition)scrollPosition;
@end

@implementation UITableView
@synthesize style = _style;
@synthesize dataSource = _dataSource;
@synthesize rowHeight = _rowHeight;
@synthesize separatorStyle = _separatorStyle;
@synthesize separatorColor = _separatorColor;
@synthesize tableHeaderView = _tableHeaderView;
@synthesize tableFooterView = _tableFooterView;
@synthesize allowsSelection = _allowsSelection;
@synthesize editing = _editing;
@synthesize sectionFooterHeight = _sectionFooterHeight;
@synthesize sectionHeaderHeight = _sectionHeaderHeight;
@synthesize allowsSelectionDuringEditing = _allowsSelectionDuringEditing;
@synthesize allowsMultipleSelection = _allowsMultipleSelection;
@synthesize selectedRows = _selectedRows;
@synthesize backgroundView = _backgroundView;

@dynamic delegate;

- (void) dealloc
{
    [_backgroundView release];
    [_selectedRows release];
    [_tableFooterView release];
    [_tableHeaderView release];
    [_cachedCells release];
    [_sections release];
    [_reusableCells release];
    [_separatorColor release];
    [super dealloc];
}

- (void) _commonInitForUITableView
{
    _cachedCells = [[NSMutableDictionary alloc] init];
    _sections = [[NSMutableArray alloc] init];
    _reusableCells = [[NSMutableSet alloc] init];
    _selectedRows = [[NSMutableArray alloc] init];
    
    self.separatorColor = [UIColor colorWithRed:.88f green:.88f blue:.88f alpha:1];
    self.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.showsHorizontalScrollIndicator = NO;
    self.allowsSelection = YES;
    self.allowsSelectionDuringEditing = NO;
    self.sectionHeaderHeight = self.sectionFooterHeight = 22;
    self.alwaysBounceVertical = YES;
    
    if (_style == UITableViewStylePlain && !self.backgroundColor) {
        self.backgroundColor = [UIColor whiteColor];
    }
    
    [self _setNeedsReload];
}

- (id) initWithFrame:(CGRect)frame
{
    return [self initWithFrame:frame style:UITableViewStylePlain];
}

- (id) initWithFrame:(CGRect)frame style:(UITableViewStyle)theStyle
{
    if (nil != (self = [super initWithFrame:frame])) {
        _style = theStyle;
        [self _commonInitForUITableView];
    }
    return self;
}

- (id) initWithCoder:(NSCoder*)coder
{
    if (nil != (self = [super initWithCoder:coder])) {
        if ([coder containsValueForKey:kUIStyleKey]) {
            _style = (UITableViewStyle)[coder decodeIntegerForKey:kUIStyleKey];
        } else {
            _style = UITableViewStylePlain;
        }
        [self _commonInitForUITableView];
        if ([coder containsValueForKey:kUIAllowsSelectionDuringEditingKey]) {
            self.allowsSelectionDuringEditing = [coder decodeBoolForKey:kUIAllowsSelectionDuringEditingKey];
        }
        if ([coder containsValueForKey:kUIRowHeightKey]) {
            self.rowHeight = [coder decodeDoubleForKey:kUIRowHeightKey];
        }
        if ([coder containsValueForKey:kUISectionFooterHeightKey]) {
            self.sectionFooterHeight = [coder decodeDoubleForKey:kUISectionFooterHeightKey];
        }
        if ([coder containsValueForKey:kUISectionHeaderHeightKey]) {
            self.sectionHeaderHeight = [coder decodeDoubleForKey:kUISectionHeaderHeightKey];
        }
        if ([coder containsValueForKey:kUISeparatorColorKey]) {
            self.separatorColor = [coder decodeObjectForKey:kUISeparatorColorKey];
        }
        if ([coder containsValueForKey:kUISeparatorStyleKey]) {
            self.separatorStyle = (UITableViewCellSeparatorStyle)[coder decodeIntegerForKey:kUISeparatorStyleKey];
        } else {
            // This means that the separator style has been set to None
            self.separatorStyle = UITableViewCellSeparatorStyleNone;
        }
    }
    return self;
}

- (void)setDataSource:(id<UITableViewDataSource>)newSource
{
    _dataSource = newSource;
    
    _dataSourceHas.numberOfSectionsInTableView = [_dataSource respondsToSelector:@selector(numberOfSectionsInTableView:)];
    _dataSourceHas.titleForHeaderInSection = [_dataSource respondsToSelector:@selector(tableView:titleForHeaderInSection:)];
    _dataSourceHas.titleForFooterInSection = [_dataSource respondsToSelector:@selector(tableView:titleForFooterInSection:)];
    _dataSourceHas.commitEditingStyle = [_dataSource respondsToSelector:@selector(tableView:commitEditingStyle:forRowAtIndexPath:)];
    _dataSourceHas.canEditRowAtIndexPath = [_dataSource respondsToSelector:@selector(tableView:canEditRowAtIndexPath:)];
    
    [self _setNeedsReload];
}

- (void)setDelegate:(id<UITableViewDelegate>)newDelegate
{
    [super setDelegate:newDelegate];
    if (newDelegate) {
        _delegateHas.heightForRowAtIndexPath = [newDelegate respondsToSelector:@selector(tableView:heightForRowAtIndexPath:)];
        _delegateHas.heightForHeaderInSection = [newDelegate respondsToSelector:@selector(tableView:heightForHeaderInSection:)];
        _delegateHas.heightForFooterInSection = [newDelegate respondsToSelector:@selector(tableView:heightForFooterInSection:)];
        _delegateHas.viewForHeaderInSection = [newDelegate respondsToSelector:@selector(tableView:viewForHeaderInSection:)];
        _delegateHas.viewForFooterInSection = [newDelegate respondsToSelector:@selector(tableView:viewForFooterInSection:)];
        _delegateHas.willSelectRowAtIndexPath = [newDelegate respondsToSelector:@selector(tableView:willSelectRowAtIndexPath:)];
        _delegateHas.didSelectRowAtIndexPath = [newDelegate respondsToSelector:@selector(tableView:didSelectRowAtIndexPath:)];
        _delegateHas.didDoubleClickRowAtIndexPath = [newDelegate respondsToSelector:@selector(tableView:didDoubleClickRowAtIndexPath:)];
        _delegateHas.willDeselectRowAtIndexPath = [newDelegate respondsToSelector:@selector(tableView:willDeselectRowAtIndexPath:)];
        _delegateHas.didDeselectRowAtIndexPath = [newDelegate respondsToSelector:@selector(tableView:didDeselectRowAtIndexPath:)];
        _delegateHas.accessoryButtonTappedForRowWithIndexPath = [newDelegate respondsToSelector:@selector(tableView:accessoryButtonTappedForRowWithIndexPath:)];
        _delegateHas.willDeselectRowAtIndexPath = [_delegate respondsToSelector:@selector(tableView:willDeselectRowAtIndexPath:)];
        _delegateHas.didDeselectRowAtIndexPath = [_delegate respondsToSelector:@selector(tableView:didDeselectRowAtIndexPath:)];
        _delegateHas.willBeginEditingRowAtIndexPath = [_delegate respondsToSelector:@selector(tableView:willBeginEditingRowAtIndexPath:)];
        _delegateHas.didEndEditingRowAtIndexPath = [_delegate respondsToSelector:@selector(tableView:didEndEditingRowAtIndexPath:)];
        _delegateHas.titleForDeleteConfirmationButtonForRowAtIndexPath = [_delegate respondsToSelector:@selector(tableView:titleForDeleteConfirmationButtonForRowAtIndexPath:)];
    }
}

- (void)setRowHeight:(CGFloat)newHeight
{
    _rowHeight = newHeight;
    [self setNeedsLayout];
}

- (void)_updateSectionsCache
{
    // uses the dataSource to rebuild the cache.
    // if there's no dataSource, this can't do anything else.
    // note that I'm presently caching and hanging on to views and titles for section headers which is something
    // the real UIKit appears to fetch more on-demand than this. so far this has not been a problem.
    
    // remove all previous section header/footer views
    for (UITableViewSection *previousSectionRecord in _sections) {
        [previousSectionRecord.headerView removeFromSuperview];
        [previousSectionRecord.footerView removeFromSuperview];
    }
    
    // clear the previous cache
    [_sections removeAllObjects];
    
    if (_dataSource) {
        // compute the heights/offsets of everything
        const CGFloat defaultRowHeight = _rowHeight ?: _UITableViewDefaultRowHeight;
        const NSInteger numberOfSections = [self numberOfSections];
        for (NSInteger section=0; section<numberOfSections; section++) {
            const NSInteger numberOfRowsInSection = [self numberOfRowsInSection:section];
            
            UITableViewSection *sectionRecord = [[UITableViewSection alloc] init];
            sectionRecord.headerView = _delegateHas.viewForHeaderInSection? [self.delegate tableView:self viewForHeaderInSection:section] : nil;
            sectionRecord.footerView = _delegateHas.viewForFooterInSection? [self.delegate tableView:self viewForFooterInSection:section] : nil;
            sectionRecord.headerTitle = _dataSourceHas.titleForHeaderInSection? [self.dataSource tableView:self titleForHeaderInSection:section] : nil;
            sectionRecord.footerTitle = _dataSourceHas.titleForFooterInSection? [self.dataSource tableView:self titleForFooterInSection:section] : nil;
            
            // make a default section header view if there's a title for it and no overriding view
            if (!sectionRecord.headerView && sectionRecord.headerTitle) {
                sectionRecord.headerView = [UITableViewSectionLabel sectionLabelWithTitle:sectionRecord.headerTitle];
            }
            
            // make a default section footer view if there's a title for it and no overriding view
            if (!sectionRecord.footerView && sectionRecord.footerTitle) {
                
                if (self.style == UITableViewStylePlain) {
                    sectionRecord.footerView = [UITableViewSectionLabel sectionLabelWithTitle:sectionRecord.footerTitle];
                } else {
                    UILabel *footerLabel = [[[UILabel alloc] init] autorelease];
                    footerLabel.text = sectionRecord.footerTitle;
                    footerLabel.backgroundColor = self.backgroundColor;
                    footerLabel.textColor = [UIColor grayColor];
                    footerLabel.textAlignment = UITextAlignmentCenter;
                    footerLabel.numberOfLines = 2;
                    sectionRecord.footerView = footerLabel;
                }
            }
            
            // if there's a view, then we need to set the height, otherwise it's going to be zero
            if (sectionRecord.headerView) {
                [self addSubview:sectionRecord.headerView];
                sectionRecord.headerHeight = _delegateHas.heightForHeaderInSection? [self.delegate tableView:self heightForHeaderInSection:section] : _sectionHeaderHeight;
            } else {
                sectionRecord.headerHeight = 0;
            }
            
            if (sectionRecord.footerView) {
                [self addSubview:sectionRecord.footerView];
                
                CGFloat _defaultSectionFooterHeight = self.style == UITableViewStylePlain ? _sectionFooterHeight: [sectionRecord.footerView sizeThatFits:CGSizeZero].height;
                
                sectionRecord.footerHeight = _delegateHas.heightForFooterInSection? [self.delegate tableView:self heightForFooterInSection:section] : _defaultSectionFooterHeight;
                
            } else {
                sectionRecord.footerHeight = 0;
            }
            
			CGFloat *rowHeights = (CGFloat *) malloc(sizeof(CGFloat) * numberOfRowsInSection);
            CGFloat totalRowsHeight = 0;
            
            for (NSInteger row=0; row<numberOfRowsInSection; row++) {
                const CGFloat rowHeight = _delegateHas.heightForRowAtIndexPath? [self.delegate tableView:self heightForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:section]] : defaultRowHeight;
                rowHeights[row] = rowHeight;
                totalRowsHeight += rowHeight;
            }
            
            sectionRecord.rowsHeight = totalRowsHeight;
            [sectionRecord setNumberOfRows:numberOfRowsInSection withHeights:rowHeights];
            
            free(rowHeights);
            
            [_sections addObject:sectionRecord];
            [sectionRecord release];
        }
    }
}

- (void)_updateSectionsCacheIfNeeded
{
    // if there's a cache already in place, this doesn't do anything,
    // otherwise calls _updateSectionsCache.
    // this is called from _setContentSize and other places that require access
    // to the section caches (mostly for size-related information)
    
    if ([_sections count] == 0) {
        [self _updateSectionsCache];
    }
}

- (void)_setContentSize
{
    // first calls _updateSectionsCacheIfNeeded, then sets the scroll view's size
    // taking into account the size of the header, footer, and all rows.
    // should be called by reloadData, setFrame, header/footer setters.
    
    [self _updateSectionsCacheIfNeeded];
    
    CGFloat height = _tableHeaderView? _tableHeaderView.frame.size.height : 0;
    
    for (UITableViewSection *section in _sections) {
        height += [section sectionHeight];
    }
    
    if (_tableFooterView) {
        height += _tableFooterView.frame.size.height;
    }
    
    // We subtract 1 here to cut off the last separator line, this should
    // probably be done a better way but this works for now
    self.contentSize = CGSizeMake(self.bounds.size.width,height - 1);
}

- (UITableViewCell*) _ensureCellExistsAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell = [_cachedCells objectForKey:indexPath];
    if (!cell) {
        cell = [self.dataSource tableView:self cellForRowAtIndexPath:indexPath];
        [_cachedCells setObject:cell forKey:indexPath];
        cell.selected = [_selectedRows containsObject:indexPath];
        cell.frame = [self rectForRowAtIndexPath:indexPath];
        
        [cell _setTableViewStyle:UITableViewStylePlain != self.style];
        
        NSUInteger numberOfRows = [[_sections objectAtIndex:indexPath.section] numberOfRows];
        if (indexPath.row == 0 && numberOfRows == 1) {
            cell.sectionLocation = UITableViewCellSectionLocationUnique;
            [cell _setSeparatorStyle:_separatorStyle color:_separatorColor];
        }
        else if (indexPath.row == 0) {
            cell.sectionLocation = UITableViewCellSectionLocationTop;
            [cell _setSeparatorStyle:_separatorStyle color:_separatorColor];
        }
        else if (indexPath.row != numberOfRows - 1) {
            cell.sectionLocation = UITableViewCellSectionLocationMiddle;
            [cell _setSeparatorStyle:_separatorStyle color:_separatorColor];
        }
        else {
            cell.sectionLocation = UITableViewCellSectionLocationBottom;
            
            // This is not iOS convention
            //[cell _setSeparatorStyle:UITableViewCellSeparatorStyleNone color:_separatorColor];
            
            // This IS iOS convention, since true "grouped" isn't currently supported
            [cell _setSeparatorStyle:_separatorStyle color:_separatorColor];
        }
        
        [self addSubview:cell];
        [cell setNeedsDisplay];
    }
    
    return cell;
}

- (void)_layoutTableView
{
    // lays out headers and rows that are visible at the time. this should also do cell
    // dequeuing and keep a list of all existing cells that are visible and those
    // that exist but are not visible and are reusable
    // if there's no section cache, no rows will be laid out but the header/footer will (if any).
    
    const CGSize boundsSize = self.bounds.size;
    const CGFloat contentOffset = self.contentOffset.y;
    const CGRect visibleBounds = CGRectMake(0,contentOffset,boundsSize.width,boundsSize.height);
    CGFloat tableHeight = 0;
    
    if (_tableHeaderView) {
        CGRect tableHeaderFrame = _tableHeaderView.frame;
        tableHeaderFrame.origin = CGPointZero;
        tableHeaderFrame.size.width = boundsSize.width;
        _tableHeaderView.frame = tableHeaderFrame;
        _tableHeaderView.hidden = !CGRectIntersectsRect(tableHeaderFrame, visibleBounds);
        tableHeight += tableHeaderFrame.size.height;
        
        if(!_tableHeaderView.hidden) {
            [_tableHeaderView setNeedsLayout];
        }
    }
    
    // layout sections and rows
    NSMutableDictionary* usedCells = [[NSMutableDictionary alloc] init];
    const NSInteger numberOfSections = [_sections count];
    
    for (NSInteger section=0; section<numberOfSections; section++) {
        NSAutoreleasePool *sectionPool = [[NSAutoreleasePool alloc] init];
        CGRect sectionRect = [self rectForSection:section];
        tableHeight += sectionRect.size.height;
		UITableViewSection *sectionRecord = [_sections objectAtIndex:section];
        const CGRect headerRect = [self rectForHeaderInSection:section];
        const CGRect footerRect = [self rectForFooterInSection:section];
        
        if (sectionRecord.headerView) {
            sectionRecord.headerView.frame = headerRect;
        }
        
        if (sectionRecord.footerView) {
            sectionRecord.footerView.frame = footerRect;
        }
        
        if (CGRectIntersectsRect(sectionRect, visibleBounds)) {
            const NSInteger numberOfRows = sectionRecord.numberOfRows;
            
            for (NSInteger row=0; row<numberOfRows; row++) {
                NSAutoreleasePool *rowPool = [[NSAutoreleasePool alloc] init];
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
                CGRect rowRect = [self rectForRowAtIndexPath:indexPath];
                if (CGRectIntersectsRect(rowRect,visibleBounds) && rowRect.size.height > 0) {
                    UITableViewCell* cell = [self _ensureCellExistsAtIndexPath:indexPath];
                    cell.frame = rowRect;
                    [usedCells setObject:cell forKey:indexPath];
                    [cell setNeedsLayout];
                }
                [rowPool drain];
            }
        }
        
        [sectionPool drain];
    }
    
    // remove old cells, but save off any that might be reusable
    for (NSIndexPath* indexPath in [_cachedCells allKeys]) {
        if (![usedCells objectForKey:indexPath]) {
            UITableViewCell* cell = [_cachedCells objectForKey:indexPath];
            if (cell.reuseIdentifier) {
                [_reusableCells addObject:cell];
            } else {
                [cell removeFromSuperview];
            }
            [_cachedCells removeObjectForKey:indexPath];
        }
    }
    
    // non-reusable cells should end up dealloced after at this point, but reusable ones live on in _reusableCells.
    [usedCells release];
    
    // now make sure that all available (but unused) reusable cells aren't on screen in the visible area.
    // this is done becaue when resizing a table view by shrinking it's height in an animation, it looks better. The reason is that
    // when an animation happens, it sets the frame to the new (shorter) size and thus recalcuates which cells should be visible.
    // If it removed all non-visible cells, then the cells on the bottom of the table view would disappear immediately but before
    // the frame of the table view has actually animated down to the new, shorter size. So the animation is jumpy/ugly because
    // the cells suddenly disappear instead of seemingly animating down and out of view like they should. This tries to leave them
    // on screen as long as possible, but only if they don't get in the way.
    NSArray* allCachedCells = [_cachedCells allValues];
    for (UITableViewCell *cell in _reusableCells) {
        if (CGRectIntersectsRect(cell.frame,visibleBounds) && ![allCachedCells containsObject: cell]) {
            [cell removeFromSuperview];
        }
    }
    
    if (_tableFooterView) {
        CGRect tableFooterFrame = _tableFooterView.frame;
        tableFooterFrame.origin = CGPointMake(0,tableHeight);
        tableFooterFrame.size.width = boundsSize.width;
        _tableFooterView.frame = tableFooterFrame;
        _tableFooterView.hidden = !CGRectIntersectsRect(tableFooterFrame, visibleBounds);
        
        if (!_tableFooterView.hidden ) {
            [_tableFooterView setNeedsLayout];
        }
    }
}

- (CGRect)_CGRectFromVerticalOffset:(CGFloat)offset height:(CGFloat)height
{
	if(self.style==UITableViewStylePlain)
        return CGRectMake(0,offset,self.bounds.size.width,height);
	else
        return CGRectMake(9,offset,self.bounds.size.width-29,height);
    
}

- (CGFloat)_offsetForSection:(NSInteger)index
{
    CGFloat offset = _tableHeaderView? _tableHeaderView.frame.size.height : 0;
    
    for (NSInteger s=0; s<index; s++) {
        offset += [[_sections objectAtIndex:s] sectionHeight];
    }
    
    return offset;
}

- (CGRect)rectForSection:(NSInteger)section
{
    [self _updateSectionsCacheIfNeeded];
    return [self _CGRectFromVerticalOffset:[self _offsetForSection:section] height:[[_sections objectAtIndex:section] sectionHeight]];
}

- (CGRect)rectForHeaderInSection:(NSInteger)section
{
    [self _updateSectionsCacheIfNeeded];
    return [self _CGRectFromVerticalOffset:[self _offsetForSection:section] height:[[_sections objectAtIndex:section] headerHeight]];
}

- (CGRect)rectForFooterInSection:(NSInteger)section
{
    [self _updateSectionsCacheIfNeeded];
    UITableViewSection *sectionRecord = [_sections objectAtIndex:section];
    CGFloat offset = [self _offsetForSection:section];
    offset += sectionRecord.headerHeight;
    offset += sectionRecord.rowsHeight;
    return [self _CGRectFromVerticalOffset:offset height:sectionRecord.footerHeight];
}

- (CGRect)rectForRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self _updateSectionsCacheIfNeeded];
    
    if (indexPath && indexPath.section < [_sections count]) {
        UITableViewSection *sectionRecord = [_sections objectAtIndex:indexPath.section];
        
        if (indexPath.row < sectionRecord.numberOfRows) {
            CGFloat offset = [self _offsetForSection:indexPath.section];
            offset += sectionRecord.headerHeight;
            
            for (NSInteger row=0; row<indexPath.row; row++) {
				offset += sectionRecord.rowHeights[row];
            }
            
            return [self _CGRectFromVerticalOffset:offset height:sectionRecord.rowHeights[indexPath.row]];
        }
    }
    
    return CGRectZero;
}

- (void) beginUpdates
{
	[UIView beginAnimations:NSStringFromSelector(_cmd) context:NULL];
}

- (void)endUpdates
{
	[self _updateSectionsCache];
	[self _setContentSize];
	[self _layoutTableView];
    
	[UIView commitAnimations];
}

- (UITableViewCell *)cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // this is allowed to return nil if the cell isn't visible and is not restricted to only returning visible cells
    // so this simple call should be good enough.
    return [_cachedCells objectForKey:indexPath];
}

- (NSArray *)indexPathsForRowsInRect:(CGRect)rect
{
    // This needs to return the index paths even if the cells don't exist in any caches or are not on screen
    // For now I'm assuming the cells stretch all the way across the view. It's not clear to me if the real
    // implementation gets anal about this or not (haven't tested it).
    
    [self _updateSectionsCacheIfNeeded];
    
    NSMutableArray *results = [[NSMutableArray alloc] init];
    const NSInteger numberOfSections = [_sections count];
    CGFloat offset = _tableHeaderView? _tableHeaderView.frame.size.height : 0;
    
    for (NSInteger section=0; section<numberOfSections; section++) {
        UITableViewSection *sectionRecord = [_sections objectAtIndex:section];
        const NSInteger numberOfRows = sectionRecord.numberOfRows;
        
        offset += sectionRecord.headerHeight;
        
        if (offset + sectionRecord.rowsHeight >= rect.origin.y) {
            for (NSInteger row=0; row<numberOfRows; row++) {
                const CGFloat height = sectionRecord.rowHeights[row];
                CGRect simpleRowRect = CGRectMake(rect.origin.x, offset, rect.size.width, height);
                
                if (CGRectIntersectsRect(rect,simpleRowRect)) {
                    [results addObject:[NSIndexPath indexPathForRow:row inSection:section]];
                } else if (simpleRowRect.origin.y > rect.origin.y+rect.size.height) {
                    break;	// don't need to find anything else.. we are past the end
                }
                
                offset += height;
            }
        } else {
            offset += sectionRecord.rowsHeight;
        }
        
        offset += sectionRecord.footerHeight;
    }
    
    return [results autorelease];
}

- (NSIndexPath *)indexPathForRowAtPoint:(CGPoint)point
{
    NSArray *paths = [self indexPathsForRowsInRect:CGRectMake(point.x,point.y,1,1)];
    return ([paths count] > 0)? [paths objectAtIndex:0] : nil;
}

- (NSArray *)indexPathsForVisibleRows
{
    [self _layoutTableView];
    
    NSMutableArray *indexes = [NSMutableArray arrayWithCapacity:[_cachedCells count]];
    const CGRect bounds = self.bounds;
    
    // Special note - it's unclear if UIKit returns these in sorted order. Because we're assuming that visibleCells returns them in order (top-bottom)
    // and visibleCells uses this method, I'm going to make the executive decision here and assume that UIKit probably does return them sorted - since
    // there's nothing warning that they aren't. :)
    
    for (NSIndexPath *indexPath in [[_cachedCells allKeys] sortedArrayUsingSelector:@selector(compare:)]) {
        if (CGRectIntersectsRect(bounds,[self rectForRowAtIndexPath:indexPath])) {
            [indexes addObject:indexPath];
        }
    }
    
    return indexes;
}

- (NSArray *)visibleCells
{
    NSMutableArray *cells = [[[NSMutableArray alloc] init] autorelease];
    for (NSIndexPath *index in [self indexPathsForVisibleRows]) {
        UITableViewCell *cell = [self cellForRowAtIndexPath:index];
        if (cell) {
            [cells addObject:cell];
        }
    }
    return cells;
}

- (void)setTableHeaderView:(UIView *)newHeader
{
    if (newHeader != _tableHeaderView) {
        [_tableHeaderView removeFromSuperview];
        [_tableHeaderView release];
        _tableHeaderView = [newHeader retain];
        [self _setContentSize];
        [self addSubview:_tableHeaderView];
    }
}

- (void)setTableFooterView:(UIView *)newFooter
{
    if (newFooter != _tableFooterView) {
        [_tableFooterView removeFromSuperview];
        [_tableFooterView release];
        _tableFooterView = [newFooter retain];
        [self _setContentSize];
        [self addSubview:_tableFooterView];
    }
}

- (void)setBackgroundView:(UIView *)backgroundView
{
    if (_backgroundView != backgroundView) {
        [_backgroundView removeFromSuperview];
        [_backgroundView release];
        _backgroundView = [backgroundView retain];
        [self insertSubview:_backgroundView atIndex:0];
    }
}

- (UIView *)backgroundView
{
    if (_backgroundView) {
        return _backgroundView;
    }
    
    return self;
}

- (NSInteger)numberOfSections
{
    if (_dataSourceHas.numberOfSectionsInTableView) {
        return [self.dataSource numberOfSectionsInTableView:self];
    } else {
        return 1;
    }
}

- (NSInteger)numberOfRowsInSection:(NSInteger)section
{
    return [self.dataSource tableView:self numberOfRowsInSection:section];
}

- (void)reloadData
{
    // clear the caches and remove the cells since everything is going to change
    [[_cachedCells allValues] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [_reusableCells makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [_reusableCells removeAllObjects];
    [_cachedCells removeAllObjects];
    
    // clear prior selection
    [_selectedRows removeAllObjects];
    
    // trigger the section cache to be repopulated
    [self _updateSectionsCache];
    [self _setContentSize];
    
    _needsReload = NO;
}


- (void)reloadRowsAtIndexPaths:(NSIndexPath *)indexPath withRowAnimation:(UITableViewRowAnimation)rowAnimation
{
    [self reloadData];
}

- (void)_reloadDataIfNeeded
{
    if (_needsReload) {
        [self reloadData];
    }
}

- (void)_setNeedsReload
{
    _needsReload = YES;
    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    _backgroundView.frame = self.bounds;
    [self _reloadDataIfNeeded];
    [self _layoutTableView];
    [super layoutSubviews];
}

- (void)setFrame:(CGRect)frame
{
    const CGRect oldFrame = self.frame;
    if (!CGRectEqualToRect(oldFrame,frame)) {
        [super setFrame:frame];
        
        if (oldFrame.size.width != frame.size.width) {
            [self _updateSectionsCache];
        }
        
        [self _setContentSize];
    }
}

- (NSIndexPath *)indexPathForSelectedRow
{
    if (![_selectedRows count]) { return nil; }
    return [[[_selectedRows objectAtIndex:0] retain] autorelease];
}

- (NSIndexPath *)indexPathForCell:(UITableViewCell *)cell
{
    for (NSIndexPath *index in [_cachedCells allKeys]) {
        if ([_cachedCells objectForKey:index] == cell) {
            return [[index retain] autorelease];
        }
    }
    
    return nil;
}

- (void)deselectRowAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated
{
    NSUInteger index = [_selectedRows indexOfObject:indexPath];
    if (indexPath && index != NSNotFound) {
        [self cellForRowAtIndexPath:indexPath].selected = NO;
        [_selectedRows removeObjectAtIndex:index];
    }
}

- (void)deselectAllRowsAnimated:(BOOL)animated
{
    for (NSIndexPath *indexPath in [NSArray arrayWithArray:_selectedRows]) {
        [self deselectRowAtIndexPath:indexPath animated:animated];
    }
}

- (void)selectRowAtIndexPath:(NSIndexPath *)indexPath exclusively:(BOOL)exclusively animated:(BOOL)animated scrollPosition:(UITableViewScrollPosition)scrollPosition
{
    [self _reloadDataIfNeeded];
    
    [self scrollToRowAtIndexPath:indexPath atScrollPosition:scrollPosition animated:animated];
    
    if (!self.allowsMultipleSelection) {
        exclusively = YES;
    }
    if (exclusively) {
        [self deselectAllRowsAnimated:animated];
    }
    if (indexPath && ![_selectedRows containsObject:indexPath]) {
        [_selectedRows addObject:indexPath];
        [self cellForRowAtIndexPath:indexPath].selected = YES;
    }
}

- (void)selectRowAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated scrollPosition:(UITableViewScrollPosition)scrollPosition
{
    [self selectRowAtIndexPath:indexPath exclusively:YES animated:animated scrollPosition:scrollPosition];
}

- (void)_scrollRectToVisible:(CGRect)aRect atScrollPosition:(UITableViewScrollPosition)scrollPosition animated:(BOOL)animated
{
    if (!CGRectIsNull(aRect) && aRect.size.height > 0) {
        // adjust the rect based on the desired scroll position setting
        switch (scrollPosition) {
            case UITableViewScrollPositionTop: {
                aRect.size.height = self.bounds.size.height;
                break;
            }
                
            case UITableViewScrollPositionMiddle: {
                aRect.origin.y -= (self.bounds.size.height / 2.f) - aRect.size.height;
                aRect.size.height = self.bounds.size.height;
                break;
            }
                
            case UITableViewScrollPositionBottom: {
                aRect.origin.y -= self.bounds.size.height - aRect.size.height;
                aRect.size.height = self.bounds.size.height;
                break;
            }
                
            case UITableViewScrollPositionNone: {
                break;
            }
        }
        
        [self scrollRectToVisible:aRect animated:animated];
    }
}

- (void)scrollToNearestSelectedRowAtScrollPosition:(UITableViewScrollPosition)scrollPosition animated:(BOOL)animated
{
    [self _scrollRectToVisible:[self rectForRowAtIndexPath:[self indexPathForSelectedRow]] atScrollPosition:scrollPosition animated:animated];
}

- (void)scrollToRowAtIndexPath:(NSIndexPath *)indexPath atScrollPosition:(UITableViewScrollPosition)scrollPosition animated:(BOOL)animated
{
    CGRect rect;
    if (indexPath.row == 0 && indexPath.section == 0) {
        rect = CGRectMake(0.0f, 0.0f, self.bounds.size.width, self.bounds.size.height);
    } else if (indexPath.row >0){
        rect = [self rectForRowAtIndexPath:indexPath];
    } else {
        //scroll to the top of the section and include the header
        rect = [self rectForSection:indexPath.section];
    }
    
    [self _scrollRectToVisible:rect atScrollPosition:scrollPosition animated:animated];
}

- (UITableViewCell *)dequeueReusableCellWithIdentifier:(NSString *)identifier
{
    for (UITableViewCell *cell in _reusableCells) {
        if ([cell.reuseIdentifier isEqualToString:identifier]) {
            [cell retain];
            [_reusableCells removeObject:cell];
            [cell prepareForReuse];
            return [cell autorelease];
        }
    }
    
    return nil;
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animate
{
    _editing = editing;
}

- (void)setEditing:(BOOL)editing
{
    [self setEditing:editing animated:NO];
}

- (void)insertSections:(NSIndexSet *)sections withRowAnimation:(UITableViewRowAnimation)animation
{
    [self reloadData];
}

- (void)deleteSections:(NSIndexSet *)sections withRowAnimation:(UITableViewRowAnimation)animation
{
    [self reloadData];
}

- (void)reloadSections:(NSIndexSet *)sections withRowAnimation:(UITableViewRowAnimation)animation {
    [self reloadData];
}

- (void)insertRowsAtIndexPaths:(NSArray *)indexPaths withRowAnimation:(UITableViewRowAnimation)animation
{
    [self reloadData];
}

- (void)deleteRowsAtIndexPaths:(NSArray *)indexPaths withRowAnimation:(UITableViewRowAnimation)animation
{
    [self reloadData];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self becomeFirstResponder];
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInView:self];
    NSIndexPath *touchedRow = [self indexPathForRowAtPoint:location];
    
    if (touchedRow) {
        BOOL commandKeyDown = ([NSEvent modifierFlags] & NSCommandKeyMask) == NSCommandKeyMask;
        BOOL exclusively = !commandKeyDown;
        if (([NSEvent modifierFlags] & NSShiftKeyMask) == NSShiftKeyMask && [_selectedRows count]) {
            NSIndexPath *firstIndexPath = [self indexPathForSelectedRow];
            NSComparisonResult result = [firstIndexPath compare:touchedRow];
            if (result != NSOrderedSame && firstIndexPath.section == touchedRow.section) {
                [self deselectAllRowsAnimated:NO];
                BOOL descending = result == NSOrderedDescending;
                NSIndexPath *startIndexPath = descending ? touchedRow : firstIndexPath;
                NSIndexPath *endIndexPath = descending ? firstIndexPath : touchedRow;
                for (NSUInteger i = startIndexPath.row; i <= endIndexPath.row; i++) {
                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:startIndexPath.section];
                    [self _selectRowAtIndexPath:indexPath exclusively:NO sendDelegateMessages:NO animated:NO scrollPosition:UITableViewScrollPositionNone];
                }
                exclusively = NO;
            }
        }
        if (commandKeyDown && [_selectedRows containsObject:touchedRow]) {
            [self deselectRowAtIndexPath:touchedRow animated:NO];
        } else {
            NSIndexPath *rowToSelect = [self _selectRowAtIndexPath:touchedRow exclusively:exclusively sendDelegateMessages:YES animated:NO scrollPosition:UITableViewScrollPositionNone];
            
            if([touch tapCount] == 2 && _delegateHas.didDoubleClickRowAtIndexPath) {
                [self.delegate tableView:self didDoubleClickRowAtIndexPath:rowToSelect];
            }
        }
    }
}


- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [self resignFirstResponder];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInView:self];
    NSIndexPath *touchedRow = [self indexPathForRowAtPoint:location];
    
    if ([_selectedRows containsObject:touchedRow]) {
        [self deselectRowAtIndexPath:touchedRow animated:NO];
    }
    [self resignFirstResponder];
}

- (NSIndexPath *)_selectRowAtIndexPath:(NSIndexPath *)indexPath exclusively:(BOOL)exclusively sendDelegateMessages:(BOOL)sendDelegateMessages animated:(BOOL)animated scrollPosition:(UITableViewScrollPosition)scrollPosition {
    if (!self.allowsMultipleSelection) {
        exclusively = YES;
    }
    if (exclusively) {
        for (NSIndexPath *rowToDeselect in [NSArray arrayWithArray:_selectedRows]) {
            if (sendDelegateMessages && _delegateHas.willDeselectRowAtIndexPath) {
                rowToDeselect = [self.delegate tableView:self willDeselectRowAtIndexPath:rowToDeselect];
            }
            
            [self deselectRowAtIndexPath:rowToDeselect animated:animated];
            
            if (sendDelegateMessages && _delegateHas.didDeselectRowAtIndexPath) {
                [self.delegate tableView:self didDeselectRowAtIndexPath:rowToDeselect];
            }
        }
    }
    
    NSIndexPath *rowToSelect = indexPath;
    
    [self _ensureCellExistsAtIndexPath:indexPath];
    
	if (sendDelegateMessages && _delegateHas.willSelectRowAtIndexPath) {
        rowToSelect = [self.delegate tableView:self willSelectRowAtIndexPath:rowToSelect];
    }
    
    [self selectRowAtIndexPath:rowToSelect exclusively:NO animated:animated scrollPosition:scrollPosition];
    
    if (sendDelegateMessages && _delegateHas.didSelectRowAtIndexPath) {
        [self.delegate tableView:self didSelectRowAtIndexPath:rowToSelect];
    }
    return rowToSelect;
}

- (void) _accessoryButtonTappedForTableViewCell:(UITableViewCell*)cell
{
    if (_delegateHas.accessoryButtonTappedForRowWithIndexPath) {
        [self.delegate tableView:self accessoryButtonTappedForRowWithIndexPath:[self indexPathForCell:cell]];
    }
}

- (BOOL)_canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // it's YES by default until the dataSource overrules
    return _dataSourceHas.commitEditingStyle && (!_dataSourceHas.canEditRowAtIndexPath || [_dataSource tableView:self canEditRowAtIndexPath:indexPath]);
}

- (void)_beginEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self _canEditRowAtIndexPath:indexPath]) {
        self.editing = YES;
        
        if (_delegateHas.willBeginEditingRowAtIndexPath) {
            [self.delegate tableView:self willBeginEditingRowAtIndexPath:indexPath];
        }
        
        // deferring this because it presents a modal menu and that's what we do everywhere else in Chameleon
        [self performSelector:@selector(_showEditMenuForRowAtIndexPath:) withObject:indexPath afterDelay:0];
    }
}

- (void)_endEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.editing) {
        self.editing = NO;
        
        if (_delegateHas.didEndEditingRowAtIndexPath) {
            [self.delegate tableView:self didEndEditingRowAtIndexPath:indexPath];
        }
    }
}

- (void)_showEditMenuForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // re-checking for safety since _showEditMenuForRowAtIndexPath is deferred. this may be overly paranoid.
    if ([self _canEditRowAtIndexPath:indexPath]) {
        UITableViewCell *cell = [self cellForRowAtIndexPath:indexPath];
        NSString *menuItemTitle = nil;
        
        // fetch the title for the delete menu item
        if (_delegateHas.titleForDeleteConfirmationButtonForRowAtIndexPath) {
            menuItemTitle = [self.delegate tableView:self titleForDeleteConfirmationButtonForRowAtIndexPath:indexPath];
        }
        if ([menuItemTitle length] == 0) {
            menuItemTitle = @"Delete";
        }
        
        cell.highlighted = YES;
        
        NSMenuItem *theItem = [[NSMenuItem alloc] initWithTitle:LocalizationNotNeeded(menuItemTitle) action:NULL keyEquivalent:@""];
        
        NSMenu *menu = [[NSMenu alloc] initWithTitle:@""];
        [menu setAutoenablesItems:NO];
        [menu setAllowsContextMenuPlugIns:NO];
        [menu addItem:theItem];
        
        // calculate the mouse's current position so we can present the menu from there since that's normal OSX behavior
        NSPoint mouseLocation = [NSEvent mouseLocation];
        CGPoint screenPoint = [self.window.screen convertPoint:NSPointToCGPoint(mouseLocation) fromScreen:nil];
        
        // modally present a menu with the single delete option on it, if it was selected, then do the delete, otherwise do nothing
        // FIXME-GNUstep
        const BOOL didSelectItem = NO;
        [menu popUpMenuPositioningItem:nil atLocation:NSPointFromCGPoint(screenPoint) inView:[self.window.screen UIKitView]];
        
        [menu release];
        [theItem release];
        
        [[UIApplication sharedApplication] _cancelTouches];
        
        if (didSelectItem) {
            [_dataSource tableView:self commitEditingStyle:UITableViewCellEditingStyleDelete forRowAtIndexPath:indexPath];
        }
        
        cell.highlighted = NO;
    }
    
    // all done
    [self _endEditingRowAtIndexPath:indexPath];
}

- (BOOL)canBecomeFirstResponder {
	return self.window != nil;
}

- (void)rightClick:(UITouch *)touch withEvent:(UIEvent *)event
{
    CGPoint location = [touch locationInView:self];
    NSIndexPath *touchedRow = [self indexPathForRowAtPoint:location];
    
    // this is meant to emulate UIKit's swipe-to-delete feature on Mac by way of a right-click menu
    if (touchedRow && [self _canEditRowAtIndexPath:touchedRow]) {
        [self _beginEditingRowAtIndexPath:touchedRow];
    }
}

- (void) moveUp:(id)sender
{
    NSIndexPath* indexPath = [self indexPathForSelectedRow];
    NSIndexPath* newIndexPath = nil;
    if (indexPath.row > 0) {
        newIndexPath = [NSIndexPath indexPathForRow:indexPath.row - 1 inSection:indexPath.section];
    } else if (indexPath.section > 0) {
        newIndexPath = [NSIndexPath indexPathForRow:[self numberOfRowsInSection:indexPath.section - 1] - 1 inSection:indexPath.section - 1];
    }
    if (newIndexPath) {
        [self _selectRowAtIndexPath:newIndexPath exclusively:YES sendDelegateMessages:YES animated:YES scrollPosition:UITableViewScrollPositionNone];
    }
    [self flashScrollIndicators];
}

- (void) moveDown:(id)sender
{
    NSIndexPath* indexPath = [self indexPathForSelectedRow];
    NSIndexPath* newIndexPath = nil;
    if(indexPath == nil && [self numberOfSections]) {
        newIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    } else if (indexPath && indexPath.section <= self.numberOfSections) {
        if (indexPath.row < [self numberOfRowsInSection:indexPath.section] - 1) {
            newIndexPath = [NSIndexPath indexPathForRow:indexPath.row + 1 inSection:indexPath.section];
        } else if (indexPath.section < [self numberOfSections] - 1) {
            newIndexPath = [NSIndexPath indexPathForRow:0 inSection:indexPath.section + 1];
        }
    }
    if (newIndexPath) {
        [self _selectRowAtIndexPath:newIndexPath exclusively:YES sendDelegateMessages:YES animated:YES scrollPosition:UITableViewScrollPositionNone];
    }
    [self flashScrollIndicators];
}

- (void) pageUp:(id)sender
{
    [self scrollRectToVisible:CGRectMake(0.0f, MAX(self.contentOffset.y - self.bounds.size.height, 0), self.bounds.size.width, self.bounds.size.height) animated:YES];
}

- (void) pageDown:(id)sender
{
    [self scrollRectToVisible:CGRectMake(0.0f, MIN(self.contentOffset.y + self.bounds.size.height, self.contentSize.height), self.bounds.size.width, self.bounds.size.height) animated:YES];
}

-(void)encodeWithCoder:(NSCoder *)aCoder {
    //TODO:later
}

@end
