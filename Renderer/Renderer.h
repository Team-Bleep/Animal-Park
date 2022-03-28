//
//  Renderer.h
//  AnimalPark
//
//  Created by Mohammed Bajaman on 2022-02-19.
//

#ifndef Renderer_h
#define Renderer_h
#import <GLKit/GLKit.h>

@interface Renderer : NSObject

@property bool isTest;

- (void)setup:(GLKView *)view;
- (void)loadBackdrop;
- (void)loadAnimal;
- (void)loadAnimal2;
- (void)update;
- (void)draw:(CGRect)drawBackdrop;
- (void)drawAnml:(CGRect)drawAnimal;
- (void)setRandomAnimalTexture;

@end


#endif /* Renderer_h */
