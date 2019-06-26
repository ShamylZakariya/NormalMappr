//
//  BatchSettings.h
//  NormalMappr
//
//  Created by Shamyl Zakariya on 4/13/09.
//  Copyright 2009-2019 Shamyl Zakariya. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum _NMNameDecoration {
    NMNameDecorationPrepend = 0,
    NMNameDecorationAppend = 1
} NMNameDecoration;

@interface BatchSettings : NSObject {

    CGFloat saveQuality;
    int sampleRadius, saveFormat, strength;
    NMNameDecoration nameDecorationStyle;
}

- (void)loadPrefs;
- (void)savePrefs;

@property (nonatomic, readwrite) CGFloat saveQuality;
@property (nonatomic, readwrite) int strength; // [0,100]
@property (nonatomic, readwrite) BOOL resizeWidth;
@property (nonatomic, readwrite) BOOL resizeHeight;
@property (nonatomic, readwrite) int outputWidth;
@property (nonatomic, readwrite) int outputHeight;
@property (nonatomic, readwrite) int sampleRadius;
@property (nonatomic, readwrite) int saveFormat;
@property (readonly) NSString* saveFormatExtension;
@property (nonatomic, readwrite) NSString* nameDecoration;
@property (nonatomic, readwrite) NMNameDecoration nameDecorationStyle;
@property (nonatomic, readwrite) BOOL showSaveQualityControls;

@end
