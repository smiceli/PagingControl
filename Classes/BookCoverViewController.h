//
//  BookCoverViewController.h
//  HTMLRef
//
//  Created by Sean Miceli on 3/4/09.
//  Copyright 2009 CoolThingsMade. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface BookCoverViewController : UIViewController {
    UIViewController *coveredViewController;
}

@property (nonatomic, retain) UIViewController* coveredViewController;

-(void)coverHasOpened;

@end
