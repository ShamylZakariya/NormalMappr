//
//  BatchSettings.m
//  NormalMappr
//
//  Created by Shamyl Zakariya on 4/13/09.
//  Copyright 2009 Shamyl Zakariya. All rights reserved.
//

#import "BatchSettings.h"


@implementation BatchSettings

- (id) init
{
	if ( self = [super init] )
	{
        self.resizeWidth = NO;
        self.resizeHeight = NO;
		self.saveQuality = 1;
		self.strength = 0.5;
		self.outputWidth = 512;
		self.outputHeight = 512;
		self.sampleRadius = 2;
		self.saveFormat = NSPNGFileType;
		self.nameDecoration = @"_normal";
		self.nameDecorationStyle = NMNameDecorationAppend;
		
		[self loadPrefs];
	}
	
	return self;
}

#pragma mark -

#define kPrefStrength				@"Strength"
#define kPrefOutputWidth			@"OutputWidth"
#define kPrefOutputHeight			@"OutputHeight"
#define kPrefSampleRadius			@"SampleRadius"
#define kPrefResizeWidth			@"ResizeWidth"
#define kPrefResizeHeight           @"ResizeHeight"
#define kPrefNameDecoration			@"NameDecoration"
#define kPrefNameDecorationStyle	@"NameDecorationStyle"
#define kPrefSaveQuality			@"SaveQuality"
#define kPrefSaveFormat				@"SaveFormat"

#define kBatchSettings				@"BatchSettings"

- (void) loadPrefs
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *settings = [defaults dictionaryForKey: kBatchSettings];
	if ( settings )
	{
		id value = nil;
		
		if ((value = [settings valueForKey: kPrefStrength]))
		{
			self.strength = [value intValue];
		}

		if ((value = [settings valueForKey: kPrefOutputWidth]))
		{
			self.outputWidth = [value intValue];
		}

		if ((value = [settings valueForKey: kPrefOutputHeight]))
		{
			self.outputHeight = [value intValue];
		}

		if ((value = [settings valueForKey: kPrefSampleRadius]))
		{
			self.sampleRadius = [value intValue];
		}

		if ((value = [settings valueForKey: kPrefResizeWidth]))
		{
			self.resizeWidth = [value boolValue];
		}
        
        if ((value = [settings valueForKey: kPrefResizeHeight]))
        {
            self.resizeHeight = [value boolValue];
        }
	
		if ((value = [settings valueForKey: kPrefNameDecoration]))
		{
			self.nameDecoration = value;
		}

		if ((value = [settings valueForKey: kPrefNameDecorationStyle]))
		{
			self.nameDecorationStyle = [value intValue];
		}

		if ((value = [settings valueForKey: kPrefSaveFormat]))
		{
			self.saveFormat = [value intValue];
		}

		if ((value = [settings valueForKey: kPrefSaveQuality]))
		{
			self.saveQuality = [value floatValue];
		}
	}
}

- (void) savePrefs
{
	NSMutableDictionary *settings = [NSMutableDictionary dictionary];
	[settings setObject: [NSNumber numberWithInt: self.strength] forKey: kPrefStrength];
	[settings setObject: [NSNumber numberWithInt: self.outputWidth] forKey: kPrefOutputWidth];
	[settings setObject: [NSNumber numberWithInt: self.outputHeight] forKey: kPrefOutputHeight];
	[settings setObject: [NSNumber numberWithInt: self.sampleRadius] forKey: kPrefSampleRadius];
	[settings setObject: [NSNumber numberWithBool: self.resizeWidth] forKey: kPrefResizeWidth];
    [settings setObject: [NSNumber numberWithBool: self.resizeHeight] forKey: kPrefResizeHeight];

	[settings setObject: self.nameDecoration forKey: kPrefNameDecoration];
	[settings setObject: [NSNumber numberWithInt: self.nameDecorationStyle] forKey: kPrefNameDecorationStyle];
	[settings setObject: [NSNumber numberWithInt: self.saveFormat] forKey: kPrefSaveFormat];
	[settings setObject: [NSNumber numberWithFloat: self.saveQuality] forKey: kPrefSaveQuality];
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject: settings forKey: kBatchSettings];
}

#pragma mark -

@synthesize resizeWidth;
@synthesize resizeHeight;
@synthesize showSaveQualityControls;
@synthesize saveQuality;
@synthesize strength;
@synthesize outputWidth;
@synthesize outputHeight; 
@synthesize sampleRadius;
@synthesize saveFormat;
@synthesize nameDecoration;
@synthesize nameDecorationStyle;

#pragma mark -

-(void) setSaveQuality: (CGFloat) newSaveQuality
{
	saveQuality = MIN(MAX(newSaveQuality,0),1);
}

- (void) setStrength: (int) newStrength
{
	strength = MIN(MAX(newStrength,0),100);
}

- (void) setSaveFormat: (int) newSaveFormat
{
	saveFormat = newSaveFormat;
	switch( saveFormat )
	{
		case NSJPEGFileType:
		{
			self.showSaveQualityControls = YES;
			break;
		}

		case NSJPEG2000FileType:
		{
			self.showSaveQualityControls = YES;
			break;
		}
		
		case NSPNGFileType:
		{
			self.showSaveQualityControls = NO;
		}
	}
}

- (NSString*) saveFormatExtension
{
	NSString *extension = nil;
	switch( saveFormat )
	{
		case NSJPEGFileType:
		{
			extension = @"jpg";
			break;
		}

		case NSJPEG2000FileType:
		{
			extension = @"jp2";
			break;
		}
		
		case NSPNGFileType:
		{
			extension = @"png";
		}
	}
	
	return extension;
}

@end

