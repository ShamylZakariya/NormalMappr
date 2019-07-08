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

@interface AddRemoveButton : NSButton {
}

@property (nonatomic, copy) void (^onClick)();

@end

@interface BatchCollectionViewItem : NSCollectionViewItem {
    BatchEntry* batchEntry;
    NSClickGestureRecognizer* clickRecognizer;
    BOOL isIncludedInBumpmapsBatch;
}

@property (weak) IBOutlet ThumbView* thumbView;
@property (weak) IBOutlet NSTextField* nameTextField;
@property (weak) IBOutlet BatchItemView* batchItemView;
@property (weak) IBOutlet AddRemoveButton* addRemoveButton;

@property (readwrite, nonatomic) BatchEntry* batchEntry;
@property (readwrite, nonatomic) BOOL isIncludedInBumpmapsBatch;

@end

@interface BatchItemView : NSBox {
}

@property (readwrite, nonatomic) BOOL selected;
@property (nonatomic, copy) void (^onMouseHoverStateChange)(BOOL mouseInside);

@end
