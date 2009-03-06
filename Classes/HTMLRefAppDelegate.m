//
//  HTMLRefAppDelegate.m
//  HTMLRef
//
//  Created by Sean Miceli on 12/31/08.
//  Copyright CoolThingsMade 2008. All rights reserved.
//

#import "HTMLRefAppDelegate.h"
#import "RootViewController.h"
#import "HTMLTagItem.h"
#import "Defs.h"

@interface HTMLRefAppDelegate (Private)
- (void)initializeDatabase;
@end

@implementation HTMLRefAppDelegate

NSString *kRestoreLocationKey = @"restoreLocation";

@synthesize window;
@synthesize navigationController;
@synthesize tagArray;
@synthesize savedLocation;


- (void)applicationDidFinishLaunching:(UIApplication *)application {
#if 0
	NSDictionary *savedLocationDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                       0, kRestoreLocationKey,
                                       0, kRestoreWebViewLocationKey,
                                       NULL, NULL];
    
	[[NSUserDefaults standardUserDefaults] registerDefaults:savedLocationDict];
	[[NSUserDefaults standardUserDefaults] synchronize];

    [self initializeDatabase];
    
	savedLocation = [[NSUserDefaults standardUserDefaults] objectForKey:kRestoreLocationKey];
    if(self.savedLocation && [self.savedLocation intValue] >= 0)
        [(RootViewController*)navigationController.topViewController restoreLocation:[savedLocation intValue]];
    else
        self.savedLocation = [NSNumber numberWithInt:-1];

#endif
    
	// Configure and show the window
	[window addSubview:[navigationController view]];
	[window makeKeyAndVisible];
}


- (void)applicationWillTerminate:(UIApplication *)application {
#if 0
	[[NSUserDefaults standardUserDefaults] setObject:savedLocation forKey:kRestoreLocationKey];
    
    [tagArray makeObjectsPerformSelector:@selector(dehydrate)];
    [HTMLTagItem finalizeStatements];
    if (sqlite3_close(database) != SQLITE_OK) {
        NSAssert1(0, @"Error: failed to close database with message '%s'.", sqlite3_errmsg(database));
    }
#endif
}

-(void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
#if 0
    [tagArray makeObjectsPerformSelector:@selector(dehydrate)];
#endif
}

-(void)dealloc {
	[navigationController release];
	[window release];
    [tagArray release];
    [savedLocation release];
	[super dealloc];
}

- (void)initializeDatabase {
    tagArray = [[NSMutableArray alloc] init];
    NSString *dbPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"database.sqlite"];
    if (sqlite3_open([dbPath UTF8String], &database) != SQLITE_OK) {
        NSAssert1(0, @"Failed to open database with message '%s'.", sqlite3_errmsg(database));
        sqlite3_close(database);
        return;
    }
    
    const char *sql = "SELECT pk FROM HTMLRef";
    sqlite3_stmt *statement;
    if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) != SQLITE_OK) {
        NSAssert1(0, @"Failed to open database with message '%s'.", sqlite3_errmsg(database));
        sqlite3_close(database);
        return;
    }

    while (sqlite3_step(statement) == SQLITE_ROW) {
        int primaryKey = sqlite3_column_int(statement, 0);
        HTMLTagItem *tagItem = [[HTMLTagItem alloc] initWithPrimaryKey:primaryKey database:database];
        [tagArray addObject:tagItem];
        [tagItem release];
    }
    sqlite3_finalize(statement);
}

@end
