//
//  Controller.h
//  FilteredImageList
//
//  Created by Shamyl Zakariya on 3/12/09.
//  Copyright 2009-2019 Shamyl Zakariya. All rights reserved.
//

#import "BatchCollectionView.h"
#import "BatchCollectionViewRoot.h"
#import "BatchCollectionViewSectionHeader.h"
#import "BatchEntry.h"
#import "BatchSettings.h"
#import <Cocoa/Cocoa.h>

@interface BatchController : NSObject <NSCollectionViewDataSource, NSCollectionViewDelegate, NSCollectionViewDelegateFlowLayout> {
    BatchSettings* batchSettings;

    CGFloat iconSize;
    NSMutableArray<BatchEntry*>* batch;
    NSMutableArray<BatchEntry*>* excludedFromBatch;

    NSUInteger sheetProcessStepTotal, sheetProcessStep;
    BOOL sheetProcessRunning;
    BOOL sheetProcessIndeterminate;
    BOOL showDropMessage;
    CGFloat sheetProcessProgress;
    NSString* sheetMessage;
    NSInteger previousSaveLocationPopupTag;
    BatchCollectionViewSectionHeader* excludedFromBatchSectionHeader;
    NSSet<NSIndexPath*>* indexPathsOfDraggingItems;

    __weak IBOutlet NSWindow* batchWindow;
    IBOutlet NSPanel* progressSheet; // intentionally strong to keep it alive when not visible
    __weak IBOutlet BatchCollectionView* batchCollectionView;
    __weak IBOutlet NSCollectionViewFlowLayout* batchCollectionViewFlowLayout;
    __weak IBOutlet NSButton* runButton;
    __weak IBOutlet NSPopUpButton* saveLocationPopup;
    __weak IBOutlet NSTextField* dropMessage;
}

/**
 Returns true iff url is (a file on disk && supported image type) || a directory.
 */
+ (BOOL)canHandleURL:(NSURL*)url;

- (void)dismiss;

@property (readwrite, retain) BatchSettings* batchSettings;
@property (weak, readonly) NSWindow* batchWindow;

@property (readwrite) NSUInteger sheetProcessStepTotal;
@property (readwrite) NSUInteger sheetProcessStep;

@property (readwrite) BOOL sheetProcessRunning;
@property (readwrite) BOOL sheetProcessIndeterminate;
@property (readwrite) CGFloat sheetProcessProgress;
@property (readwrite, retain) NSString* sheetMessage;

@property (readwrite, nonatomic) BOOL showDropMessage;

- (void)addFiles:(NSArray<NSURL*>*)fileURLs;

- (IBAction)executeBatch:(id)sender;
- (IBAction)onSaveLocationPopupAction:(id)sender;

@end
