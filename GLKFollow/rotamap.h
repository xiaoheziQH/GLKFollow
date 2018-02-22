//
//  rotamap.h
//  LearnOpenGLES
//
//  Created by QiuH on 2017/10/31.
//  Copyright © 2017年 林伟池. All rights reserved.
//

#ifndef rotamap_h
#define rotamap_h

#include <stdio.h>
extern int remapCoordinateSystem(float * inR, int X, int Y, float * outR);
extern void getRotationMatrixFromVector(float* R, int rlength,float* rotationVector, int vlength);
#endif /* rotamap_h */
