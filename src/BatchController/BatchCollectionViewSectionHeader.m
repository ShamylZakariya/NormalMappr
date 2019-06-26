//
//  BatchCollectionViewSectionHeader.m
//  NormalMappr
//
//  Created by Shamyl Zakariya on 5/25/19.
//

#import "BatchCollectionViewSectionHeader.h"

@implementation ItemCountBackgroundView

- (void)drawRect:(NSRect)dirtyRect
{
    if (@available(macOS 10.13, *)) {
        [[NSColor colorNamed:@"ItemCountBackgroundColor"] set];
    } else {
        [[NSColor redColor] set];
    }

    CGFloat radius = MIN(self.bounds.size.width, self.bounds.size.height) / 2;
    [[NSBezierPath bezierPathWithRoundedRect:self.bounds xRadius:radius yRadius:radius] fill];
}

@end

@implementation BatchCollectionViewSectionHeader

@synthesize sectionTitle;
@synthesize itemCount;

@end
