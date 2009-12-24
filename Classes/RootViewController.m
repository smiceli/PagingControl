//
//  RootViewController.m
//  HTMLRef
//
//  Created by Sean Miceli on 12/31/08.
//  Copyright CoolThingsMade 2008. All rights reserved.
//

#import "RootViewController.h"
#import "HTMLDetailController.h"
#import "HTMLRefAppDelegate.h"
#import "HTMLTagItem.h"
#import "TopicTableViewCell.h"


@implementation RootViewController

@synthesize detailController;

#define ROW_HEIGHT 60

- (id)initWithStyle:(UITableViewStyle)style {
	if ((self = [super initWithStyle:style])) {
		self.tableView.rowHeight = ROW_HEIGHT;
	}
	return self;
}

/*
- (void)viewDidLoad {
    [super viewDidLoad];

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}
*/

-(void)awakeFromNib {
    self.title = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
}

- (void)viewWillAppear:(BOOL)animated {
    [self.tableView reloadData];
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    HTMLRefAppDelegate *appDelegate = (HTMLRefAppDelegate *)[[UIApplication sharedApplication] delegate];
    appDelegate.savedLocation = [NSNumber numberWithInt:-1];
    [super viewDidAppear:animated];
}
/*
- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}
*/
/*
- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}
*/

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}

-(HTMLDetailController*)detailController {
    if(!detailController)
        detailController = [[HTMLDetailController alloc] initWithNibName:@"HTMLDetailView" bundle:nil];
    return detailController;
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    HTMLRefAppDelegate *appDelegate = (HTMLRefAppDelegate *)[[UIApplication sharedApplication] delegate];
    return [[appDelegate tagArray] count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return ROW_HEIGHT;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if(!cell) {
        cell = [[[TopicTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    // Set up the cell...
    HTMLRefAppDelegate *appDelegate = (HTMLRefAppDelegate *)[[UIApplication sharedApplication] delegate];
    HTMLTagItem *tagItem = [[appDelegate tagArray] objectAtIndex:indexPath.row];
    [(TopicTableViewCell*)cell setTagItem:tagItem];

    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    HTMLRefAppDelegate *appDelegate = (HTMLRefAppDelegate *)[[UIApplication sharedApplication] delegate];
    appDelegate.savedLocation = [NSNumber numberWithInt:indexPath.row];
    HTMLDetailController *controller = self.detailController;
    controller.tagItem = [[appDelegate tagArray] objectAtIndex:indexPath.row];
    [controller.tagItem hydrate];
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)dealloc {
    [detailController release];
    [super dealloc];
}

-(void)restoreLocation:(NSInteger)location {
    HTMLRefAppDelegate *appDelegate = (HTMLRefAppDelegate *)[[UIApplication sharedApplication] delegate];
    HTMLDetailController *controller = self.detailController;
    controller.tagItem = [[appDelegate tagArray] objectAtIndex:location];
    [controller.tagItem hydrate];
    [self.navigationController pushViewController:controller animated:NO];
}

@end

