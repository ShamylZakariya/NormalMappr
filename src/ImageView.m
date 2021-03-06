#import "ImageView.h"

@interface ImageView (Private)

- (NSSize)minimumSize;

@end

@implementation ImageView

- (id)initWithFrame:(NSRect)frameRect
{
    if ((self = [super initWithFrame:frameRect]) != nil) {

        [self setPostsFrameChangedNotifications:YES];

        NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self
               selector:@selector(frameSizeChanged:)
                   name:NSViewFrameDidChangeNotification
                 object:nil];

        shadow = [[NSShadow alloc] init];
        [shadow setShadowBlurRadius:20];
        [shadow setShadowOffset:NSMakeSize(1, -1)];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)awakeFromNib
{
    NSScrollView* sv = [self enclosingScrollView];
    if (sv != nil) {
        /*
			Resize self to fit scrollview
			And set width/height resizable
		*/

        NSSize contentSize = [sv contentSize];
        [self setFrameSize:contentSize];
        [self setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    }
}

- (void)setImage:(NSBitmapImageRep*)anImage
{
    BOOL newShadowNeeded = NO;

    if (anImage != image) {
        if (image) {
            newShadowNeeded = (((int)[image size].width != (int)[anImage size].width) || ((int)[image size].height != (int)[anImage size].height));
        } else {
            newShadowNeeded = YES;
        }

        image = anImage;

        if (newShadowNeeded) {
            //
            // update shadow image
            //

            NSSize shadowImageSize = NSMakeSize([image size].width + 2 * [shadow shadowBlurRadius],
                [image size].height + 2 * [shadow shadowBlurRadius]);

            shadowImage = [[NSImage alloc] initWithSize:shadowImageSize];

            NSBitmapImageRep* rep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
                                                                            pixelsWide:shadowImageSize.width
                                                                            pixelsHigh:shadowImageSize.height
                                                                         bitsPerSample:8
                                                                       samplesPerPixel:4
                                                                              hasAlpha:YES
                                                                              isPlanar:NO
                                                                        colorSpaceName:NSDeviceRGBColorSpace
                                                                           bytesPerRow:0
                                                                          bitsPerPixel:0];

            [shadowImage addRepresentation:rep];

            //
            // Create an NSGraphicsContext that draws into the NSBitmapImageRep, and make it current.
            //

            NSGraphicsContext* nsContext = [NSGraphicsContext graphicsContextWithBitmapImageRep:rep];
            [NSGraphicsContext saveGraphicsState];
            [NSGraphicsContext setCurrentContext:nsContext];

            //
            // Clear the bitmap to zero alpha.
            //

            [[NSColor clearColor] set];
            NSRectFill(NSMakeRect(0, 0, [rep pixelsWide], [rep pixelsHigh]));

            //
            // Draw shadow into rep
            //

            [shadow set];
            [[NSColor blackColor] set];
            [[NSBezierPath bezierPathWithRect:NSMakeRect([shadow shadowBlurRadius], [shadow shadowBlurRadius], [image size].width, [image size].height)] fill];

            [NSGraphicsContext restoreGraphicsState];
        }

        if ([self enclosingScrollView]) {
            [self setFrameSize:[self minimumSize]];
        }
    }

    [self setNeedsDisplay:YES];
}

- (NSBitmapImageRep*)image
{
    return image;
}

///////////////////////////////////////////////////////////////////////
// NSView

- (void)drawRect:(NSRect)rect
{
    if (@available(macOS 10.13, *)) {
        [[NSColor colorNamed:@"BatchViewBackground"] set];
    } else {
        [[NSColor colorWithDeviceWhite:0.9 alpha:1] set];
    }
    NSRectFill([self bounds]);

    float scale = self.hiDPI ? (1.0f / [[self window] screen].backingScaleFactor) : 1.0f;
    NSSize imageSize = [image size];
    imageSize.width *= scale;
    imageSize.height *= scale;

    NSSize shadowSize = [shadowImage size];
    shadowSize.width *= scale;
    shadowSize.height *= scale;

    NSSize size = [self bounds].size;

    NSPoint center = NSMakePoint(lrintf(size.width * 0.5f), lrintf(size.height * 0.5f));

    NSPoint imageOrigin = NSMakePoint(center.x - imageSize.width * 0.5f,
        center.y - imageSize.height * 0.5f);

    NSPoint shadowOrigin = NSMakePoint(center.x - shadowSize.width * 0.5f,
        center.y - shadowSize.height * 0.5f);

    [shadowImage drawInRect:NSMakeRect(shadowOrigin.x, shadowOrigin.y, shadowSize.width, shadowSize.height) fromRect:NSMakeRect(0, 0, [shadowImage size].width, [shadowImage size].height) operation:NSCompositingOperationSourceOver fraction:1];

    [image drawInRect:NSMakeRect(imageOrigin.x, imageOrigin.y, imageSize.width, imageSize.height)];
}

- (BOOL)isOpaque
{
    return YES;
}

- (void)frameSizeChanged:(NSNotification*)aNotification
{
    NSScrollView* sv = [self enclosingScrollView];
    if (sv != nil) {
        NSSize contentSize = [sv contentSize],
               finalSize = [self minimumSize];

        if (contentSize.width > finalSize.width) {
            finalSize.width = contentSize.width;
        }

        if (contentSize.height > finalSize.height) {
            finalSize.height = contentSize.height;
        }

        [self setFrameSize:finalSize];
        [self setFrameOrigin:NSMakePoint(0, contentSize.height)];
    }
}

///////////////////////////////////////////////////////////////////////
// Private

- (NSSize)minimumSize
{
    NSSize size = NSMakeSize(0, 0);

    if (image != nil) {
        size = [image size];

        if (self.hiDPI) {
            float scale = 1.0f / [[self window] screen].backingScaleFactor;
            size.width *= scale;
            size.height *= scale;
        }
    }

    return size;
}

@end
