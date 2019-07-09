//
//  BatchCollectionViewSectionHeader.m
//  NormalMappr
//
//  Created by Shamyl Zakariya on 5/25/19.
//

#import "BatchCollectionViewSectionHeader.h"

@implementation BatchCollectionViewSectionHeader

- (void)drawRect:(NSRect)dirtyRect {
    if (@available(macOS 10.13, *)) {
        [[NSColor colorNamed:@"BatchCollectionViewSectionHeaderRule"] set];
    } else {
        // previous macos versions don't have dark mode, so we'll just hardcode a light gray
        [[NSColor colorWithWhite:0.9 alpha:1] set];
    }
    NSRectFill(NSMakeRect(0, self.bounds.size.height - 1, self.bounds.size.width, 1));
}

@end
