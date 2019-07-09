//
//  BatchCollectionViewSectionHeader.h
//  NormalMappr
//
//  Created by Shamyl Zakariya on 5/25/19.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface BatchCollectionViewSectionHeaderBackground : NSView
@end

@interface BatchCollectionViewSectionHeader : NSView

- (void)setContentHidden:(BOOL)contentHidden animated:(BOOL)animated;

@property (weak) IBOutlet NSButton* addToBatchButton;
@property (weak) IBOutlet NSTextField* sectionTitle;
@property (weak) IBOutlet BatchCollectionViewSectionHeaderBackground* backgroundView;

@end

NS_ASSUME_NONNULL_END
