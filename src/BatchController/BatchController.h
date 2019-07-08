//
//  Controller.h
//  FilteredImageList
//
//  Created by Shamyl Zakariya on 3/12/09.
//  Copyright 2009-2019 Shamyl Zakariya. All rights reserved.
//

#import "BatchCollectionView.h"
#import "BatchCollectionViewRoot.h"
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

    __weak IBOutlet NSWindow* batchWindow;
    IBOutlet NSPanel* progressSheet; // intentionally strong to keep it alive when not visible
    __weak IBOutlet BatchCollectionView* batchCollectionView;
    __weak IBOutlet NSCollectionViewFlowLayout* batchCollectionViewFlowLayout;
    __weak IBOutlet NSButton* runButton;
    __weak IBOutlet NSPopUpButton* saveLocationPopup;
}

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
@property (readwrite, nonatomic) CGFloat iconSize;

- (void)addFiles:(NSArray<NSURL*>*)fileURLs;

- (IBAction)executeBatch:(id)sender;
- (IBAction)onSaveLocationPopupAction:(id)sender;

@end
