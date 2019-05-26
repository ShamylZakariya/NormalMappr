//
//  Controller.h
//  FilteredImageList
//
//  Created by Shamyl Zakariya on 3/12/09.
//  Copyright 2009 Shamyl Zakariya. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BatchSettings.h"
#import "BatchEntry.h"

@interface BatchController : NSObject <NSCollectionViewDataSource, NSCollectionViewDelegate, NSCollectionViewDelegateFlowLayout> {
    BatchSettings					*batchSettings;
    
    CGFloat							iconSize;
    NSMutableArray<BatchEntry*>		*bumpmaps;
    NSMutableArray<BatchEntry*>		*nonBumpmaps;
    
    NSUInteger						sheetProcessStepTotal, sheetProcessStep;
    BOOL							showWindow;
    BOOL							sheetProcessRunning;
    BOOL							sheetProcessIndeterminate;
    BOOL							showDropMessage;
    CGFloat							sheetProcessProgress;
    NSString						*sheetMessage;
    
    __weak IBOutlet NSWindow        *batchWindow;
    IBOutlet NSPanel			    *progressSheet;
    __weak IBOutlet NSCollectionView *bumpmapsCollectionView;
    __weak IBOutlet NSCollectionViewFlowLayout *bumpmapsCollectionViewFL;
}

@property (readwrite,retain) BatchSettings* batchSettings;
@property (readwrite) BOOL showWindow;

@property (readwrite) NSUInteger sheetProcessStepTotal;
@property (readwrite) NSUInteger sheetProcessStep;

@property (readwrite) BOOL sheetProcessRunning;
@property (readwrite) BOOL sheetProcessIndeterminate;
@property (readwrite) CGFloat sheetProcessProgress;
@property (readwrite,retain) NSString* sheetMessage;

@property (readwrite, nonatomic) BOOL showDropMessage;
@property (readwrite, nonatomic) CGFloat iconSize;

- (NSInteger) bumpmapCount;
- (NSInteger) nonBumpmapCount;

- (void) addFiles:(NSArray<NSURL*>*) fileURLs;
- (void) removeFiles: (NSArray<NSURL*>*) fileURLs;
- (void) savePreferences;

- (IBAction) executeBatch: (id) sender;

@end
