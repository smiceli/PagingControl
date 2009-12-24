//
//  BookCoverView.m
//  HTMLRef
//
//  Created by Sean Miceli on 3/4/09.
//  Copyright 2009 CoolThingsMade. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>

#import "BookCoverView.h"
#import "Page.h"
#import "UIView+CTMImage.h"

#define USE_DEPTH_BUFFER 1

typedef struct {
    GLubyte r, g, b, a;
} BlockColor;

BlockColor *blockColors;

// A class extension to declare private methods
@interface BookCoverView ()

@property (nonatomic, retain) EAGLContext *context;
@property (nonatomic, assign) NSTimer *animationTimer;

- (BOOL) createFramebuffer;
- (void) destroyFramebuffer;
- (void) layoutPaper;
- (void) prepareOpenGL;
- (void) drawBackground;

@end


@implementation BookCoverView

@synthesize context;
@synthesize animationTimer;
@synthesize animationInterval;
@synthesize behindView;


// You must implement this method
+ (Class)layerClass {
    return [CAEAGLLayer class];
}

//The GL view is stored in the nib file. When it's unarchived it's sent -initWithCoder:
- (id)initWithCoder:(NSCoder*)coder {
    
    if(!(self = [super initWithCoder:coder])) return nil;

    // Get the layer
    CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
    
    eaglLayer.opaque = YES;
    eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
    
    context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
    
    if (!context || ![EAGLContext setCurrentContext:context]) {
        [self release];
        return nil;
    }
    
    animationInterval = 1.0 / 30.0;
    return self;
}

-(void) layoutPaper {
    meshSize = CGSizeMake(10, 20);
    
#pragma mark Color Code
    blockColors = malloc((int)(meshSize.width*meshSize.height*sizeof(*blockColors)));
    BlockColor *c = blockColors;
    for(int y = 0; y < meshSize.height; y++) {
        for(int x = 0; x < meshSize.width; x++) {
            c->r = rand()/(float)RAND_MAX*255;
            c->g = rand()/(float)RAND_MAX*255;
            c->b = rand()/(float)RAND_MAX*255;
            c++;
        }
    }

    normals = malloc((int)(meshSize.width*meshSize.height*sizeof(*normals)));
    indicies = malloc((int)((meshSize.width-1)*(meshSize.height-1)*sizeof(*indicies))*6);
    GLushort *anIndex = indicies;
    for(int y = 0; y < meshSize.height-1; y++) {
        for(int x = 0; x < meshSize.width-1; x++) {
            *anIndex++ = y*(int)meshSize.width+x;
            *anIndex++ = (y+1)*(int)meshSize.width+x;
            *anIndex++ = y*(int)meshSize.width+(x+1);

            *anIndex++ = (y+1)*(int)meshSize.width+x;
            *anIndex++ = (y+1)*(int)meshSize.width+(x+1);
            *anIndex++ = y*(int)meshSize.width+(x+1);
        }
    }
    
    glViewCoords = CGRectMake(-backingWidth/(CGFloat)2.0, -backingHeight/(CGFloat)2.0, backingWidth, backingHeight);
 
    viewFront = backingHeight*10;
    paperZ = viewFront + backingHeight;
    CGFloat newW = ((backingWidth/(CGFloat)2.0)/viewFront)*paperZ;
    CGFloat newH = ((backingHeight/(CGFloat)2.0)/viewFront)*paperZ;
    modelCoords = CGRectMake(-newW, -newH, newW*2, newH*2);
    
    page = [[Page alloc] initWithSize:modelCoords.size andMeshSize:meshSize];    
    
#if 0
    UIImage *image = [UIImage imageNamed:@"ethan.jpg"];
    if(!image) return;
    
    
    NSImageRep *imageRep = [image bestRepresentationForDevice:nil];
    if(![imageRep isKindOfClass:[NSBitmapImageRep class]]) return;
    
    NSBitmapImageRep *bitmapImageRep = (NSBitmapImageRep*)imageRep;
    glGenTextures(1, &imageTexture);
    [bitmapImageRep copyToGLTexture:imageTexture];
#endif
    lightPosition.x = -4*backingHeight;
    lightPosition.y = backingHeight*2;
    lightPosition.z = paperZ;
    
    PVector a = {modelCoords.size.width, 0, 0};
    PVector b = {0, modelCoords.size.height, 0};
    PVector o = {modelCoords.size.width, modelCoords.size.height, 0};
    PVector lp = {0, backingHeight*2, paperZ};
    CGFloat planeEq[4];
    planeEquation(planeEq, a, b, o);
    fillInPlanarShadowMatrix(shadowMatrix, planeEq, lp);
}


-(void)prepareOpenGL {
    glEnable(GL_LIGHTING);
    
    GLfloat global_ambient[] = { (CGFloat).4, (CGFloat).4, (CGFloat).4, (CGFloat).4 };
    glLightModelfv(GL_LIGHT_MODEL_AMBIENT, global_ambient);
    
    GLfloat ambient[] = { (CGFloat).3, (CGFloat).3, (CGFloat).3 };
    glLightfv(GL_LIGHT0, GL_AMBIENT, ambient);
    GLfloat diffuseLight[] = { (CGFloat)0.9, (CGFloat)0.9, (CGFloat)0.9, (CGFloat)1.0 };
    glLightfv(GL_LIGHT0, GL_DIFFUSE, diffuseLight);
    //    GLfloat specularLight[] = { 0.4f, 0.4f, 0.4, 1.0f };
    //    glLightfv(GL_LIGHT0, GL_SPECULAR, specularLight);
    GLfloat lightPosition4f[4];
    lightPosition4f[0] = lightPosition.x;
    lightPosition4f[1] = lightPosition.y;
    lightPosition4f[2] = lightPosition.z;
    lightPosition4f[3] = (CGFloat)1.0;
    glLightfv(GL_LIGHT0, GL_POSITION, lightPosition4f);
    
    PVector vdirection = {CGRectGetMidX(modelCoords), CGRectGetMidY(modelCoords), paperZ};
    vdirection = vnormalize(vsub(vdirection, lightPosition));
    float direction[4];
    direction[0] = vdirection.x;
    direction[1] = vdirection.y;
    direction[2] = vdirection.z;
    direction[3] = (CGFloat)1.0;
//    glLightfv(GL_LIGHT0, GL_SPOT_DIRECTION, direction);
//    glLightf(GL_LIGHT0, GL_SPOT_CUTOFF, 30);
    glEnable(GL_LIGHT0);
    glEnable(GL_COLOR_MATERIAL);

#if 0
    if(imageTexture) {
        glEnable(GL_TEXTURE_2D);
        glBindTexture(GL_TEXTURE_2D, imageTexture);
        
        glMatrixMode(GL_TEXTURE);
        glRotatef(90, 0, 0, 1);
    }
#endif
}

#if 0
-(void)drawView {
    [EAGLContext setCurrentContext:context];
    
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
    glViewport(0, 0, backingWidth, backingHeight);

    glClearColor(0.5f, 0.5f, 0.5f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    [self prepareOpenGL];
    
    [page updateParticles:animationInterval];
    
#if 0
    int neighbors[] = {
        0, 1, meshSize.width, meshSize.width+1
    };
    Particle *c = [page particles];
    
    CGFloat x0 = c->p0.x;
    CGFloat y0 = c->p0.y;
    
//    glBegin(GL_QUADS);
    int ci = 0;
    for(int y = 0; y < meshSize.height-1; y++) {
        for(int x = 0; x < meshSize.width-1; x++) {
//            if(!imageTexture)
//                glColor3f(blockColors[ci].r, blockColors[ci].g, blockColors[ci].b);
            
#if 0
            PVector n = normal3((c+neighbors[1])->p, (c+neighbors[3])->p, c->p);
            //            glNormal3dv((CGFloat*)&n);
#else
            Particle *particles = [page particles];
#if 0
            PVector normals[4];
            int normalIndex = 0;
            static int nneigborsX[] = {0, -1, 0, 1};
            static int nneigborsY[] = {1, 0, -1, 0};
            for(int i = 0; i < 4; i++) {
                int nx = x + nneigborsX[i];
                int ny = y + nneigborsY[i];
                Particle *p1 = NULL;
                if(nx >= 0 && ny >= 0 && nx < meshSize.width && ny < meshSize.height)
                    p1 = particles+ny*(int)meshSize.width+nx;
                
                nx = x + nneigborsX[(i+1)%4];
                ny = y + nneigborsY[(i+1)%4];
                Particle *p2 = NULL;
                if(nx >= 0 && ny >= 0 && nx < meshSize.width && ny < meshSize.height)
                    p2 = particles+ny*(int)meshSize.width+nx;
                if(p1 && p2)
                    normals[normalIndex++] = normal3(p1->p, p2->p, c->p);
            }
            PVector normalSum = normals[0];
            for(int i = 1; i < normalIndex; i++)
                normalSum = vadd(normalSum, normals[i]);
            PVector n = vnormalize(vmulConst(normalSum, (CGFloat)1.0/(CGFloat)normalIndex));
#endif
#endif
            CGFloat virtecies[4*3];
            int j = 0;
            for(int i = 0; i < 4; i++) {
                Particle *p = c+neighbors[i];
                colors[j] = blockColors[ci].r;
                virtecies[j++] = p->p.x;
                colors[j] = blockColors[ci].g;
                virtecies[j++] = p->p.y;
                colors[j] = blockColors[ci].b;
                virtecies[j++] = p->p.z;
//                glNormal3dv((CGFloat*)&n);
//                if(imageTexture)
//                    glTexCoord2f((p->p0.x-x0), (p->p0.y-y0));
//                glVertex3f(p->p.x, p->p.y, p->p.z);
                
            }

            glVertexPointer(3, GL_FLOAT, 0, virtecies);
            glEnableClientState(GL_VERTEX_ARRAY);
            glColorPointer(3, GL_FLOAT, 0, colors);
            glEnableClientState(GL_COLOR_ARRAY);
            
            glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
            c++;
            ci++;
       }
        c++;
    }
//    glEnd();
#else
    const GLfloat squareVertices[] = {
        -0.5f, -0.5f,
        0.5f,  -0.5f,
        -0.5f,  0.5f,
        0.5f,   0.5f,
    };
    const GLubyte squareColors[] = {
        255, 255,   0, 255,
        0,   255, 255, 255,
        0,     0,   0,   0,
        255,   0, 255, 255,
    };
    glVertexPointer(2, GL_FLOAT, 0, squareVertices);
    glEnableClientState(GL_VERTEX_ARRAY);
    glColorPointer(4, GL_UNSIGNED_BYTE, 0, squareColors);
    glEnableClientState(GL_COLOR_ARRAY);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
#endif

    glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
    [context presentRenderbuffer:GL_RENDERBUFFER_OES];
}
#endif

-(void)drawBackground {
    if(!behindView) return;
    
    glEnable(GL_TEXTURE_2D);
    if(!behindTexture) {
        glGenTextures(1, &behindTexture);
        [behindView copyToGLTexture:behindTexture putTextureCoordsIn:&behindTextureCoords];
    }
    
    GLfloat squareVertices[8];
    squareVertices[0] = CGRectGetMinX(modelCoords);
    squareVertices[1] = CGRectGetMinY(modelCoords);
    squareVertices[2] = CGRectGetMaxX(modelCoords);
    squareVertices[3] = CGRectGetMinY(modelCoords);
    squareVertices[4] = CGRectGetMinX(modelCoords);
    squareVertices[5] = CGRectGetMaxY(modelCoords);
    squareVertices[6] = CGRectGetMaxX(modelCoords);
    squareVertices[7] = CGRectGetMaxY(modelCoords);
    
    const GLfloat textureCoords[] = {
        behindTextureCoords.origin.x, behindTextureCoords.origin.y,
        behindTextureCoords.size.width, behindTextureCoords.origin.y,
        behindTextureCoords.origin.x, behindTextureCoords.size.height,
        behindTextureCoords.size.width, behindTextureCoords.size.height
    };
    const GLfloat normalCoords[] = {
        0, 0, 1,
        0, 0, 1,
        0, 0, 1,
        0, 0, 1
    };
    glPushMatrix();
    glTranslatef(0, 0, -paperZ-(CGFloat).1);
    glVertexPointer(2, GL_FLOAT, 0, squareVertices);
    glEnableClientState(GL_VERTEX_ARRAY);
    glTexCoordPointer(2, GL_FLOAT, 0, textureCoords);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    glNormalPointer(GL_FLOAT, 0, normalCoords);
    glEnableClientState(GL_NORMAL_ARRAY);
    glColor4f(1, 1, 1, 1);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    glPopMatrix();
    
    glDisable(GL_TEXTURE_2D);
    glDisableClientState(GL_TEXTURE_COORD_ARRAY);
}

- (void)drawView {
    [EAGLContext setCurrentContext:context];
    
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
    glViewport(0, 0, backingWidth, backingHeight);
    
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glFrustumf(CGRectGetMinX(glViewCoords), CGRectGetMaxX(glViewCoords), CGRectGetMinY(glViewCoords), CGRectGetMaxY(glViewCoords), viewFront, paperZ+100);
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
  
    glEnable(GL_DEPTH_TEST);
    glClearColor(0.5f, 0.5f, 0.5f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);
    
#pragma mark Drawing Code

    [page updateParticles:animationInterval*4];
    
    Particle *p = [page particles];
    PVector vertecies[(int)(meshSize.width*meshSize.height)];
    PVector *v = vertecies;
    PVector *n = normals;
    for(int y = 0; y < meshSize.height; y++) {
        for(int x = 0; x < meshSize.width; x++) {
            *v++ = p->p;
            if(x != meshSize.width-1 && y != meshSize.height-1)
                *n++ = normal3((p+1)->p, (p+(int)meshSize.width)->p, p->p);
            else if(x == meshSize.width-1 && y == meshSize.height-1)
                *n++ = normal3((p-1)->p, (p-(int)meshSize.width)->p, p->p);
            else if(x == meshSize.width-1)
                *n++ = normal3((p+(int)meshSize.width)->p, (p-1)->p, p->p);
            else
                *n++ = normal3((p-(int)meshSize.width)->p, (p+1)->p, p->p);
                
            p++;
        }
    }

    [self drawBackground];

    glTranslatef(modelCoords.origin.x, modelCoords.origin.y, -paperZ);

//    glPushMatrix();
//    glMultMatrixf(shadowMatrix);
//    glDisable(GL_LIGHTING);
    
    glEnableClientState(GL_VERTEX_ARRAY);
    glVertexPointer(3, GL_FLOAT, 0, vertecies);
    glEnableClientState(GL_NORMAL_ARRAY);
    glNormalPointer(GL_FLOAT, 0, normals);
    
//    glColor4f(0, 0, 0, 0.3);
  
//    glDrawElements(GL_TRIANGLES, (int)(meshSize.width-1)*(meshSize.height-1)*6, GL_UNSIGNED_SHORT, indicies);
    
//    glPopMatrix();
    
    glEnable(GL_LIGHTING);
    glEnableClientState(GL_COLOR_ARRAY);
    glColorPointer(4, GL_UNSIGNED_BYTE, 0, blockColors);
    glDrawElements(GL_TRIANGLES, (int)(meshSize.width-1)*(meshSize.height-1)*6, GL_UNSIGNED_SHORT, indicies);
    
    glDisableClientState(GL_COLOR_ARRAY);
    
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
    [context presentRenderbuffer:GL_RENDERBUFFER_OES];
}


- (void)layoutSubviews {
    [EAGLContext setCurrentContext:context];
    [self destroyFramebuffer];
    [self createFramebuffer];
    [self layoutPaper];
    [self drawView];
}


- (BOOL)createFramebuffer {
    
    glGenFramebuffersOES(1, &viewFramebuffer);
    glGenRenderbuffersOES(1, &viewRenderbuffer);
    
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
    [context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:(CAEAGLLayer*)self.layer];
    glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, viewRenderbuffer);
    
    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &backingWidth);
    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &backingHeight);
    
    if (USE_DEPTH_BUFFER) {
        glGenRenderbuffersOES(1, &depthRenderbuffer);
        glBindRenderbufferOES(GL_RENDERBUFFER_OES, depthRenderbuffer);
        glRenderbufferStorageOES(GL_RENDERBUFFER_OES, GL_DEPTH_COMPONENT16_OES, backingWidth, backingHeight);
        glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_DEPTH_ATTACHMENT_OES, GL_RENDERBUFFER_OES, depthRenderbuffer);
    }
    
    if(glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES) != GL_FRAMEBUFFER_COMPLETE_OES) {
        NSLog(@"failed to make complete framebuffer object %x", glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES));
        return NO;
    }
    
    [self prepareOpenGL];
    
    return YES;
}


- (void)destroyFramebuffer {
    
    glDeleteFramebuffersOES(1, &viewFramebuffer);
    viewFramebuffer = 0;
    glDeleteRenderbuffersOES(1, &viewRenderbuffer);
    viewRenderbuffer = 0;
    
    if(depthRenderbuffer) {
        glDeleteRenderbuffersOES(1, &depthRenderbuffer);
        depthRenderbuffer = 0;
    }
}


- (void)startAnimation {
    self.animationTimer = [NSTimer scheduledTimerWithTimeInterval:animationInterval target:self selector:@selector(drawView) userInfo:nil repeats:YES];
}


- (void)stopAnimation {
    self.animationTimer = nil;
}


- (void)setAnimationTimer:(NSTimer *)newTimer {
    [animationTimer invalidate];
    animationTimer = newTimer;
}


- (void)setAnimationInterval:(NSTimeInterval)interval {
    
    animationInterval = interval;
    if (animationTimer) {
        [self stopAnimation];
        [self startAnimation];
    }
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [page clearPullPoint];
}

-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [page clearPullPoint];
}

// We are going to try to tack the finger by pulling a spring.
// One end of the spring will be by the finger and the other
// end we will calcuate it position so that the finger end ends
// up by the finger.
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    // convert touch to view coords
    UITouch *aTouch = [touches anyObject];
    CGPoint point = [aTouch locationInView:self];
    CGPoint prevPoint = [aTouch previousLocationInView:self];
    
    // calculate pull end
    PVector pullEnd;
    pullEnd.x = point.x;
    pullEnd.y = point.y;
    
    // ... calculate z based on x scaled to -1..1
    CGFloat x = (point.x/backingWidth)*2-1;
    x /= (CGFloat)0.75;
    if(fabsf(x) > 1.0) x = x > 0 ? (CGFloat)1.0 : (CGFloat)-1.0;
    x = (x+1)/2;
    pullEnd.z = sqrtf(fabsf(((CGFloat)(CGFloat)1.0 - (x*x)/1.0)*(CGFloat).90));
    pullEnd.z = pullEnd.z*glViewCoords.size.width;

    // move pull end ahead to track finger
    
    // ... calculate finger velocity
    CGFloat vx = point.x-prevPoint.x;
    
    // ... adjust x to track finger based on velocity
//    CGFloat moveAhead = 40 + powf(fabsf(vx), 2.2);
    CGFloat moveAhead = 40 + 15*(CGFloat)fabsf(vx);
    if(vx > 1) pullEnd.x += moveAhead;
    else if(vx < -1) pullEnd.x -= moveAhead;
    
    // convert to gl coords
    pullEnd.x = pullEnd.x/backingWidth*glViewCoords.size.width-glViewCoords.size.width/(CGFloat)2.0;
    pullEnd.y = (backingHeight-pullEnd.y)/backingHeight*glViewCoords.size.height-glViewCoords.size.height/(CGFloat)2.0;
    
    // convert position to model coords
    pullEnd.x += glViewCoords.size.width/(CGFloat)2.0;
    pullEnd.y += glViewCoords.size.height/(CGFloat)2.0;
        
    [page pullAtPoint:pullEnd];
}


- (void)dealloc {
    
    [self stopAnimation];
    
    if ([EAGLContext currentContext] == context) {
        [EAGLContext setCurrentContext:nil];
    }
    
    [context release];
    [behindView release];
    [super dealloc];
}

@end
