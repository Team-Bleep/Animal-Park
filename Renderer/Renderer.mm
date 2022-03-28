//
//  Copyright © 2017 Borna Noureddin. All rights reserved.
//

#import "Renderer.h"
#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#include <chrono>
#include "GLESRenderer.hpp"

// small struct to hold object-specific information
struct RenderObject
{
    GLuint vao, ibo;    // VAO and index buffer object IDs

    // model-view, model-view-projection and normal matrices
    GLKMatrix4 mvp, mvm;
    GLKMatrix3 normalMatrix;

    // diffuse lighting parameters
    GLKVector4 diffuseLightPosition;
    GLKVector4 diffuseComponent;

    // vertex data
    float *vertices, *normals, *texCoords;
    int *indices, numIndices;
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
    UNIFORM_LIGHT_AMBIENT_COMPONENT,\
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
    GLuint crateTexture;
    GLuint mapTexture;

    // global lighting parameters
    GLKVector4 specularLightPosition;
    GLKVector4 specularComponent;
    GLfloat shininess;
    GLKVector4 ambientComponent;
    
    // render objects
    RenderObject objects[4];
    RenderObject backdrop;

    // moving camera automatically
    float dist, distIncr;
}

@end

@implementation Renderer

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
       backdrop.numIndices = glesRenderer.GenCube(1.0f, &backdrop.vertices, &backdrop.normals, &backdrop.texCoords, &backdrop.indices);

        // set up VBOs (one per attribute)
        glBindVertexArray(backdrop.vao);
        GLuint vbo[3];
        glGenBuffers(3, vbo);

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

- (void)loadAnimal
{
    // -------------- Load maze objects
    for(int i = 0; i < sizeof(objects)/sizeof(objects[0]); i = i+1) {
            
            // cube (centre, textured)
            glGenVertexArrays(1, &objects[i].vao);
            glGenBuffers(1, &objects[i].ibo);

            // get cube data
            objects[i].numIndices = glesRenderer.GenCube(1.0f, &objects[i].vertices, &objects[i].normals, &objects[i].texCoords, &objects[i].indices);

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
    crateTexture = [self setupTexture:@"park.png"];

    // set up lighting values
    specularComponent = GLKVector4Make(0.8f, 0.1f, 0.1f, 1.0f);
    specularLightPosition = GLKVector4Make(1.0f, 1.0f, 1.0f, 1.0f);
    shininess = 200.0f;
    
    ambientComponent = GLKVector4Make(0.46f, 0.78f, 0.9f, 1.0f);
    
    for(int i = 0; i < sizeof(objects)/sizeof(objects[0]); i = i+1) {
            objects[i].diffuseLightPosition = GLKVector4Make(0.0f, 1.0f, 0.0f, 1.0f);
            objects[i].diffuseComponent = GLKVector4Make(0.0f, 0.0f, 0.0f, 1.0f);
    }
    
    backdrop.diffuseLightPosition = GLKVector4Make(-1.0f, 0.0f, 0.0f, 1.0f);
    backdrop.diffuseComponent = GLKVector4Make(0.0f, 0.0f, 0.4f, 1.0f);
    
    // Set background/sky colour
    glClearColor (0.0f, 0.0f, 0.4f, 1.0f);
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_CULL_FACE);
    lastTime = std::chrono::steady_clock::now();
}

- (void)update
{
    ambientComponent = GLKVector4Make(0.16f, 0.48f, 0.6f, 1.0f);
    //glClearColor (0.0f, 0.0f, 0.0f, 1.0f);
    
    // make specular light move with camera
    specularLightPosition = GLKVector4Make(dist, 0.0f, 0.0f, 1.0f);
    
    GLKVector4 specComponentFlashOff = GLKVector4Make(0.4f, 0.2f, 0.2f, 0.1f);
    float shininessFlashOff = 200.0;
    shininess = shininessFlashOff;
    specularComponent = specComponentFlashOff;
    
    // perspective projection matrix
    float aspect = (float)theView.drawableWidth / (float)theView.drawableHeight;
    GLKMatrix4 perspective = GLKMatrix4MakePerspective(60.0f * M_PI / 180.0f, aspect, 1.0f, 20.0f);

    // backdrop
    backdrop.mvp = GLKMatrix4Scale(GLKMatrix4Translate(GLKMatrix4Identity, -3.0, 0.2, -5.0),4.0,4.0,0.0);
    backdrop.mvp = GLKMatrix4Rotate(backdrop.mvp, 1.57f, 1.0,0.0,0.0);
    backdrop.mvm = backdrop.mvp =   GLKMatrix4Multiply(GLKMatrix4Translate(GLKMatrix4Identity, 3, -0.5, 0), backdrop.mvp);
    backdrop.normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(backdrop.mvp), NULL);
    backdrop.mvp = GLKMatrix4Multiply(perspective, backdrop.mvp);

    for(int i = 0; i < sizeof(objects)/sizeof(objects[0]); i = i+1) {
        objects[i].mvp = GLKMatrix4Translate(GLKMatrix4Identity, -2.0, 0.0, -5.0);
        objects[i].mvm = objects[i].mvp = GLKMatrix4Multiply(GLKMatrix4Translate(GLKMatrix4Identity, i, -0.5, 0), objects[i].mvp);
        objects[i].normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(objects[i].mvp), NULL);
        objects[i].mvp = GLKMatrix4Multiply(perspective, objects[i].mvp);
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
            glUniform1i(uniforms[UNIFORM_USE_TEXTURE], 1);
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


