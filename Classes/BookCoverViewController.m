//
//  BookCoverViewController.m
//  HTMLRef
//
//  Created by Sean Miceli on 3/4/09.
//  Copyright 2009 CoolThingsMade. All rights reserved.
//

#import "BookCoverViewController.h"
#import "BookCoverView.h"
#import "RootViewController.h"


@implementation BookCoverViewController

@synthesize coveredViewController;

/*
// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}
*/

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    coveredViewController = [[RootViewController alloc] initWithNibName:@"RootViewController" bundle:nil];
    
    ((BookCoverView *)self.view).behindView = coveredViewController.view;
    [(BookCoverView *)self.view startAnimation];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}


- (void)dealloc {
    [super dealloc];
}

-(void)coverHasOpened {
//    [self.navigationController pushViewController:coveredView animated:NO];
}

@end
