//
//  ArnPerspectiveCamera.h
//  AdvancedRenderingToolkit
//
//  Created by Dominik Dinh on 05.03.2024.
//


#include "ART_Foundation.h"

ART_MODULE_INTERFACE(ArnPerspectiveCamera)

#import "ART_Scenegraph.h"

@interface ArnPerspectiveCamera
    : ArNode
    < ArpConcreteClass, ArpCoding, ArpCamera >
{
    
@public
    double FocalDistance;
    double HFOV;
    
    Ray3D       ray;
    IVec2D      imageSize;
    double      zoom;           // zoom == 1.0: diagonal of field of view
                                //  is equal to the imageplane distance
    double      twist;
    double      near;
    double      ratio;

    Vec3D       upVector;
    double      xscale;
    double      yscale;
    double      zscale;

    
    double      pixelArea;
    double      planeArea;
    double      planeDist;
    
    Trafo4D WorldToRaster;
    Trafo4D RasterToWorld;
    
    HTrafo3D    world2camera;
    HTrafo3D    camera2world;

    HTrafo3D *  near2world;
}

- (id) init
        : (Ray3D) newRay
        : (IVec2D) newImageSize
        : (double) newHFOV
        : (double) newZoom;


- (void) transformByMatrix : (Vec3D*) vec : (Trafo4D*) trafo : (Vec3D*) result;

@end
