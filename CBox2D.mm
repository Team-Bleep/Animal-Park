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
            
            if (bodyA->GetLinearVelocity().y == 0) {
                float x = bodyA->GetPosition().x;
                float y = bodyA->GetPosition().y;
                [parentObj RegisterHit:x Ex: y]; // uses RegisterHit function as a callback
            }
            
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
    
    b2BodyDef *groundBodyDef[NUM_BRICKS];
    b2Body *groundBody[NUM_BRICKS];
    b2PolygonShape *groundBox[NUM_BRICKS];
    b2Body *theBrick[NUM_BRICKS];
    
    b2BodyDef *wallBodyDef[3];
    b2Body *wallBody[3];
    b2PolygonShape *wallBox[3];
    b2Body *theWall[3];
    
    b2Body *theBall;
    
    b2BodyDef *paddleBodyDef;
    b2Body *paddleBody;
    b2PolygonShape *paddleBox;
    b2Body *thePaddle;
    
    CContactListener *contactListener;
    float totalElapsedTime;

    // You will also need some extra variables here for the logic
    bool ballHitBrick;
    bool ballLaunched;
    
    int brickKilledIndex;
    int paddleMove;
    int score;
    int lives;
    
    float currPosX;
}
@end

@implementation CBox2D

- (instancetype)init
{
    self = [super init];
    if (self) {
        // Initialize Box2D
        gravity = new b2Vec2(0.0f, 0.0f);
        world = new b2World(*gravity);

        // For brick & ball sample
        contactListener = new CContactListener();
        world->SetContactListener(contactListener);
        
        // Set up the brick objects
        for (int i = 0; i < NUM_BRICKS; i++) {
            b2BodyDef brickBodyDef;
            brickBodyDef.type = b2_staticBody;
            float spacerX = (BRICK_WIDTH*1.2);
            float spacerY = (BRICK_HEIGHT * 1.8);
            if (i/3 == 0) {
                spacerX = spacerX * i;
                brickBodyDef.position.Set(BRICK_POS_X + spacerX, BRICK_POS_Y);
            }
            else if (i/3 == 1) {
                spacerX = spacerX * (i - 3);
                brickBodyDef.position.Set(BRICK_POS_X + spacerX, BRICK_POS_Y - spacerY);
            }
            else if (i/3 == 2) {
                spacerX = spacerX * (i - 6);
                spacerY = spacerY * 2;
                brickBodyDef.position.Set(BRICK_POS_X + spacerX, BRICK_POS_Y - spacerY);
            }
                
            theBrick[i] = world->CreateBody(&brickBodyDef);
            
            if (theBrick[i]) {
                theBrick[i]->SetUserData((__bridge void *)self);
                theBrick[i]->SetAwake(false);
                
                b2PolygonShape dynamicBox;
                dynamicBox.SetAsBox(BRICK_WIDTH/2, BRICK_HEIGHT/2);
                
                b2FixtureDef fixtureDef; // definition for collision detection
                fixtureDef.shape = &dynamicBox;
                fixtureDef.density = 1.0f;
                fixtureDef.friction = 0.0f;
                fixtureDef.restitution = 1.0f;
                
                theBrick[i]->CreateFixture(&fixtureDef); // ACTUAL collision detection
            }
        }
        
        // Set up the 3 walls
        for (int i = 0; i < 3; i++) {
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
            else if (i == 2) {
                wallBodyDef.position.Set(390, 844-BALL_RADIUS);
                
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
                }            }
                
            
        }

        
        // CREATE THE PADDLE
        b2BodyDef paddleBodyDef;
        paddleBodyDef.type = b2_staticBody;
        paddleBodyDef.position.Set(PADDLE_POS_X, PADDLE_POS_Y);
        thePaddle = world->CreateBody(&paddleBodyDef);
        
        if (thePaddle) {
            thePaddle->SetUserData((__bridge void *)self);
            thePaddle->SetAwake(false);
            
            b2PolygonShape dynamicBox;
            dynamicBox.SetAsBox(PADDLE_WIDTH/2, PADDLE_HEIGHT/2);
            
            b2FixtureDef fixtureDef; // definition for collision detection
            fixtureDef.shape = &dynamicBox;
            fixtureDef.density = 1.0f;
            fixtureDef.friction = 0.0f;
            fixtureDef.restitution = 1.0f;
            
            thePaddle->CreateFixture(&fixtureDef); // ACTUAL collision detection
        }
        
        // CREATE THE BALL
        b2BodyDef ballBodyDef; // Only a reference to the physics body
        ballBodyDef.type = b2_dynamicBody;
        ballBodyDef.position.Set(BALL_POS_X, BALL_POS_Y);
        theBall = world->CreateBody(&ballBodyDef); // ACTUAL physics body
        
        if (theBall) {
            theBall->SetUserData((__bridge void *)self);
            theBall->SetAwake(false);
            b2CircleShape circle;
            circle.m_p.Set(0, 0); // pos in relation to physics body?
            circle.m_radius = BALL_RADIUS;
            
            b2FixtureDef circleFixtureDef;  // collider definition
            circleFixtureDef.shape = &circle;
            circleFixtureDef.density = 1.0f;
            circleFixtureDef.friction = 0.0f;
            circleFixtureDef.restitution = 1.0f;
            
            theBall->CreateFixture(&circleFixtureDef); // ACTUAL collision detection
        }
        
        // Initial values:
        totalElapsedTime = 0;
        ballHitBrick = false;
        ballLaunched = false;
        paddleMove = 0;
        brickKilledIndex = -1;
        score = 0;
        lives = 3;
        currPosX = PADDLE_POS_X;
    }
    return self;
}

-(void) UpdatePaddleMovement:(int)direction
{
    paddleMove = direction;
}

- (void)dealloc
{
    if (gravity) delete gravity;
    if (world) delete world;
    
    for (int i = 0; i < NUM_BRICKS; i++) {
        if (groundBodyDef[i]) delete groundBodyDef[i];
        if (groundBox[i]) delete groundBox[i];
    }
    
    if (contactListener) delete contactListener;
}

-(void)Update:(float)elapsedTime
{
    if (theBall->GetPosition().y < BALL_RADIUS) {
        totalElapsedTime = 0;
        theBall->SetLinearVelocity(b2Vec2(0,0));
        theBall->SetTransform(b2Vec2(BALL_POS_X, BALL_POS_Y), 0);
        
        if (lives > 0){
            lives --;
        }
    }
    
    if (ballLaunched) {
        //theBall->ApplyLinearImpulse(b2Vec2(BALL_VELOCITY, BALL_VELOCITY), theBall->GetPosition(), true);
        theBall->SetLinearVelocity(b2Vec2(BALL_VELOCITY, BALL_VELOCITY));
        theBall->SetAwake(true);
        ballLaunched = false;
    }
    if (brickKilledIndex > -1) {
        world->DestroyBody(theBrick[brickKilledIndex]);
        theBrick[brickKilledIndex] = NULL;
        brickKilledIndex = -1;
    }
    
    if (paddleMove == 1) {
        currPosX += PADDLE_VELOCITY;
        if (currPosX >= 390-PADDLE_WIDTH/2) {
            paddleMove = -1;
        }
    }
    else if (paddleMove == -1) {
        currPosX -= PADDLE_VELOCITY;
        if (currPosX <= PADDLE_WIDTH/2) {
            paddleMove = 1;
        }
    }
    thePaddle->SetAwake(true);
    thePaddle->SetTransform(b2Vec2(currPosX, PADDLE_POS_Y), 0);
    
    // Check if it is time yet to drop the brick, and if so
    //  call SetAwake()
    totalElapsedTime += elapsedTime;
    
    
    if (totalElapsedTime > BRICK_WAIT && totalElapsedTime <= BRICK_WAIT+1){
        for (int i = 0; i < NUM_BRICKS; i++) {
            if (theBrick[i]) {
                theBrick[i]->SetAwake(true);
                ballLaunched = true;
            }
        }
    }
    // If the last collision test was positive,
    //  stop the ball and destroy the brick
    if (ballHitBrick) {
        //theBall->SetLinearVelocity(b2Vec2(0, 0));
        //theBall->SetAngularVelocity(0);
        //theBall->SetActive(false);
        
        ballHitBrick = false;
        //NSLog(@"touched");
    }

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

-(void)RegisterHit: (float)posX Ex:(float)posY
{
    theBall->SetAngularVelocity(0);
    // Get brick positions and find the one hit
    for (int i = 0; i < NUM_BRICKS; i++) {
        if (theBrick[i] && theBrick[i]->GetPosition().x == posX && theBrick[i]->GetPosition().y == posY) {
            brickKilledIndex = i;
            score++;
            return;
        }
    }
}

-(void)LaunchBall
{
    // Set some flag here for processing later...
    //ballLaunched = true;
}

-(void *)GetObjectPositions
{
    auto *objPosList = new std::map<const char *,b2Vec2>;
    if (theBall) {
        (*objPosList)["ball"] = theBall->GetPosition();
    }
    
    if (thePaddle) {
        (*objPosList)["paddle"] = thePaddle->GetPosition();
    }
    
    for (int i = 0; i < NUM_BRICKS; i++) {
        if (theBrick[i]) {
            (*objPosList)[&"brick" [ (i)]] = theBrick[i]->GetPosition();
        }
    }
    return reinterpret_cast<void *>(objPosList);
}

-(int)GetScore{
    return score;
}

-(int)GetLives{
    return lives;
}

@end
