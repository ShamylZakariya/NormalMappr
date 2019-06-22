//
//  BatchItemView.h
//  FilteredImageList
//
//  Created by Shamyl Zakariya on 3/22/09.
//  Copyright 2009 Shamyl Zakariya. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BatchEntry.h"
#import "ThumbView.h"

@class BatchItemView;

@interface BatchCollectionViewItem : NSCollectionViewItem {
    __weak IBOutlet ThumbView *thumb;
    __weak IBOutlet NSTextField *label;
    __weak IBOutlet BatchItemView *batchItemView;
    BatchEntry *batchEntry;
    NSClickGestureRecognizer *clickRecognizer;
}

@property (readwrite, nonatomic) BatchEntry *batchEntry;

@end

@interface BatchItemView : NSBox {
}

@property (readwrite, nonatomic) BOOL selected;

@end

