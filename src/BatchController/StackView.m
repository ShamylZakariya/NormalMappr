//
//  StackView.m
//  FilteredImageList
//
//  Created by Shamyl Zakariya on 3/30/09.
//  Copyright 2009 Shamyl Zakariya. All rights reserved.
//

#import "StackView.h"
#import "NSArray+reversedArray.h"

#pragma mark StackView (Private)

@interface StackView(Private)

- (void) animationDidEnd: (NSAnimation*) animation;
- (CGFloat) collapseForView: (NSView*) view;
- (void) setCollapseProgress: (CGFloat) progress;

- (void) frameSizeChanged: (NSNotification*) notification;
- (void) layout;
- (void) generateLayoutForTokens: (NSArray*) tokens availableSize: (CGFloat) size;
- (void) computeCollapseForTokens: (NSArray*) tokens availableSize: (CGFloat) size;

@end

#pragma mark -
#pragma mark CollapseAnimation

@interface CollapseAnimation : NSAnimation
@end

@implementation CollapseAnimation

- (void)setCurrentProgress:(NSAnimationProgress)progress {
    [super setCurrentProgress:progress];	
	[(StackView*)[self delegate] setCollapseProgress: [self currentValue]];
}

@end

#pragma mark -
#pragma mark LayoutToken

@implementation LayoutToken

@synthesize preferredSize, layoutSize, spring, collapse;

+ (LayoutToken*) layoutTokenWithPreferredSize: (CGFloat) size andCollapse: (CGFloat) collapse
{
	return [[[LayoutToken alloc] initWithPreferredSize: size andCollapse: collapse] autorelease];
}

- (id) initWithPreferredSize: (CGFloat) size andCollapse: (CGFloat) collapseAmount
{
	if ( self = [super init] )
	{
		self.preferredSize = size;
		self.layoutSize = size;
		self.spring = size < 0;		
		self.collapse = MIN( MAX( collapseAmount, 0.0 ), 1.0);
	}
	
	return self;
}

@end

#pragma mark -
#pragma mark StackView (Private)

@implementation StackView

@synthesize backgroundColor;

- (id)initWithCoder: (NSCoder*) decoder
{
	if ( self = [super initWithCoder:decoder] )
	{
		[self setPostsFrameChangedNotifications: YES];		
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		[nc addObserver:self 
			selector: @selector( frameSizeChanged: ) 
			name: NSViewFrameDidChangeNotification 
			object: nil ];	
			
		self.backgroundColor = [NSColor clearColor];
		[self setAutoresizesSubviews:NO];
	}

	return self;
}

- (id)initWithFrame:(NSRect)frame 
{
    if (self = [super initWithFrame:frame]) 
	{
		[self setPostsFrameChangedNotifications: YES];		
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		[nc addObserver:self 
			selector: @selector( frameSizeChanged: ) 
			name: NSViewFrameDidChangeNotification 
			object: nil ];	

		self.backgroundColor = [NSColor clearColor];
		[self setAutoresizesSubviews:NO];
    }

    return self;
}

- (void) dealloc
{
	[previousViewCollapse release];
	[viewCollapse release];
	[super dealloc];
}

- (void) awakeFromNib
{
	[self setAutoresizesSubviews:NO];
	[self layout];
}

- (void) setBackgroundColor: (NSColor*) nc
{
	if ( nc != backgroundColor )
	{
		[nc retain];
		[backgroundColor release];
		backgroundColor = nc;
		[self setNeedsDisplay:YES];
	}
}

- (void) setViewCollapse: (NSDictionary*) newViewCollapse animate: (BOOL) animate;
{
	//
	// We move the current view collapse to previousViewCollapse,
	// and then assign the current one
	//

	[previousViewCollapse release];
	previousViewCollapse = viewCollapse;		
	viewCollapse = [newViewCollapse retain];

	if ( animate )
	{
		collapseAnimation = [[CollapseAnimation alloc] initWithDuration: 0.25 animationCurve:NSAnimationEaseInOut];
		[collapseAnimation setDelegate: self];
		[collapseAnimation setAnimationBlockingMode: NSAnimationNonblockingThreaded];
		[collapseAnimation startAnimation];
	}
	else
	{
		collapseProgress = 1;
		[self layout];
	}		
}

- (NSDictionary*) viewCollapse
{
	return viewCollapse;
}

#pragma mark -
#pragma mark NSView Overrides

- (void)didAddSubview:(NSView *)subview
{
	[self layout];
}

- (void)willRemoveSubview:(NSView *)subview
{
	[self performSelector:@selector(frameSizeChanged:) withObject:nil afterDelay:0.0];
}

- (void) drawRect: (NSRect) rect
{
	[backgroundColor set];
	NSRectFill( rect );
}

- (void)resizeSubviewsWithOldSize:(NSSize)oldBoundsSize
{}

#pragma mark -
#pragma mark Private

- (void) animationDidEnd: (NSAnimation*) animation
{
	[collapseAnimation release];
	collapseAnimation = nil;
}

- (CGFloat) collapseForView: (NSView*) view
{
	CGFloat target=1,
	        previous = 1;

	if ( previousViewCollapse )
	{
		NSNumber *key = [NSNumber numberWithUnsignedInteger: (NSUInteger) view];
		NSNumber *collapse = [previousViewCollapse objectForKey: key];
		if ( collapse ) previous = [collapse floatValue];
	}

	if ( viewCollapse )
	{
		NSNumber *key = [NSNumber numberWithUnsignedInteger: (NSUInteger) view];
		NSNumber *collapse = [viewCollapse objectForKey: key];
		if ( collapse ) target = [collapse floatValue];
	}
	
	CGFloat progress = MIN(MAX(collapseProgress,0),1);
	return (progress*target) + ((1-progress)*previous);	
}

- (void) setCollapseProgress: (CGFloat) progress
{
	collapseProgress = MIN(MAX(progress,0),1);
	[self layout];
}

- (void) frameSizeChanged: (NSNotification*) notification
{
	[self layout];
}

- (void) layout
{
	if ( layingOut || !self.subviews.count ) return;
	
	layingOut = YES;
	NSArray *children = [self.subviews reversedArray];
	
	NSMutableArray *tokens = [NSMutableArray arrayWithCapacity: children.count];
	for ( NSView *v in children )
	{
		CGFloat collapse = [self collapseForView: v];
		if ( [v respondsToSelector: @selector(preferredHeight)] )
		{
			[tokens addObject: [LayoutToken layoutTokenWithPreferredSize: [(id)v preferredHeight] andCollapse: collapse ]];
		}
		else
		{
			[tokens addObject: [LayoutToken layoutTokenWithPreferredSize: v.bounds.size.height andCollapse: collapse]];		
		}	
	}

	[self generateLayoutForTokens: tokens availableSize: self.bounds.size.height];

	CGFloat y = self.bounds.size.height;
	for ( NSUInteger i = 0, N = children.count; i < N; i++ )
	{
		NSView *v = [children objectAtIndex: i];
		
		LayoutToken *t = [tokens objectAtIndex:i];

		CGFloat width = self.bounds.size.width,
		        height = t.layoutSize;

		v.frame = NSMakeRect( 0, y - height, width, height );		
		y -= height;
	}
		
	layingOut = NO;	
}

- (void) generateLayoutForTokens: (NSArray*) tokens availableSize: (CGFloat) across
{
	//
	// Determine initial minimum layout space
	//

	CGFloat sizeRequired = 0;
	for ( LayoutToken *token in tokens )
	{
		CGFloat size = token.preferredSize;
		token.layoutSize = size;
		sizeRequired += size;
	}
	
	//
	//	If the required size is less than the area available, distribute
	//	available space across springy tokens.
	//
	if ( sizeRequired < across )
	{
		CGFloat available = across - sizeRequired;
		bool springyTokenAvailable = false;
		
		while ( available > 0 )
		{
			for ( LayoutToken *token in tokens )
			{
				if ( token.spring )
				{
					springyTokenAvailable = true;
					if ( available > 0 )
					{
						token.layoutSize = token.layoutSize + 1;
						available--;
					}
				}
			}
			
			if ( !springyTokenAvailable ) break;
		}
	}
	else
	{
		//
		//	We don't have enough room. Subtract from all until 
		//	overflow is zero.
		//
		
		int overflow = sizeRequired - across;
		
		while ( overflow > 0 )
		{
			bool compactPassPerformed = false;
			
			for ( LayoutToken *token in tokens )
			{
				if ( token.layoutSize > token.preferredSize )
				{
					compactPassPerformed = true;
					token.layoutSize = token.layoutSize - 1;
					overflow--;
					
					if ( overflow <= 0 ) break;
				}
			}
			
			if ( !compactPassPerformed ) break;
		}		
	}
	
	[self computeCollapseForTokens: tokens availableSize: across];
}

- (void) computeCollapseForTokens: (NSArray*) tokens availableSize: (CGFloat) across
{
	//
	// First walk through the tokens and rescale them by their collapse percentage
	//
	
	const CGFloat EPSILON = 1e-3;
	BOOL canExpand = NO;
	CGFloat sizeRequired = 0;
	for ( LayoutToken *token in tokens )
	{
		if ( token.collapse < 1.0 - EPSILON )
		{
			token.layoutSize = token.layoutSize * token.collapse;
		}
		else if ( token.spring )
		{
			canExpand = YES;
		}
		
		sizeRequired += token.layoutSize;
	}
	
	//
	//	If the required size is less than the area available, distribute
	//	available space across springy tokens.
	//

	if ( sizeRequired < across && canExpand )
	{
		CGFloat available = across - sizeRequired;
		bool springyTokenAvailable = false;
		
		while ( available > 0 )
		{
			NSUInteger index = 0;
			for ( LayoutToken *token in tokens )
			{
				if ( token.spring && ( token.collapse >= 1.0 - EPSILON ))
				{
					springyTokenAvailable = true;
					if ( available > 0 )
					{
						token.layoutSize = token.layoutSize + 1;
						available--;
					}
				}
				
				index++;
			}
			
			if ( !springyTokenAvailable ) break;
		}
	}
		
}

@end
