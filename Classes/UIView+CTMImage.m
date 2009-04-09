//
//  UIView+CTMImage.m
//  HTMLRef
//
//  Created by Sean Miceli on 3/21/09.
//  Copyright 2009 CoolThingsMade. All rights reserved.
//

#import "UIView+CTMImage.h"

#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>

#import <QuartzCore/CALayer.h>

static unsigned nearestPowerOf2(unsigned int x) {
	--x;    
	x |= x >> 1;
	x |= x >> 2;    
	x |= x >> 4;    
	x |= x >> 8;    
	x |= x >> 16;    
	return ++x;
}

@implementation UIView (CTMImage)

-(UIImage *)imageFrom {
    UIGraphicsBeginImageContext(self.bounds.size);
    [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

-(void)copyToGLTexture:(int)textureName putTextureCoordsIn:(CGRect*)textureRect {
    int textureWidth = nearestPowerOf2((unsigned int)self.bounds.size.width);
    int textureHeight = nearestPowerOf2((unsigned int)self.bounds.size.height);
    
    NSMutableData *pixels = [NSMutableData dataWithLength:textureWidth*textureHeight*4];
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    if(!colorSpace) return;
    
    CGContextRef context = CGBitmapContextCreate([pixels mutableBytes], textureWidth, textureHeight, 8, textureWidth*4, colorSpace, kCGImageAlphaPremultipliedLast);
    CGColorSpaceRelease(colorSpace);
    if(!context) return;

    [self.layer renderInContext:context];
    CGContextRelease(context);    
    
    glBindTexture(GL_TEXTURE_2D, textureName);
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);

    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, textureWidth, textureHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, [pixels mutableBytes]);
    
    *textureRect = CGRectMake(0, (textureHeight-self.bounds.size.height)/textureHeight, self.bounds.size.width/textureWidth,1.0);
}

@end
