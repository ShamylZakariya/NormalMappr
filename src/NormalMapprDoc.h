//
//  NormalMapprDoc.h
//  NormalMappr
//
//  Created by Shamyl Zakariya on 6/26/07.
//  Copyright Shamyl Zakariya 2007 . All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "VDKQueue.h"

#import "CINormalMapper.h"
#import "ImageView.h"
#import "TilingImageView.h"

#define kJPEG2000Format @"JPEG-2000"
#define kJPEGFormat @"JPEG"
#define kPNGFormat @"PNG"
#define kTIFFFormat @"TIFF"

@interface NormalMapprDoc : NSDocument <NSWindowDelegate, VDKQueueDelegate> {
    VDKQueue* _fileWatcher;
    CGSize _outputSize;
    CINormalMapper* _normalmapper;
    NSArray* _saveFormats;
    NSString* _saveFormat;
    NSSavePanel* _currentSavePanel;
    NSDate* _fileTimestamp;
    float _saveQuality;
    BOOL _syncAspectRatio;

    // strong references, because only one is visible at a time
    IBOutlet ImageView* imageView;
    IBOutlet TilingImageView* tilingImageView;

    __weak IBOutlet NSWindow* docWindow;
    __weak IBOutlet NSView* imageViewContainer;
    __weak IBOutlet NSScrollView* imageViewScroller;
    __weak IBOutlet NSSlider* strengthSlider;
    __weak IBOutlet NSSlider* sampleRadiusSlider;
    __weak IBOutlet NSView* savePanelDialog;
    __weak IBOutlet NSBox* savePanelQualityControls;
    __weak IBOutlet NSView* controlPanelView;
    __weak IBOutlet NSButton* linkWidthHeightToggleButton;
}

@property (readwrite) int strength;
@property (readwrite) int sampleSize;
@property (readwrite) BOOL clampToEdge;
@property (readwrite) int outputWidth;
@property (readwrite) int outputHeight;
@property (readwrite) BOOL syncAspectRatio;
@property (readonly, retain) NSArray* saveFormats;
@property (readwrite, retain) NSString* saveFormat;
@property (readwrite) float saveQuality;
@property (readwrite) int tileMode;

#pragma mark -

/**
	Reload the current image being displayed
*/
- (void)reload;

#pragma mark -

- (IBAction)export:(id)sender;
- (IBAction)showSingleImage:(id)sender;
- (IBAction)showTiledImage:(id)sender;

#pragma mark -

- (NSRect)windowWillUseStandardFrame:(NSWindow*)window defaultFrame:(NSRect)newFrame;

@end
