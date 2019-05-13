//
//  DarkModeAdaptingButton.m
//  NormalMappr
//
//  Created by Shamyl Zakariya on 5/12/19.
//

#import "TemplateInDarkModeButton.h"

@implementation TemplateInDarkModeButton

- (void) layout {
    if (@available(macOS 10.14, *)) {
        if ([[self effectiveAppearance].name isEqualToString:NSAppearanceNameDarkAqua])
        {
            [[self image] setTemplate:YES];
        }
    }
    [super layout];
}

@end
