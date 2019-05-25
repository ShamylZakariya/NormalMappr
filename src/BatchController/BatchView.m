//
//  BatchView.m
//  FilteredImageList
//
//  Created by Shamyl Zakariya on 3/22/09.
//  Copyright 2009 Shamyl Zakariya. All rights reserved.
//
//	Drag & Drop code inspired by excellent RKCollectionView 
//	sample code from: http://www.cocoadev.com/index.pl?NSCollectionView
//

#import "BatchView.h"
#include "BatchEntry.h"
#include "CTBadge.h"

#import "NSView+viewAtPointExcluding.h"
#import "NSArray+reversedArray.h"

#define ENABLE_DRAG_OUT_TO_DELETE 1

NSString *kBatchViewDefaultDragType	= @"kBatchViewDefaultDragType";

@interface BatchView (Private)
// Dragging
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender;
- (void)draggingExited:(id <NSDraggingInfo>)sender;
- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender;
- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender;
- (NSImage*) dragImage;
- (NSImage*) dragBadge: (NSUInteger) count;

// event helpers
- (NSUInteger) indexOfViewAtPoint: (NSPoint) locationInWindow;
- (void) showPoofAnimation;

@end

#pragma mark -

///////////////////////////////////////////////////////////////////////

@implementation BatchView

@synthesize dragTypeString;
@synthesize delegate;
@synthesize dropAction;
@synthesize dropFilesAction;
@synthesize deleteAction;
@synthesize showMessage;
@synthesize message;

- (void) awakeFromNib
{
    [super awakeFromNib];
	[self setFocusRingType:NSFocusRingTypeDefault];
	[self setDragTypeString: kBatchViewDefaultDragType];
}

- (void)drawRect:(NSRect)rect {
	[super drawRect: rect];
	
	NSRect highlightRect = self.bounds;
	if ( self.enclosingScrollView )
	{
		//
		// We want to convert highlight rect to the enclosing
		// scroll view's content view
		//
		
		NSClipView *contentView = self.enclosingScrollView.contentView;
		NSRect cvb = contentView.bounds;
		highlightRect = [self convertRect:cvb fromView:contentView];		
	}

	//
	// Draw focus ring
	//

	if ( NO && self.window.firstResponder == self )
	{
		[[NSColor selectedControlColor] set];
        NSFrameRectWithWidthUsingOperation( highlightRect, 3, NSCompositingOperationSourceOver );
	}

	//
	// Draw drop-highlight ring
	//

    if ( dropInProgress )
	{
		[[[NSColor selectedControlColor] colorWithAlphaComponent:0.5] set];
        NSFrameRectWithWidthUsingOperation( highlightRect, 3, NSCompositingOperationSourceOver );
	}	
	
	if ( self.showMessage && self.message )
	{	
		NSShadow *shadow = [[NSShadow alloc] init];
		shadow.shadowBlurRadius = 1;
		shadow.shadowOffset = NSMakeSize( 0,-1 );
		shadow.shadowColor = [NSColor colorWithDeviceWhite:0 alpha:0.5];
		
		NSFont *font = [NSFont fontWithName: @"Helvetica Neue UltraLight" size:32];
		NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
			font, NSFontAttributeName,
			[NSColor colorWithDeviceWhite:1 alpha:1], NSForegroundColorAttributeName,
			shadow, NSShadowAttributeName,
			nil ];
			
		NSSize labelSize = [self.message sizeWithAttributes:attrs];
		[self.message drawAtPoint: NSMakePoint( NSMidX( self.bounds ) - labelSize.width/2,  NSMidY( self.bounds ) - labelSize.height/2 + 1 ) withAttributes:attrs];		
	}
}

- (BOOL) isOpaque
{
	return NO;
}

- (void)setDragTypeString:(NSString *)aString 
{
	if ( aString != dragTypeString )
	{
		dragTypeString = aString;
		[self registerForDraggedTypes:[NSArray arrayWithObjects:dragTypeString, NSFilenamesPboardType, nil]];
	}
}

- (void) setMessage: (NSString*) newMessage
{
	if ( newMessage != message )
	{
		message = newMessage;
		
		if ( showMessage ) [self setNeedsDisplay: YES];
	}
}

- (void) setShowMessage: (BOOL) sm
{
	showMessage = sm;
	[self setNeedsDisplay:YES];
}

#pragma mark -
#pragma mark Events

- (void)mouseDown:(NSEvent *) event 
{
	shouldInitiateDrag = NO;
	mouseDownPosition = [self convertPoint:[event locationInWindow] fromView:nil];

	NSUInteger targetIndex = [self indexOfViewAtPoint:[event locationInWindow]];
	if ( targetIndex != NSNotFound )
	{
		if ( [[self selectionIndexes] containsIndex:targetIndex] )
		{
			shouldInitiateDrag = YES;
			return;
		}
		else
		{
			//
			//	Start a drag with the icon clicked on
			//
			[self setSelectionIndexes: [NSIndexSet indexSetWithIndex:targetIndex]];
			shouldInitiateDrag = YES;
			return;
		}
				
	}
	
	[super mouseDown: event];
}

- (void)mouseDragged:(NSEvent *) event 
{
	if ( !shouldInitiateDrag )
	{
		[super mouseDragged: event];
		return;
	}
		
	const float dragThreshold = 4;
	NSPoint mousePosition = [self convertPoint:[event locationInWindow] fromView:nil];
	BOOL draggedFarEnough = ABS( mousePosition.x - mouseDownPosition.x ) > dragThreshold ||
							ABS( mousePosition.y - mouseDownPosition.y ) > dragThreshold;
	
	
	NSArray *selectedObjects = [self selectedObjects];	
	if( selectedObjects && [selectedObjects count] && !dragInProgress && draggedFarEnough ) 
	{
		dragInProgress = YES;

		//
		//	Gather up identifier strings
		//

		NSMutableArray *identifiers = [NSMutableArray array];
		for ( id obj in selectedObjects )
		{
			[identifiers addObject: [obj identifier]];
		}

		//
		// Stuff data in pasteboard
		//

		NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSDragPboard];        
		[pboard declareTypes:[NSArray arrayWithObject:dragTypeString] owner:self];
		[pboard setPropertyList: identifiers forType: dragTypeString];

		//
		// Now, we need to create a drag image
		//

		NSImage *dragImage = [self dragImage];
		NSPoint position = [self convertPoint:[event locationInWindow] fromView:nil];
		position.x -= dragImage.size.width/2;
		position.y += dragImage.size.height/2;
		
		//
		// Finally, initiate drag!
		//

		[self  dragImage: dragImage
					  at: position
				  offset: NSZeroSize
				   event: event
			  pasteboard: pboard
				  source: self
			   slideBack: ENABLE_DRAG_OUT_TO_DELETE ? NO : YES];

        self.selectionIndexPaths = [NSSet set];
	}
}

- (void)mouseUp:(NSEvent *)event 
{
	dragInProgress = NO;
	shouldInitiateDrag = NO;
    [self setNeedsDisplay:YES];
	[super mouseUp:event];
}

- (void)deleteBackward:(id)sender
{
	if ( [[self selectedObjects] count] )
	{
		if ( self.delegate &&
			 [self.delegate respondsToSelector: self.deleteAction] )
		{
			[self.delegate performSelector: self.deleteAction withObject: [self selectedObjects]];
		}	
		
        self.selectionIndexPaths = [NSSet set];
	}
}

- (void) deleteForward: (id) sender
{
	// same behavior for delete key as backspace
	[self deleteBackward: sender];
}

- (BOOL) becomeFirstResponder
{
	[self setNeedsDisplay:YES];
	return [super becomeFirstResponder];
}

- (BOOL) resignFirstResponder
{
	[self setNeedsDisplay:YES];
    self.selectionIndexPaths = [NSSet set];
	return [super resignFirstResponder];
}

#pragma mark -
#pragma mark Helpers

- (id)selectedObject 
{
	NSArray * selectedObjects = [self selectedObjects];
	
	if( [selectedObjects count] < 1 ) 
	{
		return nil;
	}
	
	return [selectedObjects objectAtIndex:0];
}

- (NSArray *)selectedObjects 
{
	return [[self content] objectsAtIndexes:[self selectionIndexes]];
}

- (NSView *)selectedView 
{
	if( [[self selectedViews] count] < 1 ) 
	{
		return nil;
	}
	
	return [[self selectedViews] objectAtIndex:0];
}

- (NSArray *)selectedViews 
{
	return [[[self subviews] reversedArray] objectsAtIndexes:[self selectionIndexes]];
}

#pragma mark -
#pragma mark Dragging/Dropping

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender 
{
	NSUInteger operation = NSDragOperationNone;

	if ( [sender draggingSource] != self )
	{
		NSArray *types = [[sender draggingPasteboard] types];
		if ( [types containsObject: dragTypeString] )
		{
			if ( self.delegate &&
			     [self.delegate respondsToSelector: self.dropAction] )
			{
				operation = NSDragOperationLink;
			}
		}		
		else if ( [types containsObject: NSFilenamesPboardType] )
		{
			if ( self.delegate &&
			     [self.delegate respondsToSelector: self.dropFilesAction] )
			{
				operation = NSDragOperationLink;
			}
		}
	}
	
	if ( operation != NSDragOperationNone )
	{
		// we want to paint a highlight when we're dragging
		dropInProgress = YES;
		[self setNeedsDisplay:YES];
	}

    return operation;
}

- (void)draggingExited:(id <NSDraggingInfo>)sender 
{
	dropInProgress = NO;
	[self setNeedsDisplay:YES];
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender 
{
	return [self draggingEntered: sender];
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
	
	if ( [sender draggingSource] != self )
	{
		NSArray *types = [sender draggingPasteboard].types;
		if ( [types containsObject:dragTypeString] )
		{
			NSArray *paths = [[sender draggingPasteboard] propertyListForType: dragTypeString];
			
			if ( self.delegate &&
				 [self.delegate respondsToSelector: self.dropAction] )
			{
				[self.delegate performSelector: self.dropAction withObject: paths];
			}

		}
		else if ( [types containsObject: NSFilenamesPboardType] )
		{
			NSArray *files = [[sender draggingPasteboard] propertyListForType:NSFilenamesPboardType];
			if ( self.delegate &&
			     [self.delegate respondsToSelector: self.dropFilesAction] )
			{
				[self.delegate performSelector: self.dropFilesAction withObject:files];
			}
		}

		//
		// The drop has changed our data source, so we should deselect
		//

        self.selectionIndexPaths = [NSSet set];
		return YES;
	}
		
	return NO;
}

- (void)draggingEnded:(id <NSDraggingInfo>)sender 
{
	dropInProgress = NO;	
	dragInProgress = NO;
    [self setNeedsDisplay:YES];
}

#if ENABLE_DRAG_OUT_TO_DELETE
- (void)draggedImage:(NSImage *)anImage endedAt:(NSPoint)aPoint operation:(NSDragOperation)operation 
{
	NSPoint mousePoint = [NSEvent mouseLocation];
	NSPoint winPoint = [[self window] convertScreenToBase:mousePoint];
	NSPoint viewPoint = [self convertPoint:winPoint fromView:nil];

	//
	// if the drag session ended in the same outline view do nothing
	//
	
	if ( operation == NSDragOperationNone )
	{
		if ( !NSMouseInRect(viewPoint, [self visibleRect], [self isFlipped]) )
		{
			//
			// Delete the selection
			//

			[self showPoofAnimation];
			[self deleteBackward:nil];
		}
	}
}
#endif

- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)isLocal
{
	return isLocal ? NSDragOperationLink : NSDragOperationNone;
}

- (BOOL) ignoreModifierKeysWhileDragging
{
	return YES;
}

- (NSImage*) dragImage
{	
	NSArray *selectedObjects = [self selectedObjects]; 
	NSImage * sourceImage = [[selectedObjects objectAtIndex:0] thumb];

	NSSize thumbSize = [sourceImage size];
	if ( thumbSize.width > 64 )
	{
		CGFloat scale = 64.0f / thumbSize.width;
		thumbSize.width *= scale;
		thumbSize.height *= scale;
	}
	
	if ( thumbSize.height > 64 )
	{
		CGFloat scale = 64.0f / thumbSize.height;
		thumbSize.width *= scale;
		thumbSize.height *= scale;
	}
	
	NSImage *dragImage = [[NSImage alloc] initWithSize: thumbSize ],
	        *badge = nil;
			
	if ( [selectedObjects count] > 1 )
	{
		badge = [self dragBadge: [selectedObjects count]];
	}

	[dragImage lockFocus];

		[sourceImage 
			drawInRect:NSMakeRect(0,0,thumbSize.width,thumbSize.height) 
			fromRect:NSMakeRect(0,0,sourceImage.size.width, sourceImage.size.height) 
         operation:NSCompositingOperationSourceOver
			fraction:0.5];

		if ( badge )
		{
			const float pad = 4;
			NSSize badgeSize = [badge size];

			[badge 
				drawAtPoint: NSMakePoint( thumbSize.width - pad - badgeSize.width, pad )
				fromRect: NSMakeRect( 0,0,badgeSize.width,badgeSize.height) 
             operation:NSCompositingOperationSourceOver
				fraction:1];
		}


	[dragImage unlockFocus];
	
    return dragImage;
}

- (NSImage*) dragBadge: (NSUInteger) count
{
	return [[CTBadge systemBadge] smallBadgeForValue: count];
}

#pragma mark -
#pragma mark Event Helpers

- (NSUInteger) indexOfViewAtPoint: (NSPoint) locationInWindow
{
	NSView *target = [self viewAtPoint:[self convertPoint:locationInWindow fromView:nil] excludingView:nil];
	
	if( target ) 
	{
		return [[self subviews] indexOfObject:target];
	}
	
	return NSNotFound;
}

- (void)showPoofAnimation
{
	NSShowAnimationEffect(NSAnimationEffectPoof, [NSEvent mouseLocation], NSZeroSize, NULL, NULL, NULL);
	[NSCursor setHiddenUntilMouseMoves:YES];
}

@end

