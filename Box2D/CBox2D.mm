//
//  Copyright © Borna Noureddin. All rights reserved.
//

#include <Box2D/Box2D.h>
#include "CBox2D.h"
#include <stdio.h>
#include <map>

// Some Box2D engine paremeters
const float MAX_TIMESTEP = 1.0f/60.0f;
const int NUM_VEL_ITERATIONS = 10;
const int NUM_POS_ITERATIONS = 3;


#pragma mark - Box2D contact listener class

// This C++ class is used to handle collisions
class CContactListener : public b2ContactListener
{
public:
    void BeginContact(b2Contact* contact) {};
    void EndContact(b2Contact* contact) {};
    void PreSolve(b2Contact* contact, const b2Manifold* oldManifold)
    {
        b2WorldManifold worldManifold;
        contact->GetWorldManifold(&worldManifold);
        b2PointState state1[2], state2[2];
        b2GetPointStates(state1, state2, oldManifold, contact->GetManifold());
        if (state2[0] == b2_addState)
        {
            // Use contact->GetFixtureA()->GetBody() to get the body
            b2Body* bodyA = contact->GetFixtureA()->GetBody();
            // Call RegisterHit (assume CBox2D object is in user data)
            CBox2D *parentObj = (__bridge CBox2D *)(bodyA->GetUserData());
            //if (bodyA->GetLinearVelocity().y == 0) {
              //  float x = bodyA->GetPosition().x;
                //float y = bodyA->GetPosition().y;
                //[parentObj RegisterHit:x Ex: y]; // uses RegisterHit function as a callback
            //}
            
        }
    }
    void PostSolve(b2Contact* contact, const b2ContactImpulse* impulse) {};
};

#pragma mark - CBox2D

@interface CBox2D ()
{
    // Box2D-specific objects
    b2Vec2 *gravity;
    b2World *world;
    
    b2BodyDef *wallBodyDef[4];
    b2Body *wallBody[4];
    b2PolygonShape *wallBox[4];
    b2Body *theWall[4];
    
    b2Body *animal[4];
    bool movementStarted;
    
    CContactListener *contactListener;
    float totalElapsedTime;
}
@end

@implementation CBox2D

@synthesize numAnimals;

- (instancetype)init
{
    
    self = [super init];
    if (self) {
        numAnimals = 4;
        // Initialize Box2D
        gravity = new b2Vec2(0.0f, 0.0f);
        world = new b2World(*gravity);

        contactListener = new CContactListener();
        world->SetContactListener(contactListener);
        
        // Set up the 4 walls
        for (int i = 0; i < 4; i++) {
            b2BodyDef wallBodyDef;
            wallBodyDef.type = b2_staticBody;
            
            // LEFT SIDE
            if (i == 0) {
                wallBodyDef.position.Set(0, 0);
                
                theWall[i] = world->CreateBody(&wallBodyDef);
                
                if (theWall[i]) {
                    theWall[i]->SetUserData((__bridge void *)self);
                    theWall[i]->SetAwake(false);
                    
                    b2PolygonShape dynamicBox;
                    dynamicBox.SetAsBox(5, 844);
                    
                    b2FixtureDef fixtureDef; // definition for collision detection
                    fixtureDef.shape = &dynamicBox;
                    fixtureDef.density = 1.0f;
                    fixtureDef.friction = 0.0f;
                    fixtureDef.restitution = 1.0f;
                    
                    theWall[i]->CreateFixture(&fixtureDef); // ACTUAL collision detection
                }
            }
            // RIGHT SIDE
            else if (i == 1) {
                wallBodyDef.position.Set(390, 0);
                
                theWall[i] = world->CreateBody(&wallBodyDef);
                
                if (theWall[i]) {
                    theWall[i]->SetUserData((__bridge void *)self);
                    theWall[i]->SetAwake(false);
                    
                    b2PolygonShape dynamicBox;
                    dynamicBox.SetAsBox(5, 844);
                    
                    b2FixtureDef fixtureDef; // definition for collision detection
                    fixtureDef.shape = &dynamicBox;
                    fixtureDef.density = 1.0f;
                    fixtureDef.friction = 0.0f;
                    fixtureDef.restitution = 1.0f;
                    
                    theWall[i]->CreateFixture(&fixtureDef); // ACTUAL collision detection
                }
            }
            else if (i == 2) { // top
                wallBodyDef.position.Set(390, 844);
                
                theWall[i] = world->CreateBody(&wallBodyDef);
                
                if (theWall[i]) {
                    theWall[i]->SetUserData((__bridge void *)self);
                    theWall[i]->SetAwake(false);
                    
                    b2PolygonShape dynamicBox;
                    dynamicBox.SetAsBox(390, 5);
                    
                    b2FixtureDef fixtureDef; // definition for collision detection
                    fixtureDef.shape = &dynamicBox;
                    fixtureDef.density = 1.0f;
                    fixtureDef.friction = 0.0f;
                    fixtureDef.restitution = 1.0f;
                    
                    theWall[i]->CreateFixture(&fixtureDef); // ACTUAL collision detection
                }
            }
            else if (i == 3) { // bot
                wallBodyDef.position.Set(390, 5);
                
                theWall[i] = world->CreateBody(&wallBodyDef);
                
                if (theWall[i]) {
                    theWall[i]->SetUserData((__bridge void *)self);
                    theWall[i]->SetAwake(false);
                    
                    b2PolygonShape dynamicBox;
                    dynamicBox.SetAsBox(390, 5);
                    
                    b2FixtureDef fixtureDef; // definition for collision detection
                    fixtureDef.shape = &dynamicBox;
                    fixtureDef.density = 1.0f;
                    fixtureDef.friction = 0.0f;
                    fixtureDef.restitution = 1.0f;
                    
                    theWall[i]->CreateFixture(&fixtureDef); // ACTUAL collision detection
                }
            }
        }
        
        for (int i = 0; i < numAnimals; i++) {
            b2BodyDef animBodyDef;
            animBodyDef.type = b2_dynamicBody;
            animBodyDef.position.Set(BALL_POS_X, BALL_POS_Y);
            animal[i] = world->CreateBody(&animBodyDef);
            
            if (animal[i]) {
                animal[i]->SetUserData((__bridge void *)self);
                animal[i]->SetAwake(false);
                
                // SET ANIMAL SIZE / 2
                b2PolygonShape dynamicBox;
                dynamicBox.SetAsBox(50, 50);
                
                b2FixtureDef circleFixtureDef;  // collider definition
                circleFixtureDef.shape = &dynamicBox;
                circleFixtureDef.density = 1.0f;
                circleFixtureDef.friction = 0.0f;
                circleFixtureDef.restitution = 1.0f;
                
                animal[i]->CreateFixture(&circleFixtureDef); // ACTUAL collision detection
            }
        }
        
        
        // Initial values:
        totalElapsedTime = 0;
        movementStarted = true;
    }
    return self;
}

-(void)dealloc
{
    if (gravity) delete gravity;
    if (world) delete world;
    if (contactListener) delete contactListener;
}

-(void)Update:(float)elapsedTime
{
    
    if (movementStarted) {
        
        // SET ANIMAL DIRECTION
        for (int i = 0; i < numAnimals; i++) {
            if (animal[i]) {
                animal[i]->SetLinearVelocity(b2Vec2(BALL_VELOCITY, BALL_VELOCITY));
                animal[i]->SetAwake(true);
            }
        }
        movementStarted = false;
    }
    totalElapsedTime += elapsedTime;
    

    if (world)
    {
        while (elapsedTime >= MAX_TIMESTEP)
        {
            world->Step(MAX_TIMESTEP, NUM_VEL_ITERATIONS, NUM_POS_ITERATIONS);
            elapsedTime -= MAX_TIMESTEP;
        }
        
        if (elapsedTime > 0.0f)
        {
            world->Step(elapsedTime, NUM_VEL_ITERATIONS, NUM_POS_ITERATIONS);
        }
    }
}

-(bool) RegisterTap:(float)posX Ex:(float)posY {
    float padding = 100.0;
    for (int i = 0; i < numAnimals; i++) {
        if (animal[i]) {
            if([self GetAnimalPositionX:i] >= (posX-padding)
               && [self GetAnimalPositionX:i] <= (posX+padding)
               && [self GetAnimalPositionX:i] != FLT_MAX) {
                
                if([self GetAnimalPositionY:i] >= (posY-padding)
                   && [self GetAnimalPositionY:i] <= (posY+padding)
                   && [self GetAnimalPositionY:i] != FLT_MAX) {
                    animal[i]->SetLinearVelocity(b2Vec2(animal[i]->GetLinearVelocity().x*-2, animal[i]->GetLinearVelocity().y*-2));
                    animal[i]->SetAwake(true);
                    return true;
                }
            }
        }
    }
    return false;
}

-(float)GetAnimalPositionX:(int)index
{
    if (animal[index]) {
        return animal[index]->GetPosition().x;
        
    }
    return FLT_MAX; // no animal found
}

-(float)GetAnimalPositionY:(int)index
{
    if (animal[index]) {
        return animal[index]->GetPosition().y;
    }
    return FLT_MAX; // no animal found
}

@end
