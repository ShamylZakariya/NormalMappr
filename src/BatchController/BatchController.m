//
//  Controller.m
//  FilteredImageList
//
//  Created by Shamyl Zakariya on 3/12/09.
//  Copyright 2009 Shamyl Zakariya. All rights reserved.
//

#import "BatchController.h"
#import "BatchEntry.h"
#import "BatchOperation.h"
#import "AppDelegate.h"

#define kPrefNonBumpmapPaneVisible @"NonBumpmapPaneVisible"

@interface BatchController(Private)

- (void) performCollapse;
- (BOOL) canOpenFileWithExtension: (NSString*) extension;
- (NSMutableArray*) gatherFiles: (NSArray *) inFiles;
- (void) loadDroppedFiles: (NSArray*) droppedFiles;
- (void) fileAddingAnalysisComplete: (NSMutableArray*) addableFiles;
- (void) normalmapFiles: (NSArray*) files;

@end


@implementation BatchController


+ (NSSet*) keyPathsForValuesAffectingShowDropMessage
{
	return [NSSet setWithObjects: @"bumpmaps", @"nonBumpmaps", nil ];
}

+ (NSSet*) keyPathsForValuesAffectingBumpmapCount
{
	return [NSSet setWithObjects: @"bumpmaps", @"nonBumpmaps", nil ];
}

+ (NSSet*) keyPathsForValuesAffectingNonBumpmapCount
{
	return [NSSet setWithObjects: @"bumpmaps", @"nonBumpmaps", nil ];
}


- (id) init 
{
	if ( self = [super init] )
	{	
		batchSettings = [[BatchSettings alloc] init];
		bumpmaps = [[NSMutableArray alloc] init];
		nonBumpmaps = [[NSMutableArray alloc] init];
		allowUIAnimations = NO;

		[NSBundle loadNibNamed: @"BatchWindow" owner:self];
	}
	
	return self;
}

- (void) awakeFromNib
{
	self.showDropMessage = YES;
	self.iconSize = 128;
	
	NSColor *backgroundColor = [NSColor grayColor];
	
	bumpmapCollectionView.delegate = self;
	bumpmapCollectionView.dropAction = @selector( makeBumpmap: );
	bumpmapCollectionView.dropFilesAction = @selector( addFiles: );
	bumpmapCollectionView.deleteAction = @selector( remove: );
	bumpmapCollectionView.message = @"Drop files & folders here";
	bumpmapCollectionView.backgroundColors = [NSArray arrayWithObject: backgroundColor];
	bumpmapCollectionViewLabel.label = @"Bumpmaps";

	nonBumpmapCollectionView.delegate = self;
	nonBumpmapCollectionView.dropAction = @selector( makeNonBumpmap: );
	nonBumpmapCollectionView.deleteAction = @selector( remove: );
	nonBumpmapCollectionView.backgroundColors = bumpmapCollectionView.backgroundColors;
	nonBumpmapCollectionViewLabel.label = @"These files may not be bumpmaps";
	
	collectionStack.backgroundColor = backgroundColor;
		
	[self bind: @"nonBumpmapPaneVisible" toObject: nonBumpmapCollectionViewLabel withKeyPath: @"open" options: nil];
	[bumpmapCollectionView bind: @"showMessage" toObject: self withKeyPath: @"showDropMessage" options:nil];

	[bumpmapCollectionViewLabel bind: @"count" toObject: self withKeyPath: @"bumpmapCount" options: nil];
	[nonBumpmapCollectionViewLabel bind: @"count" toObject: self withKeyPath: @"nonBumpmapCount" options: nil];

	//
	// Load settings
	//

	id value = nil;
	if ((value = [[NSUserDefaults standardUserDefaults] valueForKey: kPrefNonBumpmapPaneVisible]))
	{
		// we need to go through the label itself, since I'm lazy regarding binding directionality, I suppose
		nonBumpmapCollectionViewLabel.open = [value boolValue];
	}
	else
	{
		nonBumpmapCollectionViewLabel.open = NO;
	}
		
	//
	//	Now that everything's set up, we will allow animations
	//

	allowUIAnimations = YES;
}

#pragma mark -

@synthesize batchSettings;
@synthesize bumpmaps;
@synthesize nonBumpmaps;
@synthesize iconSize;
@synthesize sheetProcessStepTotal;
@synthesize sheetProcessStep;
@synthesize sheetProcessRunning;
@synthesize sheetProcessIndeterminate;
@synthesize sheetProcessProgress;
@synthesize showDropMessage;
@synthesize nonBumpmapPaneVisible;
@synthesize bumpmapsArrayController;
@synthesize nonBumpmapsArrayController;
@synthesize sheetMessage;

- (void) setShowWindow: (BOOL) shouldShowWindow 
{
	if ( shouldShowWindow != showWindow )
	{
		showWindow = shouldShowWindow;
		if ( showWindow ) 
		{
			[batchWindow makeKeyAndOrderFront:self];
		}
		else if ( [batchWindow isVisible] )
		{
			[batchWindow orderOut:self];
		}
	}
}

- (BOOL) showWindow
{
	return showWindow;
}

- (void) setIconSize: (CGFloat) size
{
	iconSize = size;
	NSSize sz = NSMakeSize( size * 1.3, size );
	bumpmapCollectionView.minItemSize = sz;
	bumpmapCollectionView.maxItemSize = sz;
	nonBumpmapCollectionView.minItemSize = sz;
	nonBumpmapCollectionView.maxItemSize = sz;
}

- (void) setShowDropMessage: (BOOL) sdm
{
	if ( sdm != showDropMessage )
	{
		showDropMessage = sdm;
		[self performCollapse];
	}
}

- (NSInteger) bumpmapCount
{
	return [bumpmaps count];
}

- (NSInteger) nonBumpmapCount
{
	return [nonBumpmaps count];
}


- (void) setNonBumpmapPaneVisible: (BOOL) visible
{
	if ( visible != nonBumpmapPaneVisible )
	{
		nonBumpmapPaneVisible = visible;
		[self performCollapse];		
	}
}

- (void)addFiles:(NSArray *)inFiles
{
	if ( self.sheetProcessRunning ) return;	
	self.sheetProcessRunning = YES;
	
	//
	// Mark indeterminate progress until we've gathered up the file listing
	// and know how many files we actually need to process.
	//

	self.sheetProcessIndeterminate = YES;	
	
	if ( progressSheet )
	{
		self.sheetMessage = @"Searching dropped files for bumpmaps...";
		[NSApp beginSheet: progressSheet 
		   modalForWindow: batchWindow 
			modalDelegate: self 
		   didEndSelector: @selector(processSheetDidEnd:returnCode:contextInfo:) 
			  contextInfo: nil];
	}

	//
	// Image analysis is expensive, so we'll spawn a thread
	//

	[NSThread detachNewThreadSelector: @selector( loadDroppedFiles: ) toTarget: self withObject: inFiles];
}

- (void) makeBumpmap: (NSArray*) paths
{
	NSMutableArray *collector = [NSMutableArray array];
	for ( NSString *file in paths )
	{
		for ( BatchEntry *entry in self.nonBumpmaps )
		{
			if ( [entry.path isEqualToString: file] )
			{
				entry.looksLikeBumpmap = YES;
				[collector addObject: entry];
			}
		}
	}
	
	if ( collector.count )
	{
		[nonBumpmapsArrayController removeObjects: collector];
		[bumpmapsArrayController addObjects: collector];		
	}

	self.showDropMessage = (bumpmaps.count==0) && (nonBumpmaps.count==0);
}

- (void) makeNonBumpmap: (NSArray*) paths
{
	NSMutableArray *collector = [NSMutableArray array];
	for ( NSString *file in paths )
	{			
		for ( BatchEntry *entry in self.bumpmaps )
		{
			if ( [entry.path isEqualToString: file] )
			{
				entry.looksLikeBumpmap = YES;
				[collector addObject: entry];
			}
		}
	}
			
	if ( collector.count )
	{
		[bumpmapsArrayController removeObjects: collector];
		[nonBumpmapsArrayController addObjects: collector];
	}

	self.showDropMessage = (bumpmaps.count==0) && (nonBumpmaps.count==0);
}

- (void) remove: (NSArray*) items
{
	[self willChangeValueForKey: @"bumpmaps"];
	[self willChangeValueForKey: @"nonBumpmaps"];

	[self.bumpmaps removeObjectsInArray:items];
	[self.nonBumpmaps removeObjectsInArray:items];

	[self didChangeValueForKey: @"bumpmaps"];
	[self didChangeValueForKey: @"nonBumpmaps"];

	self.showDropMessage = (bumpmaps.count==0) && (nonBumpmaps.count==0);
}

- (void) savePreferences
{
	[batchSettings savePrefs];
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject: [NSNumber numberWithBool:self.nonBumpmapPaneVisible] forKey: kPrefNonBumpmapPaneVisible];
}

- (IBAction) executeBatch: (id) sender
{
	if ( self.sheetProcessRunning ) return;	
	self.sheetProcessRunning = YES;
	
	//
	// Mark indeterminate progress until we've gathered up the file listing
	// and know how many files we actually need to process.
	//

	self.sheetProcessIndeterminate = YES;	
	
	if ( progressSheet )
	{
		self.sheetMessage = @"Normalmapping...";
		[NSApp beginSheet: progressSheet 
		   modalForWindow: batchWindow 
			modalDelegate: self 
		   didEndSelector: @selector(processSheetDidEnd:returnCode:contextInfo:) 
			  contextInfo: nil];
	}

	//
	// Image analysis is expensive, so we'll spawn a thread
	//

	[NSThread detachNewThreadSelector: @selector( normalmapFiles: ) toTarget: self withObject: self.bumpmaps];	
}

#pragma mark -
#pragma mark Private

- (void) performCollapse
{		
	NSDictionary *collapseParams = nil;
	if ( showDropMessage )
	{
		collapseParams = [NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithFloat:0], [NSNumber numberWithUnsignedInteger: (NSUInteger)bumpmapCollectionViewLabel],
			[NSNumber numberWithFloat:1.0], [NSNumber numberWithUnsignedInteger: (NSUInteger)[bumpmapCollectionView enclosingScrollView]],
			[NSNumber numberWithFloat:0], [NSNumber numberWithUnsignedInteger: (NSUInteger)nonBumpmapCollectionViewLabel],
			[NSNumber numberWithFloat:0], [NSNumber numberWithUnsignedInteger: (NSUInteger)[nonBumpmapCollectionView enclosingScrollView]],
			nil];
	}
	else if ( !nonBumpmapPaneVisible )
	{
		collapseParams = [NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithFloat:1.0], [NSNumber numberWithUnsignedInteger: (NSUInteger)bumpmapCollectionViewLabel],
			[NSNumber numberWithFloat:1.0], [NSNumber numberWithUnsignedInteger: (NSUInteger)[bumpmapCollectionView enclosingScrollView]],
			[NSNumber numberWithFloat:1.0], [NSNumber numberWithUnsignedInteger: (NSUInteger)nonBumpmapCollectionViewLabel],
			[NSNumber numberWithFloat:0], [NSNumber numberWithUnsignedInteger: (NSUInteger)[nonBumpmapCollectionView enclosingScrollView]],
			nil];
	}

	[collectionStack setViewCollapse: collapseParams animate: allowUIAnimations];
}

#pragma mark -
#pragma mark File analysis

- (BOOL) canOpenFileWithExtension: (NSString*) extension
{
	extension = [extension lowercaseString];
	return ( [extension isEqualToString: @"tif"] ||
			 [extension isEqualToString: @"tiff"] ||
			 [extension isEqualToString: @"jp2"] ||
			 [extension isEqualToString: @"jpg"] ||
			 [extension isEqualToString: @"jpeg"] ||
			 [extension isEqualToString: @"png"] ||
			 [extension isEqualToString: @"gif"] || 
			 [extension isEqualToString: @"psd"] /*||
			 [extension isEqualToString: @"dds"]*/ );
}

- (NSMutableArray*) gatherFiles: (NSArray*) inFiles
{
	NSFileManager *fm = [NSFileManager defaultManager];

	//
	// we'll stick addable images here
	//

	NSMutableArray *files = [NSMutableArray array];

	for ( NSString *path in inFiles )
	{
		BOOL isDir = NO;
		if ( [fm fileExistsAtPath: path isDirectory: &isDir ] )
		{
			if ( isDir )
			{
				//
				// subpaths performs a complete filesystem traversal -- no need to recurse!
				//

				for ( NSString* subpath in [fm subpathsAtPath: path] )
				{
					NSString *actualPath = [path stringByAppendingPathComponent: subpath];
					if ( [self canOpenFileWithExtension: [actualPath pathExtension]] )
					{
						[files addObject: actualPath];
					}
				}
			}
			else
			{
				if ( [self canOpenFileWithExtension: [path pathExtension]] )
				{
					[files addObject: path];
				}
			}
		}
	}

	return files;
}

- (void) loadDroppedFiles: (NSArray*) droppedFiles
{
	//
	// gather image files we recognize
	//
	
	NSArray *files = [self gatherFiles: droppedFiles];
	NSMutableArray *entries = [NSMutableArray array];
		
	//
	// now we know how many we need to examine
	//
	
	self.sheetProcessStepTotal = files.count;
	self.sheetProcessStep = 0;
	self.sheetProcessIndeterminate = NO;	
	
	//
	// Now load batch entries
	//

	for ( NSString *file in files )
	{
		BatchEntry *be = [BatchEntry imageEntryWithPath: file];
		if ( be )
		{
			[entries addObject:be];
		}

		self.sheetProcessStep = self.sheetProcessStep + 1;
		self.sheetProcessProgress = (float) self.sheetProcessStep / (float)self.sheetProcessStepTotal;
	}

	//
	// we're done, notify self on main thread
	//

	[self performSelectorOnMainThread: @selector( fileAddingAnalysisComplete: ) withObject: entries waitUntilDone: NO];
}

- (void) fileAddingAnalysisComplete: (NSMutableArray*) newEntries
{
	self.sheetProcessRunning = NO;

	if ( progressSheet )
	{
		[NSApp endSheet: progressSheet];
	}

	NSMutableArray *bumps = [NSMutableArray array],
	               *nonBumps = [NSMutableArray array];

	for ( BatchEntry *entry in newEntries )
	{
		if ( entry.looksLikeBumpmap )
		{
			[bumps addObject: entry];
		}
		else
		{
			[nonBumps addObject: entry];
		}
	}
	
	[bumpmapsArrayController addObjects:bumps];
	[nonBumpmapsArrayController addObjects: nonBumps];

	self.showDropMessage = (bumpmaps.count==0) && (nonBumpmaps.count==0);
}

- (void)processSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    [sheet orderOut:self];
}

#pragma mark -
#pragma mark Normal Mapping

- (void) normalmapFiles: (NSArray*) entries
{
	self.sheetProcessStepTotal = entries.count;
	self.sheetProcessStep = 0;
	self.sheetProcessIndeterminate = NO;	
	
	//
	// Now load batch entries
	//

	for ( BatchEntry *entry in entries )
	{
		DebugLog( @"normalmapping %@", entry );
		
		BatchOperation *op = [[BatchOperation alloc] initWithEntry: entry andSettings: batchSettings];
		[op run];
		
		self.sheetProcessStep = self.sheetProcessStep + 1;
		self.sheetProcessProgress = (float) self.sheetProcessStep / (float)self.sheetProcessStepTotal;
	}

	//
	// we're done, notify self on main thread
	//
	
	[self performSelectorOnMainThread: @selector( normalmappingComplete: ) withObject: nil waitUntilDone: NO];
}

- (void) normalmappingComplete: (id) info
{
	self.sheetProcessRunning = NO;

	if ( progressSheet )
	{
		[NSApp endSheet: progressSheet];
	}
}

#pragma mark -
#pragma mark NSWindow Delegate

- (void)windowWillClose:(NSNotification *)notification
{
	DebugLog( @"Batch window will close" );
	
	//
	//	This is stupid hacky, but the menu-state is maintained in the AppDelegate
	//	and this means that when the user hits command-w or clicks the close button,
	//	and the window is manually closed, we need to keep menu state in sync by
	//	going through this way.
	//

	((AppDelegate*)[NSApp delegate]).batchWindowShowing = NO;
}


@end
