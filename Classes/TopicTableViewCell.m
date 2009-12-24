//
//  TopicTableViewCell.m
//  HTMLRef
//
//  Created by Sean Miceli on 1/21/09.
//  Copyright 2009 CoolThingsMade. All rights reserved.
//

#import "TopicTableViewCell.h"
#import "TopicView.h"


@implementation TopicTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
		CGRect topicViewFrame = CGRectMake((CGFloat)0.0, (CGFloat)0.0, self.contentView.bounds.size.width, self.contentView.bounds.size.height);
		topicView = [[TopicView alloc] initWithFrame:topicViewFrame];
		topicView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		[self.contentView addSubview:topicView];
    }
    return self;
}


- (void)dealloc {
    [topicView dealloc];
    [super dealloc];
}

-(void)setTagItem:(HTMLTagItem*)item {
    topicView.tagItem = item;
}
@end
