//
//  StackViewScrollView.h
//  FilteredImageList
//
//  Created by Shamyl Zakariya on 3/31/09.
//  Copyright 2009 Shamyl Zakariya. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "StackView.h"

@interface StackViewScrollView : NSScrollView  <StackViewSizing> {

}

- (CGFloat) preferredHeight;

@end
