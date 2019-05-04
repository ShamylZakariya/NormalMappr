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

@property (readwrite,retain) NSString* label;
@property (readwrite,retain) NSGradient *fill;
@property (readwrite) BOOL open;
@property (readwrite) NSInteger count;

- (CGFloat) preferredHeight;

@end
