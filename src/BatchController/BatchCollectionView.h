//
//  BatchCollectionView.h
//  NormalMappr
//
//  Created by Shamyl Zakariya on 7/4/19.
//

#import <Cocoa/Cocoa.h>

@class BatchController;

NS_ASSUME_NONNULL_BEGIN

@interface BatchCollectionView : NSCollectionView
{
    BOOL isDropTarget;
}

@property (weak,readwrite,nonatomic) BatchController* batchController;

@end

NS_ASSUME_NONNULL_END
