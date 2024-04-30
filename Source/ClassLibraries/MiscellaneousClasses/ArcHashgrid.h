#ifndef _ARCHASHGRID_H_
#define _ARCHASHGRID_H_

#include "ART_Foundation.h"

#include "ArPathVertex.h"
ART_MODULE_INTERFACE(ArcHashgrid)

typedef struct ArIndexHolder
{
    uint32_t index;
} ArIndexHolder;


ARDYNARRAY_INTERFACE_FOR_ARTYPE(IndexHolder,iholder,iholder);
ARDYNARRAY_INTERFACE_FOR_ARTYPE_PTR(IndexHolder,iholder,iholder);

#define CELL_SIZE 70
@interface ArcHashgrid
        : ArcObject
{
@public
Vec3D bboxMin;
Vec3D bboxMax;

double cellsize[3];
ArIndexHolderDynArray cells[CELL_SIZE][CELL_SIZE][CELL_SIZE];

ArIntArray *indices;
ArIntArray *ends;

double radius;
double radiusSQR;

double invCellSize;

int DEBUG_COUNT;
double                                vmNormalization;
double                                VMweight;
double                                VCweight;
}

- (void) CLEAR
        ;

- (Pnt3D) GetCellIndex
        : (Pnt3D) position
        ;

- (int) GetCellIndexF
        : (Pnt3D) position
        ;

- (void) Reserve
        : (unsigned int) numVertices
        ;

- (void) GetCellRange
        : (int) cellIndex
        : (Pnt2D*) cellRange
        ;

- (void) ProcessContribution
        : (ArPathVertex *) currentState
        : (ArPathVertex *) particle
        : (ArLightAlphaSample *) contribution
        : (ArBSDFSampleGenerationContext *)       sgc
        : (ART_GV *) gv
        ;
- (bool) Process
        : (ArPathVertex *) currentState
        : (Pnt3D) position
        : (ArPathVertexDynArray *) vertices
        : (ArLightAlphaSample *) contribution
        : (ArBSDFSampleGenerationContext *)       sgc
        : (ART_GV *) gv
        ;

- (void) BuildHashgrid
        : (ArPathVertexDynArray *) vertices
        : (double)         radius
        ;

@end


#endif // _ARCHASHGRID_H_