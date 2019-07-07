//
//  BatchCollectionViewSectionHeader.h
//  NormalMappr
//
//  Created by Shamyl Zakariya on 5/25/19.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface BatchCollectionViewSectionHeader : NSView
@property (weak) IBOutlet NSButton* addToBatchButton;
@property (weak) IBOutlet NSTextField* sectionTitle;
@end

NS_ASSUME_NONNULL_END
