//
//  RootViewController.h
//  HTMLRef
//
//  Created by Sean Miceli on 12/31/08.
//  Copyright CoolThingsMade 2008. All rights reserved.
//

#import <UIKit/UIKit.h>

@class HTMLDetailController;

@interface RootViewController : UITableViewController {
    HTMLDetailController *detailController;
}

@property (nonatomic, retain) HTMLDetailController* detailController;

-(void)restoreLocation:(NSInteger)location;

@end
