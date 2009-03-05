//
//  HTMLDetailController.m
//  HTMLRef
//
//  Created by Sean Miceli on 1/1/09.
//  Copyright 2009 CoolThingsMade. All rights reserved.
//

#import "HTMLDetailController.h"
#import "HTMLTagItem.h"
#import "UIWebView+CTMScrollTo.h"

@implementation HTMLDetailController

@synthesize tagItem;

NSString *kRestoreWebViewLocationKey = @"restoreWebViewLocation";

/*
// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
 self.navigationItem.rightBarButtonItem = self.editButtonItem;
}
*/

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
//    return (interfaceOrientation == UIInterfaceOrientationPortrait);
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}


- (void)dealloc {
    [tagItem release];
    [myWebView release];
    [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.title = self.tagItem.tag;
    
    [myWebView loadHTMLString:tagItem.body baseURL:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    int yLoc = [myWebView ctmPosition];
    [[NSUserDefaults standardUserDefaults] setInteger:yLoc forKey:kRestoreWebViewLocationKey];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    int yLoc = [[[NSUserDefaults standardUserDefaults] objectForKey:kRestoreWebViewLocationKey] intValue];
    [myWebView setCtmPosition:yLoc];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
	// report the error inside the webview
	NSString* errorString = [NSString stringWithFormat:
							 @"<html><center><font size=+5 color='red'>An error occurred:<br>%@</font></center></html>",
							 error.localizedDescription];
	[myWebView loadHTMLString:errorString baseURL:nil];
}

@end
