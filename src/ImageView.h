/* ImageView */

#import <Cocoa/Cocoa.h>

@interface ImageView : NSView
{
	NSImage *shadowImage;
	NSBitmapImageRep *image;
	NSShadow *shadow;
}

@property (readwrite,retain) NSBitmapImageRep* image;

// if true, images will be displayed in high-dpi on retina displays
// note: this means they'll be "half as big"
@property (readwrite,atomic) BOOL hiDPI;

@end
