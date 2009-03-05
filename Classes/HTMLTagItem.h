//
//  HTMLTagItem.h
//  HTMLRef
//
//  Created by Sean Miceli on 12/31/08.
//  Copyright 2008 CoolThingsMade. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>


@interface HTMLTagItem : NSObject {
    NSString *tag;
    NSString *tagDescription;
    NSString *body;
    
    NSInteger primaryKey;
    sqlite3 *database;
    bool hydrated;
}

@property (nonatomic, copy) NSString *tag;
@property (nonatomic, copy) NSString *tagDescription;
@property (nonatomic, copy) NSString *body;

-(id)initWithString: (NSString*)aTag;
- (id)initWithPrimaryKey:(NSInteger)pk database:(sqlite3 *)db;
+(HTMLTagItem *)HTMLTagItemWithString: (NSString*)aTag;
+(void)finalizeStatements;

-(void)hydrate;
-(void)dehydrate;

@end
