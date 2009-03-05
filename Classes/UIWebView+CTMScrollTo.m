//
//  UIWebView+CTMScrollTo.m
//  HTMLRef
//
//  Created by Sean Miceli on 1/12/09.
//  Copyright 2009 CoolThingsMade. All rights reserved.
//

#import "UIWebView+CTMScrollTo.h"


@implementation UIWebView (CTMScrollTo)
-(NSInteger)ctmPosition {
    return [[self stringByEvaluatingJavaScriptFromString:@"scrollY"] intValue];
}

-(void)setCtmPosition:(NSInteger)yPixels {
    [self stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"window.scrollTo(0, %d);", yPixels]];
}
@end
