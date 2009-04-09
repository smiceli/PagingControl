//
//  UIView+CTMImage.h
//  HTMLRef
//
//  Created by Sean Miceli on 3/21/09.
//  Copyright 2009 CoolThingsMade. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface UIView (CTMImage)
    
-(UIImage *)imageFrom;
-(void)copyToGLTexture:(int)textureName putTextureCoordsIn:(CGRect*)textureRect;

@end
