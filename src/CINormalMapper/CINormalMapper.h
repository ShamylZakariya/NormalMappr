//
//  CINormalMapper.h
//  CINormapMappr
//
//  Created by Shamyl Zakariya on 3/2/09.
//  Copyright 2009-2019 Shamyl Zakariya. All rights reserved.
//

#import "NormalMapFilter.h"
#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

@interface CINormalMapper : NSObject {
    NSBitmapImageRep *bumpmap, *normalmap;
    CIImage* inputImage;
    NormalMapFilter* filter;
    CGColorSpaceRef colorSpace;
    CGSize size;
    BOOL dirty;
}

- (id)init;
- (id)initWithBumpmap:(NSURL*)bumpmapURL strength:(float)strength sampleSize:(NMSampleSize)sampleSize andClampToEdge:(BOOL)cte;

@property (readwrite, retain) NSBitmapImageRep* bumpmap;
@property (readonly) NSBitmapImageRep* normalmap;
@property (readwrite) float strength;
@property (readwrite) NMSampleSize sampleSize;
@property (readwrite) BOOL clampToEdge;
@property (readwrite) CGSize size;
@property (readonly) BOOL dirty;

@end
