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

@interface BatchItemView : NSBox {
}

@property (readwrite, nonatomic) BOOL selected;

@end

@interface BatchCollectionViewItem : NSCollectionViewItem {
    __weak IBOutlet ThumbView *thumb;
    __weak IBOutlet NSTextField *label;
    __weak IBOutlet BatchItemView *batchItemView;
}

@property (readwrite, nonatomic) NSString* thumbnailTitle;
@property (readwrite, nonatomic) NSImage* thumbnailImage;

@end
