//
//  StackView.h
//  FilteredImageList
//
//  Created by Shamyl Zakariya on 3/30/09.
//  Copyright 2009 Shamyl Zakariya. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol StackViewSizing

- (CGFloat) preferredHeight;

@end

@interface LayoutToken : NSObject {
	CGFloat preferredSize;
	CGFloat layoutSize;
	CGFloat	collapse;
	BOOL    spring;
}

+ (LayoutToken*) layoutTokenWithPreferredSize: (CGFloat) size andCollapse: (CGFloat) collapse;
- (id) initWithPreferredSize: (CGFloat) size andCollapse: (CGFloat) collapse;


@property (readwrite) CGFloat preferredSize;
@property (readwrite) CGFloat layoutSize;
@property (readwrite) BOOL    spring;
@property (readwrite) CGFloat collapse;

@end



@interface StackView : NSView <NSAnimationDelegate> {
	NSColor *backgroundColor;
	
	NSAnimation *collapseAnimation;
	NSDictionary *previousViewCollapse;
	NSDictionary *viewCollapse;
	CGFloat collapseProgress;

	BOOL	layingOut;
}

@property (readwrite,retain) NSColor* backgroundColor; 

- (void) setViewCollapse: (NSDictionary*) viewCollapse animate: (BOOL) animate;
- (NSDictionary*) viewCollapse;

@end
