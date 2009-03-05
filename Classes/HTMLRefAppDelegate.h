//
//  HTMLRefAppDelegate.h
//  HTMLRef
//
//  Created by Sean Miceli on 12/31/08.
//  Copyright CoolThingsMade 2008. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <sqlite3.h>

@interface HTMLRefAppDelegate : NSObject <UIApplicationDelegate> {
    
    UIWindow *window;
    UINavigationController *navigationController;
    NSMutableArray *tagArray;
    sqlite3 *database;
    NSNumber *savedLocation;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UINavigationController *navigationController;
@property (nonatomic, retain) NSMutableArray *tagArray;
@property (nonatomic, copy) NSNumber*savedLocation;

@end

