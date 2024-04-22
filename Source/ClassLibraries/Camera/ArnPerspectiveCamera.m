/* ===========================================================================

    Copyright (c) The ART Development Team
    --------------------------------------

    For a comprehensive list of the members of the development team, and a
    description of their respective contributions, see the file
    "ART_DeveloperList.txt" that is distributed with the libraries.

    This file is part of the Advanced Rendering Toolkit (ART) libraries.

    ART is free software: you can redistribute it and/or modify it under the
    terms of the GNU General Public License as published by the Free Software
    Foundation, either version 3 of the License, or (at your option) any
    later version.

    ART is distributed in the hope that it will be useful, but WITHOUT ANY
    WARRANTY; without even the implied warranty of MERCHANTABILITY or
    FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
    for more details.

    You should have received a copy of the GNU General Public License
    along with ART.  If not, see <http://www.gnu.org/licenses/>.

=========================================================================== */

#define ART_MODULE_NAME     ArnPerspectiveCamera

#import "ArnPerspectiveCamera.h"

#import "ART_Trafo.h"
#import "Trafo3D.h"

ART_MODULE_INITIALISATION_FUNCTION
(
    (void) art_gv;
    [ ArnPerspectiveCamera registerWithRuntime ];
)

ART_NO_MODULE_SHUTDOWN_FUNCTION_NECESSARY


@implementation ArnPerspectiveCamera

ARPCONCRETECLASS_DEFAULT_IMPLEMENTATION(ArnPerspectiveCamera)

- (void) _setupCamera
{
    near2world = NULL;
}

- (id) imageSize
                : (IVec2D) newImageSize
        ray     : (Ray3D) newRay
        zoom    : (double) newZoom
{
    return
    [self init
        : newRay
        : newImageSize
        : newZoom
    ];
}


- (id) init
        : (Ray3D) newRay
        : (IVec2D) newImageSize
        : (double) newHFOV
        : (double) newZoom
{
    self = [super init];
    
    if ( self )
    {
        ray =               newRay;
        imageSize =        newImageSize;
        HFOV =              newHFOV;
        twist =             0.0 DEGREES;
        near =              0.0;
        ratio =             1.0;
        zoom = newZoom;
        [self _setupCamera];
    }
    
    return self;
}

- (id) withTwist
        : (double) newTwist
{
    twist = newTwist;
    return self;
}

- (id) withNear
        : (double) newNear
{
    near = newNear;
    return self;
}

- (id) withRatio
        : (double) newRatio
{
    ratio = newRatio;
    return self;
}

- (id) init
        : (Ray3D) newRay
        : (IVec2D) newImageSize
        : (double) newZoom
        : (double) newTwist
        : (double) newNear
        : (double) newRatio
{
    self = [super init];
    
    if ( self )
    {
        ray =               newRay;
        imageSize =         newImageSize;
        zoom =              newZoom;
        twist =             newTwist;
        near =              newNear;
        ratio =             newRatio;
        [self _setupCamera];
    }
    return self;
}

- (id) copy
{
    ArnPerspectiveCamera  * copiedInstance = [ super copy ];

    copiedInstance->ray = ray;
    copiedInstance->imageSize = imageSize;
    copiedInstance->zoom = zoom;

    copiedInstance->twist = twist;
    copiedInstance->near = near;
    copiedInstance->ratio = ratio;

    copiedInstance->xscale = xscale;
    copiedInstance->yscale = yscale;

    copiedInstance->world2camera = world2camera;
    copiedInstance->camera2world = camera2world;

    if ( near2world )
    {
        copiedInstance->near2world = ALLOC(HTrafo3D);
        *copiedInstance->near2world = *near2world;
    }

    return copiedInstance;
}

- (id) deepSemanticCopy
        : (ArnGraphTraversal *) traversal
{
    ArnPerspectiveCamera  * copiedInstance =
        [ super deepSemanticCopy
            :   traversal
            ];

    copiedInstance->ray = ray;
    copiedInstance->imageSize = imageSize;
    copiedInstance->zoom = zoom;

    copiedInstance->twist = twist;
    copiedInstance->near = near;
    copiedInstance->ratio = ratio;

    copiedInstance->xscale = xscale;
    copiedInstance->yscale = yscale;

    copiedInstance->world2camera = world2camera;
    copiedInstance->camera2world = camera2world;

    if ( near2world )
    {
        copiedInstance->near2world = ALLOC(HTrafo3D);
        *copiedInstance->near2world = *near2world;
    }

    return copiedInstance;
}

- (void) getImageSize
        :(IVec2D *) outImageSize
{
    *outImageSize = imageSize;
}

- (void) setImageSize
        : (const IVec2D *) inImageSize
{
    imageSize = *inImageSize;
}


- (double) getPlaneArea
{
    return planeArea;
}

- (void) setupForObject
        : (ArNode <ArpBBox> *) inObject
        : (ArcObject <ArpReporter> *) reporter
{
    
    ratio = XC(imageSize) / YC(imageSize);
    
    double halfAngle = tan(HFOV * M_PI / 360.f);
    planeDist = XC(imageSize) / (2.f * halfAngle);
    
    yscale = 1.0f / tan(HFOV * 0.5f);
    xscale = yscale / ratio;

    
    WorldToRaster = TRAFO4D(619.787, -13.8793, -251.355, 1067.26, 1.5318, -631.009, -222.111, 1056.76, 0, 0, 0, 0, 0.00688625, -0.0542161, -0.998506, 4.13149);
    
    RasterToWorld = TRAFO4D(0.00161798, -6.04972e-07, 0 ,-0.627072, -7.80214e-13, -0.00161564, 0, 1.47209, 1.11585e-05, 8.77207e-05, 0, 19.6028, -1.21908e-14, 1.52386e-15, 0, 5.00004);
    
//    RELEASE_OBJECT(trafo);f
}


- (double) getPlaneDist
{
    return planeDist;
}

- (const Pnt3D *) eye
{
    return &ray.point;
}

- (void) setEye
        : (const Pnt3D *) newEye
{
    RAY3D_POINT(ray) = *newEye;
}

- (double) near
{
    return near;
}

// Uncomment this to get debug printouts from getRay
// Generates huge amounts of bizarre output - use carefully!
//#define DEBUGPRINTF_ArnCamera_getRay

- (HTrafo3D*) getCameraToWorld
{
    return &camera2world;
}

- (double) getImportance
    : (Vec3D *) outDirection
    : (ArPDFValue*) cameraPointPDF
{
    Vec3D normal;
    vec3d_v_norm_v(&ray.vector, &normal);
    
    double cosine = vec3d_vv_dot(&normal, outDirection);
    float imgToCameraDist = planeDist / cosine;
    float imgSolidAngle = imgToCameraDist * imgToCameraDist / cosine;
    
    
    arpdfvalue_d_init_p(imgSolidAngle, cameraPointPDF);
    
    
    return imgSolidAngle / cosine;
}

- (BOOL) getWorldspaceRay
        : (const Vec2D *) pixelCoordinates
        : (      ArcObject <ArpRandomGenerator> *) randomGenerator
        : (      ArReferenceFrame *) outReferenceFrame
        : (      Ray3D *) outRay
{
    (void) randomGenerator;

    Vec3D TransformVec = VEC3D_INVALID;
    XC(TransformVec) = XC(*pixelCoordinates);
    YC(TransformVec) = YC(*pixelCoordinates);

    Vec3D outVec = VEC3D_INVALID;
    [self transformByMatrix : &TransformVec : &RasterToWorld : &outVec];
    
    outRay->point = ray.point;
    outRay->vector = outVec;
    
    return YES;
}

- (void) transformByMatrix : (Vec3D*) vec : (Trafo4D*) trafo : (Vec3D*) result
{
    Mat4 matrix = trafo->m;
    
    double w = matrix.x[3][3];
    
    for(int i = 0; i < 3; i++)
    {
        w += matrix.x[3][i] * (vec->c.x[i]);
    }
    
    double inverseW = 1.0f / w;
    
    *result = VEC3D_INVALID;
    
    for(int r = 0; r < 3; r++)
    {
        
        result->c.x[r] = matrix.x[r][3];
        
        for(int c = 0; c < 3; c++)
        {
            result->c.x[r] += vec->c.x[c] * matrix.x[r][c];
        }
        
        result->c.x[r] *= inverseW;
    }
}

- (BOOL) getPixelCoordinates
        : (const Pnt3D *) worldPosition
        : (      Vec2D *) pixelCoordinates
{
    Pnt3D  cameraSpacePosition;
    Ray3D camera_ray;
    
    pnt3d_p_htrafo3d_p(worldPosition, & world2camera, &cameraSpacePosition);
    vec3d_pp_sub_v(&PNT3D_ZERO, &cameraSpacePosition, &RAY3D_V(camera_ray));

    vec3d_norm_v(&RAY3D_V(camera_ray));

    double factor = 1.0 / ZC(RAY3D_V(camera_ray));
    vec3d_d_mul_v(factor, &RAY3D_V(camera_ray));

    XC(*pixelCoordinates) = XC(RAY3D_V(camera_ray)) + xscale;
    YC(*pixelCoordinates) = YC(RAY3D_V(camera_ray)) + yscale;
    
    return YES;
}


- (void) getCameraRay
        : (Ray3D *) outCameraRay
{
    *outCameraRay = ray;
}

- (double) getZoom
{
    return zoom;
}


- (double) getTwist
{
    return twist;
}

- (double)getSurfaceFactor:(Vec3D *)outDirection :(Pnt3D *)hitPoint :(const Vec3D *)normal { 
    
    return 0;
}



- (void) code
        : (ArcObject <ArpCoder> *) coder
{
    [super code :coder];
    if ([coder isReading]) [self _setupCamera];

    [coder codeRay3D :&ray];
    [coder codeIVec2D :&imageSize];
    [coder codeDouble :&zoom];
    [coder codeDouble :&twist];
    [coder codeDouble :&near];
    [coder codeDouble:  &HFOV];
    [coder codeDouble :&ratio];
}

@end

// ===========================================================================
