//
//  Copyright © Borna Noureddin. All rights reserved.
//

#ifndef MyGLGame_CBox2D_h
#define MyGLGame_CBox2D_h

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>


// Set up brick and ball physics parameters here:
//   position, width+height (or radius), velocity,
//   and how long to wait before dropping brick

#define BRICK_POS_X            100
#define BRICK_POS_Y            750
#define BRICK_WIDTH            80.0f
#define BRICK_HEIGHT        20.0f
#define BRICK_WAIT            1.5f
#define BALL_POS_X            210
#define BALL_POS_Y            150
#define BALL_RADIUS            15.0f
#define BALL_VELOCITY        600000.0f
#define BALL_SPHERE_SEGS    128
#define NUM_BRICKS          9
#define PADDLE_WIDTH     90.0f
#define PADDLE_HEIGHT   30.0f
#define PADDLE_POS_X      210
#define PADDLE_POS_Y     50
#define PADDLE_VELOCITY   5.0f

@interface CBox2D : NSObject 

@property int numAnimals;

-(void) Update:(float)elapsedTime;  // update the Box2D engine
//-(void) RegisterHit:(float)posx Ex:(float)posy;                // Register when the ball hits the brick
-(float) GetAnimalPositionX:(int)index;
-(float) GetAnimalPositionY:(int)index;
-(bool) RegisterTap:(float)posX Ex:(float)posY;
@end

#endif
