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
    if (isReceivingDropFromExternalSource) {
        // draw an inset highlight in the highlight color
        [[NSColor selectedControlColor] set];
        NSRect insetBounds = NSInsetRect(self.visibleRect, 4, 4);
        NSBezierPath* p = [NSBezierPath bezierPathWithRoundedRect:insetBounds xRadius:4 yRadius:4];
        p.lineWidth = 2;
        [p stroke];
    }
}

#pragma mark - Drop handling from external source

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender
{
    if (sender.draggingSource == nil) {
        isReceivingDropFromExternalSource = YES;
        [self setNeedsDisplay:YES];
        return NSDragOperationGeneric;
    }

    return [super draggingEntered:sender];
}

- (NSDragOperation)draggingUpdated:(id<NSDraggingInfo>)sender
{
    if (isReceivingDropFromExternalSource) {
        return NSDragOperationGeneric;
    }
    return [super draggingUpdated:sender];
}

- (void)draggingExited:(nullable id<NSDraggingInfo>)sender
{
    if (isReceivingDropFromExternalSource) {
        isReceivingDropFromExternalSource = NO;
        [self setNeedsDisplay:YES];
    } else {
        [super draggingExited:sender];
    }
}

- (void)draggingEnded:(id<NSDraggingInfo>)sender
{
    if (isReceivingDropFromExternalSource) {
        isReceivingDropFromExternalSource = NO;
        [self setNeedsDisplay:YES];
    } else {
        [super draggingEnded:sender];
    }
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)draggingInfo
{
    if (isReceivingDropFromExternalSource) {
        NSMutableArray<NSURL*>* droppedFileURLs = [NSMutableArray array];
        [draggingInfo enumerateDraggingItemsWithOptions:NSDraggingItemEnumerationConcurrent
                                                forView:self
                                                classes:@ [[NSURL class]]
                                                searchOptions:@{
                                                    NSPasteboardURLReadingFileURLsOnlyKey : @(1)
                                                }
                                             usingBlock:^(NSDraggingItem* _Nonnull draggingItem, NSInteger idx, BOOL* _Nonnull stop) {
                                                 NSURL* url = draggingItem.item;
                                                 if ([BatchController canHandleURL:url]) {
                                                     [droppedFileURLs addObject:url];
                                                 }
                                             }];

        if (droppedFileURLs.count > 0) {
            [self.batchController addFiles:droppedFileURLs];
            return YES;
        }
        return NO;
    }

    return [super performDragOperation:draggingInfo];
}

@end
