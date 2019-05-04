//
//  BatchView.h
//  FilteredImageList
//
//  Created by Shamyl Zakariya on 3/22/09.
//  Copyright 2009 Shamyl Zakariya. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString *			kBatchViewDefaultDragType;

@interface BatchView : NSCollectionView {
	BOOL		dragInProgress;
	BOOL		dropInProgress;
	BOOL		shouldInitiateDrag;
	BOOL		showMessage;
	NSString	*dragTypeString;
	NSString	*message;
	
	id			delegate;
	SEL			dropAction;
	SEL			dropFilesAction;
	SEL			deleteAction;
	NSPoint		mouseDownPosition;
	NSGradient	*innerShadowGradient;
}

@property (retain) NSString				*dragTypeString;

/**
	The delegate for drag-drop and deletion
*/
@property (assign) id					delegate;

/**
	The action invoked on the delegate when a drop occurs.
	The action receives an array of the items' -identifier
	
	Note: We're passing the items' identifiers since DnD doesn't 
	like passing around raw pointers for obvious reasons.
*/
@property (assign) SEL					dropAction;

/**
	The action invoked on the delegate when files are dropped
*/
@property (assign) SEL					dropFilesAction;

/**
	The action invoked on the delegate when a selected tile is deleted (by keyboard, or drag-out)
	The action receives an array of the items.
*/
@property (assign) SEL					deleteAction;

@property (readwrite) BOOL showMessage;
@property (readwrite,retain) NSString* message;

//
// Selection
// 

- (id)selectedObject;
- (NSArray *)selectedObjects;

- (NSView *)selectedView;
- (NSArray *)selectedViews;

@end
