//
//  Controller.m
//  FilteredImageList
//
//  Created by Shamyl Zakariya on 3/12/09.
//  Copyright 2009 Shamyl Zakariya. All rights reserved.
//

#import "BatchController.h"

#import "AppDelegate.h"
#import "BatchCollectionViewItem.h"
#import "BatchOperation.h"

#define kBatchCollectionViewItemIdentifier @"batchCollectionViewItem"

@interface BatchController(Private)

- (BOOL) canOpenFileWithExtension: (NSString*) extension;
- (NSMutableArray<NSURL*>*) gatherFiles: (NSArray<NSURL*> *) fileURLs;
- (void) loadDroppedFiles: (NSArray<NSURL*>*) fileURLs;
- (void) fileAddingAnalysisComplete: (NSMutableArray<BatchEntry*>*) addableFiles;
- (void) normalmapFiles: (NSArray<BatchEntry*>*) files;

@end


@implementation BatchController

- (id) init 
{
    if ( self = [super init] )
    {
        batchSettings = [[BatchSettings alloc] init];
        bumpmaps = [[NSMutableArray alloc] init];
        nonBumpmaps = [[NSMutableArray alloc] init];
        
        [[NSBundle mainBundle] loadNibNamed:@"BatchWindow" owner:self topLevelObjects:nil];
    }
    
    return self;
}

- (void) awakeFromNib
{
    self.showDropMessage = YES;
    self.iconSize = 128;
    
    bumpmapsCollectionView.dataSource = self;
    bumpmapsCollectionView.delegate = self;
    NSNib* itemNib = [[NSNib alloc] initWithNibNamed:@"BatchCollectionViewItem" bundle:[NSBundle mainBundle]];
    [bumpmapsCollectionView registerNib:itemNib forItemWithIdentifier:kBatchCollectionViewItemIdentifier];
    [bumpmapsCollectionView registerForDraggedTypes:@[NSURLPboardType]];
    [bumpmapsCollectionView setDraggingSourceOperationMask:NSDragOperationEvery forLocal:YES];
    
    if (@available(macOS 10.13, *)) {
        bumpmapsCollectionView.backgroundColors = @[[NSColor colorNamed:@"BatchViewBackground"]];
    } else {
        bumpmapsCollectionView.backgroundColors = @[[NSColor colorWithDeviceWhite:0.9 alpha:1]];
    }
}

#pragma mark -

@synthesize batchSettings;
@synthesize sheetProcessStepTotal;
@synthesize sheetProcessStep;
@synthesize sheetProcessRunning;
@synthesize sheetProcessIndeterminate;
@synthesize sheetProcessProgress;
@synthesize sheetMessage;
@synthesize showDropMessage;
@synthesize iconSize;

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
    bumpmapsCollectionViewFL.itemSize = NSMakeSize( size * 1.3, size );
}

- (void) setShowDropMessage: (BOOL) sdm
{
    if ( sdm != showDropMessage )
    {
        showDropMessage = sdm;
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

- (void)addFiles:(NSArray<NSURL*> *)fileURLs
{
    if ( self.sheetProcessRunning ) return;
    self.sheetProcessRunning = YES;
    
    //
    // Mark indeterminate progress until we've gathered up the file listing
    // and know how many files we actually need to process.
    //
    
    self.sheetProcessIndeterminate = YES;
    self.sheetMessage = @"Searching dropped files for bumpmaps...";
    [batchWindow beginSheet:progressSheet completionHandler:^(NSModalResponse returnCode) {
        [progressSheet orderOut:self];
    }];
    
    //
    // Image analysis is expensive, so we'll spawn a thread
    //

#warning Use GCD
    [NSThread detachNewThreadSelector: @selector( loadDroppedFiles: ) toTarget: self withObject: fileURLs];
}

- (void) removeFiles:(NSArray<NSURL *> *)fileURLs
{
    DebugLog(@"remove %@", [fileURLs componentsJoinedByString:@"\n"]);
}

- (void) savePreferences
{
    [batchSettings savePrefs];
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
    
    self.sheetMessage = @"Normalmapping...";
    [batchWindow beginSheet:progressSheet completionHandler:^(NSModalResponse returnCode) {
        [progressSheet orderOut:nil];
    }];
    
    //
    // Image analysis is expensive, so we'll spawn a thread
    //
    
    [NSThread detachNewThreadSelector: @selector( normalmapFiles: ) toTarget: self withObject: bumpmaps];
}

#pragma mark - File analysis

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
            [extension isEqualToString: @"psd"] );
}

- (NSMutableArray<NSURL*>*) gatherFiles: (NSArray<NSURL*> *) fileURLs;
{
    NSFileManager *fm = [NSFileManager defaultManager];
    
    //
    // we'll stick addable images here
    //
    
    NSMutableArray<NSURL*> *result = [NSMutableArray array];
    
    for ( NSURL *fileURL in fileURLs )
    {
        BOOL isDir = NO;
        NSString *path = @([fileURL fileSystemRepresentation]);
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
                        [result addObject: [NSURL fileURLWithPath:actualPath]];
                    }
                }
            }
            else
            {
                if ( [self canOpenFileWithExtension: [path pathExtension]] )
                {
                    [result addObject: fileURL];
                }
            }
        }
    }
    
    return result;
}

- (void) loadDroppedFiles: (NSArray<NSURL*>*) fileURLs
{
    //
    // gather image files we recognize
    //
    
    fileURLs = [self gatherFiles: fileURLs];
    NSMutableArray<BatchEntry*> *entries = [NSMutableArray array];
    
    //
    // now we know how many we need to examine
    //
    
    self.sheetProcessStepTotal = fileURLs.count;
    self.sheetProcessStep = 0;
    self.sheetProcessIndeterminate = NO;
    
    //
    // Now load batch entries
    //
    
    for ( NSURL *fileURL in fileURLs )
    {
        BatchEntry *be = [BatchEntry fromFileURL: fileURL];
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

- (void) fileAddingAnalysisComplete: (NSMutableArray<BatchEntry*>*) newEntries
{
    self.sheetProcessRunning = NO;
    
    [NSApp endSheet: progressSheet];
    
    for ( BatchEntry *entry in newEntries )
    {
        if ( entry.looksLikeBumpmap )
        {
            [bumpmaps addObject:entry];
        }
        else
        {
            [nonBumpmaps addObject:entry];
        }
    }
    
    [bumpmapsCollectionView reloadData];
    self.showDropMessage = (bumpmaps.count==0) && (nonBumpmaps.count==0);
}

#pragma mark - Normal Mapping

- (void) normalmapFiles: (NSArray<BatchEntry*>*) entries
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
    [NSApp endSheet: progressSheet];
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

#pragma mark - NSCollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(NSCollectionView *)collectionView
{
    return [nonBumpmaps count] > 0 ? 2 : 1;
}

- (NSInteger)collectionView:(NSCollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    switch(section)
    {
        case 0:
            return [bumpmaps count];
        case 1:
            return [nonBumpmaps count];
    }
    return 0;
}

- (NSCollectionViewItem *)collectionView:(NSCollectionView *)collectionView itemForRepresentedObjectAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableArray<BatchEntry*> *source = nil;
    switch(indexPath.section)
    {
        case 0: source = bumpmaps; break;
        case 1: source = nonBumpmaps; break;
        default: return nil;
    }
    
    BatchEntry *entry = source[indexPath.item];
    BatchCollectionViewItem *item = [collectionView makeItemWithIdentifier:kBatchCollectionViewItemIdentifier forIndexPath:indexPath];
    if (item != nil)
    {
        item.thumbnailTitle = [[entry.filePath lastPathComponent] stringByDeletingPathExtension];
        item.thumbnailImage = entry.thumb;
    }
    else
    {
        DebugLog(@"Unable to vend item %d section %d", indexPath.item, indexPath.section);
    }

    return item;
}

#pragma mark - NSCollectionViewDelegate

- (NSDragOperation)collectionView:(NSCollectionView *)collectionView validateDrop:(id <NSDraggingInfo>)draggingInfo proposedIndexPath:(NSIndexPath * __nonnull * __nonnull)proposedDropIndexPath dropOperation:(NSCollectionViewDropOperation *)proposedDropOperation
{
    switch((*proposedDropIndexPath).section)
    {
        case 0:
            return NSDragOperationLink;
        default:
            break;
    }
    return NSDragOperationNone;
}

- (BOOL)collectionView:(NSCollectionView *)collectionView acceptDrop:(id <NSDraggingInfo>)draggingInfo indexPath:(NSIndexPath *)indexPath dropOperation:(NSCollectionViewDropOperation)dropOperation
{
    NSMutableArray<NSURL*> *droppedFileURLs = [NSMutableArray array];
    [draggingInfo enumerateDraggingItemsWithOptions:NSDraggingItemEnumerationConcurrent
                                            forView:collectionView
                                            classes:@[[NSURL class]]
                                      searchOptions:@{
                                                      NSPasteboardURLReadingFileURLsOnlyKey : @(1)}
                                         usingBlock:^(NSDraggingItem * _Nonnull draggingItem, NSInteger idx, BOOL * _Nonnull stop) {
                                             NSURL *url = draggingItem.item;
                                             [droppedFileURLs addObject:url];
                                         }];

    [self addFiles:droppedFileURLs];
    return YES;
}

@end
