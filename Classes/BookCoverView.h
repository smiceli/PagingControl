//
//  BookCoverView.h
//  HTMLRef
//
//  Created by Sean Miceli on 3/4/09.
//  Copyright 2009 CoolThingsMade. All rights reserved.
//


#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>

#import "PVector.h"

@class Page;

/*
 This class wraps the CAEAGLLayer from CoreAnimation into a convenient UIView subclass.
 The view content is basically an EAGL surface you render your OpenGL scene into.
 Note that setting the view non-opaque will only work if the EAGL surface has an alpha channel.
 */
@interface BookCoverView : UIView {
    
    UIView *behindView;
    
@private
    /* The pixel dimensions of the backbuffer */
    GLint backingWidth;
    GLint backingHeight;
    
    EAGLContext *context;
    
    /* OpenGL names for the renderbuffer and framebuffers used to render to this view */
    GLuint viewRenderbuffer, viewFramebuffer;
    
    /* OpenGL name for the depth buffer that is attached to viewFramebuffer, if it exists (0 if it does not exist) */
    GLuint depthRenderbuffer;
    
    NSTimer *animationTimer;
    NSTimeInterval animationInterval;
    
    Page *page;
    GLushort *indicies;
    PVector *normals;
    CGSize meshSize;
    
    CGRect modelCoords;
    CGRect glViewCoords;
    CGFloat viewFront;
    CGFloat paperZ;

    PVector lightPosition;
    CGFloat shadowMatrix[16];
    
    GLuint behindTexture;
    CGRect behindTextureCoords;
}

@property (nonatomic, assign) NSTimeInterval animationInterval;
@property (nonatomic, retain) UIView *behindView;

- (void)startAnimation;
- (void)stopAnimation;
- (void)drawView;

@end
