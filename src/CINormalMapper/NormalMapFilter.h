//
//  NormalMapFilter.h
//  CINormapMappr
//
//  Created by Shamyl Zakariya on 2/25/09.
//  Copyright 2009 Shamyl Zakariya. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

#define NORMAL_MAP_3X3 1
#define NORMAL_MAP_5X5 2

@interface NormalMapFilter : CIFilter {
	NSMutableDictionary	*kernelsByName;
	CIKernel			*currentKernel;
	CIImage				*inputImage;
	CGFloat				strength;
	NSUInteger			sampleRadius;
	BOOL				clampToEdge;
}

@property (readwrite) CGFloat strength;
@property (readwrite) NSUInteger sampleRadius;
@property (readwrite) BOOL clampToEdge;

- (CIImage *)outputImage;

@end
