//
//  TopicView.h
//  HTMLRef
//
//  Created by Sean Miceli on 1/23/09.
//  Copyright 2009 CoolThingsMade. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HTMLTagItem.h"


@interface TopicView : UIView {
    bool highlighted;
    HTMLTagItem *tagItem;
}

@property (nonatomic, assign, getter=isHighlighted) bool highlighted;
@property (nonatomic, retain) HTMLTagItem *tagItem;
@end
