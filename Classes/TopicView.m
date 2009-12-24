//
//  TopicView.m
//  HTMLRef
//
//  Created by Sean Miceli on 1/23/09.
//  Copyright 2009 CoolThingsMade. All rights reserved.
//

#import "TopicView.h"


@implementation TopicView

@synthesize highlighted, tagItem;

static UIFont *topicFont = nil;
static UIFont *briefDescriptionFont = nil;

#define LEFT_COLUMN_OFFSET 10

#define UPPER_ROW_TOP 8
#define LOWER_ROW_TOP 34

#define MAIN_FONT_SIZE 18
#define MIN_MAIN_FONT_SIZE 16
#define SECONDARY_FONT_SIZE 12
#define MIN_SECONDARY_FONT_SIZE 10

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        if(!topicFont)
            topicFont = [[UIFont boldSystemFontOfSize:MAIN_FONT_SIZE] retain];
        if(!briefDescriptionFont)
            briefDescriptionFont = [[UIFont systemFontOfSize:SECONDARY_FONT_SIZE] retain];
        
		self.opaque = YES;
		self.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
	UIColor *topicColor;
	UIColor *descriptionColor;
	
	if(self.highlighted) {
		topicColor = [UIColor whiteColor];
        descriptionColor = [UIColor whiteColor];
	}
    else {
		topicColor = [UIColor blackColor];
        descriptionColor = [UIColor darkGrayColor];
		self.backgroundColor = [UIColor whiteColor];
    }
	
	CGRect contentRect = self.bounds;
    CGFloat boundsX = contentRect.origin.x;
    CGPoint point = CGPointMake(boundsX + LEFT_COLUMN_OFFSET, UPPER_ROW_TOP);
    	
	[topicColor set];
	[tagItem.tag drawAtPoint:point withFont:topicFont];
	
    [descriptionColor set];
    point = CGPointMake(boundsX + LEFT_COLUMN_OFFSET, LOWER_ROW_TOP);
	[tagItem.tagDescription drawAtPoint:point withFont:briefDescriptionFont];
}


- (void)dealloc {
    [tagItem release];
    [super dealloc];
}

-(void)setHighlighted:(bool)isHighlighted {
    highlighted = isHighlighted;
    [self setNeedsDisplay];
}

-(void)setTagItem:(HTMLTagItem*)item {
    if(tagItem == item) return;
    [tagItem release];
    tagItem = item;
    [self setNeedsDisplay];
}
@end
