//
//  TopicTableViewCell.h
//  HTMLRef
//
//  Created by Sean Miceli on 1/21/09.
//  Copyright 2009 CoolThingsMade. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TopicView;
@class HTMLTagItem;

@interface TopicTableViewCell : UITableViewCell {
    TopicView *topicView;
}

-(void)setTagItem:(HTMLTagItem *)item;

@end
