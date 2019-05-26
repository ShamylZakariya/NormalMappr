//
//  BatchCollectionViewSectionHeader.h
//  NormalMappr
//
//  Created by Shamyl Zakariya on 5/25/19.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface ItemCountBackgroundView : NSView
@end

@interface BatchCollectionViewSectionHeader : NSView
@property (weak) IBOutlet NSView *itemCountContainer;
@property (weak) IBOutlet NSTextField *sectionTitle;
@property (weak) IBOutlet NSTextField *itemCount;
@end

NS_ASSUME_NONNULL_END
