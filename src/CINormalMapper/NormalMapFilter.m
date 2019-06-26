//
//  NormalMapFilter.m
//  CINormapMappr
//
//  Created by Shamyl Zakariya on 2/25/09.
//  Copyright 2009-2019 Shamyl Zakariya. All rights reserved.
//

#import "NormalMapFilter.h"

@interface NormalMapFilterFactory : NSObject <CIFilterConstructor>
@end

@implementation NormalMapFilterFactory

- (nullable CIFilter*)filterWithName:(nonnull NSString*)name
{
    if ([name isEqualToString:@"NormalMapFilter"]) {
        return [[NormalMapFilter alloc] init];
    }
    return nil;
}

@end

@interface NormalMapFilter (Private)

- (void)selectKernel;

@end

@implementation NormalMapFilter

+ (void)initialize
{
    [CIFilter registerFilterName:@"NormalMapFilter"
                     constructor:[[NormalMapFilterFactory alloc] init]
                 classAttributes:
                     [NSDictionary dictionaryWithObjectsAndKeys:
                                       @"Normal Map", kCIAttributeFilterDisplayName,
                                   [NSArray arrayWithObjects:kCICategoryColorAdjustment, kCICategoryVideo, kCICategoryStillImage, nil], kCIAttributeFilterCategories,
                                   nil]];
}

- (id)init
{
    if (self = [super init]) {
        NSBundle* bundle = [NSBundle bundleForClass:[self class]];
        NSString* code = [NSString stringWithContentsOfFile:[bundle pathForResource:@"NormalMap" ofType:@"cikernel"]
                                                   encoding:NSUTF8StringEncoding
                                                      error:nil];

        kernelsByName = [[NSMutableDictionary alloc] init];
        for (CIKernel* kernel in [CIKernel kernelsWithString:code]) {
            [kernelsByName setObject:kernel forKey:kernel.name];
        }

        self.strength = 0.5f;
        self.sampleRadius = 1.0f;
        self.clampToEdge = NO;
    }

    return self;
}

- (CIImage*)outputImage
{
    if (!currentKernel)
        [self selectKernel];

    CISampler* src = [CISampler
        samplerWithImage:inputImage
                 options:
                     [NSDictionary dictionaryWithObjectsAndKeys:
                                       kCISamplerFilterNearest, kCISamplerFilterMode,
                                   (self.clampToEdge ? kCISamplerWrapClamp : kCISamplerWrapBlack), kCISamplerWrapMode,
                                   nil]];

    return [self apply:currentKernel
             arguments:[NSArray arrayWithObjects:src, [NSNumber numberWithFloat:strength], nil]
               options:[NSDictionary dictionaryWithObjectsAndKeys:
                                         [src definition], kCIApplyOptionDefinition,
                                     nil]];
}

- (NSDictionary*)customAttributes
{
    return [NSDictionary dictionaryWithObjectsAndKeys:

                             [NSDictionary dictionaryWithObjectsAndKeys:
                                               [NSNumber numberWithDouble:0.0], kCIAttributeMin,
                                           [NSNumber numberWithDouble:1.0], kCIAttributeMax,
                                           [NSNumber numberWithDouble:0.0], kCIAttributeSliderMin,
                                           [NSNumber numberWithDouble:1.0], kCIAttributeSliderMax,
                                           [NSNumber numberWithDouble:0.5], kCIAttributeDefault,
                                           [NSNumber numberWithDouble:1.0], kCIAttributeIdentity,
                                           kCIAttributeTypeScalar, kCIAttributeType,
                                           nil],
                         @"strength",

                         [NSDictionary dictionaryWithObjectsAndKeys:
                                           [NSNumber numberWithDouble:1.0], kCIAttributeMin,
                                       [NSNumber numberWithDouble:2.0], kCIAttributeMax,
                                       [NSNumber numberWithDouble:1.0], kCIAttributeSliderMin,
                                       [NSNumber numberWithDouble:2.0], kCIAttributeSliderMax,
                                       [NSNumber numberWithDouble:1.0], kCIAttributeDefault,
                                       [NSNumber numberWithDouble:1.0], kCIAttributeIdentity,
                                       kCIAttributeTypeScalar, kCIAttributeType,
                                       nil],
                         @"sampleRadius",

                         nil];
}

#pragma mark -

@synthesize strength, sampleRadius, clampToEdge;

- (void)setStrength:(CGFloat)s
{
    strength = MIN(MAX(s, 0.0f), 1.0f);
}

- (void)setSampleRadius:(NSUInteger)r
{
    switch (r) {
    case NORMAL_MAP_5X5: {
        sampleRadius = NORMAL_MAP_5X5;
        break;
    }

    default:
    case NORMAL_MAP_3X3: {
        sampleRadius = NORMAL_MAP_3X3;
        break;
    }
    }

    currentKernel = nil;
}

- (void)setClampToEdge:(BOOL)cte
{
    clampToEdge = cte;
    currentKernel = nil;
}

#pragma mark -
#pragma mark Private

- (void)selectKernel
{
    NSString* kernelName = nil;
    switch (sampleRadius) {
    case NORMAL_MAP_5X5: {
        kernelName = @"normalMap5x5";
        break;
    }

    default:
    case NORMAL_MAP_3X3: {
        kernelName = @"normalMap3x3";
        break;
    }
    }

    if (self.clampToEdge) {
        kernelName = [kernelName stringByAppendingString:@"_clamp"];
    }

    currentKernel = [kernelsByName objectForKey:kernelName];
}

@end
