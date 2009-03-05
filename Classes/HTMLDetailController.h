//
//  HTMLDetailController.h
//  HTMLRef
//
//  Created by Sean Miceli on 1/1/09.
//  Copyright 2009 CoolThingsMade. All rights reserved.
//

#import <UIKit/UIKit.h>

@class HTMLTagItem;

@interface HTMLDetailController : UIViewController <UIWebViewDelegate>{
    HTMLTagItem *tagItem;
    IBOutlet UIWebView *myWebView;
}

@property (nonatomic, retain) HTMLTagItem *tagItem;

@end
