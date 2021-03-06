//
//  GLESRenderer.cpp
//  AnimalPark
//
//  Created by Mohammed Bajaman on 2022-02-19.
//

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <iostream>
#include "GLESRenderer.hpp"

// Open and read Shader file source. Returns contents of shader file
char *GLESRenderer::LoadShaderFile(const char *shaderFileName) {
    FILE *fp = fopen(shaderFileName, "rb");
    if(fp == NULL)
        return NULL;
    
    fseek(fp, 0, SEEK_END);
    long totalBytes = ftell(fp);
    fclose(fp);
    
    char *buf = (char *) malloc(totalBytes+1);
    memset(buf, 0, totalBytes+1);
    
    fp = fopen(shaderFileName, "rb");
    if(fp == NULL)
        return NULL;
    
    size_t bytesRead = fread(buf, totalBytes, 1, fp);
    fclose(fp);
    if (bytesRead < 1){
        return NULL;
    }
    
    return buf;
}

// Compile shaders for OpenGL program
GLuint GLESRenderer::LoadShader(GLenum type, const char *shaderSrc) {
    //LoadShader
    GLuint shader = glCreateShader(type);
    if(shader == 0)
        return 0;
    
    glShaderSource(shader, 1, &shaderSrc, NULL);
    glCompileShader(shader);
    
    GLint compiled;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &compiled);
    if(!compiled){
        GLint infoLen = 0;
        glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &infoLen);
        if(infoLen > 1) {
            char *infoLog = (char *)malloc(sizeof (char) * infoLen);
            glGetShaderInfoLog(shader, infoLen, NULL, infoLog);
            std::cerr << "*** SHADER COMPILER ERROR:" <<std::endl;
            std::cerr << infoLog << std::endl;
            free(infoLog);
        }
        glDeleteShader(shader);
        return 0;
    }
    
    
    return shader;
}

// Setup and Load the OpenGL program after reading both vertex and fragment Shaders
GLuint GLESRenderer::LoadProgram(const char *vertShaderSrc, const char *fragShaderSrc) {
    GLuint vertexShader = LoadShader(GL_VERTEX_SHADER, vertShaderSrc);
    if (vertexShader == 0)
        return 0;
    
    GLuint fragmentShader = LoadShader(GL_FRAGMENT_SHADER, fragShaderSrc);
    if (fragmentShader == 0) {
        glDeleteShader(vertexShader);
        return 0;
    }
    
    
    GLuint programObject = glCreateProgram();
    if (programObject == 0) {
        glDeleteShader(vertexShader);
        glDeleteShader(fragmentShader);
        return 0;
    }
    
    glAttachShader(programObject, vertexShader);
    glAttachShader(programObject, fragmentShader);
    glLinkProgram(programObject);
    
    GLint linked;
    
    glGetProgramiv(programObject, GL_LINK_STATUS, &linked);
    if (!linked) {
        GLint infoLen = 0;
        glGetProgramiv(programObject, GL_INFO_LOG_LENGTH, &infoLen);
        if (infoLen > 1) {
            char *infoLog = (char *)malloc(sizeof(char) *infoLen);
            glGetProgramInfoLog(programObject, infoLen, NULL, infoLog);
            std::cerr << "**SHADER LINK ERROR:" << std::endl;
            std::cerr << infoLog << std::endl;
            free(infoLog);
        }
        glDeleteProgram(programObject);
        return 0;
    }
    
    glDeleteShader(vertexShader);
    glDeleteShader(fragmentShader);
    
    return programObject;
}

// Generate square information for Backdrop w/ textures
int GLESRenderer::GenBackdrop(float scale, float **vertices, float **normals, float **texCoords, int **indices) {
    //Generate backdrop
    int i;
    int numVertices = 4;
    int numIndices = 6;
    
    float squareVerts[] = {
        -2.0f, -2.0f, 2.0f,  //Bottom Left
        -2.0f, 2.0f,  2.0f,  //Top Left
        2.0f, -2.0f,  2.0f, //Bottom Right
        2.0f, 2.0f,  2.0f,  //Top Right
    };
    
    float squareNormals[] = {
        0.0f, 0.0f, 1.0f,
        0.0f, 0.0f, 1.0f,
        0.0f, 0.0f, 1.0f,
        0.0f, 0.0f, 1.0f,
    };
    
    float squareTex[] = {
        1.0f, 1.0f,
        1.0f, 0.0f,
        0.0f, 1.0f,
        0.0f, 0.0,
    };
   
    
    // Memory for buffers - VERTICES
    if (vertices!=NULL) {
        *vertices = (float *) malloc(sizeof(float) * 3 * numVertices);
        memcpy(*vertices, squareVerts, sizeof(squareVerts));
        
        for(i = 0; i < numVertices * 3; i++){
            (*vertices) [i] *= scale;
        }
    }
    
    // Memory for buffers - NORMALS
    if (normals!=NULL) {
        *normals = (float *) malloc(sizeof(float) * 3 * numVertices);
        memcpy(*normals, squareNormals, sizeof(squareNormals));
    }
    
    // Memory for buffers - TEXTURE COORDINATES
    if (texCoords != NULL) {
        *texCoords = (float *)malloc (sizeof(float) * 2 * numVertices);
        memcpy (*texCoords, squareTex, sizeof (squareTex)) ;
    }
    
    // Memory for buffers - INDICES + Generation of indices
    if (indices!=NULL) {
        GLuint squareIndices[] = {
            0,1,2,
            1,3,2
        };
        
        *indices = (int *) malloc(sizeof(int) * numIndices);
        memcpy(*indices, squareIndices, sizeof(squareIndices));
    }
    
    return numIndices;
}

// Generate a 3D cube for animals w/ texture
int GLESRenderer::GenAnimal(float scale, float **vertices, float **normals, float **texCoords, int **indices) {
    int i;
    int numVertices = 24;
    int numIndices = 36;
    
    float cubeVerts[] = {
        -0.5f, -0.5f, -0.5f,
        -0.5f, -0.5f,  0.5f,
        0.5f, -0.5f,  0.5f,
        0.5f, -0.5f, -0.5f,
        -0.5f,  0.5f, -0.5f,
        -0.5f,  0.5f,  0.5f,
        0.5f,  0.5f,  0.5f,
        0.5f,  0.5f, -0.5f,
        -0.5f, -0.5f, -0.5f,
        -0.5f,  0.5f, -0.5f,
        0.5f,  0.5f, -0.5f,
        0.5f, -0.5f, -0.5f,
        -0.5f, -0.5f, 0.5f,
        -0.5f,  0.5f, 0.5f,
        0.5f,  0.5f, 0.5f,
        0.5f, -0.5f, 0.5f,
        -0.5f, -0.5f, -0.5f,
        -0.5f, -0.5f,  0.5f,
        -0.5f,  0.5f,  0.5f,
        -0.5f,  0.5f, -0.5f,
        0.5f, -0.5f, -0.5f,
        0.5f, -0.5f,  0.5f,
        0.5f,  0.5f,  0.5f,
        0.5f,  0.5f, -0.5f,
    };
    
    float cubeNormals[] = {
        0.0f, -1.0f, 0.0f,
        0.0f, -1.0f, 0.0f,
        0.0f, -1.0f, 0.0f,
        0.0f, -1.0f, 0.0f,
        0.0f, 1.0f, 0.0f,
        0.0f, 1.0f, 0.0f,
        0.0f, 1.0f, 0.0f,
        0.0f, 1.0f, 0.0f,
        0.0f, 0.0f, -1.0f,
        0.0f, 0.0f, -1.0f,
        0.0f, 0.0f, -1.0f,
        0.0f, 0.0f, -1.0f,
        0.0f, 0.0f, 1.0f,
        0.0f, 0.0f, 1.0f,
        0.0f, 0.0f, 1.0f,
        0.0f, 0.0f, 1.0f,
        -1.0f, 0.0f, 0.0f,
        -1.0f, 0.0f, 0.0f,
        -1.0f, 0.0f, 0.0f,
        -1.0f, 0.0f, 0.0f,
        1.0f, 0.0f, 0.0f,
        1.0f, 0.0f, 0.0f,
        1.0f, 0.0f, 0.0f,
        1.0f, 0.0f, 0.0f,
    };
    
    float cubeTex[] = {
        0.0f, 0.0f,
        0.0f, 1.0f,
        1.0f, 1.0f,
        1.0f, 0.0f,
        1.0f, 0.0f,
        1.0f, 1.0f,
        0.0f, 1.0f,
        0.0f, 0.0f,
        0.0f, 0.0f,
        0.0f, 1.0f,
        1.0f, 1.0f,
        1.0f, 0.0f,
        0.0f, 0.0f,
        0.0f, 1.0f,
        1.0f, 1.0f,
        1.0f, 0.0f,
        0.0f, 0.0f,
        0.0f, 1.0f,
        1.0f, 1.0f,
        1.0f, 0.0f,
        0.0f, 0.0f,
        0.0f, 1.0f,
        1.0f, 1.0f,
        1.0f, 0.0f,
    };
    
    // Allocate memory for buffers
    if (vertices != NULL) {
        *vertices = (float *)malloc (sizeof (float) * 3 * numVertices);
        memcpy (*vertices, cubeVerts, sizeof (cubeVerts));
        
        for (i = 0; i < numVertices * 3; i++) {
            (*vertices) [i] *= scale;
        }
    }
    
    if (normals != NULL) {
        *normals = (float *)malloc (sizeof(float) * 3 * numVertices);
        memcpy (*normals, cubeNormals, sizeof ( cubeNormals));
    }
    
    if (texCoords != NULL) {
        *texCoords = (float *)malloc (sizeof(float) * 2 * numVertices);
        memcpy (*texCoords, cubeTex, sizeof (cubeTex ));
    }
    
    
    // Generate the indices
    if (indices != NULL) {
        GLuint cubeIndices[] = {
            0, 2, 1,
            0, 3, 2,
            4, 5, 6,
            4, 6, 7,
            8, 9, 10,
            8, 10, 11,
            12, 15, 14,
            12, 14, 13,
            16, 17, 18,
            16, 18, 19,
            20, 23, 22,
            20, 22, 21
        };
        
        *indices = (int *)malloc (sizeof (int) * numIndices);
        memcpy (*indices, cubeIndices, sizeof (cubeIndices));
    }
    
    return numIndices;
}
