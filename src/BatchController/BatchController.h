//
//  Controller.h
//  FilteredImageList
//
//  Created by Shamyl Zakariya on 3/12/09.
//  Copyright 2009 Shamyl Zakariya. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BatchView.h"
#import "StackView.h"
#import "BatchLabel.h"
#import "BatchSettings.h"

@interface BatchController : NSObject {
	BatchSettings					*batchSettings;

	CGFloat							iconSize;
	NSMutableArray					*bumpmaps;
	NSMutableArray					*nonBumpmaps;
	
	IBOutlet NSArrayController		*bumpmapsArrayController;
	IBOutlet NSArrayController		*nonBumpmapsArrayController;

	NSUInteger						sheetProcessStepTotal, sheetProcessStep;
	BOOL							allowUIAnimations;
	BOOL							showWindow;
	BOOL							sheetProcessRunning;
	BOOL							sheetProcessIndeterminate;
	BOOL							showDropMessage;
	BOOL							nonBumpmapPaneVisible;
	CGFloat							sheetProcessProgress;
	NSString						*sheetMessage;

	IBOutlet NSWindow               *batchWindow;
	IBOutlet BatchView				*bumpmapCollectionView;
	IBOutlet BatchView				*nonBumpmapCollectionView;
	IBOutlet StackView				*collectionStack;
	IBOutlet BatchLabel				*bumpmapCollectionViewLabel;
	IBOutlet BatchLabel				*nonBumpmapCollectionViewLabel;
	IBOutlet NSPanel				*progressSheet;
}

@property (readwrite,retain) BatchSettings* batchSettings;
@property (readwrite) BOOL showWindow;
@property (readwrite) CGFloat iconSize;
@property (readwrite,retain) NSMutableArray* bumpmaps;
@property (readwrite,retain) NSMutableArray* nonBumpmaps;
@property (readonly) NSArrayController *bumpmapsArrayController;
@property (readonly) NSArrayController *nonBumpmapsArrayController;

@property (readwrite) NSUInteger sheetProcessStepTotal;
@property (readwrite) NSUInteger sheetProcessStep;

@property (readwrite) BOOL sheetProcessRunning;
@property (readwrite) BOOL sheetProcessIndeterminate;
@property (readwrite) CGFloat sheetProcessProgress;
@property (readwrite,retain) NSString* sheetMessage;

@property (readwrite) BOOL showDropMessage;
@property (readwrite) BOOL nonBumpmapPaneVisible;

- (NSInteger) bumpmapCount;
- (NSInteger) nonBumpmapCount;

- (void) addFiles:(NSArray *)inFiles;
- (void) makeBumpmap: (NSArray*) paths;
- (void) makeNonBumpmap: (NSArray*) paths;
- (void) remove: (NSArray*) paths;
- (void) savePreferences;

- (IBAction) executeBatch: (id) sender;

@end
