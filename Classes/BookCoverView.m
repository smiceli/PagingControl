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
    CGFloat r, g, b, a;
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
        
        animationInterval = 1.0 / 60.0;

        meshSize = CGSizeMake(10, 10);
        blockColors = (BlockColor*)malloc(meshSize.width*meshSize.height*sizeof(*blockColors)*2);
        for(int y = 0; y < meshSize.height; y++) {
            for(int x = 0; x < meshSize.width; x++) {
                int ci = 2*y*meshSize.width+x;
#if 0
                blockColors[ci].r = 1.0;
                blockColors[ci].g = 0;
                blockColors[ci].b = 0;
#else
                blockColors[ci].r = rand()/(float)RAND_MAX;
                blockColors[ci].g = rand()/(float)RAND_MAX;
                blockColors[ci].b = rand()/(float)RAND_MAX;
                blockColors[ci].a = 1.0;
                
                blockColors[ci+(int)meshSize.width].r = blockColors[ci].r;
                blockColors[ci+(int)meshSize.width].g = blockColors[ci].g;
                blockColors[ci+(int)meshSize.width].b = blockColors[ci].b;
                blockColors[ci+(int)meshSize.width].a = 1.0;

#endif
            }
        }
        page = [[Page alloc] initWithSize:CGSizeMake(1.0, 1.5) andMeshSize:meshSize];    
        
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
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glFrustumf(-1.0, 1.0, -1.5, 1.5, 1, 6);
    glMatrixMode(GL_MODELVIEW);
    
    glTranslatef(0, 0, -2);
    
    glEnable(GL_LIGHTING);
    
    GLfloat global_ambient[] = { .4, .4, .4, .4 };
    glLightModelfv(GL_LIGHT_MODEL_AMBIENT, global_ambient);
    
    GLfloat ambient[] = { .3, .3,.3 };
    glLightfv(GL_LIGHT0, GL_AMBIENT, ambient);
    GLfloat diffuseLight[] = { 0.9f, 0.9f, 0.9, 1.0f };
    glLightfv(GL_LIGHT0, GL_DIFFUSE, diffuseLight);
    //    GLfloat specularLight[] = { 0.4f, 0.4f, 0.4, 1.0f };
    //    glLightfv(GL_LIGHT0, GL_SPECULAR, specularLight);
    PVector vposition = { -1.5, 1.5, 1.5};
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
    glLightfv(GL_LIGHT0, GL_SPOT_DIRECTION, direction);
    glLightf(GL_LIGHT0, GL_SPOT_CUTOFF, 45);
    glEnable(GL_LIGHT0);
    
#if 0
    float mcolor[] = { 1.0, 1.0, 1.0, 0 };
    glMaterialfv(GL_FRONT, GL_AMBIENT_AND_DIFFUSE, mcolor);
    //    glMaterialfv(GL_BACK, GL_AMBIENT_AND_DIFFUSE, mcolor);
#endif
    
    glEnable(GL_COLOR_MATERIAL);
//    glColorMaterial(GL_FRONT, GL_AMBIENT_AND_DIFFUSE);
    //    glColorMaterial(GL_BACK, GL_AMBIENT_AND_DIFFUSE);

#if 0
    if(imageTexture) {
        glEnable(GL_TEXTURE_2D);
        glBindTexture(GL_TEXTURE_2D, imageTexture);
        
        glMatrixMode(GL_TEXTURE);
        glRotatef(90, 0, 0, 1);
    }
#endif
    
//    glEnable(GL_DEPTH);
    glEnable(GL_DEPTH_TEST);
    glFrontFace(GL_CCW);
    
    [self performSelector:@selector(update:) withObject:nil afterDelay:0.1];
}

#if 0
-(void)drawView {
    [EAGLContext setCurrentContext:context];
    
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
    glViewport(0, 0, backingWidth, backingHeight);

    glClearColor(0.5f, 0.5f, 0.5f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    [self prepareOpenGL];
    
    [page updateParticles:0.05];
    
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

#if 1
- (void)drawView {
    
    // Replace the implementation of this method to do your own custom drawing
    
    [EAGLContext setCurrentContext:context];
    
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
    glViewport(0, 0, backingWidth, backingHeight);
    
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
//    glOrthof(-1.0f, 1.0f, -1.5f, 1.5f, -1.0f, 1.0f);
    glFrustumf(-1.0, 1.0, -1.5, 1.5, 1.0-.0001, 6);
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    glTranslatef(position.x, position.y, -1.0f);
    glRotatef(angle, 0, 0, 1);
    
    glClearColor(0.5f, 0.5f, 0.5f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glColor4ub(255, 0, 0, 255);

    Particle *c = [page particles];
    CGFloat vertecies[(int)meshSize.width*2*3];
    for(int y = 0; y < meshSize.height-1; y++) {
        CGFloat *v = vertecies;
        for(int x = 0; x < meshSize.width; x++) {
            Particle *p = c;
            for(int i = 0; i < 2; i++) {
                *v++ = p->p.x;
                *v++ = p->p.y;
                *v++ = p->p.z;
                p += (int)meshSize.width;
            }
            c++;
        }
        glEnableClientState(GL_VERTEX_ARRAY);
        glVertexPointer(3, GL_FLOAT, 0, vertecies);
        glEnableClientState(GL_COLOR_ARRAY);
        glColorPointer(4, GL_FLOAT, 0, blockColors+2*y*(int)meshSize.width);
        
        int n = meshSize.width*2;
        glDrawArrays(GL_TRIANGLE_STRIP, 0, n);
    }
#if 0
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
    UITouch *touch = [touches anyObject];
    position = [touch locationInView:self];
    position.x = position.x/backingWidth*2.0-1.0;
    position.y = -(position.y/backingHeight*3.0-1.5);
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
