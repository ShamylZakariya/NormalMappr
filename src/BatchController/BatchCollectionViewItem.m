//
//  BatchItemView.m
//  FilteredImageList
//
//  Created by Shamyl Zakariya on 3/22/09.
//  Copyright 2009-2019 Shamyl Zakariya. All rights reserved.
//

#import "BatchCollectionViewItem.h"

#pragma mark - BatchCollectionViewItem

@interface BatchCollectionViewItem (Private)
- (void)onAddRemoveButtonTapped:(id)sender;
@end

@implementation BatchCollectionViewItem

@synthesize batchEntry = batchEntry;
@synthesize isIncludedInBumpmapsBatch = isIncludedInBumpmapsBatch;

- (void)awakeFromNib
{
    self.addRemoveButton.hidden = YES;
    self.addRemoveButton.target = self;
    self.addRemoveButton.action = @selector(onAddRemoveButtonTapped:);
}

- (void)setBatchEntry:(BatchEntry*)batchEntry
{
    self->batchEntry = batchEntry;
    [self.nameTextField setStringValue:[[batchEntry.filePath lastPathComponent] stringByDeletingPathExtension]];
    [self.thumbView setImage:batchEntry.thumb];

    self.batchItemView.onMouseHoverStateChange = ^(BOOL mouseInside) {
        [self.addRemoveButton animator].hidden = !mouseInside;
    };
}

- (void)setIsIncludedInBumpmapsBatch:(BOOL)isIncludedInBumpmapsBatch
{
    self->isIncludedInBumpmapsBatch = isIncludedInBumpmapsBatch;

    self.addRemoveButton.title = isIncludedInBumpmapsBatch
        ? NSLocalizedString(@"Exclude", @"Title of button to remove item from batch")
        : NSLocalizedString(@"Include", @"Title of button to add items to batch");

    CGFloat alpha = isIncludedInBumpmapsBatch ? 1 : 0.5;
    
    BOOL visibleOnScreen = NSIntersectsRect(self.view.frame, self.collectionView.visibleRect);
    if (visibleOnScreen) {
        self.thumbView.animator.alphaValue = alpha * alpha;
        self.nameTextField.animator.alphaValue = alpha;
    } else {
        self.thumbView.alphaValue = alpha * alpha;
        self.nameTextField.alphaValue = alpha;
    }
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    self.batchItemView.selected = selected;
    [self.batchItemView setNeedsDisplay:YES];

    BOOL lightMode = YES;
    if (@available(macOS 10.14, *)) {
        if ([[self.view effectiveAppearance].name isEqualToString:NSAppearanceNameDarkAqua]) {
            lightMode = NO;
        }
    }

    if (lightMode) {
        self.nameTextField.textColor = selected ? [NSColor whiteColor] : [NSColor controlTextColor];
    } else {
        self.nameTextField.textColor = [NSColor whiteColor];
    }
}

- (void)onAddRemoveButtonTapped:(id)sender
{
    self.onAddRemoveButtonTapped();
}

@end

#pragma mark - BatchItemView

@implementation BatchItemView

@synthesize selected;

- (void)awakeFromNib
{
    NSTrackingArea* ta = [[NSTrackingArea alloc] initWithRect:self.bounds options:NSTrackingInVisibleRect | NSTrackingActiveInKeyWindow | NSTrackingMouseEnteredAndExited owner:self userInfo:nil];
    [self addTrackingArea:ta];
}

- (void)drawRect:(NSRect)rect
{
    if (selected) {
        if (@available(macOS 10.14, *)) {
            [[NSColor selectedContentBackgroundColor] set];
        } else {
            [[NSColor alternateSelectedControlColor] set];
        }

        [[NSBezierPath bezierPathWithRoundedRect:NSInsetRect(self.bounds, 5, 5) xRadius:6 yRadius:6] fill];
    }
}

- (void)mouseEntered:(NSEvent*)event
{
    self.onMouseHoverStateChange(YES);
}

- (void)mouseExited:(NSEvent*)event
{
    self.onMouseHoverStateChange(NO);
}

@end
