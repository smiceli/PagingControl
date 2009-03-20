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
- (void) prepareOpenGL;

@end


@implementation BookCoverView

@synthesize context;
@synthesize animationTimer;
@synthesize animationInterval;


// You must implement this method
+ (Class)layerClass {
    return [CAEAGLLayer class];
}

//The GL view is stored in the nib file. When it's unarchived it's sent -initWithCoder:
- (id)initWithCoder:(NSCoder*)coder {
    
    if ((self = [super initWithCoder:coder])) {
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

        meshSize = CGSizeMake(10, 20);
        
#pragma mark Color Code
        blockColors = malloc((int)((meshSize.width-1)*(meshSize.height-1)*sizeof(*blockColors)));
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
        GLushort *index = indicies;
        for(int y = 0; y < meshSize.height-1; y++) {
            for(int x = 0; x < meshSize.width-1; x++) {
                *index++ = y*(int)meshSize.width+x;
                *index++ = (y+1)*(int)meshSize.width+x;
                *index++ = y*(int)meshSize.width+(x+1);

                *index++ = (y+1)*(int)meshSize.width+x;
                *index++ = (y+1)*(int)meshSize.width+(x+1);
                *index++ = y*(int)meshSize.width+(x+1);
            }
        }
        
        page = [[Page alloc] initWithSize:CGSizeMake(1.5*2, 2.0*3) andMeshSize:meshSize];    
        
#if 0
        UIImage *image = [UIImage imageNamed:@"ethan.jpg"];
        if(!image) return;
        
        
        NSImageRep *imageRep = [image bestRepresentationForDevice:nil];
        if(![imageRep isKindOfClass:[NSBitmapImageRep class]]) return;
        
        NSBitmapImageRep *bitmapImageRep = (NSBitmapImageRep*)imageRep;
        glGenTextures(1, &imageTexture);
        [bitmapImageRep copyToGLTexture:imageTexture];
#endif
        
        //    mouseParticle = &[page particles][(int)(meshSize.width*(meshSize.height-1)/2+meshSize.width-1)];
        //    mouseParticle2 = mouseParticle + (int)meshSize.width;
        
    }
    return self;
}


-(void)prepareOpenGL {
    glEnable(GL_LIGHTING);
    
    GLfloat global_ambient[] = { .4, .4, .4, .4 };
    glLightModelfv(GL_LIGHT_MODEL_AMBIENT, global_ambient);
    
    GLfloat ambient[] = { .3, .3,.3 };
    glLightfv(GL_LIGHT0, GL_AMBIENT, ambient);
    GLfloat diffuseLight[] = { 0.9f, 0.9f, 0.9, 1.0f };
    glLightfv(GL_LIGHT0, GL_DIFFUSE, diffuseLight);
    //    GLfloat specularLight[] = { 0.4f, 0.4f, 0.4, 1.0f };
    //    glLightfv(GL_LIGHT0, GL_SPECULAR, specularLight);
    PVector vposition = { -1.5, .25, 0};
    GLfloat lightPosition[4];
    lightPosition[0] = vposition.x;
    lightPosition[1] = vposition.y;
    lightPosition[2] = vposition.z;
    lightPosition[3] = 1.0;
    glLightfv(GL_LIGHT0, GL_POSITION, lightPosition);
    
    PVector vdirection = {0, 0, 0};
    vdirection = vnormalize(vsub(vdirection, vposition));
    float direction[4];
    direction[0] = vdirection.x;
    direction[1] = vdirection.y;
    direction[2] = vdirection.z;
    direction[3] = 1.0;
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
    
    double x0 = c->p0.x;
    double y0 = c->p0.y;
    
//    glBegin(GL_QUADS);
    int ci = 0;
    for(int y = 0; y < meshSize.height-1; y++) {
        for(int x = 0; x < meshSize.width-1; x++) {
//            if(!imageTexture)
//                glColor3f(blockColors[ci].r, blockColors[ci].g, blockColors[ci].b);
            
#if 0
            PVector n = normal3((c+neighbors[1])->p, (c+neighbors[3])->p, c->p);
            //            glNormal3dv((double*)&n);
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
            PVector n = vnormalize(vmulConst(normalSum, 1.0/(double)normalIndex));
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
//                glNormal3dv((double*)&n);
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

- (void)drawView {
    [EAGLContext setCurrentContext:context];
    
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
    glViewport(0, 0, backingWidth, backingHeight);
    
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glFrustumf(-1.0, 1.0, -1.5, 1.5, 2.5, 200);
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    glTranslatef(0, -2.5, -7.5f);
  
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
            if(x != meshSize.width-1 || y != meshSize.height-1)
                *n++ = normal3((p+(int)meshSize.width)->p, (p+1)->p, p->p);
            else
                *n++ = normal3((p-(int)meshSize.width)->p, (p-1)->p, p->p);
            p++;
        }
    }

    glEnableClientState(GL_VERTEX_ARRAY);
    glVertexPointer(3, GL_FLOAT, 0, vertecies);
    glEnableClientState(GL_COLOR_ARRAY);
    glColorPointer(4, GL_UNSIGNED_BYTE, 0, blockColors);
    glEnableClientState(GL_NORMAL_ARRAY);
    glNormalPointer(GL_FLOAT, 0, normals);
    
    glDrawElements(GL_TRIANGLES, (int)(meshSize.width-1)*(meshSize.height-1)*6, GL_UNSIGNED_SHORT, indicies);
    
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
    [context presentRenderbuffer:GL_RENDERBUFFER_OES];
}


- (void)layoutSubviews {
    [EAGLContext setCurrentContext:context];
    [self destroyFramebuffer];
    [self createFramebuffer];
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

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *aTouch = [touches anyObject];
    CGPoint point = [aTouch locationInView:self];
    CGPoint prevPoint = [aTouch previousLocationInView:self];
    CGFloat vx = point.x-prevPoint.x;
    CGFloat moveAhead = 40 + powf(fabs(vx), 2.2);
    if(vx > 0) point.x += moveAhead;
    else point.x -= moveAhead;
    PVector position;
    position.x = point.x/backingWidth*2.0-1.0;
    position.y = (backingHeight-point.y)/backingHeight*2.0-1.0;
    CGFloat x = position.x;
    x /= 0.75;
    if(fabs(x) > 1.0) x = x > 0 ? 1.0 : -1.0;
    position.z = sqrtf(fabs((1.0 - x*x/1.0)*.90));
    // x moves from -3 to 3 as the page is being flopped over.
    // This is in the coordinates of the particles.
    position.x *= 3;
    // y will stay -3 to 3.
    position.y = (position.y + 1.0) * 3;
    [page pullAtPoint:position];
}


- (void)dealloc {
    
    [self stopAnimation];
    
    if ([EAGLContext currentContext] == context) {
        [EAGLContext setCurrentContext:nil];
    }
    
    [context release];  
    [super dealloc];
}

@end
