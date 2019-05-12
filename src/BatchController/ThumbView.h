//
//  ThumbView.h
//  FilteredImageList
//
//  Created by Shamyl Zakariya on 3/21/09.
//  Copyright 2009 Shamyl Zakariya. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ThumbView : NSImageView {
	NSShadow	*shadow;
	CGFloat		inset;
}

@property (nonatomic, readwrite) CGFloat inset;

@end
