//
//  rotamap.c
//  LearnOpenGLES
//
//  Created by QiuH on 2017/10/31.
//  Copyright © 2017年 林伟池. All rights reserved.
//

#include "rotamap.h"
#include <math.h>
void getRotationMatrixFromVector(float* R, int rlength, float* rotationVector, int vlength)
{
    
    float q0;
    float q1 = rotationVector[0];
    float q2 = rotationVector[1];
    float q3 = rotationVector[2];
    
    if (vlength >= 4) {
        q0 = rotationVector[3];
    } else {
        q0 = 1 - q1*q1 - q2*q2 - q3*q3;
        q0 = (q0 > 0) ? sqrtf(q0) : 0;
    }
    
    float sq_q1 = 2 * q1 * q1;
    float sq_q2 = 2 * q2 * q2;
    float sq_q3 = 2 * q3 * q3;
    float q1_q2 = 2 * q1 * q2;
    float q3_q0 = 2 * q3 * q0;
    float q1_q3 = 2 * q1 * q3;
    float q2_q0 = 2 * q2 * q0;
    float q2_q3 = 2 * q2 * q3;
    float q1_q0 = 2 * q1 * q0;
    
    if(rlength == 9) {
        R[0] = 1 - sq_q2 - sq_q3;
        R[1] = q1_q2 - q3_q0;
        R[2] = q1_q3 + q2_q0;
        
        R[3] = q1_q2 + q3_q0;
        R[4] = 1 - sq_q1 - sq_q3;
        R[5] = q2_q3 - q1_q0;
        
        R[6] = q1_q3 - q2_q0;
        R[7] = q2_q3 + q1_q0;
        R[8] = 1 - sq_q1 - sq_q2;
    } else if (rlength == 16) {
        R[0] = 1 - sq_q2 - sq_q3;
        R[1] = q1_q2 - q3_q0;
        R[2] = q1_q3 + q2_q0;
        R[3] = 0.0f;
        
        R[4] = q1_q2 + q3_q0;
        R[5] = 1 - sq_q1 - sq_q3;
        R[6] = q2_q3 - q1_q0;
        R[7] = 0.0f;
        
        R[8] = q1_q3 - q2_q0;
        R[9] = q2_q3 + q1_q0;
        R[10] = 1 - sq_q1 - sq_q2;
        R[11] = 0.0f;
        
        R[12] = R[13] = R[14] = 0.0f;
        R[15] = 1.0f;
    }
}
float mTemp[16];

const int remapCoordinateSystemImpl(float* inR, int X, int Y, float* outR, int length)
{
    if ((X & 0x7C)!=0 || (Y & 0x7C)!=0)
        return 0;   // invalid parameter
    if (((X & 0x3)==0) || ((Y & 0x3)==0))
        return 0;   // no axis specified
    if ((X & 0x3) == (Y & 0x3))
        return 0;   // same axis specified
    // Z is "the other" axis, its sign is either +/- sign(X)*sign(Y)
    // this can be calculated by exclusive-or'ing X and Y; except for
    // the sign inversion (+/-) which is calculated below.
    int Z = X ^ Y;
    
    // extract the axis (remove the sign), offset in the range 0 to 2.
    int x = (X & 0x3)-1;
    int y = (Y & 0x3)-1;
    int z = (Z & 0x3)-1;
    
    // compute the sign of Z (whether it needs to be inverted)
    int axis_y = (z+1)%3;
    int axis_z = (z+2)%3;
    if (((x^axis_y)|(y^axis_z)) != 0)
        Z ^= 0x80;
    
    int sx = (X>=0x80);
    int sy = (Y>=0x80);
    int sz = (Z>=0x80);
    
    // Perform R * r, in avoiding actual muls and adds.
    int rowLength = ((length==16)?4:3);
    for (int j=0 ; j<3 ; j++) {
        int offset = j*rowLength;
        for (int i=0 ; i<3 ; i++) {
            if (x==i)   outR[offset+i] = sx ? -inR[offset+0] : inR[offset+0];
            if (y==i)   outR[offset+i] = sy ? -inR[offset+1] : inR[offset+1];
            if (z==i)   outR[offset+i] = sz ? -inR[offset+2] : inR[offset+2];
        }
    }
    if (length == 16) {
        outR[3] = outR[7] = outR[11] = outR[12] = outR[13] = outR[14] = 0;
        outR[15] = 1;
    }
    outR[2] = - inR[2];
    outR[6] = - inR[6];
    outR[10] = - inR[10];
    outR [14] = - inR[14];
    return 1;
}
int remapCoordinateSystem(float * inR, int X, int Y,
                                float* outR)
{
    if (inR == outR) {
        float* temp = mTemp;
        //        synchronized(temp) {
        // we don't expect to have a lot of contention
        if (remapCoordinateSystemImpl(inR, X, Y, outR, 16) == 1)  {
            for (int i=0 ; i<16 ; i++)
                outR[i] = temp[i];
            return 1;
        }
        //        }
    }
    return remapCoordinateSystemImpl(inR, X, Y, outR, 16);
}
