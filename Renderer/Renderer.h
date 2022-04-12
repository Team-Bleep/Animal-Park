//
//  Renderer.h
//  AnimalPark
//
//  Created by Mohammed Bajaman on 2022-02-19.
//

#ifndef Renderer_h
#define Renderer_h
#import <GLKit/GLKit.h>
#import "CBox2D.h"

@interface Renderer : NSObject

@property (strong, nonatomic) CBox2D *box2d;

- (void)setup:(GLKView *)view;
- (void)loadBackdrop;
- (void)loadAnimal:(int)animalCount;
- (void)update;
- (void)draw:(CGRect)drawBackdrop;
- (void)despawnAnimals;

@end


#endif /* Renderer_h */
