//
//  NormalMapprDoc.m
//  NormalMappr
//
//  Created by Shamyl Zakariya on 6/26/07.
//  Copyright Shamyl Zakariya 2007 . All rights reserved.
//

#import "NormalMapprDoc.h"

@interface NormalMapprDoc(Private)

- (NSString*) currentSaveExtension;
- (void) update;
- (NSRect) idealZoomWindowSize;
- (void) fitWindowToContents;
- (NSRect) windowWillUseStandardFrame:(NSWindow *)window defaultFrame:(NSRect)newFrame;
- (void) exportSheetDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode  contextInfo:(void  *)contextInfo;


@end


@implementation NormalMapprDoc

/*
	CGSize _outputSize;
	CINormalMapper *_normalmapper;
	NSArray *_saveFormats;
	NSString *_saveFormat;
	NSSavePanel *_currentSavePanel;
	NSDate *_fileTimestamp;
	float _saveQuality;
	BOOL _syncDimensions;

	IBOutlet NSWindow *docWindow;
	IBOutlet NSView *imageViewContainer;
	IBOutlet ImageView *imageView;
	IBOutlet TilingImageView *tilingImageView;
	IBOutlet NSScrollView *imageViewScroller;
	IBOutlet NSSlider *strengthSlider;
	IBOutlet NSSlider *sampleRadiusSlider;
	IBOutlet NSView *savePanelDialog;
	IBOutlet NSBox *savePanelQualityControls;
*/

- (id)init
{
    if (self = [super init]) 
	{
		_saveFormats = @[kJPEG2000Format, kJPEGFormat, kPNGFormat, kTIFFFormat];
	    _syncAspectRatio = YES;
        
        _fileWatcher = [[VDKQueue alloc] init];
        _fileWatcher.delegate = self;
    }
    return self;
}

- (void) dealloc
{
    DebugLog(@"dealloc");
}

#pragma mark -
#pragma mark KVC

+ (NSSet*) keyPathsForValuesAffectingOutputHeight
{
	return [NSSet setWithObject: @"outputWidth" ];
}

+ (NSSet*) keyPathsForValuesAffectingOutputWidth
{
	return [NSSet setWithObject: @"outputHeight" ];
}

#pragma mark -
#pragma mark NSDocument stuff

- (NSString *)windowNibName
{
    return @"NormalMapprDoc";
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
	[docWindow setDelegate: self];
    [super windowControllerDidLoadNib:aController];
    
    imageView.hiDPI = YES;
    tilingImageView.hiDPI = YES;

	self.saveFormat = kPNGFormat;
	self.saveQuality = 80;
	self.tileMode = 0;

	[self fitWindowToContents];
	[self update];
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
	NSBitmapFormat format;
	NSDictionary *props = nil;

	if ( [_saveFormat isEqualToString: kJPEG2000Format] )
	{
        format = NSBitmapImageFileTypeJPEG2000;
		props = [NSDictionary dictionaryWithObject: [NSNumber numberWithFloat:_saveQuality / 100.0f] forKey: NSImageCompressionFactor];
	}
	else if ( [_saveFormat isEqualToString: kJPEGFormat] )
	{
        format = NSBitmapImageFileTypeJPEG;
		props = [NSDictionary dictionaryWithObject: [NSNumber numberWithFloat:_saveQuality / 100.0f] forKey: NSImageCompressionFactor];
	}
	else if ( [_saveFormat isEqualToString: kPNGFormat] )
	{
        format = NSBitmapImageFileTypePNG;
	}
	else if ( [_saveFormat isEqualToString: kTIFFFormat] )
	{
        format = NSBitmapImageFileTypeTIFF;
		props = [NSDictionary dictionaryWithObject: [NSNumber numberWithInt:NSTIFFCompressionLZW] forKey: NSImageCompressionMethod];
	}
	else
	{
		NSLog( @"Unrecognized save format %@", _saveFormat );
		return nil;
	}
	
	return [[_normalmapper normalmap] representationUsingType:format properties:props];
}


- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError
{
	_normalmapper = nil;
	
	NSData *data = [NSData dataWithContentsOfURL:absoluteURL];
	if ( data )
	{
		NSBitmapImageRep *image = [[NSBitmapImageRep alloc] initWithData: data];
		if ( image )
		{
			_normalmapper = [[CINormalMapper alloc] init];
			_normalmapper.bumpmap = image;
			_outputSize = NSSizeToCGSize( image.size );
			
			//
			//	Start a watch on the containing folder
			//

			NSString *containingFolderPath = [[absoluteURL path] stringByDeletingLastPathComponent];
            [_fileWatcher addPath:containingFolderPath];

			//
			//	Record timestamp
			//

			NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath: [absoluteURL path] error:nil];
			if ( attrs )
			{
				_fileTimestamp = [attrs objectForKey: NSFileModificationDate];
			}
			else if ( outError )
			{
				*outError = [NSError errorWithDomain:@"NormalMapprErrorDomain" 
												code:-1 
											userInfo:[NSDictionary dictionaryWithObject: @"Unable to read timestamp on image" forKey:NSLocalizedFailureReasonErrorKey]];
			}
			
			[self setStrength: 50];
			[self setSampleRadius: 1];
			[self fitWindowToContents];
		}
		else if ( outError )
		{
			*outError = [NSError errorWithDomain:@"NormalMapprErrorDomain" 
											code:-1 
										userInfo:[NSDictionary dictionaryWithObject: @"Unable to open image" forKey:NSLocalizedFailureReasonErrorKey]];
		}
	}
	else if ( outError )
	{
		*outError = [NSError errorWithDomain:@"NormalMapprErrorDomain" 
										code:-1 
									userInfo:[NSDictionary dictionaryWithObject: @"Unable to open file" forKey:NSLocalizedFailureReasonErrorKey]];
	}
	
    return _normalmapper != nil ? YES : NO;
}

#pragma mark -
#pragma mark Properties

- (void) setStrength: (int) strength
{
	_normalmapper.strength = ((float)strength) / 100.0f;
	[self update];
}

- (int) strength
{
	return _normalmapper.strength * 100.0f;
}

- (void) setSampleRadius: (int) sampleRadius
{
	_normalmapper.sampleRadius = sampleRadius;
	[self update];
}

- (int) sampleRadius
{
	return _normalmapper.sampleRadius;
}

- (void) setClampToEdge: (BOOL) cte
{
	_normalmapper.clampToEdge = cte;
	[self update];
}

- (BOOL) clampToEdge
{
	return _normalmapper.clampToEdge;
}

- (void) setOutputWidth: (int) width
{
	width = MAX( width, 8 );
	CGSize size = _normalmapper.size;
	size.width = width;

	if ( _syncAspectRatio )
	{
		float newHeight = ceilf(_normalmapper.bumpmap.size.height * ((float) width / (float)_normalmapper.bumpmap.size.width));
		size.height = lrintf( ceilf(newHeight) );
	}
	
	_outputSize = size;
	_normalmapper.size = size;
	[self update];
}

- (int) outputWidth
{
	return _normalmapper.size.width;
}

- (void) setOutputHeight: (int) height
{
	height = MAX( height, 8 );
	CGSize size = _normalmapper.size;
	size.height = height;

	if ( _syncAspectRatio )
	{
		float newWidth = ceilf((_normalmapper.bumpmap.size.width ) * ((float) height / _normalmapper.bumpmap.size.height));
		size.width = lrintf( ceilf(newWidth) );
	}

	_outputSize = size;
	_normalmapper.size = size;

	[self update];
}

- (int) outputHeight
{
	return _normalmapper.size.height;
}

- (NSArray*) saveFormats
{
	return _saveFormats;
}

- (void) setSaveFormat: (NSString *) formatName
{
	_saveFormat = formatName;
	
	if ( [_saveFormat isEqualToString: kJPEG2000Format] ||
	     [_saveFormat isEqualToString: kJPEGFormat] )
	{
		[savePanelQualityControls setHidden: NO];
	}
	else
	{
		[savePanelQualityControls setHidden: YES];
	}
	
    NSArray<NSString*> *extensions = @[[self currentSaveExtension]];
    [_currentSavePanel setAllowedFileTypes: extensions];
}

- (NSString *) saveFormat
{
	return _saveFormat;
}

- (void) setSaveQuality: (float) quality
{
	if ( quality < 0 ) quality = 0;
	else if ( quality > 100 ) quality = 100;
	_saveQuality = quality;
}

- (float) saveQuality
{
	return _saveQuality;
}

- (void) setSyncAspectRatio: (BOOL) sync
{
	_syncAspectRatio = sync;
    
    NSImage *toggleButtonImage = [NSImage imageNamed:sync? @"LinkWidthHeight-Button" : @"UnLinkWidthHeight-Button"];
    [linkWidthHeightToggleButton setImage:toggleButtonImage];
	
	if ( _syncAspectRatio )
	{
		[self setOutputWidth: [self outputWidth]];
	}	
}

- (BOOL) syncAspectRatio
{
	return _syncAspectRatio;
}

- (void) setTileMode: (int) tileMode
{
	// in case imageView has a scroller superview
	NSView *iv = imageViewScroller ? (NSView*)imageViewScroller : (NSView*)imageView;

	switch( tileMode )
	{		
		case 1:
		{
			if ( tilingImageView.superview == nil )
			{
				// tiling
				[imageViewContainer.animator replaceSubview:iv with:tilingImageView];
			}
		
			break;
		}

		case 0:
		default:
		{
			if ( iv.superview == nil )
			{
				// non-tiling
				[imageViewContainer.animator replaceSubview:tilingImageView with:iv];
			}
			
			break;
		}
	}

	NSRect viewFrame = NSMakeRect( 0,0, imageViewContainer.frame.size.width, imageViewContainer.frame.size.height );
	tilingImageView.frame = viewFrame;
	iv.frame = viewFrame;
}

- (int) tileMode
{
	return [tilingImageView superview] != nil ? 1 : 0;
}

#pragma mark -

- (void) reload
{
	NSURL *url = [self fileURL];
	NSString *pretty = [[url path] lastPathComponent];

	DebugLog( @"reloading image %@", pretty);
	NSData *data = [NSData dataWithContentsOfURL:url];
	if ( data )
	{
		NSBitmapImageRep *image = [[NSBitmapImageRep alloc] initWithData: data];
		if ( image )
		{
			_normalmapper.bumpmap = image;
			_normalmapper.size = _outputSize;
			[self update];
		}
		else
		{
			DebugLog( @"Unable to load image from %@", pretty);
		}
	}
	else
	{
		DebugLog( @"Unable to reload image data from %@", pretty);
	}
}


#pragma mark -
#pragma mark IBActions

- (IBAction) export: (id) sender
{
	_currentSavePanel = [NSSavePanel savePanel];
	[_currentSavePanel setMessage:@"Export the normalmap to:"];
    [_currentSavePanel setAllowedFileTypes:@[[self currentSaveExtension]]];
	[_currentSavePanel setAccessoryView: savePanelDialog];
    [_currentSavePanel setDirectoryURL:[[self fileURL] URLByDeletingLastPathComponent]];
    [_currentSavePanel setNameFieldStringValue:[[[[self fileURL] path] lastPathComponent] stringByDeletingPathExtension]];
    
    [_currentSavePanel beginSheetModalForWindow:docWindow completionHandler:^(NSModalResponse result) {
        if ( result == NSModalResponseOK )
        {
            [[self dataOfType: @"Export Type Or Something" error: nil] writeToURL: [_currentSavePanel URL] atomically: NO];
        }
    }];
}

- (IBAction) showSingleImage: (id) sender
{
	self.tileMode = 0;
}

- (IBAction) showTiledImage: (id) sender
{
	self.tileMode = 1;
}

#pragma mark -
#pragma mark NSWindowDelegate

- (NSRect) windowWillUseStandardFrame:(NSWindow *)window defaultFrame:(NSRect)newFrame
{
	if ( window == docWindow )
	{
		return [self idealZoomWindowSize];
	}
	
	return newFrame;
}

#pragma mark -
#pragma mark VDKQueueDelegate

-(void) VDKQueue:(VDKQueue *)queue receivedNotification:(NSString*)noteName forPath:(NSString*)fpath
{
    if ([noteName isEqualToString:VDKQueueWriteNotification])
    {
        //
        //    We know that a file in the folder containing this file was written to.
        //    It may or may not have been our file. So we're going to do a timestamp check.
        //
        
        NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:[[self fileURL] path] error:nil];
        if ( attrs )
        {
            NSDate *timestamp = [attrs objectForKey: NSFileModificationDate];
            if ( [_fileTimestamp compare: timestamp] == NSOrderedAscending )
            {
                _fileTimestamp = timestamp;
                
                //
                //    This is hincty -- photoshop seems to perform multiple immediate writes to the file,
                //    but our use of timestamps causes only the first to be read, which is
                //    insufficient. So, we have to shedule a reload in the near future.
                //
                
                WEAK_SELF;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    STRONG_SELF;
                    DebugLog( @"Reloading %@", [[strongSelf fileURL] path]);
                    [strongSelf reload];
                });
            }
            else
            {
                NSTimeInterval difference = [timestamp timeIntervalSinceReferenceDate] - [_fileTimestamp timeIntervalSinceReferenceDate];
                DebugLog( @"timestamp difference %.2f on %@ doesn't show difference: not reloading",
                         difference, [[[self fileURL] path] lastPathComponent] );
            }
        }
    }
}

#pragma mark -
#pragma mark Private

- (NSString*) currentSaveExtension
{
	if ( [_saveFormat isEqualToString: kJPEG2000Format] )
	{
		return @"jp2";
	}
	else if ( [_saveFormat isEqualToString: kJPEGFormat] )
	{
		return @"jpeg";
	}
	else if ( [_saveFormat isEqualToString: kPNGFormat] )
	{
		return @"png";
	}
	else if ( [_saveFormat isEqualToString: kTIFFFormat] )
	{
		return @"tiff";
	}

	return nil;
}


- (void) update
{
	if ( nil != _normalmapper )
	{
		imageView.image = _normalmapper.normalmap;
		tilingImageView.image = _normalmapper.normalmap;
	}
}

- (NSRect) idealZoomWindowSize
{
	NSSize size;
    float scale = 1.0f / [docWindow screen].backingScaleFactor;
	size.width = _normalmapper.size.width * scale;
	size.height = (_normalmapper.size.height * scale) + controlPanelView.bounds.size.height;
	NSRect fr = [docWindow frameRectForContentRect: NSMakeRect( 0,0, size.width, size.height )];
	
	//
	// now we need to compare the current window height to the proposed new height 
	// and adjust the frame origin accordingly to keep the top-left in the correct place.
	//
	
	float dh = fr.size.height - docWindow.frame.size.height;
	fr.origin.x = docWindow.frame.origin.x;
	fr.origin.y = docWindow.frame.origin.y - dh;	
	
	return fr;
}

- (void) fitWindowToContents
{
	if ( docWindow )
	{
		[docWindow setFrame: [self idealZoomWindowSize] display: YES];
	}
}


@end
