//
//  BatchItemView.m
//  FilteredImageList
//
//  Created by Shamyl Zakariya on 3/22/09.
//  Copyright 2009-2019 Shamyl Zakariya. All rights reserved.
//

#import "BatchCollectionViewItem.h"

#pragma mark - BatchCollectionViewItem

@implementation BatchCollectionViewItem

@synthesize batchEntry = batchEntry;

- (void)setBatchEntry:(BatchEntry*)batchEntry
{
    self->batchEntry = batchEntry;
    [label setStringValue:[[batchEntry.filePath lastPathComponent] stringByDeletingPathExtension]];
    [thumb setImage:batchEntry.thumb];
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    batchItemView.selected = selected;
    [batchItemView setNeedsDisplay:YES];

    BOOL lightMode = YES;
    if (@available(macOS 10.14, *)) {
        if ([[self.view effectiveAppearance].name isEqualToString:NSAppearanceNameDarkAqua]) {
            lightMode = NO;
        }
    }

    if (lightMode) {
        label.textColor = selected ? [NSColor whiteColor] : [NSColor controlTextColor];
    } else {
        label.textColor = [NSColor whiteColor];
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
