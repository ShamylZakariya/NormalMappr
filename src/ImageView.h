/* ImageView */

#import <Cocoa/Cocoa.h>

@interface ImageView : NSView
{
	NSImage *shadowImage;
	NSBitmapImageRep *image;
	NSShadow *shadow;
}

@property (readwrite,retain) NSBitmapImageRep* image;

@end
