//
//  BatchItemView.h
//  FilteredImageList
//
//  Created by Shamyl Zakariya on 3/22/09.
//  Copyright 2009-2019 Shamyl Zakariya. All rights reserved.
//

#import "BatchEntry.h"
#import "ThumbView.h"
#import <Cocoa/Cocoa.h>

@class BatchItemView;

@interface BatchCollectionViewItem : NSCollectionViewItem {
    __weak IBOutlet ThumbView* thumb;
    __weak IBOutlet NSTextField* label;
    __weak IBOutlet BatchItemView* batchItemView;
    BatchEntry* batchEntry;
    NSClickGestureRecognizer* clickRecognizer;
    BOOL isIncludedInBumpmapsBatch;
}

@property (readwrite, nonatomic) BatchEntry* batchEntry;
@property (readwrite, nonatomic) BOOL isIncludedInBumpmapsBatch;

@end

@interface BatchItemView : NSBox {
}

@property (readwrite, nonatomic) BOOL selected;

@end
