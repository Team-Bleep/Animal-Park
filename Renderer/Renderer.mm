//
//  Copyright © 2017 Borna Noureddin. All rights reserved.
//

#import "Renderer.h"
#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#include <chrono>
#include "GLESRenderer.hpp"
#include <stdlib.h>
#include <Box2D/Box2D.h>
#include <map>

// small struct to hold object-specific information
struct RenderObject
{
    GLuint vao, ibo;    // VAO and index buffer object IDs
    GLuint animalTexture;
    
    int animalTextureIndex = -1;
    
    // model-view, model-view-projection and normal matrices
    GLKMatrix4 mvp, mvm;
    GLKMatrix3 normalMatrix;

    // diffuse lighting parameters
    GLKVector4 diffuseLightPosition;
    GLKVector4 diffuseComponent;

    // vertex data
    float *vertices, *normals, *texCoords;
    int *indices, numIndices;
    
    float animalSpawnPosX, animalSpawnPosY;
};

// macro to hep with GL calls
#define BUFFER_OFFSET(i) ((char *)NULL + (i))

// uniform variables for shaders
enum
{
    UNIFORM_MODELVIEWPROJECTION_MATRIX,
    UNIFORM_MODELVIEW_MATRIX,
    UNIFORM_NORMAL_MATRIX,
    UNIFORM_TEXTURE,
    UNIFORM_LIGHT_SPECULAR_POSITION,
    UNIFORM_LIGHT_DIFFUSE_POSITION,
    UNIFORM_LIGHT_DIFFUSE_COMPONENT,
    UNIFORM_LIGHT_SHININESS,
    UNIFORM_LIGHT_SPECULAR_COMPONENT,
    UNIFORM_LIGHT_AMBIENT_COMPONENT,
    UNIFORM_USE_TEXTURE,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

// vertex attributes
enum
{
    ATTRIB_POSITION,
    ATTRIB_NORMAL,
    ATTRIB_TEXTURE,
    NUM_ATTRIBUTES
};

@interface Renderer () {
    GLKView *theView;
    GLESRenderer glesRenderer;
    std::chrono::time_point<std::chrono::steady_clock> lastTime;

    // OpenGL IDs
    GLuint programObject;
    GLuint backgroundTexture;
    NSString* animalTextures[4]; // PLS UPDATE ARRAY SIZE WITH OBJECTS ARRAY

    // global lighting parameters
    GLKVector4 specularLightPosition;
    GLKVector4 specularComponent;
    GLfloat shininess;
    GLKVector4 ambientComponent;
    
    // render objects
    RenderObject objects[4]; // PLS UPDATE ARRAY SIZE WITH ANIMAL TEXTURES ARRAY
    RenderObject nullObjects[4]; // PLS UPDATE SIZE WITH OBJECTS ARRAY
    RenderObject backdrop;
    
    int animalCount;
    // moving camera automatically
    float distx, disty, distIncr;
}

@end

@implementation Renderer

@synthesize box2d;

- (void)dealloc
{
    glDeleteProgram(programObject);
}

- (void)loadBackdrop
{
    
    
        // cube (centre, textured)
        glGenVertexArrays(1, &backdrop.vao);
        glGenBuffers(1, &backdrop.ibo);

        // get cube data
       backdrop.numIndices = glesRenderer.GenAnimal(1.0f, &backdrop.vertices, &backdrop.normals, &backdrop.texCoords, &backdrop.indices);

        // set up VBOs (one per attribute)
        glBindVertexArray(backdrop.vao);
        GLuint vbo[3];
        glGenBuffers(3, vbo);
    
    backgroundTexture = [self setupTexture:@"parkbg.png"];
    glActiveTexture(GL_TEXTURE0);
    
    

        // pass on position data
        glBindBuffer(GL_ARRAY_BUFFER, vbo[0]);
        glBufferData(GL_ARRAY_BUFFER, 3*24*sizeof(GLfloat), backdrop.vertices, GL_STATIC_DRAW);
        glEnableVertexAttribArray(ATTRIB_POSITION);
        glVertexAttribPointer(ATTRIB_POSITION, 3, GL_FLOAT, GL_FALSE, 3*sizeof(GLfloat), BUFFER_OFFSET(0));

        // pass on normals
        glBindBuffer(GL_ARRAY_BUFFER, vbo[1]);
        glBufferData(GL_ARRAY_BUFFER, 3*24*sizeof(GLfloat), backdrop.normals, GL_STATIC_DRAW);
        glEnableVertexAttribArray(ATTRIB_NORMAL);
        glVertexAttribPointer(ATTRIB_NORMAL, 3, GL_FLOAT, GL_FALSE, 3*sizeof(GLfloat), BUFFER_OFFSET(0));

        // pass on texture coordinates
        glBindBuffer(GL_ARRAY_BUFFER, vbo[2]);
        glBufferData(GL_ARRAY_BUFFER, 2*24*sizeof(GLfloat), backdrop.texCoords, GL_STATIC_DRAW);
        glEnableVertexAttribArray(ATTRIB_TEXTURE);
        glVertexAttribPointer(ATTRIB_TEXTURE, 3, GL_FLOAT, GL_FALSE, 2*sizeof(GLfloat), BUFFER_OFFSET(0));

        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, backdrop.ibo);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(backdrop.indices[0]) * backdrop.numIndices, backdrop.indices, GL_STATIC_DRAW);
    
    // deselect the VAOs just to be clean
    glBindVertexArray(0);
}

- (void)despawnAnimals {
    for (int i = 0; i < sizeof(objects)/sizeof(objects[0]); i++){
        objects[i] = nullObjects[i];
    }
}

- (void)loadAnimal:(int)animalCountx
{
    distx = 0;
    disty = 0;
    animalCount = animalCountx;
    
    
    for(int i = 0; i < sizeof(objects)/sizeof(objects[0]); i = i+1) {
        // cube (centre, textured)
        glGenVertexArrays(1, &objects[i].vao);
        glGenBuffers(1, &objects[i].ibo);

        // get cube data
        objects[i].numIndices = glesRenderer.GenAnimal(1.0f, &objects[i].vertices, &objects[i].normals, &objects[i].texCoords, &objects[i].indices);

        switch(arc4random_uniform(5)+1) {
            case 1:
                objects[i].animalTexture = [self setupTexture:(@"durgon.png")];
                glActiveTexture(GL_TEXTURE1);
                objects[i].animalTextureIndex = 1;
                break;
                
            case 2:
                objects[i].animalTexture = [self setupTexture:(@"durgon2.png")];
                glActiveTexture(GL_TEXTURE2);
                objects[i].animalTextureIndex = 3;
                break;
                
            case 3:
                objects[i].animalTexture = [self setupTexture:(@"durgon3.png")];
                glActiveTexture(GL_TEXTURE3);
                objects[i].animalTextureIndex = 3;
                break;
                
            case 4:
                objects[i].animalTexture = [self setupTexture:(@"badger.png")];
                glActiveTexture(GL_TEXTURE4);
                objects[i].animalTextureIndex = 4;
                break;
                
            case 5:
                objects[i].animalTexture = [self setupTexture:(@"badger2.png")];
                glActiveTexture(GL_TEXTURE5);
                objects[i].animalTextureIndex = 5;
                break;
                
            case 6:
                objects[i].animalTexture = [self setupTexture:(@"badger3.png")];
                glActiveTexture(GL_TEXTURE6);
                objects[i].animalTextureIndex = 6;
                break;
                
            case 7:
                objects[i].animalTexture = [self setupTexture:(@"pig.png")];
                glActiveTexture(GL_TEXTURE7);
                objects[i].animalTextureIndex = 7;
                break;
                
            case 8:
                
                objects[i].animalTexture = [self setupTexture:(@"pig2.png")];
                glActiveTexture(GL_TEXTURE8);
                objects[i].animalTextureIndex = 8;
                break;
                
            case 9:
                objects[i].animalTexture = [self setupTexture:(@"pig3.png")];
                glActiveTexture(GL_TEXTURE9);
                objects[i].animalTextureIndex = 9;
                break;
                
            case 10:
                objects[i].animalTexture = [self setupTexture:(@"sheep.png")];
                glActiveTexture(GL_TEXTURE10);
                objects[i].animalTextureIndex = 10;
                break;
                
            case 11:
                objects[i].animalTexture = [self setupTexture:(@"sheep2.png")];
                glActiveTexture(GL_TEXTURE11);
                objects[i].animalTextureIndex = 11;
                break;
                
            case 12:
                objects[i].animalTexture = [self setupTexture:(@"sheep3.png")];
                glActiveTexture(GL_TEXTURE12);
                objects[i].animalTextureIndex = 12;
                break;
                
            case 13:
                objects[i].animalTexture = [self setupTexture:(@"anteater.png")];
                glActiveTexture(GL_TEXTURE13);
                objects[i].animalTextureIndex = 13;
                break;
                
        }
        
        glBindTexture(GL_TEXTURE_2D, objects[i].animalTexture);
        glUniform1i(uniforms[UNIFORM_TEXTURE], 0);
        
        // set up VBOs (one per attribute)
        glBindVertexArray(objects[i].vao);
        GLuint vbo[3];
        glGenBuffers(3, vbo);

        // pass on position data
        glBindBuffer(GL_ARRAY_BUFFER, vbo[0]);
        glBufferData(GL_ARRAY_BUFFER, 3*24*sizeof(GLfloat), objects[i].vertices, GL_STATIC_DRAW);
        glEnableVertexAttribArray(ATTRIB_POSITION);
        glVertexAttribPointer(ATTRIB_POSITION, 3, GL_FLOAT, GL_FALSE, 3*sizeof(GLfloat), BUFFER_OFFSET(0));

        // pass on normals
        glBindBuffer(GL_ARRAY_BUFFER, vbo[1]);
        glBufferData(GL_ARRAY_BUFFER, 3*24*sizeof(GLfloat), objects[i].normals, GL_STATIC_DRAW);
        glEnableVertexAttribArray(ATTRIB_NORMAL);
        glVertexAttribPointer(ATTRIB_NORMAL, 3, GL_FLOAT, GL_FALSE, 3*sizeof(GLfloat), BUFFER_OFFSET(0));

        // pass on texture coordinates
        glBindBuffer(GL_ARRAY_BUFFER, vbo[2]);
        glBufferData(GL_ARRAY_BUFFER, 2*24*sizeof(GLfloat), objects[i].texCoords, GL_STATIC_DRAW);
        glEnableVertexAttribArray(ATTRIB_TEXTURE);
        glVertexAttribPointer(ATTRIB_TEXTURE, 3, GL_FLOAT, GL_FALSE, 2*sizeof(GLfloat), BUFFER_OFFSET(0));

        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, objects[i].ibo);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(objects[i].indices[0]) * objects[i].numIndices, objects[i].indices, GL_STATIC_DRAW);
        
        objects[i].animalSpawnPosX = arc4random_uniform(3) + 1;
        objects[i].animalSpawnPosY = (arc4random_uniform(15) - 1.5)/10;
    }
    // deselect the VAOs just to be clean
    glBindVertexArray(0);
}

- (void)setup:(GLKView *)view
{
    view.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    
    if (!view.context) {
        NSLog(@"Failed to create ES context");
    }
    
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    theView = view;
    [EAGLContext setCurrentContext:view.context];
    if (![self setupShaders])
        return;
    
    box2d = [[CBox2D alloc] init];
    
    // set up lighting values
    specularComponent = GLKVector4Make(1.0f, 1.0f, 1.0f, 1.0f);
    specularLightPosition = GLKVector4Make(1.0f, 1.0f, 1.0f, 1.0f);
    shininess = 200.0f;
    
    ambientComponent = GLKVector4Make(1.0f, 1.0f, 1.0f, 1.0f);
    
    for(int i = 0; i < sizeof(objects)/sizeof(objects[0]); i = i+1) {
            objects[i].diffuseLightPosition = GLKVector4Make(0.0f, 1.0f, 0.0f, 1.0f);
            objects[i].diffuseComponent = GLKVector4Make(1.0f, 1.0f, 1.0f, 1.0f);
    }
    
    backdrop.diffuseLightPosition = GLKVector4Make(0.0f, 2.0f, 2.0f, 1.0f);
    backdrop.diffuseComponent = GLKVector4Make(0.5375f, 0.8695f, 1.076f, 1.0f);
    
    // Set background/sky colour
    glClearColor(0.5764f, 0.74509f, 0.929411f, 1.0f);
    //glEnable(GL_DEPTH_TEST);
    //glEnable(GL_CULL_FACE);
    lastTime = std::chrono::steady_clock::now();
    
    distx = 0.0;
    disty = 0.0;
    distIncr = 0.05f;
}

- (void)update
{
    // Calculate elapsed time and update Box2D
    auto currentTime = std::chrono::steady_clock::now();
    auto elapsedTime = std::chrono::duration_cast<std::chrono::milliseconds>(currentTime - lastTime).count();
    lastTime = currentTime;
    [box2d Update:elapsedTime/1000.0f];
    
    // make specular light move with camera
    specularLightPosition = GLKVector4Make(0.0, 0.0f, -15.0f, 1.0f);
    
    GLKVector4 specComponentFlashOff = GLKVector4Make(0.4f, 0.2f, 0.2f, 0.1f);
    float shininessFlashOff = 200.0;
    shininess = shininessFlashOff;
    specularComponent = specComponentFlashOff;
    
    // perspective projection matrix
    //float aspect = (float)theView.drawableWidth / (float)theView.drawableHeight;
    //GLKMatrix4 perspective = GLKMatrix4MakePerspective(60.0f * M_PI / 180.0f, aspect, 1.0f, 20.0f);
    
    GLKMatrix4 perspective = GLKMatrix4MakeOrtho(-1.5f,1.5f, -3, 3,1,10);
    
    // backdrop
    backdrop.mvp = GLKMatrix4Scale(GLKMatrix4Translate(GLKMatrix4Identity, -3.0, 0.2, -5.0),4.0,4.0,0.0);
    backdrop.mvp = GLKMatrix4Rotate(backdrop.mvp, 1.57f, 1.0,0.0,0.0);
    backdrop.mvm = backdrop.mvp =   GLKMatrix4Multiply(GLKMatrix4Translate(GLKMatrix4Identity, 3, -0.5, 0), backdrop.mvp);
    backdrop.normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(backdrop.mvp), NULL);
    backdrop.mvp = GLKMatrix4Multiply(perspective, backdrop.mvp);

    for(int i = 0; i < animalCount; i = i+1) {
        objects[i].mvp = GLKMatrix4Scale(GLKMatrix4Translate(GLKMatrix4Identity, -2.0, 0.0, -5.0 - i/10),1.0,1.0,0.000001);
        objects[i].mvm = objects[i].mvp = GLKMatrix4Multiply(GLKMatrix4Translate(GLKMatrix4Identity, 0, 0, 0), objects[i].mvp);
        objects[i].normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(objects[i].mvp), NULL);
        objects[i].mvp = GLKMatrix4Multiply(perspective, objects[i].mvp);
        
        // movement
        float x = ((([box2d GetAnimalPositionX:i]-1)*(3-1))/(390 - 1)) + 1;
        float y = ((([box2d GetAnimalPositionY:i]-1)*(1.5f-(-1.5f)))/(750-1))-1.5f;
        if (x != FLT_MAX && y != FLT_MAX) {
            //objects[i].mvp = GLKMatrix4Translate(objects[i].mvp, x, y, 0.000001);
            objects[i].mvp = GLKMatrix4TranslateWithVector3(objects[i].mvp, GLKVector3Make(x,y,0));
        }
    }

}

- (void)draw:(CGRect)drawRect;
{
    // pass on global lighting, fog and texture values
    
    glUniform4fv(uniforms[UNIFORM_LIGHT_SPECULAR_POSITION], 1, specularLightPosition.v);
    glUniform1i(uniforms[UNIFORM_LIGHT_SHININESS], shininess);
    glUniform4fv(uniforms[UNIFORM_LIGHT_SPECULAR_COMPONENT], 1, specularComponent.v);
    glUniform4fv(uniforms[UNIFORM_LIGHT_AMBIENT_COMPONENT], 1, ambientComponent.v);
    
    // set up GL for drawing
    glViewport(0, 0, (int)theView.drawableWidth, (int)theView.drawableHeight);
    glClear ( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
    glUseProgram ( programObject );
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, backgroundTexture);
    glUniform1i(uniforms[UNIFORM_TEXTURE], 0);
    
    glUniform1i(uniforms[UNIFORM_USE_TEXTURE], 1);
    glUniform4fv(uniforms[UNIFORM_LIGHT_DIFFUSE_POSITION], 1, backdrop.diffuseLightPosition.v);
    glUniform4fv(uniforms[UNIFORM_LIGHT_DIFFUSE_COMPONENT], 1, backdrop.diffuseComponent.v);
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, FALSE, (const float *)backdrop.mvp.m);
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEW_MATRIX], 1, FALSE, (const float *)backdrop.mvm.m);
    glUniformMatrix3fv(uniforms[UNIFORM_NORMAL_MATRIX], 1, 0, backdrop.normalMatrix.m);
    
    glBindVertexArray(backdrop.vao);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, backdrop.ibo);
    glDrawElements(GL_TRIANGLES, (GLsizei)backdrop.numIndices, GL_UNSIGNED_INT, 0);

    for(int i = 0; i < sizeof(objects)/sizeof(objects[0]); i = i+1) {
        glEnable(GL_BLEND);
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        
        
        switch (objects[i].animalTextureIndex) {
            case 1:
                glActiveTexture(GL_TEXTURE1);
                glBindTexture(GL_TEXTURE_2D, objects[i].animalTexture);
                glUniform1i(uniforms[UNIFORM_TEXTURE], 1);
                break;
            case 2:
                glActiveTexture(GL_TEXTURE2);
                glBindTexture(GL_TEXTURE_2D, objects[i].animalTexture);
                glUniform1i(uniforms[UNIFORM_TEXTURE], 2);
                break;
            case 3:
                glActiveTexture(GL_TEXTURE3);
                glBindTexture(GL_TEXTURE_2D, objects[i].animalTexture);
                glUniform1i(uniforms[UNIFORM_TEXTURE], 3);
                break;
            case 4:
                glActiveTexture(GL_TEXTURE5);
                glBindTexture(GL_TEXTURE_2D, objects[i].animalTexture);
                glUniform1i(uniforms[UNIFORM_TEXTURE], 5);
                break;
            case 6:
                glActiveTexture(GL_TEXTURE6);
                glBindTexture(GL_TEXTURE_2D, objects[i].animalTexture);
                glUniform1i(uniforms[UNIFORM_TEXTURE], 6);
                break;
            case 7:
                glActiveTexture(GL_TEXTURE7);
                glBindTexture(GL_TEXTURE_2D, objects[i].animalTexture);
                glUniform1i(uniforms[UNIFORM_TEXTURE], 7);
                break;
            case 8:
                glActiveTexture(GL_TEXTURE8);
                glBindTexture(GL_TEXTURE_2D, objects[i].animalTexture);
                glUniform1i(uniforms[UNIFORM_TEXTURE], 8);
                break;
            case 9:
                glActiveTexture(GL_TEXTURE9);
                glBindTexture(GL_TEXTURE_2D, objects[i].animalTexture);
                glUniform1i(uniforms[UNIFORM_TEXTURE], 9);
                break;
            case 10:
                glActiveTexture(GL_TEXTURE10);
                glBindTexture(GL_TEXTURE_2D, objects[i].animalTexture);
                glUniform1i(uniforms[UNIFORM_TEXTURE], 10);
                break;
            case 11:
                glActiveTexture(GL_TEXTURE11);
                glBindTexture(GL_TEXTURE_2D, objects[i].animalTexture);
                glUniform1i(uniforms[UNIFORM_TEXTURE], 11);
                break;
            case 12:
                glActiveTexture(GL_TEXTURE12);
                glBindTexture(GL_TEXTURE_2D, objects[i].animalTexture);
                glUniform1i(uniforms[UNIFORM_TEXTURE], 12);
                break;
            case 13:
                glActiveTexture(GL_TEXTURE13);
                glBindTexture(GL_TEXTURE_2D, objects[i].animalTexture);
                glUniform1i(uniforms[UNIFORM_TEXTURE], 13);
                break;
        }
        
        
        glUniform4fv(uniforms[UNIFORM_LIGHT_DIFFUSE_POSITION], 1, objects[i].diffuseLightPosition.v);
        glUniform4fv(uniforms[UNIFORM_LIGHT_DIFFUSE_COMPONENT], 1, objects[i].diffuseComponent.v);
        glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, FALSE, (const float *)objects[i].mvp.m);
        glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEW_MATRIX], 1, FALSE, (const float *)objects[i].mvm.m);
        glUniformMatrix3fv(uniforms[UNIFORM_NORMAL_MATRIX], 1, 0, objects[i].normalMatrix.m);
        
        glBindVertexArray(objects[i].vao);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, objects[i].ibo);
        glDrawElements(GL_TRIANGLES, (GLsizei)objects[i].numIndices, GL_UNSIGNED_INT, 0);
    }
}


- (bool)setupShaders
{
    // Load shaders
    char *vShaderStr = glesRenderer.LoadShaderFile([[[NSBundle mainBundle] pathForResource:[[NSString stringWithUTF8String:"VertexShader.vsh"] stringByDeletingPathExtension] ofType:[[NSString stringWithUTF8String:"VertexShader.vsh"] pathExtension]] cStringUsingEncoding:1]);
    char *fShaderStr = glesRenderer.LoadShaderFile([[[NSBundle mainBundle] pathForResource:[[NSString stringWithUTF8String:"FragmentShader.fsh"] stringByDeletingPathExtension] ofType:[[NSString stringWithUTF8String:"FragmentShader.fsh"] pathExtension]] cStringUsingEncoding:1]);
    programObject = glesRenderer.LoadProgram(vShaderStr, fShaderStr);
    if (programObject == 0)
        return false;
    
    // Set up uniform variables
    uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX] = glGetUniformLocation(programObject, "modelViewProjectionMatrix");
    uniforms[UNIFORM_MODELVIEW_MATRIX] = glGetUniformLocation(programObject, "modelViewMatrix");
    uniforms[UNIFORM_NORMAL_MATRIX] = glGetUniformLocation(programObject, "normalMatrix");
    uniforms[UNIFORM_TEXTURE] = glGetUniformLocation(programObject, "texSampler");
    uniforms[UNIFORM_LIGHT_SPECULAR_POSITION] = glGetUniformLocation(programObject, "specularLightPosition");
    uniforms[UNIFORM_LIGHT_DIFFUSE_POSITION] = glGetUniformLocation(programObject, "diffuseLightPosition");
    uniforms[UNIFORM_LIGHT_DIFFUSE_COMPONENT] = glGetUniformLocation(programObject, "diffuseComponent");
    uniforms[UNIFORM_LIGHT_SHININESS] = glGetUniformLocation(programObject, "shininess");
    uniforms[UNIFORM_LIGHT_SPECULAR_COMPONENT] = glGetUniformLocation(programObject, "specularComponent");
    uniforms[UNIFORM_LIGHT_AMBIENT_COMPONENT] = glGetUniformLocation(programObject, "ambientComponent");
    uniforms[UNIFORM_USE_TEXTURE] = glGetUniformLocation(programObject, "useTexture");
    return true;
}


// Load in and set up texture image (adapted from Ray Wenderlich)
- (GLuint)setupTexture:(NSString *)fileName
{
    CGImageRef spriteImage = [UIImage imageNamed:fileName].CGImage;
    if (!spriteImage) {
        NSLog(@"Failed to load image %@", fileName);
        exit(1);
    }
    
    size_t width = CGImageGetWidth(spriteImage);
    size_t height = CGImageGetHeight(spriteImage);
    
    GLubyte *spriteData = (GLubyte *) calloc(width*height*4, sizeof(GLubyte));
    
    CGContextRef spriteContext = CGBitmapContextCreate(spriteData, width, height, 8, width*4, CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);
    
    CGContextDrawImage(spriteContext, CGRectMake(0, 0, width, height), spriteImage);
    
    CGContextRelease(spriteContext);
    
    GLuint texName;
    glGenTextures(2, &texName);
    glBindTexture(GL_TEXTURE_2D, texName);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (GLsizei)width, (GLsizei)height, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
    
    free(spriteData);
    return texName;
}

@end


