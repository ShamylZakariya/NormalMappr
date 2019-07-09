//
//  BatchCollectionView.m
//  NormalMappr
//
//  Created by Shamyl Zakariya on 7/4/19.
//

#import "BatchCollectionView.h"
#import "BatchController.h"

@implementation BatchCollectionView

- (void)drawRect:(NSRect)dirtyRect
{
    if (isDropTarget) {

        // draw an inset highlight in the highlight color
        [[NSColor selectedControlColor] set];
        NSRect insetBounds = NSInsetRect([self bounds], 4, 4);
        NSBezierPath* p = [NSBezierPath bezierPathWithRoundedRect:insetBounds xRadius:4 yRadius:4];
        p.lineWidth = 2;
        [p stroke];
    }
}

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender
{
    isDropTarget = YES;
    [self setNeedsDisplay:YES];
    return NSDragOperationGeneric;
}

- (NSDragOperation)draggingUpdated:(id<NSDraggingInfo>)sender
{
    return NSDragOperationGeneric;
}

- (void)draggingExited:(nullable id<NSDraggingInfo>)sender
{
    isDropTarget = NO;
    [self setNeedsDisplay:YES];
}

- (void)draggingEnded:(id<NSDraggingInfo>)sender
{
    isDropTarget = NO;
    [self setNeedsDisplay:YES];
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)draggingInfo
{
    NSMutableArray<NSURL*>* droppedFileURLs = [NSMutableArray array];
    [draggingInfo enumerateDraggingItemsWithOptions:NSDraggingItemEnumerationConcurrent
                                            forView:self
                                            classes:@ [[NSURL class]]
                                            searchOptions:@{
                                                NSPasteboardURLReadingFileURLsOnlyKey : @(1)
                                            }
                                         usingBlock:^(NSDraggingItem* _Nonnull draggingItem, NSInteger idx, BOOL* _Nonnull stop) {
                                             NSURL* url = draggingItem.item;
                                             [droppedFileURLs addObject:url];
                                         }];

    [self.batchController addFiles:droppedFileURLs];
    return droppedFileURLs.count > 0;
}

@end
