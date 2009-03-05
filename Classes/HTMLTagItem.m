//
//  HTMLTagItem.m
//  HTMLRef
//
//  Created by Sean Miceli on 12/31/08.
//  Copyright 2008 CoolThingsMade. All rights reserved.
//

#import "HTMLTagItem.h"

static sqlite3_stmt *init_statement = nil;
static sqlite3_stmt *hydrate_statement = nil;

@implementation HTMLTagItem

@synthesize tag, tagDescription, body;

-(id)initWithString: (NSString*)aTag {
    if(!(self = [super init])) return nil;
        
    self.tag = aTag;
    return self;
}

-(id)initWithPrimaryKey:(NSInteger)pk database:(sqlite3 *)db {
    if(!(self = [super init])) return nil;
    
    primaryKey = pk;
    database = db;
    if(init_statement == nil) {
        const char *sql = "SELECT tag, description FROM HTMLRef WHERE pk=?";
        if(sqlite3_prepare_v2(database, sql, -1, &init_statement, NULL) != SQLITE_OK) {
            NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
        }
    }
    sqlite3_bind_int(init_statement, 1, primaryKey);
    if(sqlite3_step(init_statement) == SQLITE_ROW) {
        self.tag = [NSString stringWithUTF8String:(char *)sqlite3_column_text(init_statement, 0)];
        self.tagDescription = [NSString stringWithUTF8String:(char *)sqlite3_column_text(init_statement, 1)];
    }
    else {
        self.tag = @"No title";
        self.tagDescription = @"";
    }

    sqlite3_reset(init_statement);
    return self;
}

+(HTMLTagItem *)HTMLTagItemWithString: (NSString*)aTag {
    return [[[HTMLTagItem alloc] initWithString:aTag] autorelease];
}

-(void)dealloc
{
    [tag release];
    [tagDescription release];
    [body release];
    [super dealloc];
}

+(void)finalizeStatements {
    if(init_statement) {
        sqlite3_finalize(init_statement);
        init_statement = nil;
    }
    if(hydrate_statement) {
        sqlite3_finalize(hydrate_statement);
        hydrate_statement = nil;
    }
}

-(void)hydrate {
    if (hydrated) return;

    if (hydrate_statement == nil) {
        const char *sql = "SELECT body FROM HTMLRef WHERE pk=?";
        if (sqlite3_prepare_v2(database, sql, -1, &hydrate_statement, NULL) != SQLITE_OK) {
            NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
        }
    }

    sqlite3_bind_int(hydrate_statement, 1, primaryKey);
    int success =sqlite3_step(hydrate_statement);
    if (success == SQLITE_ROW) {
        char *str = (char *)sqlite3_column_text(hydrate_statement, 0);
        self.body = (str) ? [NSString stringWithUTF8String:str] : @"<html><center><font size=+5 color='red'>Error reading tag reference page.</font></center></html>";
    } else {
        self.body = @"<html><center><font size=+5 color='red'>Error reading tag reference page.</font></center></html>";
    }
    // Reset the query for the next use.
    sqlite3_reset(hydrate_statement);
    // Update object state with respect to hydration.
    hydrated = YES;
}

-(void)dehydrate {
    self.body = nil;
    hydrated = NO;
}
@end
