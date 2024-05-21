//
//  LightsourceSamplingCommonMacros.m
//  AdvancedRenderingToolkit
//
//  Created by Dominik Dinh on 26.01.2024.
//


#import "LightsourceSamplingCommonMacros.h"


@implementation LightsourceSamplingCommonMacros


+ (double) sampleCosineWeighedHemisphere
        : (Vec3D*) _worldVec
        : (Vec3D) _normal
        : (double*) cosine
{
    
        Vec3D       _localVec;
        Trafo3D     local2world;
        Trafo3D     world2local;
    
        trafo3d_v_world2local_from_worldspace_normal_t( & _normal, & world2local );
        trafo3d_t_transpose_t( & world2local, & local2world );
    
    
        double  sqrlen;
        double retPDF = 1;
    
        double r1, r2;
        r1 = (double)rand() / RAND_MAX;
        r2 = (double)rand() / RAND_MAX;

        double z = sqrt(r2);
        double x = cos(2 * M_PI * r1) * sqrt(1 - r2);
        double y = sin(2 * M_PI * r1) * sqrt(1 - r2);
    
    
    (_localVec) = VEC3D(x, y, z);
    z = fmax(z, 1e-6f);

    vec3d_v_trafo3d_v( & (_localVec), & (local2world), (_worldVec) );
    *cosine = z;
    
    return z / M_PI;
//        do
//        {
//            double  phi, z, r;
//            
////            [ RANDOM_GENERATOR getValuesFromNewSequences: & z : & phi ];
////            [ RANDOM_GENERATOR r]
//            double r1, r2;
//    
//            r1 = (float)rand() / RAND_MAX;
//            r2 = (float)rand() / RAND_MAX;
//            
//            z = 1 - 2.0f * r1;
//            r = sqrt ( M_MAX(0.0f, 1 - z * z ) );
//            phi = MATH_2_MUL_PI * r2;
//            
//            
//            (_localVec) = VEC3D(r * cos(phi), r * sin(phi), z);
////            XC(_localVec) = 0.174944952f;
////            YC(_localVec) = -0.159112081f;
////            ZC(_localVec) = 0.971636534;
//            
//            
//            *cosine = ZC(_localVec);
//            
//            vec3d_v_trafo3d_v( & (_localVec), & (local2world), (_worldVec) );
//            
//            sqrlen = vec3d_v_sqrlen((_worldVec));
//            
//            retPDF = z / M_PI;
//        }
//        while ( sqrlen < MATH_TINY_DOUBLE );
        
        const double len_inv = 1.0 / sqrt(sqrlen);
        
    
        vec3d_norm_v(_worldVec);

    
    return M_ABS(retPDF);
}

@end
