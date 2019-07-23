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
    BatchEntry* batchEntry;
    BOOL isIncludedInBumpmapsBatch;
}

@property (weak) IBOutlet ThumbView* thumbView;
@property (weak) IBOutlet NSTextField* nameTextField;
@property (weak) IBOutlet BatchItemView* batchItemView;
@property (weak) IBOutlet NSButton* addRemoveButton;

@property (readwrite, nonatomic) BatchEntry* batchEntry;
@property (readwrite, nonatomic) BOOL isIncludedInBumpmapsBatch;

@property (nonatomic, copy) void (^onAddRemoveButtonTapped)(void);

@end

/**
 BatchItemView draws selection state
*/
@interface BatchItemView : NSBox {
}

@property (readwrite, nonatomic) BOOL selected;
@property (nonatomic, copy) void (^onMouseHoverStateChange)(BOOL mouseInside);

@end
