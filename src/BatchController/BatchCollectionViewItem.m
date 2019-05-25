//
//  BatchItemView.m
//  FilteredImageList
//
//  Created by Shamyl Zakariya on 3/22/09.
//  Copyright 2009 Shamyl Zakariya. All rights reserved.
//

#import "BatchCollectionViewItem.h"

#pragma mark - BatchCollectionViewItem

@implementation BatchCollectionViewItem

- (void) setSelected:(BOOL)selected
{
    [super setSelected:selected];
    
    BOOL lightMode = YES;
    if (@available(macOS 10.14, *))
    {
        if ([[self.view effectiveAppearance].name isEqualToString:NSAppearanceNameDarkAqua])
        {
            lightMode = NO;
        }
    }
    
    if (lightMode)
    {
        label.textColor = selected ? [NSColor whiteColor] : [NSColor controlTextColor];
    }
    else
    {
        label.textColor = [NSColor whiteColor];
    }
}

- (void) setThumbnailTitle:(NSString *)title
{
    [label setStringValue:title];
}

- (NSString*) thumbnailTitle
{
    return [label stringValue];
}

- (void) setThumbnailImage:(NSImage *)thumbnailImage
{
    [thumb setImage:thumbnailImage];
}

- (NSImage*) thumbnailImage
{
    return [thumb image];
}

@end

#pragma mark - BatchItemView

@interface BatchItemView(Private)

- (NSView*) hitTest: (NSPoint) point forView: (NSView*) view;

@end


@implementation BatchItemView

@synthesize selected;

- (void)drawRect:(NSRect)rect
{
    if ( selected )
    {
        if (@available(macOS 10.14, *))
        {
            [[NSColor selectedContentBackgroundColor] set];
        }
        else
        {
            [[NSColor alternateSelectedControlColor] set];
        }
        
        [[NSBezierPath bezierPathWithRoundedRect:NSInsetRect( self.bounds, 5,5 ) xRadius:6 yRadius:6] fill];
    }
}

- (BOOL)acceptsFirstResponder
{
    return NO;
}

- (NSView *)hitTest:(NSPoint)aPoint
{
    for ( NSView *sv in self.subviews )
    {
        NSView *tv = [self hitTest: aPoint forView: sv];
        if ( tv ) return tv;
    }
    
    return nil;
}

#pragma mark - Private

- (NSView*) hitTest: (NSPoint) point forView: (NSView*) view
{
    if(NSPointInRect(point,[view convertRect:[view bounds] toView:[view superview]]))
    {
        return view;
    }
    
    return nil;
}


@end
