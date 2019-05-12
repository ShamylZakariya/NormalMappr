//
//  BatchLabel.h
//  FilteredImageList
//
//  Created by Shamyl Zakariya on 4/1/09.
//  Copyright 2009 Shamyl Zakariya. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "StackView.h"

@interface BatchLabel : NSView <StackViewSizing> {
	BOOL		open;
	IBOutlet	NSButton	*toggleSwitch;
	NSString	*label;
	NSShadow	*shadow;
	NSGradient	*fill, *fillShadow;
	NSInteger	count;
}

@property (nonatomic, readwrite,retain) NSString* label;
@property (nonatomic, readwrite,retain) NSGradient *fill;
@property (nonatomic, readwrite) BOOL open;
@property (nonatomic, readwrite) NSInteger count;

- (CGFloat) preferredHeight;

@end
