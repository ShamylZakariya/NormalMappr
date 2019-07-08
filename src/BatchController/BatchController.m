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
#define kUserSaveLocationTag 100

@interface BatchController (Private)

- (void)requestUserSaveDestination;
- (void)addUserSaveDestination:(NSURL*)destination;
- (BOOL)canOpenFileWithExtension:(NSString*)extension;
- (NSMutableArray<NSURL*>*)gatherFiles:(NSArray<NSURL*>*)fileURLs;
- (void)loadDroppedFiles:(NSArray<NSURL*>*)fileURLs;
- (void)removeItems:(NSSet<NSIndexPath*>*)items animated:(BOOL)animated;
- (void)addExcludedItemsToBatch:(id)sender;
- (void)moveEntry:(BatchEntry*)batchEntry toBatch:(BOOL)includedInBatch;
- (void)prepareItem:(BatchCollectionViewItem*)item forBatchEntry:(BatchEntry*)entry inBatch:(BOOL)inBatch;
- (void)fileAddingAnalysisComplete:(NSMutableArray<BatchEntry*>*)addableFiles;
- (void)normalmapFiles:(NSArray<BatchEntry*>*)files;

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
    self.showDropMessage = YES;
    self.iconSize = 128;

    batchCollectionView.dataSource = self;
    batchCollectionView.delegate = self;
    batchCollectionView.selectable = YES;
    batchCollectionView.allowsMultipleSelection = YES;
    batchCollectionView.batchController = self;

    NSNib* itemNib = [[NSNib alloc] initWithNibNamed:@"BatchCollectionViewItem" bundle:[NSBundle mainBundle]];
    [batchCollectionView registerNib:itemNib forItemWithIdentifier:kBatchCollectionViewItemIdentifier];

    NSNib* headerNib = [[NSNib alloc] initWithNibNamed:@"BatchCollectionViewSectionHeader" bundle:[NSBundle mainBundle]];
    [batchCollectionView registerNib:headerNib forSupplementaryViewOfKind:NSCollectionElementKindSectionHeader withIdentifier:kBatchCollectionViewSectionHeaderIdentifier];

    [batchCollectionView registerForDraggedTypes:@[ NSURLPboardType ]];

    [batchWindow makeKeyAndOrderFront:self];
    batchWindow.defaultButtonCell = runButton.cell;

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
@synthesize iconSize;

- (void)setIconSize:(CGFloat)size
{
    iconSize = size;
    batchCollectionViewFlowLayout.itemSize = NSMakeSize(size * 1.1, size);
}

- (void)setShowDropMessage:(BOOL)sdm
{
    if (sdm != showDropMessage) {
        showDropMessage = sdm;
    }
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
        [strongSelf normalmapFiles:batch];
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
    int count = 0;
    if ([batch count] > 0) {
        count++;
    }
    if ([excludedFromBatch count] > 0) {
        count++;
    }
    return count;
}

- (NSInteger)collectionView:(NSCollectionView*)collectionView numberOfItemsInSection:(NSInteger)section
{
    BOOL isBatchSection = section == 0 && [batch count] > 0;
    if (isBatchSection) {
        return batch.count;
    } else {
        return excludedFromBatch.count;
    }
}

- (NSCollectionViewItem*)collectionView:(NSCollectionView*)collectionView itemForRepresentedObjectAtIndexPath:(NSIndexPath*)indexPath
{
    BOOL isBatchSection = indexPath.section == 0 && [batch count] > 0;
    NSMutableArray<BatchEntry*>* source = isBatchSection ? batch : excludedFromBatch;
    BatchEntry* entry = source[indexPath.item];
    BatchCollectionViewItem* item = [collectionView makeItemWithIdentifier:kBatchCollectionViewItemIdentifier forIndexPath:indexPath];

    [self prepareItem:item forBatchEntry:entry inBatch:isBatchSection];

    return item;
}

- (NSView*)collectionView:(NSCollectionView*)collectionView viewForSupplementaryElementOfKind:(NSCollectionViewSupplementaryElementKind)kind atIndexPath:(NSIndexPath*)indexPath
{
    if ([kind isEqualToString:NSCollectionElementKindSectionHeader]) {
        BatchCollectionViewSectionHeader* header = [collectionView makeSupplementaryViewOfKind:NSCollectionElementKindSectionHeader withIdentifier:kBatchCollectionViewSectionHeaderIdentifier forIndexPath:indexPath];

        NSString* bumpmapHeaderTitle = NSLocalizedString(@"Bumpmaps", @"Title of section holding apparently valid bumpmaps");
        NSString* nonBumpmapHeaderTitle = NSLocalizedString(@"Excluded", "Title of section holding images which don't appear to be bumpmaps");

        BOOL isBatchSection = indexPath.section == 0 && [batch count] > 0;
        if (isBatchSection) {

            [header.sectionTitle setStringValue:bumpmapHeaderTitle];
            [header.addToBatchButton setHidden:YES];
            [header.addToBatchButton setEnabled:NO];

        } else {

            [header.sectionTitle setStringValue:nonBumpmapHeaderTitle];
            [header.addToBatchButton setHidden:NO];
            [header.addToBatchButton setEnabled:YES];

            [header.addToBatchButton setTarget:self];
            [header.addToBatchButton setAction:@selector(addExcludedItemsToBatch:)];
        }

        return header;
    }

    return [collectionView makeSupplementaryViewOfKind:kind withIdentifier:@"" forIndexPath:indexPath];
}

#pragma mark - NSCollectionViewDelegate

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

#pragma mark - NSCollectionViewDelegateFlowLayout

- (NSSize)collectionView:(NSCollectionView*)collectionView layout:(NSCollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    return NSMakeSize(0, 80);
}

#pragma mark - Keyboard interaction

- (void)deleteForward:(id)sender
{
    [self removeItems:batchCollectionView.selectionIndexPaths animated:YES];
}

- (void)deleteBackward:(id)sender
{
    [self removeItems:batchCollectionView.selectionIndexPaths animated:YES];
}

#pragma mark - Private

- (void)requestUserSaveDestination
{
    NSOpenPanel* panel = [NSOpenPanel openPanel];
    panel.canChooseFiles = NO;
    panel.canChooseDirectories = YES;
    panel.allowsMultipleSelection = NO;
    
    [panel beginSheetModalForWindow:self.batchWindow
                  completionHandler:^(NSModalResponse result) {
                      switch (result) {
                          case NSFileHandlingPanelOKButton:
                              DebugLog(@"user selected OK, urls: %@", panel.URLs.firstObject);
                              self.batchSettings.userSaveDestination = panel.URLs.firstObject;
                              [self addUserSaveDestination:self.batchSettings.userSaveDestination];
                              break;
                          default:
                              // user cancelled, select the previously selected item
                              [saveLocationPopup selectItemWithTag:previousSaveLocationPopupTag];
                              break;
                      }
                  }];
}

- (void)addUserSaveDestination:(NSURL*)destination
{
    int existingIndex = [saveLocationPopup indexOfItemWithTag:kUserSaveLocationTag];
    if (existingIndex >= 0) {
        [saveLocationPopup removeItemAtIndex:existingIndex];
    }
    
    const int index = 1; // element 0 is the default, "Current directory"
    [saveLocationPopup insertItemWithTitle:[destination.absoluteString lastPathComponent] atIndex:index];
    [[saveLocationPopup itemAtIndex:index] setTag:kUserSaveLocationTag];
    [saveLocationPopup selectItemAtIndex:index];
}

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

- (void)removeItems:(NSSet<NSIndexPath*>*)items animated:(BOOL)animated
{
    [batchCollectionView deselectItemsAtIndexPaths:items];
    
    // remove these items from internal store
    NSMutableIndexSet* bumpmapIndices = [[NSMutableIndexSet alloc] init];
    NSMutableIndexSet* nonBumpmapIndices = [[NSMutableIndexSet alloc] init];
    for (NSIndexPath* indexPath in items) {
        
        BOOL isBatchSection = indexPath.section == 0 && [batch count] > 0;
        if (isBatchSection) {
            [bumpmapIndices addIndex:indexPath.item];
        } else {
            [nonBumpmapIndices addIndex:indexPath.item];
        }
    }
    
    BOOL bumpmapsWasPopulated = [batch count] > 0;
    BOOL nonBumpmapsWasPopulated = [excludedFromBatch count] > 0;
    
    if (bumpmapIndices.count > 0) {
        [batch removeObjectsAtIndexes:bumpmapIndices];
    }
    
    if (nonBumpmapIndices.count > 0) {
        [excludedFromBatch removeObjectsAtIndexes:nonBumpmapIndices];
    }
    
    BOOL bumpmapsIsEmpty = [batch count] == 0;
    BOOL nonBumpmapsIsEmpty = [excludedFromBatch count] == 0;
    
    // remove from collection view
    if (animated) {
        NSAnimationContext.currentContext.duration = 0.2;
        [[batchCollectionView animator]
         performBatchUpdates:^{
             [batchCollectionView deleteItemsAtIndexPaths:items];
             if (nonBumpmapsIsEmpty && nonBumpmapsWasPopulated) {
                 [batchCollectionView deleteSections:[NSIndexSet indexSetWithIndex:bumpmapsWasPopulated ? 1 : 0]];
             }
             
             if (bumpmapsIsEmpty && bumpmapsWasPopulated) {
                 [batchCollectionView deleteSections:[NSIndexSet indexSetWithIndex:0]];
             }
         }
         completionHandler:^(BOOL finished) {
         }];
    } else {
        [batchCollectionView deleteItemsAtIndexPaths:items];
        
        if (nonBumpmapsIsEmpty && nonBumpmapsWasPopulated) {
            [batchCollectionView deleteSections:[NSIndexSet indexSetWithIndex:bumpmapsWasPopulated ? 1 : 0]];
        }
        
        if (bumpmapsIsEmpty && bumpmapsWasPopulated) {
            [batchCollectionView deleteSections:[NSIndexSet indexSetWithIndex:0]];
        }
    }
    
    self.showDropMessage = bumpmapsIsEmpty && nonBumpmapsIsEmpty;
}

- (void)addExcludedItemsToBatch:(id)sender
{
    int startIndex = [batch count];
    int count = [excludedFromBatch count];
    [batch addObjectsFromArray:excludedFromBatch];
    [excludedFromBatch removeAllObjects];
    
    //
    //  If we have no bumpmaps, only non-bumpmaps, we can't move them from section 0 to section 0...
    //  so we need to just do a reload data
    //
    if (startIndex == 0) {
        [batchCollectionView reloadData];
    } else {
        // we have both sections, we can perform a move
        [[batchCollectionView animator]
         performBatchUpdates:^{
             for (int i = 0; i < count; i++) {
                 NSIndexPath* source = [NSIndexPath indexPathForItem:i inSection:1];
                 NSIndexPath* dest = [NSIndexPath indexPathForItem:startIndex + i inSection:0];
                 
                 BatchCollectionViewItem* item = (BatchCollectionViewItem*)[batchCollectionView itemAtIndexPath:source];
                 [self prepareItem:item forBatchEntry:item.batchEntry inBatch:YES];
                 [batchCollectionView moveItemAtIndexPath:source toIndexPath:dest];
             }
             
             [batchCollectionView deleteSections:[NSIndexSet indexSetWithIndex:1]];
         }
         completionHandler:^(BOOL finished) {
             ;
         }];
    }
}

- (void)moveEntry:(BatchEntry*)batchEntry toBatch:(BOOL)includedInBatch
{
    if (YES && [batch count] > 0 && [excludedFromBatch count] > 0) {
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
            
            [[batchCollectionView animator]
             performBatchUpdates:^{
                 [batchCollectionView moveItemAtIndexPath:source toIndexPath:dest];
                 if (batch.count == 0) {
                     [batchCollectionView deleteSections:[NSIndexSet indexSetWithIndex:0]];
                 } else if (excludedFromBatch.count == 0) {
                     [batchCollectionView deleteSections:[NSIndexSet indexSetWithIndex:1]];
                 }
             }
             completionHandler:^(BOOL finished) {
                 BatchCollectionViewItem* item = (BatchCollectionViewItem*)[batchCollectionView itemAtIndexPath:dest];
                 [self prepareItem:item forBatchEntry:batchEntry inBatch:includedInBatch];
             }];
            
        } else {
            DebugLog(@"Unable to perform move - Missing one or both of source (%@) and dest (%@) index paths", source, dest);
        }
    } else {
        // we don't have a bumpmaps (or) non-bumpmaps section - this complicates the move.
        // instead, for now just call reloadData
        if (includedInBatch) {
            // moving from exclusion to inclusion
            NSIndexPath* source = [NSIndexPath indexPathForItem:[excludedFromBatch indexOfObject:batchEntry] inSection:1];
            BatchCollectionViewItem* item = (BatchCollectionViewItem*)[batchCollectionView itemAtIndexPath:source];
            [self prepareItem:item forBatchEntry:batchEntry inBatch:YES];
            
            [excludedFromBatch removeObject:batchEntry];
            [batch addObject:batchEntry];
        } else {
            // moving from inclusion to exclusion
            
            NSIndexPath* source = [NSIndexPath indexPathForItem:[batch indexOfObject:batchEntry] inSection:0];
            BatchCollectionViewItem* item = (BatchCollectionViewItem*)[batchCollectionView itemAtIndexPath:source];
            [self prepareItem:item forBatchEntry:batchEntry inBatch:NO];
            
            [batch removeObject:batchEntry];
            [excludedFromBatch addObject:batchEntry];
        }
        [batchCollectionView reloadData];
    }
}

- (void)prepareItem:(BatchCollectionViewItem*)item forBatchEntry:(BatchEntry*)entry inBatch:(BOOL)inBatch
{
    item.batchEntry = entry;
    item.isIncludedInBumpmapsBatch = inBatch;
    item.addRemoveButton.title = inBatch ? @"-" : @"+";
    
    item.addRemoveButton.target = self;
    WEAK_SELF;
    if (inBatch) {
        item.addRemoveButton.onClick = ^() {
            STRONG_SELF;
            [strongSelf moveEntry:entry toBatch:NO];
        };
    } else {
        item.addRemoveButton.onClick = ^() {
            STRONG_SELF;
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
    self.showDropMessage = (batch.count == 0) && (excludedFromBatch.count == 0);
}

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

@end
