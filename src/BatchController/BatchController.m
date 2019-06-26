//
//  Controller.m
//  FilteredImageList
//
//  Created by Shamyl Zakariya on 3/12/09.
//  Copyright 2009-2019 Shamyl Zakariya. All rights reserved.
//

#import "BatchController.h"

#import "AppDelegate.h"
#import "BatchCollectionViewItem.h"
#import "BatchCollectionViewSectionHeader.h"
#import "BatchOperation.h"

#define kBatchCollectionViewItemIdentifier @"batchCollectionViewItem"
#define kBatchCollectionViewSectionHeaderIdentifier @"batchCollectionSectionHeader"

@interface BatchController (Private)

- (BOOL)canOpenFileWithExtension:(NSString*)extension;
- (NSMutableArray<NSURL*>*)gatherFiles:(NSArray<NSURL*>*)fileURLs;
- (void)loadDroppedFiles:(NSArray<NSURL*>*)fileURLs;
- (void)fileAddingAnalysisComplete:(NSMutableArray<BatchEntry*>*)addableFiles;
- (void)normalmapFiles:(NSArray<BatchEntry*>*)files;

@end

@implementation BatchController

- (id)init
{
    if (self = [super init]) {
        batchSettings = [[BatchSettings alloc] init];
        bumpmaps = [[NSMutableArray alloc] init];
        nonBumpmaps = [[NSMutableArray alloc] init];

        [[NSBundle mainBundle] loadNibNamed:@"BatchWindow" owner:self topLevelObjects:nil];
    }

    return self;
}

- (void)awakeFromNib
{
    self.showDropMessage = YES;
    self.iconSize = 128;

    bumpmapsCollectionView.dataSource = self;
    bumpmapsCollectionView.delegate = self;
    bumpmapsCollectionView.selectable = YES;
    bumpmapsCollectionView.allowsMultipleSelection = YES;

    NSNib* itemNib = [[NSNib alloc] initWithNibNamed:@"BatchCollectionViewItem" bundle:[NSBundle mainBundle]];
    [bumpmapsCollectionView registerNib:itemNib forItemWithIdentifier:kBatchCollectionViewItemIdentifier];

    NSNib* headerNib = [[NSNib alloc] initWithNibNamed:@"BatchCollectionViewSectionHeader" bundle:[NSBundle mainBundle]];
    [bumpmapsCollectionView registerNib:headerNib forSupplementaryViewOfKind:NSCollectionElementKindSectionHeader withIdentifier:kBatchCollectionViewSectionHeaderIdentifier];

    [bumpmapsCollectionView registerForDraggedTypes:@[ NSURLPboardType ]];

    if (@available(macOS 10.13, *)) {
        bumpmapsCollectionView.backgroundColors = @[ [NSColor colorNamed:@"BatchViewBackground"] ];
    } else {
        bumpmapsCollectionView.backgroundColors = @[ [NSColor colorWithDeviceWhite:0.9 alpha:1] ];
    }

    [batchWindow makeKeyAndOrderFront:self];
    batchWindow.defaultButtonCell = runButton.cell;
}

- (void)dismiss
{
    // progressSheet has to be strong ptr because it's selectively shown at runtime
    // however, keeping it strong causes memory leak, so we have to explicitly nil it
    progressSheet = nil;

    if ([batchWindow isVisible]) {
        [batchWindow orderOut:self];
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

- (void)setIconSize:(CGFloat)size
{
    iconSize = size;
    bumpmapsCollectionViewFL.itemSize = NSMakeSize(size * 1.3, size);
}

- (void)setShowDropMessage:(BOOL)sdm
{
    if (sdm != showDropMessage) {
        showDropMessage = sdm;
    }
}

- (NSInteger)bumpmapCount
{
    return [bumpmaps count];
}

- (NSInteger)nonBumpmapCount
{
    return [nonBumpmaps count];
}

- (void)addFiles:(NSArray<NSURL*>*)fileURLs
{
    if (self.sheetProcessRunning)
        return;
    self.sheetProcessRunning = YES;

    //
    // Mark indeterminate progress until we've gathered up the file listing
    // and know how many files we actually need to process.
    //

    self.sheetProcessIndeterminate = YES;
    self.sheetMessage = @"Searching dropped files for bumpmaps...";
    [batchWindow beginSheet:progressSheet
          completionHandler:^(NSModalResponse returnCode) {
              [progressSheet orderOut:self];
          }];

    //
    // Image analysis is expensive, so we'll spawn a thread
    //

    WEAK_SELF;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        STRONG_SELF;
        [strongSelf loadDroppedFiles:fileURLs];
    });
}

- (void)removeFiles:(NSArray<NSURL*>*)fileURLs
{
    DebugLog(@"remove %@", [fileURLs componentsJoinedByString:@"\n"]);
}

- (void)savePreferences
{
    [batchSettings savePrefs];
}

- (IBAction)executeBatch:(id)sender
{
    if (self.sheetProcessRunning)
        return;
    self.sheetProcessRunning = YES;

    //
    // Mark indeterminate progress until we've gathered up the file listing
    // and know how many files we actually need to process.
    //

    self.sheetProcessIndeterminate = YES;

    self.sheetMessage = @"Normalmapping...";
    [batchWindow beginSheet:progressSheet
          completionHandler:^(NSModalResponse returnCode) {
              [progressSheet orderOut:nil];
          }];

    //
    // Image analysis is expensive, so we'll spawn a thread
    //

    WEAK_SELF;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        STRONG_SELF;
        [strongSelf normalmapFiles:bumpmaps];
    });
}

#pragma mark - File analysis

- (BOOL)canOpenFileWithExtension:(NSString*)extension
{
    extension = [extension lowercaseString];
    return ([extension isEqualToString:@"tif"] ||
        [extension isEqualToString:@"tiff"] ||
        [extension isEqualToString:@"jp2"] ||
        [extension isEqualToString:@"jpg"] ||
        [extension isEqualToString:@"jpeg"] ||
        [extension isEqualToString:@"png"] ||
        [extension isEqualToString:@"gif"] ||
        [extension isEqualToString:@"psd"]);
}

- (NSMutableArray<NSURL*>*)gatherFiles:(NSArray<NSURL*>*)fileURLs;
{
    NSFileManager* fm = [NSFileManager defaultManager];

    //
    // we'll stick addable images here
    //

    NSMutableArray<NSURL*>* result = [NSMutableArray array];

    for (NSURL* fileURL in fileURLs) {
        BOOL isDir = NO;
        NSString* path = @([fileURL fileSystemRepresentation]);
        if ([fm fileExistsAtPath:path isDirectory:&isDir]) {
            if (isDir) {
                //
                // subpaths performs a complete filesystem traversal -- no need to recurse!
                //

                for (NSString* subpath in [fm subpathsAtPath:path]) {
                    NSString* actualPath = [path stringByAppendingPathComponent:subpath];
                    if ([self canOpenFileWithExtension:[actualPath pathExtension]]) {
                        [result addObject:[NSURL fileURLWithPath:actualPath]];
                    }
                }
            } else {
                if ([self canOpenFileWithExtension:[path pathExtension]]) {
                    [result addObject:fileURL];
                }
            }
        }
    }

    return result;
}

- (void)loadDroppedFiles:(NSArray<NSURL*>*)fileURLs
{
    WEAK_SELF;

    //
    // gather image files we recognize
    //

    fileURLs = [self gatherFiles:fileURLs];
    NSMutableArray<BatchEntry*>* entries = [NSMutableArray array];

    //
    // now we know how many we need to examine
    //

    dispatch_async(dispatch_get_main_queue(), ^{
        STRONG_SELF;

        strongSelf.sheetProcessStepTotal = fileURLs.count;
        strongSelf.sheetProcessStep = 0;
        strongSelf.sheetProcessIndeterminate = NO;
    });

    //
    // Now load batch entries
    //

    for (NSURL* fileURL in fileURLs) {
        BatchEntry* be = [BatchEntry fromFileURL:fileURL];
        if (be) {
            [entries addObject:be];
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            STRONG_SELF;
            strongSelf.sheetProcessStep = strongSelf.sheetProcessStep + 1;
            strongSelf.sheetProcessProgress = (float)strongSelf.sheetProcessStep / (float)strongSelf.sheetProcessStepTotal;
        });
    }

    //
    // we're done, notify self on main thread
    //

    dispatch_async(dispatch_get_main_queue(), ^{
        STRONG_SELF;
        [strongSelf fileAddingAnalysisComplete:entries];
    });
}

- (void)fileAddingAnalysisComplete:(NSMutableArray<BatchEntry*>*)newEntries
{
    self.sheetProcessRunning = NO;

    [NSApp endSheet:progressSheet];

    for (BatchEntry* entry in newEntries) {
        if (entry.looksLikeBumpmap) {
            [bumpmaps addObject:entry];
        } else {
            [nonBumpmaps addObject:entry];
        }
    }

    [bumpmapsCollectionView reloadData];
    self.showDropMessage = (bumpmaps.count == 0) && (nonBumpmaps.count == 0);
}

#pragma mark - Normal Mapping

- (void)normalmapFiles:(NSArray<BatchEntry*>*)entries
{
    WEAK_SELF;

    dispatch_async(dispatch_get_main_queue(), ^{
        STRONG_SELF;
        strongSelf.sheetProcessStepTotal = entries.count;
        strongSelf.sheetProcessStep = 0;
        strongSelf.sheetProcessIndeterminate = NO;
    });

    //
    // Now load batch entries
    //

    for (BatchEntry* entry in entries) {
        BatchOperation* op = [[BatchOperation alloc] initWithEntry:entry andSettings:batchSettings];
        [op run];

        dispatch_async(dispatch_get_main_queue(), ^{
            STRONG_SELF;
            strongSelf.sheetProcessStep = strongSelf.sheetProcessStep + 1;
            strongSelf.sheetProcessProgress = (float)strongSelf.sheetProcessStep / (float)strongSelf.sheetProcessStepTotal;
        });
    }

    //
    // we're done, notify self on main thread
    //

    dispatch_async(dispatch_get_main_queue(), ^{
        self.sheetProcessRunning = NO;
        [NSApp endSheet:progressSheet];
    });
}

#pragma mark -
#pragma mark NSWindow Delegate

- (void)windowWillClose:(NSNotification*)notification
{
    //
    //    This is stupid hacky, but the menu-state is maintained in the AppDelegate
    //    and this means that when the user hits command-w or clicks the close button,
    //    and the window is manually closed, we need to keep menu state in sync by
    //    going through this way.
    //

    AppDelegate* delegate = [NSApp delegate];
    if (delegate.batchWindowShowing) {
        delegate.batchWindowShowing = NO;
    }
}

#pragma mark - NSCollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(NSCollectionView*)collectionView
{
    return 2;
}

- (NSInteger)collectionView:(NSCollectionView*)collectionView numberOfItemsInSection:(NSInteger)section
{
    switch (section) {
    case 0:
        return [bumpmaps count];
    case 1:
        return [nonBumpmaps count];
    }
    return 0;
}

- (NSCollectionViewItem*)collectionView:(NSCollectionView*)collectionView itemForRepresentedObjectAtIndexPath:(NSIndexPath*)indexPath
{
    NSMutableArray<BatchEntry*>* source = nil;
    switch (indexPath.section) {
    case 0:
        source = bumpmaps;
        break;
    case 1:
        source = nonBumpmaps;
        break;
    default:
        return nil;
    }

    BatchEntry* entry = source[indexPath.item];
    BatchCollectionViewItem* item = [collectionView makeItemWithIdentifier:kBatchCollectionViewItemIdentifier forIndexPath:indexPath];
    if (item != nil) {
        item.batchEntry = entry;
    } else {
        DebugLog(@"Unable to vend item %d section %d", indexPath.item, indexPath.section);
    }

    return item;
}

- (NSView*)collectionView:(NSCollectionView*)collectionView viewForSupplementaryElementOfKind:(NSCollectionViewSupplementaryElementKind)kind atIndexPath:(NSIndexPath*)indexPath
{
    if ([kind isEqualToString:NSCollectionElementKindSectionHeader]) {
        BatchCollectionViewSectionHeader* header = [collectionView makeSupplementaryViewOfKind:NSCollectionElementKindSectionHeader withIdentifier:kBatchCollectionViewSectionHeaderIdentifier forIndexPath:indexPath];
        switch (indexPath.section) {
        case 0:
            [header.sectionTitle setStringValue:@"Bumpmaps"];
            [header.itemCount setStringValue:[NSString stringWithFormat:@"%lu", [bumpmaps count]]];
            break;
        case 1:
            [header.sectionTitle setStringValue:@"Non-bumpmaps"];
            [header.itemCount setStringValue:[NSString stringWithFormat:@"%lu", [nonBumpmaps count]]];
            break;
        }
        return header;
    }

    return [collectionView makeSupplementaryViewOfKind:kind withIdentifier:@"" forIndexPath:indexPath];
}

#pragma mark - NSCollectionViewDelegate

- (NSDragOperation)collectionView:(NSCollectionView*)collectionView validateDrop:(id<NSDraggingInfo>)draggingInfo proposedIndexPath:(NSIndexPath* __nonnull* __nonnull)proposedDropIndexPath dropOperation:(NSCollectionViewDropOperation*)proposedDropOperation
{
    switch ((*proposedDropIndexPath).section) {
    case 0:
        return NSDragOperationGeneric;
    default:
        break;
    }
    return NSDragOperationNone;
}

- (BOOL)collectionView:(NSCollectionView*)collectionView acceptDrop:(id<NSDraggingInfo>)draggingInfo indexPath:(NSIndexPath*)indexPath dropOperation:(NSCollectionViewDropOperation)dropOperation
{
    NSMutableArray<NSURL*>* droppedFileURLs = [NSMutableArray array];
    [draggingInfo enumerateDraggingItemsWithOptions:NSDraggingItemEnumerationConcurrent
                                            forView:collectionView
                                            classes:@ [[NSURL class]]
                                            searchOptions:@{
                                                NSPasteboardURLReadingFileURLsOnlyKey : @(1)
                                            }
                                         usingBlock:^(NSDraggingItem* _Nonnull draggingItem, NSInteger idx, BOOL* _Nonnull stop) {
                                             NSURL* url = draggingItem.item;
                                             [droppedFileURLs addObject:url];
                                         }];

    [self addFiles:droppedFileURLs];
    return YES;
}

- (NSSet<NSIndexPath*>*)collectionView:(NSCollectionView*)collectionView shouldChangeItemsAtIndexPaths:(NSSet<NSIndexPath*>*)indexPaths toHighlightState:(NSCollectionViewItemHighlightState)highlightState
{
    return indexPaths;
}

- (NSSet<NSIndexPath*>*)collectionView:(NSCollectionView*)collectionView shouldSelectItemsAtIndexPaths:(NSSet<NSIndexPath*>*)indexPaths
{
    // all selection is OK
    return indexPaths;
}

- (NSSet<NSIndexPath*>*)collectionView:(NSCollectionView*)collectionView shouldDeselectItemsAtIndexPaths:(NSSet<NSIndexPath*>*)indexPaths
{
    // all deselection is OK
    return indexPaths;
}

- (void)collectionView:(NSCollectionView*)collectionView didSelectItemsAtIndexPaths:(NSSet<NSIndexPath*>*)indexPaths
{
}

- (void)collectionView:(NSCollectionView*)collectionView didDeselectItemsAtIndexPaths:(NSSet<NSIndexPath*>*)indexPaths
{
}

#pragma mark - NSCollectionViewDelegateFlowLayout

- (NSSize)collectionView:(NSCollectionView*)collectionView layout:(NSCollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    return NSMakeSize(0, 80);
}

@end
