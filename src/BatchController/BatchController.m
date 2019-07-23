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
#import "BatchCollectionViewItemDropPlaceholder.h"
#import "BatchCollectionViewSectionHeader.h"
#import "BatchOperation.h"

#define kBatchCollectionViewItemIdentifier @"batchCollectionViewItem"
#define kBatchCollectionViewItemDropPlaceholderIdentifier @"batchCollectionViewItemDropPlaceholderIdentifier"
#define kBatchCollectionViewSectionHeaderIdentifier @"batchCollectionSectionHeader"
#define kUserSaveLocationTag 100
const NSSize kItemSize = { 200, 140 };

@interface BatchController (Private)

- (BOOL)isEmpty;
- (void)requestUserSaveDestination;
- (void)addUserSaveDestination:(NSURL*)destination;
- (NSMutableArray<NSURL*>*)gatherFiles:(NSArray<NSURL*>*)fileURLs;
- (void)loadDroppedFiles:(NSArray<NSURL*>*)fileURLs;
- (void)removeItems:(NSSet<NSIndexPath*>*)items;
- (void)addExcludedItemsToBatch:(id)sender;
- (void)discardExcludedItems:(id)sender;
- (void)updateExcludedSectionHeaderAnimated:(BOOL)animated;
- (void)moveEntry:(BatchEntry*)batchEntry toBatch:(BOOL)includedInBatch;
- (void)prepareItem:(BatchCollectionViewItem*)item forBatchEntry:(BatchEntry*)entry inBatch:(BOOL)inBatch;
- (void)fileAddingAnalysisComplete:(NSMutableArray<BatchEntry*>*)addableFiles;
- (void)normalmapFiles:(NSArray<BatchEntry*>*)files;
- (NSSet<NSIndexPath*>*)userInteractableIndexPathsFrom:(NSSet<NSIndexPath*>*)proposedIndexPaths;

@end

@implementation BatchController

- (id)init
{
    if (self = [super init]) {
        batchSettings = [[BatchSettings alloc] init];
        batch = [[NSMutableArray alloc] init];
        excludedFromBatch = [[NSMutableArray alloc] init];

        [[NSBundle mainBundle] loadNibNamed:@"BatchWindow" owner:self topLevelObjects:nil];
    }

    return self;
}

- (void)awakeFromNib
{
    NSAnimationContext.currentContext.duration = 0.2;

    //
    //  Configure the batch collection view
    //

    batchCollectionView.dataSource = self;
    batchCollectionView.delegate = self;
    batchCollectionView.selectable = YES;
    batchCollectionView.allowsMultipleSelection = YES;
    batchCollectionView.batchController = self;
    batchCollectionViewFlowLayout.itemSize = kItemSize;

    NSNib* itemNib = [[NSNib alloc] initWithNibNamed:@"BatchCollectionViewItem" bundle:[NSBundle mainBundle]];
    [batchCollectionView registerNib:itemNib forItemWithIdentifier:kBatchCollectionViewItemIdentifier];

    NSNib* placeholderNib = [[NSNib alloc] initWithNibNamed:@"BatchCollectionViewItemDropPlaceholder" bundle:[NSBundle mainBundle]];
    [batchCollectionView registerNib:placeholderNib forItemWithIdentifier:kBatchCollectionViewItemDropPlaceholderIdentifier];

    NSNib* headerNib = [[NSNib alloc] initWithNibNamed:@"BatchCollectionViewSectionHeader" bundle:[NSBundle mainBundle]];
    [batchCollectionView registerNib:headerNib forSupplementaryViewOfKind:NSCollectionElementKindSectionHeader withIdentifier:kBatchCollectionViewSectionHeaderIdentifier];

    // set up DnD - specify we accept file drops, and dragging internally (not dragging out to other apps)
    [batchCollectionView registerForDraggedTypes:@[ NSURLPboardType ]];
    [batchCollectionView setDraggingSourceOperationMask:NSDragOperationEvery forLocal:YES];

    //
    // sync up user save dir popup
    // NOTE: We don't use cocoa bindings with the popup, because it
    // led to some oddities where at startup the menu attempted to select
    // an item which mapped to a tag which hasn't been built yet
    //

    if (batchSettings.userSaveDestination != nil) {
        previousSaveLocationPopupTag = kUserSaveLocationTag;
        [self addUserSaveDestination:batchSettings.userSaveDestination];
    } else {
        previousSaveLocationPopupTag = 0;
    }

    if (batchSettings.saveDestinationType == NMSaveDestinationInPlace) {
        [saveLocationPopup selectItemWithTag:NMSaveDestinationInPlace];
    }

    //
    //  Finally show the window
    //

    self.showDropMessage = YES;
    batchWindow.defaultButtonCell = runButton.cell;
    [batchWindow makeKeyAndOrderFront:self];
}

+ (BOOL)canHandleURL:(NSURL*)url
{
    NSFileManager* fm = [NSFileManager defaultManager];
    NSWorkspace* ws = [NSWorkspace sharedWorkspace];
    NSString* path = @(url.fileSystemRepresentation);
    BOOL isDir = NO;

    if ([fm fileExistsAtPath:path isDirectory:&isDir]) {
        if (isDir) {
            // directories are fine
            return YES;
        }

        NSString* fileUti = [ws typeOfFile:path error:nil];
        if (fileUti) {
            return UTTypeConformsTo((__bridge CFStringRef)fileUti, (__bridge CFStringRef) @"public.image");
        }
    }

    return NO;
}

- (void)dismiss
{
    [batchSettings savePrefs];

    // progressSheet has to be strong ptr because it's selectively shown at runtime
    // however, keeping it strong causes memory leak, so we have to explicitly nil it
    progressSheet = nil;

    if ([batchWindow isVisible]) {
        [batchWindow orderOut:self];
    }
}

#pragma mark - Public Interface

@synthesize batchSettings;
@synthesize batchWindow = batchWindow;
@synthesize sheetProcessStepTotal;
@synthesize sheetProcessStep;
@synthesize sheetProcessRunning;
@synthesize sheetProcessIndeterminate;
@synthesize sheetProcessProgress;
@synthesize sheetMessage;
@synthesize showDropMessage;

- (void)setShowDropMessage:(BOOL)sdm
{
    if (sdm != showDropMessage) {
        showDropMessage = sdm;
        dropMessage.animator.hidden = !showDropMessage;
    }
}

- (void)addFiles:(NSArray<NSURL*>*)fileURLs
{
    if (self.sheetProcessRunning)
        return;
    self.sheetProcessRunning = YES;

    WEAK_SELF;

    //
    // Mark indeterminate progress until we've gathered up the file listing
    // and know how many files we actually need to process.
    //

    self.sheetProcessIndeterminate = YES;
    self.sheetMessage = @"Searching dropped files for bumpmaps...";
    [batchWindow beginSheet:progressSheet
          completionHandler:^(NSModalResponse returnCode) {
              STRONG_SELF;
              if (!strongSelf)
                  return;

              [strongSelf->progressSheet orderOut:strongSelf];
          }];

    //
    // Image analysis is expensive, so we'll spawn a thread
    //

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        STRONG_SELF;
        if (!strongSelf)
            return;

        [strongSelf loadDroppedFiles:fileURLs];
    });
}

- (IBAction)executeBatch:(id)sender
{
    if (self.sheetProcessRunning) {
        return;
    }

    self.sheetProcessRunning = YES;

    //
    // Mark indeterminate progress until we've gathered up the file listing
    // and know how many files we actually need to process.
    //

    self.sheetProcessIndeterminate = YES;
    self.sheetMessage = @"Normalmapping...";

    WEAK_SELF;
    [batchWindow beginSheet:progressSheet
          completionHandler:^(NSModalResponse returnCode) {
              STRONG_SELF;
              if (!strongSelf)
                  return;
              [strongSelf->progressSheet orderOut:nil];
          }];

    //
    // Image processing is expensive, so we'll spawn a thread
    //

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        STRONG_SELF;
        if (!strongSelf)
            return;

        [strongSelf normalmapFiles:strongSelf->batch];
    });
}

- (IBAction)onSaveLocationPopupAction:(id)sender
{
    NSMenuItem* selected = saveLocationPopup.selectedItem;
    if (selected != nil) {
        switch (selected.tag) {
        case NMSaveDestinationUserSelected:
            batchSettings.saveDestinationType = NMSaveDestinationUserSelected;
            [self requestUserSaveDestination];
            break;
        case NMSaveDestinationInPlace:
            batchSettings.saveDestinationType = NMSaveDestinationInPlace;
            previousSaveLocationPopupTag = selected.tag;
            break;
        case kUserSaveLocationTag:
            batchSettings.saveDestinationType = NMSaveDestinationUserSelected;
            previousSaveLocationPopupTag = selected.tag;
            break;
        }
    }
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
        return batch.count + 1;
    case 1:
        return excludedFromBatch.count + 1;
    }
    return 0;
}

- (NSCollectionViewItem*)collectionView:(NSCollectionView*)collectionView itemForRepresentedObjectAtIndexPath:(NSIndexPath*)indexPath
{
    BOOL isBatchSection = indexPath.section == 0;
    NSMutableArray<BatchEntry*>* source = isBatchSection ? batch : excludedFromBatch;

    if (indexPath.item < source.count) {
        BatchCollectionViewItem* item = [collectionView makeItemWithIdentifier:kBatchCollectionViewItemIdentifier forIndexPath:indexPath];
        BatchEntry* entry = source[indexPath.item];
        [self prepareItem:item forBatchEntry:entry inBatch:isBatchSection];
        return item;
    }

    // vend the drop placeholder view
    BatchCollectionViewItemDropPlaceholder* item = [collectionView makeItemWithIdentifier:kBatchCollectionViewItemDropPlaceholderIdentifier forIndexPath:indexPath];

    return item;
}

- (NSView*)collectionView:(NSCollectionView*)collectionView viewForSupplementaryElementOfKind:(NSCollectionViewSupplementaryElementKind)kind atIndexPath:(NSIndexPath*)indexPath
{
    if ([kind isEqualToString:NSCollectionElementKindSectionHeader] && indexPath.section == 1) {
        excludedFromBatchSectionHeader = [collectionView makeSupplementaryViewOfKind:NSCollectionElementKindSectionHeader withIdentifier:kBatchCollectionViewSectionHeaderIdentifier forIndexPath:indexPath];

        [excludedFromBatchSectionHeader.sectionTitle setStringValue:NSLocalizedString(@"Excluded", "Title of section holding images which don't appear to be bumpmaps")];
        [excludedFromBatchSectionHeader.addToBatchButton setHidden:NO];
        [excludedFromBatchSectionHeader.addToBatchButton setEnabled:YES];

        [excludedFromBatchSectionHeader.addToBatchButton setTarget:self];
        [excludedFromBatchSectionHeader.addToBatchButton setAction:@selector(addExcludedItemsToBatch:)];

        [excludedFromBatchSectionHeader.discardItems setTarget:self];
        [excludedFromBatchSectionHeader.discardItems setAction:@selector(discardExcludedItems:)];

        [self updateExcludedSectionHeaderAnimated:NO];

        return excludedFromBatchSectionHeader;
    }

    return [collectionView makeSupplementaryViewOfKind:kind withIdentifier:@"" forIndexPath:indexPath];
}

#pragma mark - NSCollectionViewDelegate

- (NSSet<NSIndexPath*>*)collectionView:(NSCollectionView*)collectionView shouldChangeItemsAtIndexPaths:(NSSet<NSIndexPath*>*)indexPaths toHighlightState:(NSCollectionViewItemHighlightState)highlightState
{
    return [self userInteractableIndexPathsFrom:indexPaths];
}

- (NSSet<NSIndexPath*>*)collectionView:(NSCollectionView*)collectionView shouldSelectItemsAtIndexPaths:(NSSet<NSIndexPath*>*)indexPaths
{
    return [self userInteractableIndexPathsFrom:indexPaths];
}

- (NSSet<NSIndexPath*>*)collectionView:(NSCollectionView*)collectionView shouldDeselectItemsAtIndexPaths:(NSSet<NSIndexPath*>*)indexPaths
{
    return [self userInteractableIndexPathsFrom:indexPaths];
}

- (BOOL)collectionView:(NSCollectionView*)collectionView canDragItemsAtIndexPaths:(NSSet<NSIndexPath*>*)indexPaths withEvent:(NSEvent*)event
{
    return YES;
}

- (id<NSPasteboardWriting>)collectionView:(NSCollectionView*)collectionView pasteboardWriterForItemAtIndexPath:(NSIndexPath*)indexPath
{
    NSUInteger count = indexPath.section == 0 ? batch.count : excludedFromBatch.count;
    if (indexPath.item < count) {
        BatchCollectionViewItem* item = (BatchCollectionViewItem*)[batchCollectionView itemAtIndexPath:indexPath];
        return item.batchEntry.fileURL;
    }
    return nil;
}

- (void)collectionView:(NSCollectionView*)collectionView draggingSession:(NSDraggingSession*)session willBeginAtPoint:(NSPoint)screenPoint forItemsAtIndexPaths:(NSSet<NSIndexPath*>*)indexPaths
{
    indexPathsOfDraggingItems = indexPaths;
    draggingItems = [NSMutableArray array];
    for (NSIndexPath* indexPath in indexPaths) {
        BatchCollectionViewItem* item = (BatchCollectionViewItem*)[collectionView itemAtIndexPath:indexPath];
        [draggingItems addObject:item.batchEntry];
    }
}

- (NSDragOperation)collectionView:(NSCollectionView*)collectionView validateDrop:(id<NSDraggingInfo>)draggingInfo proposedIndexPath:(NSIndexPath* _Nonnull*)proposedDropIndexPath dropOperation:(NSCollectionViewDropOperation*)proposedDropOperation
{
    if (draggingItems != nil) {
        // NOTE: I never seem to get NSCollectionViewDropOn, only 'Before
        //        if (*proposedDropOperation == NSCollectionViewDropOn) {
        //            *proposedDropOperation = NSCollectionViewDropBefore;
        //        }

        NSArray<BatchEntry*>* source = (*proposedDropIndexPath).section == 0 ? batch : excludedFromBatch;
        if ((*proposedDropIndexPath).item > source.count) {
            *proposedDropIndexPath = [NSIndexPath indexPathForItem:source.count inSection:(*proposedDropIndexPath).section];
        }

        return NSDragOperationMove;
    }
    return NSDragOperationNone;
}

- (BOOL)collectionView:(NSCollectionView*)collectionView acceptDrop:(id<NSDraggingInfo>)draggingInfo indexPath:(NSIndexPath*)dropIndexPath dropOperation:(NSCollectionViewDropOperation)dropOperation;
{
    if (draggingItems != nil) {
        // 1) remove these items from batch and excludedFromBatch

        NSMutableIndexSet* indexesToRemoveFromBatch = [NSMutableIndexSet indexSet];
        NSMutableIndexSet* indexesToRemoveFromExcluded = [NSMutableIndexSet indexSet];
        for (NSIndexPath* indexPath in indexPathsOfDraggingItems) {
            switch (indexPath.section) {
            case 0:
                [indexesToRemoveFromBatch addIndex:indexPath.item];
                break;
            case 1:
                [indexesToRemoveFromExcluded addIndex:indexPath.item];
                break;
            }
        }

        [batch removeObjectsAtIndexes:indexesToRemoveFromBatch];
        [excludedFromBatch removeObjectsAtIndexes:indexesToRemoveFromExcluded];

        WEAK_SELF;
        [[batchCollectionView animator]
            performBatchUpdates:^{
                STRONG_SELF;
                if (!strongSelf)
                    return;

                // 2) remove the index paths from the collection view
                [strongSelf->batchCollectionView deleteItemsAtIndexPaths:strongSelf->indexPathsOfDraggingItems];

                // 3) add draggingItems to the right position in batch or excludedFromBatch
                // note 1: dropOperation will always be NSCollectionViewDropBefore here
                // note 2: adding items using reverse object enumerator so they land in same order as collected
                NSMutableArray<BatchEntry*>* destination = dropIndexPath.section == 0 ? strongSelf->batch : strongSelf->excludedFromBatch;
                NSIndexPath* destIndexPath = [NSIndexPath indexPathForItem:MIN(dropIndexPath.item, destination.count) inSection:dropIndexPath.section];

                for (BatchEntry* entry in strongSelf->draggingItems.reverseObjectEnumerator) {
                    [destination insertObject:entry atIndex:destIndexPath.item];
                }

                // 4) add the iems to the collection view
                for (int i = 0; i < strongSelf->draggingItems.count; i++) {
                    [strongSelf->batchCollectionView insertItemsAtIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:destIndexPath.item + i inSection:destIndexPath.section]]];
                }
            }
            completionHandler:^(BOOL finished) {
                STRONG_SELF;
                if (!strongSelf)
                    return;

                [strongSelf updateExcludedSectionHeaderAnimated:YES];
            }];

        // approve the drop
        return YES;
    }
    return NO;
}

- (void)collectionView:(NSCollectionView*)collectionView draggingSession:(NSDraggingSession*)session endedAtPoint:(NSPoint)screenPoint dragOperation:(NSDragOperation)operation
{
    // we're done
    indexPathsOfDraggingItems = nil;
    draggingItems = nil;
}

#pragma mark - NSCollectionViewDelegateFlowLayout

- (NSSize)collectionView:(NSCollectionView*)collectionView layout:(NSCollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    switch (section) {
    case 0:
        return NSMakeSize(0, 0);
    case 1:
        return NSMakeSize(0, 40);
    }
    return NSZeroSize;
}

#pragma mark - Keyboard interaction

- (void)deleteForward:(id)sender
{
    [batchCollectionView reloadData];
    //    if (batchWindow.firstResponder == batchCollectionView) {
    //        [self removeItems:batchCollectionView.selectionIndexPaths];
    //    }
}

- (void)deleteBackward:(id)sender
{
    if (batchWindow.firstResponder == batchCollectionView) {
        [self removeItems:batchCollectionView.selectionIndexPaths];
    }
}

#pragma mark - Private

- (BOOL)isEmpty
{
    return batch.count == 0 && excludedFromBatch.count == 0;
}

- (void)requestUserSaveDestination
{
    NSOpenPanel* panel = [NSOpenPanel openPanel];
    panel.canChooseFiles = NO;
    panel.canChooseDirectories = YES;
    panel.allowsMultipleSelection = NO;

    WEAK_SELF;
    [panel beginSheetModalForWindow:self.batchWindow
                  completionHandler:^(NSModalResponse result) {
                      STRONG_SELF;
                      if (!strongSelf)
                          return;

                      switch (result) {
                      case NSFileHandlingPanelOKButton:
                          DebugLog(@"user selected OK, urls: %@", panel.URLs.firstObject);
                          strongSelf.batchSettings.userSaveDestination = panel.URLs.firstObject;
                          [strongSelf addUserSaveDestination:strongSelf.batchSettings.userSaveDestination];
                          break;
                      default:
                          // user cancelled, select the previously selected item
                          [strongSelf->saveLocationPopup selectItemWithTag:strongSelf->previousSaveLocationPopupTag];
                          break;
                      }
                  }];
}

- (void)addUserSaveDestination:(NSURL*)destination
{
    NSInteger existingIndex = [saveLocationPopup indexOfItemWithTag:kUserSaveLocationTag];
    if (existingIndex >= 0) {
        [saveLocationPopup removeItemAtIndex:existingIndex];
    }

    const int index = 1; // element 0 is the default, "Current directory"
    [saveLocationPopup insertItemWithTitle:[destination.absoluteString lastPathComponent] atIndex:index];
    [[saveLocationPopup itemAtIndex:index] setTag:kUserSaveLocationTag];
    [saveLocationPopup selectItemAtIndex:index];
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
                    NSURL* fileURL = [NSURL fileURLWithPath:actualPath];
                    if ([[self class] canHandleURL:fileURL]) {
                        [result addObject:fileURL];
                    }
                }
            } else {
                NSURL* fileURL = [NSURL fileURLWithPath:path];
                if ([[self class] canHandleURL:fileURL]) {
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

    dispatch_sync(dispatch_get_main_queue(), ^{
        STRONG_SELF;
        if (!strongSelf)
            return;

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

        dispatch_sync(dispatch_get_main_queue(), ^{
            STRONG_SELF;
            if (!strongSelf)
                return;

            strongSelf.sheetProcessStep = strongSelf.sheetProcessStep + 1;
            strongSelf.sheetProcessProgress = (float)strongSelf.sheetProcessStep / (float)strongSelf.sheetProcessStepTotal;
        });
    }

    //
    // we're done, notify self on main thread
    //

    dispatch_async(dispatch_get_main_queue(), ^{
        STRONG_SELF;
        if (!strongSelf)
            return;

        [strongSelf fileAddingAnalysisComplete:entries];
    });
}

- (void)removeItems:(NSSet<NSIndexPath*>*)items
{
    [batchCollectionView deselectItemsAtIndexPaths:items];

    // remove these items from internal store
    NSMutableIndexSet* batchIndices = [[NSMutableIndexSet alloc] init];
    NSMutableIndexSet* excludedFromBatchIndices = [[NSMutableIndexSet alloc] init];
    for (NSIndexPath* indexPath in items) {
        switch (indexPath.section) {
        case 0:
            [batchIndices addIndex:indexPath.item];
            break;
        case 1:
            [excludedFromBatchIndices addIndex:indexPath.item];
            break;
        }
    }

    if (batchIndices.count > 0) {
        [batch removeObjectsAtIndexes:batchIndices];
    }

    if (excludedFromBatchIndices.count > 0) {
        [excludedFromBatch removeObjectsAtIndexes:excludedFromBatchIndices];
    }

    WEAK_SELF;
    [[batchCollectionView animator]
        performBatchUpdates:^{
            STRONG_SELF;
            if (!strongSelf)
                return;

            [strongSelf->batchCollectionView deleteItemsAtIndexPaths:items];
        }
        completionHandler:^(BOOL finished) {
            STRONG_SELF;
            if (!strongSelf)
                return;

            strongSelf.showDropMessage = strongSelf.isEmpty;
            [strongSelf updateExcludedSectionHeaderAnimated:YES];
        }];
}

- (void)addExcludedItemsToBatch:(id)sender
{
    NSUInteger startIndex = [batch count];
    NSUInteger count = [excludedFromBatch count];
    [batch addObjectsFromArray:excludedFromBatch];
    [excludedFromBatch removeAllObjects];

    WEAK_SELF;
    [[batchCollectionView animator]
        performBatchUpdates:^{
            STRONG_SELF;
            if (!strongSelf)
                return;

            for (int i = 0; i < count; i++) {
                NSIndexPath* source = [NSIndexPath indexPathForItem:i inSection:1];
                NSIndexPath* dest = [NSIndexPath indexPathForItem:startIndex + i inSection:0];

                BatchCollectionViewItem* item = (BatchCollectionViewItem*)[strongSelf->batchCollectionView itemAtIndexPath:source];
                [strongSelf prepareItem:item forBatchEntry:item.batchEntry inBatch:YES];
                [strongSelf->batchCollectionView moveItemAtIndexPath:source toIndexPath:dest];
            }
        }
        completionHandler:^(BOOL finished) {
            STRONG_SELF;
            if (!strongSelf)
                return;

            [strongSelf updateExcludedSectionHeaderAnimated:YES];
        }];
}

- (void)discardExcludedItems:(id)sender
{
    NSUInteger count = [excludedFromBatch count];
    [excludedFromBatch removeAllObjects];

    WEAK_SELF;
    [[batchCollectionView animator]
        performBatchUpdates:^{
            STRONG_SELF;
            if (!strongSelf)
                return;

            NSMutableSet<NSIndexPath*>* itemsToDelete = [NSMutableSet set];
            for (int i = 0; i < count; i++) {
                [itemsToDelete addObject:[NSIndexPath indexPathForItem:i inSection:1]];
            }
            [strongSelf->batchCollectionView deleteItemsAtIndexPaths:itemsToDelete];
        }
        completionHandler:^(BOOL finished) {
            STRONG_SELF;
            if (!strongSelf)
                return;

            [strongSelf updateExcludedSectionHeaderAnimated:YES];
        }];
}

- (void)updateExcludedSectionHeaderAnimated:(BOOL)animated
{
    if (excludedFromBatchSectionHeader != nil) {
        BOOL hidden = excludedFromBatch.count == 0;
        if (animated) {
            [excludedFromBatchSectionHeader setContentHidden:self.isEmpty animated:YES];
            excludedFromBatchSectionHeader.addToBatchButton.animator.hidden = hidden;
            excludedFromBatchSectionHeader.discardItems.animator.hidden = hidden;
        } else {
            [excludedFromBatchSectionHeader setContentHidden:self.isEmpty animated:NO];
            excludedFromBatchSectionHeader.addToBatchButton.hidden = hidden;
            excludedFromBatchSectionHeader.discardItems.hidden = hidden;
        }
    }
}

- (void)moveEntry:(BatchEntry*)batchEntry toBatch:(BOOL)includedInBatch
{
    NSIndexPath* source = nil;
    NSIndexPath* dest = nil;
    if (includedInBatch) {
        // moving from exclusion to inclusion
        source = [NSIndexPath indexPathForItem:[excludedFromBatch indexOfObject:batchEntry] inSection:1];
        dest = [NSIndexPath indexPathForItem:batch.count inSection:0];
        [excludedFromBatch removeObject:batchEntry];
        [batch addObject:batchEntry];
    } else {
        // moving from inclusion to exclusion
        source = [NSIndexPath indexPathForItem:[batch indexOfObject:batchEntry] inSection:0];
        dest = [NSIndexPath indexPathForItem:excludedFromBatch.count inSection:1];
        [batch removeObject:batchEntry];
        [excludedFromBatch addObject:batchEntry];
    }

    if (source != nil && dest != nil) {

        WEAK_SELF;
        [[batchCollectionView animator]
            performBatchUpdates:^{
                STRONG_SELF;
                if (!strongSelf)
                    return;

                [strongSelf->batchCollectionView moveItemAtIndexPath:source toIndexPath:dest];
            }
            completionHandler:^(BOOL finished) {
                STRONG_SELF;
                if (!strongSelf)
                    return;

                BatchCollectionViewItem* item = (BatchCollectionViewItem*)[strongSelf->batchCollectionView itemAtIndexPath:dest];
                [strongSelf prepareItem:item forBatchEntry:batchEntry inBatch:includedInBatch];
                [strongSelf updateExcludedSectionHeaderAnimated:YES];
            }];

    } else {
        DebugLog(@"Unable to perform move - Missing one or both of source (%@) and dest (%@) index paths", source, dest);
    }
}

- (void)prepareItem:(BatchCollectionViewItem*)item forBatchEntry:(BatchEntry*)entry inBatch:(BOOL)inBatch
{
    item.batchEntry = entry;
    item.isIncludedInBumpmapsBatch = inBatch;

    WEAK_SELF;
    if (inBatch) {
        item.onAddRemoveButtonTapped = ^() {
            STRONG_SELF;
            if (!strongSelf)
                return;

            [strongSelf moveEntry:entry toBatch:NO];
        };
    } else {
        item.onAddRemoveButtonTapped = ^() {
            STRONG_SELF;
            if (!strongSelf)
                return;

            [strongSelf moveEntry:entry toBatch:YES];
        };
    }
}

- (void)fileAddingAnalysisComplete:(NSMutableArray<BatchEntry*>*)newEntries
{
    self.sheetProcessRunning = NO;

    [NSApp endSheet:progressSheet];

    for (BatchEntry* entry in newEntries) {
        if (entry.looksLikeBumpmap) {
            [batch addObject:entry];
        } else {
            [excludedFromBatch addObject:entry];
        }
    }

    [batchCollectionView reloadData];
    [self updateExcludedSectionHeaderAnimated:NO];
    self.showDropMessage = self.isEmpty;
}

- (void)normalmapFiles:(NSArray<BatchEntry*>*)entries
{
    WEAK_SELF;

    dispatch_sync(dispatch_get_main_queue(), ^{
        STRONG_SELF;
        if (!strongSelf)
            return;

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

        dispatch_sync(dispatch_get_main_queue(), ^{
            STRONG_SELF;
            if (!strongSelf)
                return;

            strongSelf.sheetProcessStep = strongSelf.sheetProcessStep + 1;
            strongSelf.sheetProcessProgress = (float)strongSelf.sheetProcessStep / (float)strongSelf.sheetProcessStepTotal;
        });
    }

    //
    // we're done, notify self on main thread
    //

    dispatch_async(dispatch_get_main_queue(), ^{
        STRONG_SELF;
        if (!strongSelf)
            return;

        strongSelf.sheetProcessRunning = NO;
        [NSApp endSheet:strongSelf->progressSheet];
    });
}

- (NSSet<NSIndexPath*>*)userInteractableIndexPathsFrom:(NSSet<NSIndexPath*>*)proposedIndexPaths
{
    NSMutableSet<NSIndexPath*>* pruned = [NSMutableSet set];
    for (NSIndexPath* p in proposedIndexPaths) {
        NSArray<BatchEntry*>* source = p.section == 0 ? batch : excludedFromBatch;
        if (p.item < source.count) {
            [pruned addObject:p];
        }
    }
    return pruned;
}

@end
