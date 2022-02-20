//
//  GLESRenderer.hpp
//  AnimalPark
//
//  Created by Mohammed Bajaman on 2022-02-19.
//

#ifndef GLESRenderer_hpp
#define GLESRenderer_hpp

#include <stdio.h>

#include <OpenGLES/ES3/gl.h>

class GLESRenderer {
public:
    char *LoadShaderFile(const char *shaderFileName);
    GLuint LoadShader(GLenum type, const char *shaderSrc);
    GLuint LoadProgram(const char *vertShaderSrc, const char *fragShaderSrc);
    
    int GenBackdrop(float scale, float **vertices, float **normals, float **texCoords, int **indices);
};

#endif /* GLESRenderer_hpp */
