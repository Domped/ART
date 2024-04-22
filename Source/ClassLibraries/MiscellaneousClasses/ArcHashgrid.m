

#define ART_MODULE_NAME     ArcHashgrid

#import "ArcHashgrid.h"
#import "ArcIntersection.h"
ART_NO_MODULE_INITIALISATION_FUNCTION_NECESSARY
//(
//        (void) art_gv;
//        [ ArcHashgrid registerWithRuntime ];
//
//)
ART_NO_MODULE_SHUTDOWN_FUNCTION_NECESSARY

ArIndexHolder _iholder_retain(
        ArIndexHolder pv
)
{
    return pv;
}

ArIndexHolder _iholder_release(
        ArIndexHolder pv
)
{
    return pv;
}
ARDYNARRAY_IMPLEMENTATION_FOR_MANAGED_TYPE(
        ArIndexHolder ,IndexHolder,iholder,iholder, (ArIndexHolder){ 0 },
        _iholder_retain,,_iholder_release
);

ARDYNARRAY_IMPLEMENTATION_FOR_ARTYPE_PTR(IndexHolder,iholder,iholder,0);

@implementation ArcHashgrid



//ARPCONCRETECLASS_DEFAULT_IMPLEMENTATION(ArcHashgrid)

- (void) CLEAR
{

    for(uint32_t x= 0; x < CELL_SIZE; x++ )
    {
        for(uint32_t y= 0; y < CELL_SIZE; y++ )
        {
            for(uint32_t z= 0; z < CELL_SIZE; z++ )
            {
//                ariholderdynarray_free(&cells[x][y][z]);
            }
        }
    }

}
- (void) Reserve
        :(unsigned int) numVertices
{

    NSLog(@"Reserve %d", numVertices);

    DEBUG_COUNT = 0;
}

- (void)BuildHashgrid
        :(ArPathVertexDynArray *)  vertices
        :(double)          radius
{
    self->radius = radius;
    self->radiusSQR = M_SQR(radius);

    self->bboxMin = VEC3D(1e36f, 1e36f, 1e36f);
    self->bboxMax = VEC3D(-1e36f, -1e36f, -1e36f);

    for (unsigned int i = 0; i < arpvdynarray_size(vertices); i++)
    {
        ArPathVertex pv = arpvdynarray_i(vertices, i);

        Pnt3D pos = pv.worldHitPoint->worldspace_point;

        for(uint32_t j = 0; j < 3; j++)
        {
            VEC3D_I(self->bboxMin, j) = fmin( VEC3D_I(self->bboxMin, j), PNT3D_I(pos, j));
            VEC3D_I(self->bboxMax, j) = fmax( VEC3D_I(self->bboxMax, j), PNT3D_I(pos, j));
        }

    }

    vec3d_d_mul_v(1.1f, &self->bboxMax);
    vec3d_d_mul_v(1.1f, &self->bboxMin);

    cellsize[0] = fabs(VEC3D_I(self->bboxMax, 0) - VEC3D_I(self->bboxMin, 0)) / CELL_SIZE;
    cellsize[1] = fabs(VEC3D_I(self->bboxMax, 1) - VEC3D_I(self->bboxMin, 1)) / CELL_SIZE;
    cellsize[2] = fabs(VEC3D_I(self->bboxMax, 2) - VEC3D_I(self->bboxMin, 2)) / CELL_SIZE;

    for(uint32_t x= 0; x < CELL_SIZE; x++ )
    {
        for(uint32_t y= 0; y < CELL_SIZE; y++ )
        {
            for(uint32_t z= 0; z < CELL_SIZE; z++ )
            {
                cells[x][y][z] = ariholderdynarray_init(1);
            }
        }
    }

    for(size_t i=0; i < arpvdynarray_size(vertices); i++)
    {
        Pnt3D  pos  = arpvdynarray_i(vertices, i).worldHitPoint->worldspace_point;

        Pnt3D temp = [self GetCellIndex: pos];

//        NSLog(@"%f %f %f", PNT3D_I(temp, 0), PNT3D_I(temp, 1), PNT3D_I(temp, 2));

        ariholderdynarray_push(&cells[(int) PNT3D_I(temp, 0)][ (int) PNT3D_I(temp, 1)][ (int) PNT3D_I(temp, 2)], (ArIndexHolder){i});
    }

//    uint32_t count = 0;
//    for(uint32_t x= 0; x < 10; x++ )
//    {
//        for(uint32_t y= 0; y < 10; y++ )
//        {
//            for(uint32_t z= 0; z < 10; z++ )
//            {
//                count += ariholderdynarray_size(&cells[x][y][z]);
//            }
//        }
//    }

    return;
}

- (void) GetCellRange
        : (int) cellIndex
        : (Pnt2D *) cellRange
{
    if(cellIndex == 0) *cellRange = PNT2D(0, ARARRAY_I(*ends, 0));
    *cellRange = PNT2D( ARARRAY_I(*ends, cellIndex - 1), ARARRAY_I(*ends, cellIndex) );
}


- (bool) Process
        : (ArPathVertex *) currentState
        : (Pnt3D) position
        : (ArPathVertexDynArray *) vertices
        : (ArLightAlphaSample *) contribution
        : (ArBSDFSampleGenerationContext *)       sgc
        : (ART_GV *) gv
{

    Pnt3D cellIndex = [self GetCellIndex: position];

    for(uint32_t x = MAX(0, PNT3D_I(cellIndex, 0) - 1); x <= MIN(CELL_SIZE-1, PNT3D_I(cellIndex, 0) + 1); x++)
    {
        for(uint32_t y = MAX(0, PNT3D_I(cellIndex, 1) - 1); y <= MIN(CELL_SIZE-1, PNT3D_I(cellIndex, 1) + 1); y++)
        {
            for(uint32_t z = MAX(0, PNT3D_I(cellIndex, 2) - 1); z <= MIN(CELL_SIZE-1, PNT3D_I(cellIndex, 2) + 1); z++)
            {

                ArIndexHolderDynArray indexes = cells[x][y][z];

                for(uint32_t j = 0; j < ariholderdynarray_size(&indexes); j++)
                {
                    ArPathVertex particle = arpvdynarray_i(vertices, ariholderdynarray_i(&indexes, j).index);

                    Vec3D distVec;
                    vec3d_pp_sub_v(&particle.worldHitPoint->worldspace_point, &position, &distVec);

                    bool areWavelengthDependent = arwavelength_ww_equal_ranged(gv,
                                                                               &particle.outgoingWavelength,
                                                                               &currentState->outgoingWavelength);

//                    if(!areWavelengthDependent)
//                    {
//                        continue;
//                    }

                    double distSqr = M_SQR(vec3d_v_len(&distVec));

                    if(distSqr <= self->radiusSQR)
                    {
                        DEBUG_COUNT++;
                        [self ProcessContribution: currentState : &particle : contribution : sgc : gv];
                    }
                }
            }
        }
    }

    return YES;
}


- (void) ProcessContribution
        : (ArPathVertex *) currentState
        : (ArPathVertex *) particle
        : (ArLightAlphaSample *) contribution
        : (ArBSDFSampleGenerationContext *)       sgc
        : (ART_GV *) gv
{
    if( particle->totalPathLength + currentState->totalPathLength > 10)
    {
        return;
    }

    Vec3D incomingLightDir = particle->incomingDirection;

    vec3d_v_negate_v(&incomingLightDir, &incomingLightDir);
    double cosine = fabs(vec3d_vv_dot(&incomingLightDir, &currentState->worldNormal));
    ArNode<ArpVolumeMaterial> * volumeMaterial;
    ArPDFValue eyeForwardPDF_W;
    ArPDFValue eyeReversePDF_W;

    ArAttenuationSample *temp = arattenuationsample_alloc(gv);
    if(![currentState->worldHitPoint evaluateScattering
            : & incomingLightDir
            :   arpathdirection_from_eye
            :   sgc
            : & currentState->incomingWavelength
            : & currentState->outgoingWavelength
            : & cosine
            : & volumeMaterial
            : & eyeForwardPDF_W
            : & eyeReversePDF_W
            : temp
    ])
    {
        arattenuationsample_free(gv, temp);
        return;

    };

    double wLight = particle->dVCM * VCweight + particle->dVM * ARPDFVALUE_MAIN(eyeForwardPDF_W);

    double wCamera = currentState->dVCM * VCweight + currentState->dVM * ARPDFVALUE_MAIN(eyeReversePDF_W);
    double misW = 1.f / (wLight + 1.f + wCamera);

    ArLightAlphaSample *tempLightSample = arlightalphasample_alloc(gv);

    if(particle->totalPathLength > 0)
    {
        arattenuationsample_a_mul_a(gv, particle->attenuationSample, temp);
    }

    arattenuationsample_d_mul_a(gv, misW * particle->throughput, temp);

    arattenuationsample_d_div_a(gv, ARPDFVALUE_MAIN(particle->pathPDF), temp);

    arlightalphasample_l_init_l(gv, particle->lightSample, tempLightSample);
    arlightsample_a_mul_l(gv, temp, tempLightSample->light);

    arlightsample_l_add_l(gv, tempLightSample->light, contribution->light);


    arattenuationsample_free(gv, temp);
    arlightalphasample_free(gv, tempLightSample);
}


- (int) GetCellIndexF
        : (Pnt3D) position
{
    Vec3D distMin;
    VEC3D_I(distMin, 0) = VEC3D_I(position, 0) - VEC3D_I(self->bboxMin, 0);
    VEC3D_I(distMin, 1) = VEC3D_I(position, 1) - VEC3D_I(self->bboxMin, 1);
    VEC3D_I(distMin, 2) = VEC3D_I(position, 2) - VEC3D_I(self->bboxMin, 2);

    VEC3D_I(distMin, 0) = floor(invCellSize * VEC3D_I(distMin, 0));
    VEC3D_I(distMin, 1) = floor(invCellSize * VEC3D_I(distMin, 1));
    VEC3D_I(distMin, 2) = floor(invCellSize * VEC3D_I(distMin, 2));

//    return [self GetCellIndex: PNT3D((int) VEC3D_I(distMin, 0), (int) VEC3D_I(distMin, 1), (int) VEC3D_I(distMin, 2))];
}

- (Pnt3D) GetCellIndex
        : (Pnt3D) position
{
    uint32_t x = (uint32_t) ( ( VEC3D_I(position, 0) - VEC3D_I(self->bboxMin, 0) ) / cellsize[0] );
    uint32_t y = (uint32_t) ( ( VEC3D_I(position, 1) - VEC3D_I(self->bboxMin, 1) ) / cellsize[1] );
    uint32_t z = (uint32_t) ( ( VEC3D_I(position, 2) - VEC3D_I(self->bboxMin, 2) ) / cellsize[2] );

//    uint32_t x = (uint32_t) VEC3D_I(position, 0);
//    uint32_t y = (uint32_t) VEC3D_I(position, 1);
//    uint32_t z = (uint32_t) VEC3D_I(position, 2);
//
//    int test = (int)(( (x * 73856093) ^ (y * 19349663) ^ (z * 83492791) ) % (uint) arintarray_size(ends));
//
//    return test;

    return PNT3D(x, y, z);

}
@end
