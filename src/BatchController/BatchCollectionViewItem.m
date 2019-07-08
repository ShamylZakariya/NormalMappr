//
//  BatchItemView.m
//  FilteredImageList
//
//  Created by Shamyl Zakariya on 3/22/09.
//  Copyright 2009-2019 Shamyl Zakariya. All rights reserved.
//

#import "BatchCollectionViewItem.h"

#pragma mark - AddRemoveButton

@interface AddRemoveButton (Private)
- (void)_onClick:(id)sender;
@end

@implementation AddRemoveButton

- (BOOL)sendAction:(SEL)action to:(id)target
{
    if (self.onClick != nil) {
        self.onClick();
    }
    return [super sendAction:action to:target];
}

@end

#pragma mark - BatchCollectionViewItem

@implementation BatchCollectionViewItem

@synthesize batchEntry = batchEntry;
@synthesize isIncludedInBumpmapsBatch = isIncludedInBumpmapsBatch;

- (void)setBatchEntry:(BatchEntry*)batchEntry
{
    self->batchEntry = batchEntry;
    [self.nameTextField setStringValue:[[batchEntry.filePath lastPathComponent] stringByDeletingPathExtension]];
    [self.thumbView setImage:batchEntry.thumb];
}

- (void)setIsIncludedInBumpmapsBatch:(BOOL)isIncludedInBumpmapsBatch
{
    self->isIncludedInBumpmapsBatch = isIncludedInBumpmapsBatch;

    CGFloat alpha = isIncludedInBumpmapsBatch ? 1 : 0.5;
    [self.thumbView animator].alphaValue = alpha * alpha;
    [self.nameTextField animator].alphaValue = alpha;
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

@end

#pragma mark - BatchItemView

@implementation BatchItemView

@synthesize selected;

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

@end
