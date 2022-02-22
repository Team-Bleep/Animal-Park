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

enum {
    UNIFORM_MODELVIEWPROJECTION_MATRIX,
    UNIFORM_NORMAL_MATRIX,
    UNIFORM_PASSTHROUGH,
    UNIFORM_SHADEINFRAG,
    UNIFORM_TEXTURE,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

enum{
    ATTRIB_VERTEX,
    ATTRIB_NORMAL,
    NUM_ATTRIBUTES
};

@interface Renderer () {
    GLKView *theView;
    GLESRenderer glesRenderer;
    GLuint programObject;
    
    GLKMatrix4 modelViewProjection;
    GLKMatrix3 normalMatrix;
    GLuint backdropTexture;
    
    float *vertices;
    float *normals, *texCoords;
    int *indices, numIndices, animalNumIndices;
}

@end

@implementation Renderer;

- (void)dealloc {
    glDeleteProgram(programObject);
}

- (void) loadBackdrop{
    numIndices = glesRenderer.GenBackdrop(1.0f, &vertices, &normals, &texCoords, &indices);
}

- (void) loadAnimal{
    animalNumIndices = glesRenderer.GenAnimal(1.0f, &vertices, &normals, &texCoords, &indices);
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
       
    
    backdropTexture = [self setupTexture:@"park.png"];
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, backdropTexture);
    glUniform1i(uniforms[UNIFORM_TEXTURE], 0);
    
    
    glClearColor(1.0f, 0.0f, 0.0f, 0.0f);
    glEnable(GL_DEPTH_TEST);
}

- (void)update {

    modelViewProjection = GLKMatrix4Translate(GLKMatrix4Identity, 0.0, 0.0, -5);
    normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(modelViewProjection), NULL);
    
    float aspect = (float)theView.drawableWidth /  (float)theView.drawableHeight;
    GLKMatrix4 perspective = GLKMatrix4MakePerspective(60.0f * M_PI / 180.0f, aspect, 1.0f, 20.0f);
    modelViewProjection = GLKMatrix4Multiply(perspective, modelViewProjection);
}

- (void)draw:(CGRect)drawBackdrop; {
    glUniformMatrix4fv(uniforms [UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, FALSE, (const float *)modelViewProjection.m);
    glUniformMatrix3fv(uniforms[UNIFORM_NORMAL_MATRIX], 1, 0, normalMatrix.m);
    glUniform1i(uniforms[UNIFORM_PASSTHROUGH], false);
    glUniform1i(uniforms[UNIFORM_SHADEINFRAG], true);
    glViewport(0, 0, (int)theView.drawableWidth, (int)theView.drawableHeight);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glUseProgram(programObject);
    
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(GLfloat), vertices);
    glEnableVertexAttribArray(0);
    glVertexAttrib4f(1, 1.0f, 1.0f, 0.0f, 1.0f);
    glVertexAttribPointer(2, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(GLfloat), normals);
    glEnableVertexAttribArray(2);
    glVertexAttribPointer(3, 2, GL_FLOAT, GL_FALSE, 2 * sizeof(GLfloat),texCoords);
    glEnableVertexAttribArray(3);
    glDrawElements(GL_TRIANGLES, numIndices, GL_UNSIGNED_INT, indices);

//
//    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(GLfloat), vertices);
//    glEnableVertexAttribArray(0);
//    glVertexAttrib4f(1, 1.0f, 1.0f, 0.0f, 1.0f);
//    glVertexAttribPointer(2, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(GLfloat), normals);
//    glEnableVertexAttribArray(2);
//    glVertexAttribPointer(3, 2, GL_FLOAT, GL_FALSE, 2 * sizeof(GLfloat),texCoords);
//    glEnableVertexAttribArray(3);
    //glDrawElements(GL_TRIANGLES, animalNumIndices, GL_UNSIGNED_INT, indices);
}

- (void)drawAnml:(CGRect)drawAnimal; {
    //glUniformMatrix4fv(uniforms [UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, FALSE, (const float *)modelViewProjection.m);
    //glUniformMatrix3fv(uniforms[UNIFORM_NORMAL_MATRIX], 1, 0, normalMatrix.m);
    //glUniform1i(uniforms[UNIFORM_PASSTHROUGH], false);
    //glUniform1i(uniforms[UNIFORM_SHADEINFRAG], true);
    //glViewport(0, 0, (int)theView.drawableWidth, (int)theView.drawableHeight);
    //glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    //glUseProgram(programObject);
    
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(GLfloat), vertices);
    glEnableVertexAttribArray(0);
    glVertexAttrib4f(1, 1.0f, 1.0f, 0.0f, 1.0f);
    glVertexAttribPointer(2, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(GLfloat), normals);
    glEnableVertexAttribArray(2);
    glVertexAttribPointer(3, 2, GL_FLOAT, GL_FALSE, 2 * sizeof(GLfloat),texCoords);
    glEnableVertexAttribArray(3);
    glDrawElements(GL_TRIANGLES, animalNumIndices, GL_UNSIGNED_INT, indices);
}

- (bool)setupShaders{
    char *vertexShaderStr = glesRenderer.LoadShaderFile([[[NSBundle mainBundle]pathForResource:[[NSString stringWithUTF8String:"VertexShader.vsh"] stringByDeletingPathExtension] ofType:[[NSString stringWithUTF8String:"VertexShader.vsh"] pathExtension]] cStringUsingEncoding:1]);
    
    char *fragmentShaderStr = glesRenderer.LoadShaderFile([[[NSBundle mainBundle] pathForResource:[[NSString stringWithUTF8String:"FragmentShader.fsh"] stringByDeletingPathExtension] ofType:[[NSString stringWithUTF8String:"FragmentShader.fsh"] pathExtension]] cStringUsingEncoding:1]);
    programObject = glesRenderer.LoadProgram(vertexShaderStr, fragmentShaderStr);
    if(programObject == 0){
        NSLog(@"PROG OBJ WHERE HOMIE???");
        return false;
    }
      
    
    uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX] = glGetUniformLocation(programObject, "modelViewProjectionMatrix");
    uniforms[UNIFORM_NORMAL_MATRIX] = glGetUniformLocation(programObject, "normalMatrix");
    uniforms[UNIFORM_PASSTHROUGH] = glGetUniformLocation(programObject, "passThrough");
    uniforms[UNIFORM_SHADEINFRAG] = glGetUniformLocation(programObject, "shadeInFrag");
    uniforms[UNIFORM_TEXTURE] = glGetUniformLocation(programObject, "texSampler");
    
    return true;
}

- (GLuint) setupTexture:(NSString *)fileName {
    CGImageRef spriteImage = [UIImage imageNamed:fileName].CGImage;
    if(!spriteImage) {
        NSLog(@"Failed to load image %@", fileName);
        exit(1);
    }
    
    int width = (int)CGImageGetWidth(spriteImage);
    int height = (int)CGImageGetHeight(spriteImage);
    NSLog(@"Image Height: %d", height);
    NSLog(@"Image Width: %d", width);
    
    GLubyte *spriteData = (GLubyte *) calloc(width*height*4, sizeof(GLubyte));
    
    CGContextRef spriteContext = CGBitmapContextCreate(spriteData, width, height, 8, width * 4, CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);
    
    CGContextDrawImage(spriteContext, CGRectMake(0, 0, width, height), spriteImage);
    
    CGContextRelease(spriteContext);
    
    GLuint texName;
    glGenTextures(1, &texName);
    glBindTexture(GL_TEXTURE_2D, texName);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
    free(spriteData);
    return texName;
}
    

@end
