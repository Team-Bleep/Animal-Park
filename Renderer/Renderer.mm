//
//  Renderer.m
//  AnimalPark
//
//  Created by Mohammed Bajaman on 2022-02-19.
//

#import "Renderer.h"
#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
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

#define BUFFER_OFFSET(i) ((char *)NULL + (i))

enum {
    UNIFORM_MODELVIEWPROJECTION_MATRIX,
    UNIFORM_MODELVIEW_MATRIX,
    UNIFORM_LIGHT_DIFFUSE_POSITION,
    UNIFORM_LIGHT_DIFFUSE_COMPONENT,
    UNIFORM_NORMAL_MATRIX,
    UNIFORM_PASSTHROUGH,
    UNIFORM_SHADEINFRAG,
    UNIFORM_USE_TEXTURE,
    UNIFORM_TEXTURE,
    UNIFORM_LIGHT_SPECULAR_POSITION,
    UNIFORM_LIGHT_SPECULAR_COMPONENT,
    UNIFORM_LIGHT_AMBIENT_COMPONENT,
    UNIFORM_LIGHT_SHININESS,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

enum{
    ATTRIB_VERTEX,
    ATTRIB_NORMAL,
    ATTRIB_POSITION,
    ATTRIB_TEXTURE,
    NUM_ATTRIBUTES
};

@interface Renderer () {
    GLKView *theView;
    GLESRenderer glesRenderer;
    
    GLuint programObject;
    GLuint backdropTexture;
    
    // global lighting parameters
    GLKVector4 specularLightPosition;
    GLKVector4 specularComponent;
    GLfloat shininess;
    GLKVector4 ambientComponent;
    
    RenderObject animals[4];
    RenderObject backdrop;
}

@end

@implementation Renderer;

- (void)dealloc {
    glDeleteProgram(programObject);
}

- (void) loadBackdrop{
    glGenVertexArrays(1, &backdrop.vao);
    glGenBuffers(1, &backdrop.ibo);
    
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

    glBindVertexArray(0);
}

- (void) loadAnimal{
    
    
    for(int i = 0; i < sizeof(animals)/sizeof(animals[0]); i=i+1) {
        glGenVertexArrays(1, &animals[i].vao);
        glGenBuffers(1, &animals[i].ibo);

        // get animal data
        animals[i].numIndices = glesRenderer.GenAnimal(1.0f, &animals[i].vertices, &animals[i].normals, &animals[i].texCoords,&animals[i].indices);

        // set up VBOs (one per attribute)
        glBindVertexArray(animals[i].vao);
        GLuint vbo[3];
        glGenBuffers(3, vbo);

        // pass on position data
        glBindBuffer(GL_ARRAY_BUFFER, vbo[0]);
        glBufferData(GL_ARRAY_BUFFER, 3*24*sizeof(GLfloat), animals[i].vertices, GL_STATIC_DRAW);
        glEnableVertexAttribArray(ATTRIB_POSITION);
        glVertexAttribPointer(ATTRIB_POSITION, 3, GL_FLOAT, GL_FALSE, 3*sizeof(GLfloat), BUFFER_OFFSET(0));

        // pass on normals
        glBindBuffer(GL_ARRAY_BUFFER, vbo[1]);
        glBufferData(GL_ARRAY_BUFFER, 3*24*sizeof(GLfloat), animals[i].normals, GL_STATIC_DRAW);
        glEnableVertexAttribArray(ATTRIB_NORMAL);
        glVertexAttribPointer(ATTRIB_NORMAL, 3, GL_FLOAT, GL_FALSE, 3*sizeof(GLfloat), BUFFER_OFFSET(0));

        // pass on texture coordinates
        glBindBuffer(GL_ARRAY_BUFFER, vbo[2]);
        glBufferData(GL_ARRAY_BUFFER, 2*24*sizeof(GLfloat), animals[i].texCoords, GL_STATIC_DRAW);
        glEnableVertexAttribArray(ATTRIB_TEXTURE);
        glVertexAttribPointer(ATTRIB_TEXTURE, 3, GL_FLOAT, GL_FALSE, 2*sizeof(GLfloat), BUFFER_OFFSET(0));

        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, animals[i].ibo);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(animals[i].indices[0]) * animals[i].numIndices, animals[i].indices, GL_STATIC_DRAW);
    }
    glBindVertexArray(0);
}

- (void) setup:(GLKView *)view {
    view.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    
    if(!view.context) {
        NSLog(@"Failed to create ES context");
    }
    
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    theView = view;
    [EAGLContext setCurrentContext:view.context];
    if(![self setupShaders]){
        NSLog(@"SHADERS WHERE BRO?");
        return;
    }
       
    // set up lighting values
    specularComponent = GLKVector4Make(0.8f, 0.0f, 0.0f, 1.0f);
    specularLightPosition = GLKVector4Make(1.0f, 1.0f, 1.0f, 1.0f);
    shininess = 200.0f;
    
    ambientComponent = GLKVector4Make(0.46f, 0.78f, 0.9f, 1.0f);
    
    for(int i = 0; i < sizeof(animals)/sizeof(animals[0]); i = i+1) {
        animals[i].diffuseLightPosition = GLKVector4Make(0.0f, 1.0f, 0.0f, 1.0f);
        animals[i].diffuseComponent = GLKVector4Make(0.2f,0.0f,0.0f,1.0f);
    }
    
    backdrop.diffuseLightPosition = GLKVector4Make(0.0f, 1.0f, 0.0f, 1.0f);
    backdrop.diffuseComponent = GLKVector4Make(0.2f,0.0f,0.0f,1.0f);
    
    
    //backdropTexture = [self setupTexture:@"park.png"];
    //glActiveTexture(GL_TEXTURE0);
    //glBindTexture(GL_TEXTURE_2D, backdropTexture);
    //glUniform1i(uniforms[UNIFORM_TEXTURE], 1);
    
    
    glClearColor(1.0f, 0.0f, 0.0f, 0.0f);
    glEnable(GL_DEPTH_TEST);
}

- (void)update {

    //modelViewProjection = GLKMatrix4Translate(GLKMatrix4Identity, 0.0, 0.0, -5.0);
    //normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(modelViewProjection), NULL);
    
    float aspect = (float)theView.drawableWidth /  (float)theView.drawableHeight;
    GLKMatrix4 perspective = GLKMatrix4MakePerspective(60.0f * M_PI / 180.0f, aspect, 1.0f, 20.0f);
    //GLKMatrix4 projectionMatrix = GLKMatrix4Multiply(perspective, modelViewProjection);
    
    backdrop.mvp = GLKMatrix4Translate(GLKMatrix4Identity, -1.0, 0.0, -5.0);
   // backdrop.mvp = GLKMatrix4Rotate(backdrop.mvp, 0.0f, 1.0f, 0.0f, 0.0f);
    backdrop.mvm = backdrop.mvp = GLKMatrix4Multiply(GLKMatrix4Translate(GLKMatrix4Identity, 1.0, 0.0, 1.0), backdrop.mvp);
    backdrop.normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(backdrop.mvp), NULL);

    backdrop.mvp = GLKMatrix4Multiply(perspective, backdrop.mvp);
    
    //for(int i = 0; i < sizeof(animals)/sizeof(animals[0]); i = i+1) {
        //animals[i].mvp = GLKMatrix4Translate(GLKMatrix4Identity, 7.0, 0.75, 2.0);
       // animals[i].mvp = GLKMatrix4Rotate(animals[i].mvp, 0.0f, 1.0f, 0.0f, 0.0f);
        //animals[i].mvm = animals[i].mvp = GLKMatrix4Multiply(GLKMatrix4Translate(GLKMatrix4Identity, 1.0, 0.0, 1.0), animals[i].mvp);
        //animals[i].normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(animals[i].mvp), NULL);

        //animals[i].mvp = GLKMatrix4Multiply(perspective, animals[i].mvp);
    //}
}

- (void)draw:(CGRect)drawRect; {
    // pass on global lighting, fog and texture values
    glUniform4fv(uniforms[UNIFORM_LIGHT_SPECULAR_POSITION], 1, specularLightPosition.v);
    glUniform1i(uniforms[UNIFORM_LIGHT_SHININESS], shininess);
    glUniform4fv(uniforms[UNIFORM_LIGHT_SPECULAR_COMPONENT], 1, specularComponent.v);
    glUniform4fv(uniforms[UNIFORM_LIGHT_AMBIENT_COMPONENT], 1, ambientComponent.v);

    // set up GL for drawing
    glViewport(0, 0, (int)theView.drawableWidth, (int)theView.drawableHeight);
    glClear ( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
    glUseProgram ( programObject );
    
    backdropTexture = [self setupTexture:@"crate.jpg"];
    glUniform1i(uniforms[UNIFORM_USE_TEXTURE], 1);
    glUniform4fv(uniforms[UNIFORM_LIGHT_DIFFUSE_POSITION], 1, backdrop.diffuseLightPosition.v);
    glUniform4fv(uniforms[UNIFORM_LIGHT_DIFFUSE_COMPONENT], 1, backdrop.diffuseComponent.v);
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, FALSE, (const float *)backdrop.mvp.m);
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEW_MATRIX], 1, FALSE, (const float *)backdrop.mvm.m);
    glUniformMatrix3fv(uniforms[UNIFORM_NORMAL_MATRIX], 1, 0, backdrop.normalMatrix.m);
    
    glBindVertexArray(backdrop.vao);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, backdrop.ibo);
    glDrawElements(GL_TRIANGLES, (GLsizei)backdrop.numIndices, GL_UNSIGNED_INT, 0);

}

- (void)drawAnml:(CGRect)drawAnimal; {
    
    for(int i = 0; i < sizeof(animals)/sizeof(animals[0]); i = i+1) {
        glUniform1i(uniforms[UNIFORM_USE_TEXTURE], 1);
        glUniform4fv(uniforms[UNIFORM_LIGHT_DIFFUSE_POSITION], 1, animals[i].diffuseLightPosition.v);
        glUniform4fv(uniforms[UNIFORM_LIGHT_DIFFUSE_COMPONENT], 1, animals[i].diffuseComponent.v);
        glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, FALSE, (const float *)animals[i].mvp.m);
        glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEW_MATRIX], 1, FALSE, (const float *)animals[i].mvm.m);
        glUniformMatrix3fv(uniforms[UNIFORM_NORMAL_MATRIX], 1, 0, animals[i].normalMatrix.m);
        
        glBindVertexArray(animals[i].vao);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, animals[i].ibo);
        glDrawElements(GL_TRIANGLES, (GLsizei)animals[i].numIndices, GL_UNSIGNED_INT, 0);

    }
}

- (bool)setupShaders{
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

- (GLuint) setupTexture:(NSString *)fileName {
    CGImageRef spriteImage = [UIImage imageNamed:fileName].CGImage;
    if (!spriteImage) {
        NSLog(@"Failed to load image %@", fileName);
        exit(1);
    }
    
    size_t width = CGImageGetWidth(spriteImage);
    size_t height = CGImageGetHeight(spriteImage);
    
    GLubyte *spriteData2 = (GLubyte *) calloc(width*height*4, sizeof(GLubyte));
    
    CGContextRef spriteContext = CGBitmapContextCreate(spriteData2, width, height, 8, width*4, CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);
    
    CGContextDrawImage(spriteContext, CGRectMake(0, 0, width, height), spriteImage);
    
    CGContextRelease(spriteContext);
    
    GLuint texName;
    glGenTextures(2, &texName);
    glBindTexture(GL_TEXTURE_2D, texName);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (GLsizei)width, (GLsizei)height, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData2);
    
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glEnable(GL_BLEND);
    
    free(spriteData2);
    return texName;

}
    

@end
