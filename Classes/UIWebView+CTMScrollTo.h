//
//  UIWebView+CTMScrollTo.h
//  HTMLRef
//
//  Created by Sean Miceli on 1/12/09.
//  Copyright 2009 CoolThingsMade. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface UIWebView (CTMScrollTo)

-(NSInteger)ctmPosition;
-(void)setCtmPosition:(NSInteger)yPixels;

@end
