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

#define ART_MODULE_NAME     ArnStochasticBackwardsSampler

#import "ArnStochasticBackwardsSampler.h"
#import "ArnImageSamplerCommonMacros.h"

#import "ArnReconstructionKernel.h"
#import "FoundationAssertionMacros.h"
#import "ArPathVertex.h"
#import "ArcHashgrid.h"


ART_MODULE_INITIALISATION_FUNCTION
(
        (void) art_gv;
        [ArnStochasticBackwardsSampler registerWithRuntime];
)

ART_NO_MODULE_SHUTDOWN_FUNCTION_NECESSARY

/* ===========================================================================
    'ArnStochasticImageSampler'
=========================================================================== */

//   k - number of sample
//   i - number of splatting kernel pixel

#define SAMPLE_SPLATTING_FACTOR(__k, __i) \
    sampleSplattingFactor[ (__k) * splattingKernelArea + (__i) ]

#define SAMPLE_SPLATTING_FACTOR_UV(__k, __u, __v) \
    SAMPLE_SPLATTING_FACTOR( __k, (__u) * splattingKernelWidth + (__v) )

@implementation ArnStochasticBackwardsSampler

ARPCONCRETECLASS_DEFAULT_IMPLEMENTATION(ArnStochasticBackwardsSampler)

- (id)init
        :(ArNode <ArpPathspaceIntegrator> *)newPathspaceIntegrator
        :(ArNode <ArpReconstructionKernel> *)newReconstructionKernel
        :(unsigned int)newNumberOfSamples
        :(int)newRandomValueGeneration {
    self =
            [super init
                    :newPathspaceIntegrator
                    :newReconstructionKernel
                    :newNumberOfSamples
                    :newRandomValueGeneration
            ];

//    vcmMode = [newPathspaceIntegrator getIntegratorMode];
    deterministicWavelengths = NO;
    wavelengthSteps = 1;

    return self;
}

- (void)useDeterministicWavelengths {
    deterministicWavelengths = YES;
    wavelengthSteps = spc_channels(art_gv);
    art_set_hero_samples_to_splat(art_gv, 1);
}

- (void)prepareForSampling
        :(ArNode <ArpWorld> *)newWorld
        :(ArNode <ArpCamera> *)newCamera
        :(ArNode <ArpImageWriter> **)image
        :(int)numberOfResultImages {
    [super prepareForSampling
            :newWorld
            :newCamera
            :image
            :numberOfResultImages
    ];

    pthread_mutex_init(&LightPathsMutex, NULL);
    //   splatting kernel properties

    splattingKernelWidth = [RECONSTRUCTION_KERNEL supportSize];
    splattingKernelWidthDiv2 = splattingKernelWidth / 2;
    splattingKernelArea = M_SQR(splattingKernelWidth);
    splattingKernelOffset = (splattingKernelWidth - 1) / 2;

    //   2D sample coordinates are pre-generated for the entire packet

    //   CAVEAT: they are the same for all packets - but given the huge
    //           packet sizes, this should never really be an issue!
    //           And as long as you cast less than DEFAULT_PACKET_SIZE
    //           rays, everything is as expected anyway - each ray has
    //           unique 2D subpixel coordinates in that case.

    numberOfSubpixelSamples =
            M_MIN(IMAGE_SAMPLER_MAX_SUBPIXEL_SAMPLES, numberOfSamplesPerThread);

    sampleCoord = ALLOC_ARRAY(Pnt2D, numberOfSubpixelSamples);

    //   Actual generation of the 2D sample coordinates

    //   Note that we reset the random generator sequence counter for each
    //   2D coordinate - they all should be from the first two sequences the
    //   generator has to offer!

    for (unsigned int i = 0; i < numberOfSubpixelSamples; i++) {
        [randomGenerator[0] resetSequenceIDs];

        [randomGenerator[0] getValuesFromNewSequences
                :&XC(sampleCoord[i])
                :&YC(sampleCoord[i])
        ];
    }

    //   We remember the sequence ID of the generator after it did the last
    //   coordinate - rendering always has to start there!

    startingSequenceID = [randomGenerator[0] currentSequenceID];

    //   Sample splatting factors: these are the contribution factors for each
    //   pre-computed 2D sample coordinate. They do not change between pixels,
    //   so pre-computing the splatting kernel influence for each of them
    //   is faster than re-evaluating this every time a sample gets splatted.

    if (splattingKernelWidth > 1) {
        sampleSplattingFactor =
                ALLOC_ARRAY(double, splattingKernelArea * numberOfSubpixelSamples);

        for (unsigned int i = 0; i < numberOfSubpixelSamples; i++) {
            for (unsigned int u = 0; u < splattingKernelWidth; u++) {
                double dY = 1.0 * u - splattingKernelOffset;

                for (unsigned int v = 0; v < splattingKernelWidth; v++) {
                    double dX = 1.0 * v - splattingKernelOffset;

                    Pnt2D localCoord;

                    XC(localCoord) = XC(sampleCoord[i]) - dX - 0.5;
                    YC(localCoord) = YC(sampleCoord[i]) - dY - 0.5;

                    SAMPLE_SPLATTING_FACTOR_UV(i, u, v) =
                            [RECONSTRUCTION_KERNEL valueAt
                            :&localCoord
                            ];

                } // splatting kernel v coord for loop
            } // splatting kernel u coord for loop
        } // i - number of samples per packet

        sampleSplattingOffset =
                ALLOC_ARRAY(IPnt2D, splattingKernelArea);

        for (unsigned int u = 0; u < splattingKernelWidth; u++)
            for (unsigned int v = 0; v < splattingKernelWidth; v++) {
                XC(sampleSplattingOffset[u * splattingKernelWidth + v])
                        = u - splattingKernelOffset;
                YC(sampleSplattingOffset[u * splattingKernelWidth + v])
                        = v - splattingKernelOffset;
            }
    }


}

- (id)copy {
    ArnStochasticBackwardsSampler *copiedInstance = [super copy];

    ART__CODE_IS_WORK_IN_PROGRESS__EXIT_WITH_ERROR

    return copiedInstance;
}

- (id)deepSemanticCopy
        :(ArnGraphTraversal *)traversal {
    ArnStochasticBackwardsSampler *copiedInstance =
            [super deepSemanticCopy
            :traversal
            ];

    ART__CODE_IS_WORK_IN_PROGRESS__EXIT_WITH_ERROR

    return copiedInstance;
}

//   Purpose of this critter: to pack pixel coordinates and thread ID into
//   one structure, so that crc32 can initialise the thread random generator
//   to a unique and repeatable value that is based both on pixel coordinates
//   and thread ID.

typedef struct ArPixelID {
    long globalRandomSeed;
    int threadIndex;
    int sampleIndex;
    Pnt2D pixelCoord;
}
        ArPixelID;


- (double)calculateSurfaceFactor
        :(ArcPointContext <ArpRayEndpoint> *)hitPoint
        :(const Vec3D *)normal {

    Ray3D cameraRay;
    [camera getCameraRay:&cameraRay];

    Vec3D directionToCamera;
    vec3d_pp_sub_v(
            &ARCPOINTCONTEXT_WORLDSPACE_POINT(hitPoint),
            &RAY3D_P(cameraRay),
            &directionToCamera
    );

    double distanceToCamera = vec3d_v_sqrlen(&directionToCamera);
    distanceToCamera = sqrt(distanceToCamera);

    vec3d_norm_v(&directionToCamera);
    Vec3D directionOutCamera;
    vec3d_v_negate_v(&directionToCamera, &directionOutCamera);

    double cosineToCamera = vec3d_vv_dot(
            normal,
            &directionToCamera
    );

    Vec3D cameraVectorOut;
    vec3d_v_htrafo3d_v(&RAY3D_V(cameraRay), [camera getCameraToWorld], &cameraVectorOut);

//    vec3d_v_norm_v(&RAY3D_V(cameraRay), &cameraVectorOut);
    vec3d_norm_v(&cameraVectorOut);

    double cosineAtCamera = vec3d_vv_dot(
            &cameraVectorOut,
            &directionOutCamera
    );

    double imagePointDistance = ([camera getPlaneDist] * 5) / M_ABS(cosineAtCamera);
    double toSolidAngle = M_SQR(imagePointDistance) / M_ABS(cosineAtCamera);
    double surfaceFactor = toSolidAngle * M_ABS(cosineToCamera) / 20;

    return 1.0f / surfaceFactor;
}

- (void)applyLightSample
        :(Vec2D)pixelCoord
        :(ArLightAlphaSample *)lightSample
        :(ArWavelength *)wavelength
        :(int)subpixelIdx
        :(ArcUnsignedInteger *)threadIndex {
    if (splattingKernelWidth == 1) {
        for (unsigned int im = 0; im < numberOfImagesToWrite; im++) {
//            PIXEL_SAMPLE_COUNT( (int) XC(pixelCoord), (int) YC(pixelCoord), THREAD_INDEX, im ) = 1.0;

            arlightalpha_wsd_sloppy_add_l(
                    art_gv,
                    lightSample,
                    wavelength,
                    &spectralSplattingData,
                    3.0 DEGREES,
                    PIXEL_SAMPLE_VALUE((int) XC(pixelCoord), (int) YC(pixelCoord), THREAD_INDEX, im)
            );
        }
    } else {
        for (unsigned int l = 0; l < splattingKernelArea; l++) {
            int cX = (int) XC(pixelCoord) + XC(sampleSplattingOffset[l]);
            int cY = (int) YC(pixelCoord) + YC(sampleSplattingOffset[l]);

            if (cX >= 0
                && cX < XC(imageSize)
                && cY >= 0
                && cY < YC(imageSize)) {
                for (unsigned int im = 0; im < numberOfImagesToWrite; im++) {
//                    PIXEL_SAMPLE_COUNT( cX, cY, THREAD_INDEX, im ) = SAMPLE_SPLATTING_FACTOR( subpixelIdx, l );

                    for (unsigned int im = 0; im < numberOfImagesToWrite; im++) {
                        arlightalpha_dwsd_mul_sloppy_add_l(
                                art_gv,
                                SAMPLE_SPLATTING_FACTOR(subpixelIdx, l),
                                lightSample,
                                wavelength,
                                &spectralSplattingData,
                                5.0 DEGREES,
                                THREAD_RESULT_PIXEL(cX, cY, im)
                        );
                    }
                }
            }
        }
    }
}

- (void) splatRenderLightPaths
    : (ArcUnsignedInteger*) threadIndex
    : (int) subpixelIdx
{
    unsigned int sizeArray = arpvptrdynarray_size(&LightPaths);

    for (unsigned int p = 0; p < sizeArray; p++) {
        ArPathVertex *pv = arpvptrdynarray_i(&LightPaths, p);

        Ray3D cameraRay;
        [camera getCameraRay:&cameraRay];

        if (ARPV_OCCLUDED(*pv)) {
            continue;
        }

        Vec2D pixelCoords;
        [camera getPixelCoordinates
                :&pv->worldHitPoint->worldspace_point
                :&pixelCoords
        ];

        if(
                XC(pixelCoords) > XC(imageSize)-1 ||
                YC(pixelCoords) > YC(imageSize)-1 ||
                XC(pixelCoords) < 0 ||
                YC(pixelCoords) < 0)
        {
            continue;
        }

        if (splattingKernelWidth == 1) {
            for (unsigned int im = 0; im < numberOfImagesToWrite; im++) {
                PIXEL_SAMPLE_COUNT((int) XC(pixelCoords), (int) YC(pixelCoords), THREAD_INDEX, im) += 1.0;

                arlightalpha_wsd_sloppy_add_l(
                        art_gv,
                        pv->cameraLightSample,
                        &pv->cameraWavelength,
                        &spectralSplattingData,
                        3.0 DEGREES,
                        PIXEL_SAMPLE_VALUE((int) XC(pixelCoords), (int) YC(pixelCoords), THREAD_INDEX, im)
                );
            }
        } else {
            for (unsigned int l = 0; l < splattingKernelArea; l++) {
                int x = XC(pixelCoords);
                int y = YC(pixelCoords);

                int cX = x + XC(sampleSplattingOffset[l]);
                int cY = y + YC(sampleSplattingOffset[l]);

                if (cX >= 0
                    && cX < XC(imageSize)
                    && cY >= 0
                    && cY < YC(imageSize)) {
                    for (unsigned int im = 0; im < numberOfImagesToWrite; im++) {
                        PIXEL_SAMPLE_COUNT(cX, cY, THREAD_INDEX, im) += SAMPLE_SPLATTING_FACTOR(subpixelIdx, l);

                        for (unsigned int im = 0; im < numberOfImagesToWrite; im++) {

                            arlightalpha_dwsd_mul_sloppy_add_l(
                                    art_gv,
                                    SAMPLE_SPLATTING_FACTOR(subpixelIdx, l),
                                    pv->cameraLightSample,
                                    &pv->cameraWavelength,
                                    &spectralSplattingData,
                                    5.0 DEGREES,
                                    THREAD_RESULT_PIXEL(cX, cY, im)
                            );
                        }
                    }
                }
            }
        }
    }
}

- (void) renderLightPaths
        : (uint32_t *)                  pathEnds
        : (ArVCMGlobalValues)           vcmGlobalValues
        : (ArcUnsignedInteger*)         threadIndex
        : (ArPathVertexptrDynArray*)    renderBucket
{
    NSAutoreleasePool *threadPool;
    threadPool = [[NSAutoreleasePool alloc] init];

//    ArPathVertexptrDynArray *pathVertexArray = [input pointerValue];
    if(arpvptrdynarray_size(renderBucket) > 1)
    {
        arpvptrdynarray_free_contents(renderBucket);
    }

    const int TILE_COUNT = XC(imageSize) * YC(imageSize) / TILE_SIZE;
    if(threadIndex->value > TILE_COUNT)
    {
        return;
    }

    const int TILE_COUNT_X = XC(imageSize) / TILE_SIZE;
    const int TILE_COUNT_Y = YC(imageSize) / TILE_SIZE;

    int iterations = 0;
    for(int tile = threadIndex->value; tile < TILE_COUNT; tile += M_MIN(numberOfRenderThreads, TILE_COUNT))
    {
        int x_tile = tile % TILE_COUNT_X;
        int y_tile = tile / TILE_COUNT_X;

        int x_start = x_tile * TILE_SIZE;
        int y_start = y_tile * TILE_SIZE;

        int x_end = M_MIN(x_start + TILE_SIZE, XC(imageSize));
        int y_end = M_MIN(y_start + TILE_SIZE, YC(imageSize));

        for (int x = x_start; x < x_end; x++) {
            for (int y = y_start; y < y_end; y++) {
                iterations++;

//            [THREAD_RANDOM_GENERATOR reInitializeWith
//            :crc32_of_data(&px_id, sizeof(ArPixelID))
//            ];

                [THREAD_RANDOM_GENERATOR setCurrentSequenceID
                :startingSequenceID
                ];
                ArWavelength wavelength;

                if (deterministicWavelengths) {
                    arwavelength_i_deterministic_init_w(
                            art_gv,
                            0,
                            &wavelength
                    );
                } else {
                    arwavelength_sd_init_w(
                            art_gv,
                            &spectralSamplingData,
                            [THREAD_RANDOM_GENERATOR valueFromNewSequence],
                            &wavelength
                    );
                }
                BOOL validSample = FALSE;

                Ray3D ray;
                ArReferenceFrame referenceFrame;

                [THREAD_PATHSPACE_INTEGRATOR generateLightPaths
                        :art_gv
                        :&ray
                        :camera
                        :renderBucket
                        :&wavelength
                        :pathEnds
                        :x + y * XC(imageSize)
                        :0
                        :&vcmGlobalValues
                ];

            }
        }
    }

    [self renderLightPathsFinished];

}

- (void) fillLightPaths
    : (ArPathVertexptrDynArray *) lightPathsBucket
    : (ArcUnsignedInteger*) threadIndex
{
    LightPaths;
    pthread_mutex_lock(&LightPathsMutex);
    int threadAccessOffset = threadIndex->value * arpvptrdynarray_size(lightPathsBucket);
    for(uint32_t threadStart = 0; threadStart < arpvptrdynarray_size(lightPathsBucket); threadStart++)
    {
        ArPathVertex *pv = arpvptrdynarray_i(lightPathsBucket, threadStart);
        arpvptrdynarray_push(&LightPaths, pv);
    }
    pthread_mutex_unlock(&LightPathsMutex);
}

- (void) renderProc
        : (ArcUnsignedInteger*) threadIndex
{
    NSAutoreleasePool *threadPool;

//    ArcVCMSamplerInput *threadInput = [input pointerValue];
//
//    ArcUnsignedInteger* threadIndex = threadInput->threadIndex;
    vcmMode = [THREAD_PATHSPACE_INTEGRATOR getIntegratorMode];
    threadPool = [[NSAutoreleasePool alloc] init];
    ArPixelID px_id;
    px_id.threadIndex = THREAD_INDEX;
    px_id.globalRandomSeed = arrandom_global_seed(art_gv);


    int threadStripWidth = YC(imageSize) / numberOfRenderThreads;
    int threadOffset = threadStripWidth * THREAD_INDEX;

    unsigned int pixelCount = 0;
    double baseRadius = 0.00665117893f;

    NSLog(@"MODE %d", THREAD_INDEX);

    ArPathVertexptrDynArray renderBucket = arpvptrdynarray_init(0);
    for(int lightIter = 0; lightIter < 1; lightIter++) {
        for (unsigned int i = 0; i < numberOfSamplesPerThread; i++) {

            ArcHashgrid *hashgrid;
            if(MODE & arvcmmode_vm)
                 hashgrid = [[ArcHashgrid alloc] init];

            int subpixelIdx = i % numberOfSubpixelSamples;
            px_id.sampleIndex = i;

            double radius = baseRadius / (pow(i + 1, 0.5f * (1 - 0.75f)));
            radius = fmax(radius, 1e-7f);
            vmNormalization = MODE & arvcmmode_vm ? 1.f / (M_SQR(radius) * M_PI * XC(imageSize) * YC(imageSize)) : 0;
            double etaVCM = (M_PI * M_SQR(radius)) * XC(imageSize) * YC(imageSize);

            VMweight = MODE & arvcmmode_vm ? etaVCM : 0;
            VCweight = MODE & arvcmmode_vm ? 1.0f / etaVCM : 0;

            ArVCMGlobalValues vcmGlobalValues;
            vcmGlobalValues.vmNormalization = vmNormalization;
            vcmGlobalValues.VMweight = VMweight;
            vcmGlobalValues.VCweight = VCweight;

            pthread_barrier_wait(&renderBarrier);

            if(threadIndex->value == 0) {
                if (arpvptrdynarray_size(&LightPaths) > 1) {
                    arpv_free_arr_itrsc(art_gv, &LightPaths);
                    arpvptrdynarray_free_contents(&LightPaths);
                }

                LightPaths = arpvptrdynarray_init(0);
            }

            pthread_barrier_wait(&renderBarrier);
            [self renderLightPaths :pathEnds : vcmGlobalValues: threadIndex : &renderBucket];
            pthread_barrier_wait(&renderBarrier);

            [self fillLightPaths : &renderBucket : threadIndex];

            pthread_barrier_wait(&renderBarrier);

            uint32_t max = 0;

            [self splatRenderLightPaths : threadIndex : subpixelIdx];

            if(!(MODE & arvcmmode_lt))
            {
                if(MODE & arvcmmode_vm)
                {
                    [hashgrid Reserve:(XC(imageSize) * YC(imageSize))];
                    [hashgrid BuildHashgrid:&LightPaths :radius];

                    hashgrid->vmNormalization = vmNormalization;
                    hashgrid->VMweight = VMweight;
                    hashgrid->VCweight = VCweight;
                }


                /* *
                 *
                 * @description: TRACE THE EYE RAYS
                 */
                int iterations = 0;
                for (int ylv = 0; ylv < YC(imageSize); ylv++) {
                    int y = ylv + threadOffset;

                    if (y >= YC(imageSize)) {
                        y = y - YC(imageSize);
                    }

                    YC(px_id.pixelCoord) = y + YC(imageOrigin);

                    /* -------------------------------------------------------------
                         We render each pixel of the scanline.
                    ------------------------------------------------------------- */

                    for (int x = x_start[y]; x < x_end[y]; x++) {

                        XC(px_id.pixelCoord) = x + XC(imageOrigin);

//                if (x< 440)
//                {
//                    continue;
//                }
                        for (int w = 0; w < wavelengthSteps; w++) {

                            iterations++;
                            ArPathVertex *currentState = arpv_alloc(art_gv);

                            ArWavelength wavelength;

                            uint32_t rangeX, rangeY;
                            rangeX = 0;

                            int pathIndex = x + y * XC(imageSize);

                            if (pathIndex > 0) {
                                rangeX = pathEnds[pathIndex - 1];
                            }

                            uint32_t ss = pathIndex - 2;
                            while (rangeX >= arpvptrdynarray_size(&LightPaths)) {
                                rangeX = pathEnds[ss];
                                ss--;
                            }

                            ArPathVertex *tempWavelengthVertex = arpvptrdynarray_i(&LightPaths, rangeX);

                            Ray3D ray;
                            ArReferenceFrame referenceFrame;
                            wavelength = tempWavelengthVertex->incomingWavelength;
                            ArLightAlphaSample *lightAlphaSample = arlightalphasample_alloc(art_gv);
                            arlightsample_d_init_unpolarised_l(art_gv, 0.0, lightAlphaSample->light);
                            lightAlphaSample->alpha = 1;
#ifdef MONOHERO
                            arwavelength_d_init_w(art_gv, 550 NM, &wavelength);
#endif
                            if ([camera getWorldspaceRay
                                    :&VEC2D(
                                            XC(px_id.pixelCoord) + XC(sampleCoord[subpixelIdx]),
                                            YC(px_id.pixelCoord) + YC(sampleCoord[subpixelIdx])
                                    )
                                    :THREAD_RANDOM_GENERATOR
                                    :&referenceFrame
                                    :&ray
                            ]) {

                                double cameraPDFA;
                                [camera getSurfaceFactor
                                        :&RAY3D_V(ray)
                                        :0
                                        :&VEC3D_X_UNIT
                                        :&cameraPDFA
                                ];

                                currentState->dVCM = (512 * 512) / cameraPDFA;
                                currentState->throughput = 1;
                                currentState->incomingWavelength = wavelength;
                                currentState->outgoingWavelength = wavelength;

                                ArWavelength sample = wavelength;

                                [THREAD_PATHSPACE_INTEGRATOR generateEyePaths
                                        :&ray
                                        :camera
                                        :&LightPaths
                                        :&wavelength
                                        :currentState
                                        :                            pathEnds
                                        :lightAlphaSample
                                        :pathIndex
                                        :hashgrid
                                        :&vcmGlobalValues
                                ];
                            }


                            if (arlightalphasample_l_valid(
                                    art_gv, lightAlphaSample)) {

                                if (splattingKernelWidth == 1) {
                                    for (unsigned int im = 0; im < numberOfImagesToWrite; im++) {
                                        PIXEL_SAMPLE_COUNT(x, y, THREAD_INDEX, im) += 1.0;

                                        arlightalpha_wsd_sloppy_add_l(
                                                art_gv,
                                                lightAlphaSample,
                                                &wavelength,
                                                &spectralSplattingData,
                                                3.0 DEGREES,
                                                PIXEL_SAMPLE_VALUE(x, y, THREAD_INDEX, im)
                                        );
                                    }
                                } else {
                                    for (unsigned int l = 0; l < splattingKernelArea; l++) {
                                        int cX = x + XC(sampleSplattingOffset[l]);
                                        int cY = y + YC(sampleSplattingOffset[l]);

                                        if (cX >= 0
                                            && cX < XC(imageSize)
                                            && cY >= 0
                                            && cY < YC(imageSize)) {
                                            for (unsigned int im = 0; im < numberOfImagesToWrite; im++) {
                                                PIXEL_SAMPLE_COUNT(cX, cY, THREAD_INDEX, im) += SAMPLE_SPLATTING_FACTOR(
                                                        subpixelIdx, l);

                                                for (unsigned int im = 0; im < numberOfImagesToWrite; im++) {

                                                    arlightalpha_dwsd_mul_sloppy_add_l(
                                                            art_gv,
                                                            SAMPLE_SPLATTING_FACTOR(subpixelIdx, l),
                                                            lightAlphaSample,
                                                            &wavelength,
                                                            &spectralSplattingData,
                                                            5.0 DEGREES,
                                                            THREAD_RESULT_PIXEL(cX, cY, im)
                                                    );
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            arlightalphasample_free(art_gv, lightAlphaSample);
                            arpv_free_pv(art_gv, currentState);
                            FREE(currentState);
                            currentState = 0;
                        }
                    } // x, XC(image)
                } // y, YC(image)
                NSLog(@"ITERATIONS %d ", iterations);
            }

            if(MODE & arvcmmode_vm)
            {
                [hashgrid dealloc];
            }

            if (THREAD_INDEX == 0) {
                [sampleCounter step
                :numberOfRenderThreads
                ];
            }
        }
        NSLog(@"%d", DEBUG_PIXEL_COUNT);
    }

    [self renderProcHasFinished:threadIndex];
}// i, sample index


- (void)dealloc {
    FREE_ARRAY(sampleCoord);

    if (splattingKernelWidth > 1) {
        FREE_ARRAY(sampleSplattingFactor);
        FREE_ARRAY(sampleSplattingOffset);
    }

    [super dealloc];
}

- (void)code
        :(ArcObject <ArpCoder> *)coder {
    [super code:coder];
    [coder codeBOOL:&deterministicWavelengths];

    if ([coder isReading]) {
        if (deterministicWavelengths) {
            [self useDeterministicWavelengths];
        } else {
            wavelengthSteps = 1;
        }
    }
}

@end

// ===========================================================================

