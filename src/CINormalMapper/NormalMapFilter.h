//
//  NormalMapFilter.h
//  CINormapMappr
//
//  Created by Shamyl Zakariya on 2/25/09.
//  Copyright 2009-2019 Shamyl Zakariya. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

typedef NS_ENUM(NSInteger, NMSampleSize) {
    NMSampleSize3x3 = 0,
    NMSampleSize5x5 = 1
};


@interface NormalMapFilter : CIFilter {
    NSMutableDictionary* kernelsByName;
    CIKernel* currentKernel;
    CIImage* inputImage;
    CGFloat strength;
    NMSampleSize sampleSize;
    BOOL clampToEdge;
}

@property (nonatomic, readwrite) CGFloat strength;
@property (nonatomic, readwrite) NMSampleSize sampleSize;
@property (nonatomic, readwrite) BOOL clampToEdge;

- (CIImage*)outputImage;

@end
