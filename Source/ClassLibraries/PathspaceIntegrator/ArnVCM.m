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

#define ART_MODULE_NAME     ArnVCM

#import "ArnVCM.h"
#import "ArnPathspaceIntegratorCommonMacros.h"
#import "ArnInfSphere.h"
#import "../Lightsource/ArcSkydomeLightsource.h"

#import "FoundationAssertionMacros.h"
#import "ArPathVertex.h"

ART_MODULE_INITIALISATION_FUNCTION
(
        (void) art_gv;
        [ ArnVCM registerWithRuntime ];
)

ART_NO_MODULE_SHUTDOWN_FUNCTION_NECESSARY

@implementation ArnVCM

ARPCONCRETECLASS_DEFAULT_IMPLEMENTATION(ArnVCM)

- (void) _setupVCM
{
    // allocation of ArLightSample and ArAttenuationSample in the buffer arrays, so
    // that the concatenation of ArAttenuations can be postponed to the point, where
    // there is the final ArLightSample and as such, no matrix multiplications take
    // place

    
    mode = arvcmmode_vc;
    
    if ( !temporaryContribution )
    {
        temporaryContribution = arlightsample_alloc(art_gv);
    }
    ASSERT_ALLOCATED_LIGHT_SAMPLE(temporaryContribution);

    if ( !temporaryAttenuation )
    {
        temporaryAttenuation = arattenuationsample_alloc(art_gv);
    }
    ASSERT_ALLOCATED_ATTENUATION_SAMPLE(temporaryAttenuation);

    if ( !temporaryMediaContribution )
    {
        temporaryMediaContribution = arlightsample_alloc(art_gv);
    }
    ASSERT_ALLOCATED_ATTENUATION_SAMPLE(temporaryMediaContribution);

    if ( !temporaryMediaAttenuation )
    {
        temporaryMediaAttenuation = arattenuationsample_alloc(art_gv);
    }
    ASSERT_ALLOCATED_ATTENUATION_SAMPLE(temporaryMediaAttenuation);


    for(size_t i = 0; i < VC_CONTRIBUTIONS_ARRAY_LENGTH; ++i)
    {
        if ( !allContributions[i] )
        {
            allContributions[i] = arlightsample_alloc(art_gv);
        }
        ASSERT_ALLOCATED_ATTENUATION_SAMPLE(allContributions[i]);
    }

    for(size_t i = 0; i < VC_ATTENUATIONS_ARRAY_LENGTH; ++i)
    {
        if ( !allAttenuations[i] )
        {
            allAttenuations[i] = arattenuationsample_alloc(art_gv);
        }
        ASSERT_ALLOCATED_ATTENUATION_SAMPLE(allAttenuations[i]);
    }

    for(size_t i = 0; i < VC_ATTENUATIONS_ARRAY_LENGTH; ++i)
    {
        if ( !allMediaAttenuations[i] )
        {
            allMediaAttenuations[i] = arattenuationsample_alloc(art_gv);
        }
        ASSERT_ALLOCATED_ATTENUATION_SAMPLE(allMediaAttenuations[i]);
    }
}

- (void) dealloc
{
    if ( temporaryContribution )
    {
        arlightsample_free(art_gv, temporaryContribution);
        temporaryContribution = 0;
    }

    if ( temporaryAttenuation )
    {
        arattenuationsample_free(art_gv, temporaryAttenuation);
        temporaryAttenuation = 0;
    }

    if ( temporaryMediaContribution )
    {
        arlightsample_free(art_gv, temporaryMediaContribution);
        temporaryMediaContribution = 0;
    }

    if ( temporaryMediaAttenuation )
    {
        arattenuationsample_free(art_gv, temporaryMediaAttenuation);
        temporaryMediaAttenuation = 0;
    }


    for(size_t i = 0; i < VC_CONTRIBUTIONS_ARRAY_LENGTH; ++i)
    {
        if ( allContributions[i] )
        {
            arlightsample_free(art_gv, allContributions[i]);
            allContributions[i] = 0;
        }
    }

    for(size_t i = 0; i < VC_ATTENUATIONS_ARRAY_LENGTH; ++i)
    {
        if ( allAttenuations[i] )
        {
            arattenuationsample_free(art_gv, allAttenuations[i]);
            allAttenuations[i] = 0;
        }
    }

    for(size_t i = 0; i < VC_ATTENUATIONS_ARRAY_LENGTH; ++i)
    {
        if ( allMediaAttenuations[i] )
        {
            arattenuationsample_free(art_gv, allMediaAttenuations[i]);
            allMediaAttenuations[i] = 0;
        }
    }

    [ super dealloc ];
}

- (void) _setup
{
    [ super _setup ];
    [ self _setupVCM ];
}

- (id) init
        : (ArNode <ArpRayCaster> *) newRayCaster
        : (unsigned int) newMaximalRecursion
        : (ArVCMMode) newMode
        : (ArDistanceTrackingMode) newDistanceTrackingMode
{
    self =
            [ super init
                    :   newRayCaster
                    :   0.0
                    :   newMaximalRecursion
                    :   newDistanceTrackingMode
            ];

    if ( self )
    {
        mode = newMode;
        [ self _setupVCM ];
    }

    return self;
}

- (id) copy
{
    ArnVCM  * copiedInstance = [ super copy ];


    [ copiedInstance _setupVCM ];

    return copiedInstance;
}

- (id) deepSemanticCopy
        : (ArnGraphTraversal *) traversal
{
    ArnVCM  * copiedInstance =
            [ super deepSemanticCopy
            :   traversal
            ];


    [ copiedInstance _setupVCM ];

    return copiedInstance;
}

- (BOOL) isEmissionDisregarded
        : (      BOOL)               specularOnlyPath
        : (      BOOL)               isLastSpecular
        : (const ArSamplingRegion *) lightSamplingRegion
{
    // exclude direct contributions from sampling the sun from non-specular-only paths with the last reflection specular
    if( (
                *lightSamplingRegion == ARNSKYLIGHT_SAMPLINGREGION_SUN_A ||
                *lightSamplingRegion == ARNSKYLIGHT_SAMPLINGREGION_SUN_B
        ) && !specularOnlyPath && isLastSpecular
            )
        return YES;
    else
        return NO;
}

- (double) mis
        : (ArPDFValue *)    currentPDF
{
    ArPDFValue sumPDF = *currentPDF;

    if(HERO_SAMPLES_TO_SPLAT > 1)
    {
        arpdfvalue_sum_p(& sumPDF);
    }

    return arpdfvalue_pp_ratio(
            currentPDF,
            & sumPDF
    );
}

- (double) mis
        : (ArPDFValue *)    currentPDF
        : (ArPDFValue *)    otherPDF
{
    ArPDFValue sumPDF;
    arpdfvalue_pp_add_p(
            currentPDF,
            otherPDF,
            & sumPDF
    );

    if(HERO_SAMPLES_TO_SPLAT > 1)
    {
        arpdfvalue_sum_p(& sumPDF);
    }

    return arpdfvalue_pp_ratio(
            currentPDF,
            & sumPDF
    );
}

- (BOOL) getEmission
        : (      ArcPointContext *)   originPoint
        : (      ArcIntersection *)   hitPoint
        : (const ArWavelength *)      wavelength
        : (      ArNode **)           emitter
        : (      ArSamplingRegion *)  samplingRegion
        : (      ArLightSample *)     emission
{
    ASSERT_ALLOCATED_LIGHT_SAMPLE(emission);

    if([ hitPoint evaluateEmission
            : originPoint
            : wavelength
            : samplingRegion
            : emission
    ])
    {
        if( emitter )
            *emitter = ARCINTERSECTION_SHAPE(hitPoint);

        return YES;
    }
    else
        return NO;
}

- (BOOL) calculateEmissionContribution
        : (      int)                 pathLength
        : (      BOOL)                specularOnlyPath
        : (      ArcPointContext *)   originPoint
        : (      ArcIntersection *)   hitPoint
        : (const ArWavelength *)      wavelength
        : (const ArWavelength *)      previousWavelength // possibly for MIS calculations
        : (      ArPDFValue *)        pathPDF
        : (      ArPDFValue *)        directionPDF
        : (      ArPDFValue *)        lssAdditionalPDF
        : (      ArLightSample *)     contribution
{
    //   compute contribution only if direction sampling is enabled
    //   or if it is a first hit on the path
    
//    if(    pathLength > 0
//        && ! ( mode & arpathtracermode_direction_sampling )
//       )
//        return NO;
//
    ASSERT_ALLOCATED_LIGHT_SAMPLE(contribution);
    
    ArSamplingRegion lightSamplingRegion;
    ArNode * emitter;
    if( [ self getEmission
             :   originPoint
             :   hitPoint
             :   wavelength
             : & emitter
             : & lightSamplingRegion
             :   contribution
             ] )
    {
        // ignore emission from regions that are marked as being disregarded in direction sampling
        if( [ self isEmissionDisregarded
                :   specularOnlyPath
                :   ARPDFVALUE_IS_INFINITE(*directionPDF)
                : & lightSamplingRegion
                ])
            return NO;
    
        BOOL weighed = NO;
        
        if(HERO_SAMPLES_TO_SPLAT > 1 && ! weighed)
        {
            // calculate the total paths pdfs for the only available sampling strategy (while keeping the dirac property of the last bounce)
            ArPDFValue totalDirectionPDF;
            arpdfvalue_pp_concat_p(
                  directionPDF,
                  pathPDF,
                & totalDirectionPDF
                );
    
            double weight =
                [ self mis
                     : & totalDirectionPDF
                     ];
            
            arlightsample_d_mul_l(
                  art_gv,
                  weight,
                  contribution
                );
        }
        // else // weight = 1, keep the contribution
        
        return YES;
    }
    else
        return NO;
}

//TODO: TODISCUSS: calculateEmissionContribution

- (BOOL) calculateIllumination
       : (      ArcPointContext<ArpRayEndpoint> *) illuminatedPoint
       : (      ArcPointContext *)                 originPoint
       : (const ArWavelength *)                    wavelength
       : (      ArPDFValue *)                      pathPDF
       : (      ArLightSample *)                   contribution
       : (      ArDirectionCosine *)               continuationDirectionCosine
{
   
   // wavelength shifting
   ArWavelength newWavelength;
   ArPDFValue wavelengthPDF;
   if( ! [ illuminatedPoint sampleWavelengthShift
           :   arpathdirection_from_eye
           : & sgc
           :   wavelength
           : & newWavelength
           : & wavelengthPDF
           ])
       return NO;

   
   // invert the direction to point towards the light source, as opposed to away from it
   
   // combine the pdf of sampling the light source point and of sampling the wavelength shift
   // any dirac properties of sampling wavelength should not be preserved
   
   ArNode<ArpVolumeMaterial> * volumeMaterial;
   ArPDFValue bsdfSampleProbability;
   if( ! [ illuminatedPoint evaluateScattering
           : & ARDIRECTIONCOSINE_VECTOR(*continuationDirectionCosine)
           :   arpathdirection_from_eye
           : & sgc
           :   wavelength
           : & newWavelength
           : & ARDIRECTIONCOSINE_COSINE(*continuationDirectionCosine)
           : & volumeMaterial
           : & bsdfSampleProbability
           :   0
           :   temporaryAttenuation
         ])
   {
       return NO;
   }
   
    ArNode<ArpVolumeMaterial> * vm2 = volumeMaterial;
    Vec3D originDirection;
    vec3d_pp_sub_v(
                   &ARCPOINTCONTEXT_WORLDSPACE_POINT(illuminatedPoint),
                   &ARCPOINTCONTEXT_WORLDSPACE_POINT(originPoint),
                   &originDirection
                   );
    
    double connectionVectorLengthSquared =
            vec3d_v_sqrlen( & originDirection );
    
    double originPointDistance = sqrt(connectionVectorLengthSquared);
   // compute the transmittance over the medium between the point and light source
   Ray3D connectionRay =
       RAY3D(
           ARCPOINTCONTEXT_WORLDSPACE_POINT(illuminatedPoint),
           ARDIRECTIONCOSINE_VECTOR(*continuationDirectionCosine)
         );
    
   unsigned int volumeHasAttenuation, volumeHasContribution;
   ArPDFValue distanceProbability, volumeProbability;
   [ self sampleVolumeTransmittance
       :   volumeMaterial
       : & connectionRay
       :   arpathdirection_from_eye
       :   originPointDistance
       : & newWavelength
       : & distanceProbability
       : & volumeProbability
       :   temporaryMediaAttenuation
       : & volumeHasAttenuation
       :   temporaryMediaContribution
       : & volumeHasContribution
       ];
   // apply the transmittance and volume emission if there is any
   if( volumeHasAttenuation )
       arlightsample_a_mul_l(art_gv, temporaryMediaAttenuation, contribution);
   if( volumeHasContribution )
       arlightsample_l_add_l(art_gv, temporaryMediaContribution, contribution);
   

   // brdf * light
   arlightsample_a_mul_l(
                         art_gv,
                         temporaryAttenuation,
                         contribution);
   

   if(HERO_SAMPLES_TO_SPLAT > 1)
   {
       // include the volume probability in the LSS pdf for MIS purposes
//       arpdfvalue_p_reverse_concat_p(
//           & volumeProbability,
//           & samplePDF
//           );
//
//       // calculate the total paths pdfs for the only available sampling strategy (while keeping the dirac property of the last bounce)
//       arpdfvalue_p_reverse_concat_p(
//             pathPDF,
//           & samplePDF
//           );

       double weight =
           [ self mis
                : & volumeProbability
                ];
       
       arlightsample_d_mul_l(
             art_gv,
             weight,
             contribution
           );
   }
   // else // weight = 1, keep the contribution
   
   return YES;
}

- (BOOL) isOccluded
        : (      ArcPointContext *)     pointFrom
        : (const Vec3D *)               direction
        : (      ArcPointContext *)     pointTo
        : (      double *)              distance_r
{
    Ray3D shadowRay;

    RAY3D_POINT(shadowRay) =
            ARCPOINTCONTEXT_WORLDSPACE_POINT(pointFrom);
    RAY3D_VECTOR(shadowRay) = *direction;

    double terminationDistance = MATH_HUGE_DOUBLE;
    if(pointTo)
    {
        Vec3D connectionVector;
        vec3d_pp_sub_v(
                & ARCPOINTCONTEXT_WORLDSPACE_POINT(pointFrom),
                & ARCPOINTCONTEXT_WORLDSPACE_POINT(pointTo),
                & connectionVector
        );
        double connectionVectorLengthSquared =
                vec3d_v_sqrlen( & connectionVector );
        terminationDistance = sqrt(connectionVectorLengthSquared);
        *distance_r = terminationDistance;
    }
    else
        *distance_r = 1.0;

    ArcIntersection  * occlusion =
            [ RAYCASTER firstRayObjectIntersection
                    :   entireScene
                    :   pointFrom
                    : & shadowRay
                    :   terminationDistance
            ];

    if( !occlusion )
        return NO; // no intersection means no occlusion

    BOOL result;
    if(pointTo)
    {
        // we do not necessarily need to hit pointTo, as it may be a virtual point
        result = m_ddd_equal( terminationDistance, ARCINTERSECTION_T(occlusion), 0.000001 )
                 ? NO : YES;
    }
    else
    {
        // if there is no point, we expect to hit infinite sphere
        result = [ ARCINTERSECTION_SHAPE(occlusion)
                         isMemberOfClass
                         :   [ ArnInfSphere class ] ] ? NO : YES;
    }

    [ INTERSECTION_FREELIST releaseInstance
    :   occlusion
    ];

    return result;
}


- (BOOL) randomWalk
        : (      ArcPointContext<ArpRayEndpoint> *) currentPoint
        : (const ArSpectralSample *)                lastMediumReflectivity
        : (const ArWavelength *)                    wavelength
        : (      ArWavelength *)                    newWavelength
        : (      ArPDFValue *)                      samplePDF
        : (      ArPDFValue *)                      wavelengthPDF
        : (      Ray3D *)                           generatedRay
        : (      ArNode<ArpVolumeMaterial> **)      volumeMaterial
        : (      ArAttenuationSample *)             attenuation
        : (      double *)                          cosTheta
        : (      ArPathVertex *)                    currentState
{
    ASSERT_ALLOCATED_ATTENUATION_SAMPLE(attenuation);

    ArDirectionCosine sampledDirection;
    ArPDFValue reversePDF;
    if( ! [ currentPoint sampleScattering
            :   arpathdirection_from_light
            : & sgc
            :   wavelength
            :   newWavelength
            : & sampledDirection
            :   volumeMaterial
            :   samplePDF
            : & reversePDF
            :   attenuation
    ] )
        return NO;

    double cos_factor;
    if (! ARPDFVALUE_IS_INFINITE(*samplePDF))
    {
        cos_factor = M_ABS( ARDIRECTIONCOSINE_COSINE(sampledDirection) );
    }
    else
    {
        cos_factor = 1.0;
    }

    *cosTheta = cos_factor;

    ArSpectralSample mul_factor = SPS4(cos_factor);
    arpdfvalue_p_div_s(samplePDF, & mul_factor);

    // retrieving reflectivity estimate from attenuation
    ArSpectralSample reflectivity;
    arattenuationsample_a_init_s(
            art_gv,
            attenuation,
            & reflectivity
    );

    // russian roulette against medium * reflectivity * cos / pdf
    ArSpectralSample continuationProbability;
    sps_ss_mul_s(art_gv, & mul_factor, & reflectivity, & continuationProbability);
    if(lastMediumReflectivity)
        sps_s_mul_s(art_gv, lastMediumReflectivity, & continuationProbability);
    sps_dd_clamp_s(art_gv, 0.0, 1.0, & continuationProbability); // clamp at max 1.0

    double  russianRouletteSample =
            [ RANDOM_GENERATOR valueFromNewSequence ];

    // decide according to the continuationProbability of hero wavelength only
//    if ( russianRouletteSample > SPS_CI(continuationProbability, 0) )
//        return NO;

    // final attenuation on this pathLength, corrected for russian roulette
    // we use only the value for hero wavelength, as that is the one that contains the actual sampling probability we used
//    arattenuationsample_d_mul_a(
//            art_gv,
//            SPS_CI(mul_factor, 0) / SPS_CI(continuationProbability, 0),
//            attenuation
//    );
    // include the pdf of russian roulette in the sampling pdf
//    arpdfvalue_s_mul_p(& continuationProbability, samplePDF);

    // setup the new ray direction
    RAY3D_POINT(*generatedRay) =
            ARCPOINTCONTEXT_WORLDSPACE_POINT(currentPoint);

    RAY3D_VECTOR(*generatedRay) =
            ARDIRECTIONCOSINE_VECTOR(sampledDirection);



    currentState->dVCM = 1.0f / ARPDFVALUE_MAIN(*samplePDF);
    currentState->dVC = (cos_factor / ARPDFVALUE_MAIN(*samplePDF)) *
            (currentState->dVC * ARPDFVALUE_MAIN(reversePDF) + currentState->dVCM);
    currentState->throughput *= cos_factor;
    // calculate the probability of sampling the wavelength when light-source sampling, but only if it then can end up being used
    // (this calculation is here, because we do not have a proper reference to the surface at calculateEmissionContribution -- because a SurfacePoint can end up there)
//    if ( mode == arpathtracermode_mis || mode == arpathtracermode_weighed_direction_sampling )
//    {
//        if( ! [ currentPoint calculateWavelengthShiftProbability
//                :   arpathdirection_from_eye
//                : & sgc
//                :   wavelength
//                :   newWavelength
//                :   wavelengthPDF
//        ])
//            arpdfvalue_dd_init_p(0.0, 0.0, wavelengthPDF);
//    }

    return YES;
}


- (double) calculateThroughputTwoPoints
        : (Pnt3D *)     point_a
        : (Pnt3D *)     point_b
        : (Vec3D *)     normal_a
        : (Vec3D *)     normal_b
{
    
    Vec3D directionAtoB, directionBtoA;
    
    vec3d_pp_sub_v(point_a, point_b, &directionAtoB);
    vec3d_v_negate_v(&directionAtoB, &directionBtoA);
    
    double connectionVectorLengthSquared =
            vec3d_v_sqrlen( & directionAtoB );
    double distance_traveled = sqrt(connectionVectorLengthSquared);
    
    vec3d_norm_v(&directionAtoB);
    vec3d_norm_v(&directionBtoA);
    
    
    double cosine_a = vec3d_vv_dot(&directionAtoB, normal_a);
    double cosine_b = vec3d_vv_dot(&directionBtoA, normal_b);
    
    double geometryFactor = M_ABS(cosine_a * cosine_b);
    
    geometryFactor /= connectionVectorLengthSquared;
    
    return geometryFactor;
}


- (BOOL) calculateCameraAttenuationContributions
        : (ArAttenuationSample *)             attenuationSample
        : (ArcPointContext<ArpRayEndpoint>*)  currentPoint
        : (Vec3D *)                           normal
        : (ArNode <ArpCamera>  *)             camera
        : (const ArWavelength *)                    incomingWavelength
        : (ArWavelength *)                    outgoingWavelength
        : (ArPDFValue *)                     pdf
{
    
    Ray3D cameraRay;
    [camera getCameraRay: &cameraRay];
    
    //Get the direction vector to the camera
    ArDirectionCosine directionToCamera, cameraToIntersection;
    vec3d_pp_sub_v(
            & ARCPOINTCONTEXT_WORLDSPACE_POINT(currentPoint),
            & RAY3D_P(cameraRay ),
            & ARDIRECTIONCOSINE_VECTOR(directionToCamera)
    );
    
    vec3d_norm_v(&directionToCamera.vector);
    double cameraCosine = vec3d_vv_dot(
            & ARDIRECTIONCOSINE_VECTOR(directionToCamera),
            normal
    );
    
    ArWavelength newWavelength;
    ArPDFValue wavelengthPDF;
    if( ! [ currentPoint sampleWavelengthShift
            :   arpathdirection_from_eye
            : & sgc
            :   incomingWavelength
            : & newWavelength
            : & wavelengthPDF
            ])
        return NO;
    
    ArNode<ArpVolumeMaterial> * volumeMaterialTemp;

    ArPDFValue cameraPDF, reverseCameraPDF;
    if( ! [ currentPoint evaluateScattering
            : & ARDIRECTIONCOSINE_VECTOR(directionToCamera)
            :   arpathdirection_from_light
            : & sgc
            :   incomingWavelength
            : & newWavelength
            : & cameraCosine
            : & volumeMaterialTemp
            : & cameraPDF
            : & reverseCameraPDF
            :   attenuationSample
    ]) {
        
        return NO;
    }

    if(ARPDFVALUE_IS_INFINITE(cameraPDF))
    {
        return NO;
    }
    
    arpdfvalue_p_reverse_concat_p(
        & wavelengthPDF,
        & cameraPDF
        );

    *pdf = reverseCameraPDF;

    Ray3D connectionRay =
        RAY3D(
            currentPoint->worldspace_point,
            directionToCamera.vector
          );
    
    Vec3D directionAtoB;
    vec3d_pp_sub_v(&currentPoint->worldspace_point, &cameraRay.point, &directionAtoB);
    
    double connectionVectorLengthSquared =
            vec3d_v_sqrlen( & directionAtoB );
    double distance_traveled = sqrt(connectionVectorLengthSquared);
    
    unsigned int volumeHasAttenuation, volumeHasContribution;
    ArPDFValue distanceProbability, volumeProbability;
    [ self sampleVolumeTransmittance
        :   volumeMaterialTemp
        : & connectionRay
        :   arpathdirection_from_eye
        :   distance_traveled
        : & newWavelength
        : & distanceProbability
        : & volumeProbability
        :   temporaryMediaAttenuation
        : & volumeHasAttenuation
        :   temporaryMediaContribution
        : & volumeHasContribution
        ];

    *outgoingWavelength = newWavelength;
//    if( volumeHasAttenuation)
//    {
//        arattenuationsample_a_mul_a(art_gv, temporaryMediaAttenuation, pathVertex->cameraDirectionAttenuationSample);
//    }
//
//    if(volumeHasContribution)
//    {
//        arlightsample_l_add_l(art_gv, temporaryMediaContribution, pathVertex->cameraLightSample->light);
//    }
    
//    arpdfvalue_p_concat_p(&cameraPDF, &pathVertex->pathPDF);
//    arpdfvalue_p_reverse_concat_p(&distanceProbability, &pathVertex->pathPDF);
    

    /* * throughput*/;
    
    return YES;
}


- (void) connectToCamera
        : (      ArcIntersection *)      intersection
        : (ArNode <ArpCamera>  *)        camera
        : (ArPathVertex *)               currentState
        : (ArPathVertex *)               connectionVertex
        : (const ArWavelength *)         incomingWavelength
{

    Ray3D cameraDirectionVector;
    [camera getCameraRay: &cameraDirectionVector];

    ArcSurfacePoint* pointContextCamera = [ ALLOC_INIT_OBJECT( ArcSurfacePoint ) ];
    ARCPOINTCONTEXT_WORLDSPACE_POINT(pointContextCamera) = RAY3D_P(cameraDirectionVector);

    Vec3D cameraDirection;
    vec3d_pp_sub_v(&intersection->worldspace_point, &pointContextCamera->worldspace_point, &cameraDirection);

    vec3d_norm_v(&cameraDirection);
    ARPV_OCCLUDED(*connectionVertex) = true;

    double distanceT;
    if ([self isOccluded
            : intersection
                : &cameraDirection
                : pointContextCamera
                : &distanceT] == NO)
    {

        Vec3D directionFromCameraOcclusion;
        Vec3D cameraForward;

        vec3d_v_norm_v(&cameraDirectionVector.vector, &cameraForward);
        vec3d_v_negate_v(&cameraDirection, &directionFromCameraOcclusion);

        if(vec3d_vv_dot(&directionFromCameraOcclusion, &cameraForward) > 0) {
            ARPV_OCCLUDED(*connectionVertex) = false;

            ArAttenuationSample* tempAtten = arattenuationsample_alloc(art_gv);
            ArWavelength outgoingWavelength;
            ArPDFValue cameraReversePDF = ARPDFVALUE_UNIT_INFINITY;
            if( ! [self calculateCameraAttenuationContributions
                    :tempAtten
                    :intersection
                    :&ARCINTERSECTION_WORLDSPACE_NORMAL(intersection)
                    :camera
                    :incomingWavelength
                    :&outgoingWavelength
                    :&cameraReversePDF
            ])
            {
                connectionVertex->occluded = true;
                return;
            }

            if(ARPDFVALUE_IS_INFINITE(currentState->pathPDF))
            {
                connectionVertex->occluded = true;
                return;
            }
            connectionVertex->cameraWavelength = outgoingWavelength;

            ArPDFValue cameraHitPdf;
            Vec3D directionFromCamera;
            Ray3D cameraRay;

            [camera getCameraRay:&cameraRay];

            vec3d_pp_sub_v(&currentState->worldHitPoint->worldspace_point,
                           &cameraRay.point,
                           &directionFromCamera);

            vec3d_norm_v(&directionFromCamera);

            double cameraPDFA;

            double surfaceFactor =
                    [camera getSurfaceFactor
                            : &directionFromCamera
                            : &currentState->worldHitPoint->worldspace_point
                            : &currentState->worldNormal
                            :&cameraPDFA
                    ];

            double div = 512 * 512;

            double wLight = (cameraPDFA / div)
                            * (currentState->dVCM + currentState->dVC
                                                    * ARPDFVALUE_MAIN(cameraReversePDF));

            double misWeight = 1.f / (wLight + 1.f);

            ArSpectralSample sample = SPS4(currentState->throughput * misWeight);

            arpdfvalue_p_div_s(&currentState->pathPDF, &sample);
            ArLightSample* init = arlightsample_alloc(art_gv);
            div *= surfaceFactor;

            arattenuationsample_d_mul_a(art_gv,
                                        SPS_CI(sample, 0),
                                        tempAtten);

            arattenuationsample_d_div_a(art_gv,
                                        div,
                                        tempAtten);

            arlightsample_l_init_l(art_gv, currentState->lightSample->light, init);
            arlightsample_a_mul_l(art_gv,
                                  tempAtten,
                                  init);


            connectionVertex->cameraLightSample = arlightalphasample_alloc(art_gv);
            arlightsample_l_init_l(art_gv, init, connectionVertex->cameraLightSample->light);

        }



    }

}


- (void) generateLightPaths
        : (const Ray3D *)              cameraPixelRay
        : (ArNode <ArpCamera> *)       camera
        : (ArPathVertexDynArray *)     lightPathsList
        : (const ArWavelength *)       wavelength
        : (uint32_t* )                 pathEnds
        : (uint32_t )                  pathIndex
        : (      ArLightAlphaSample *)  lightalpha_r
{

    [ self traceRay
            :   cameraPixelRay
            :   camera
            :   lightPathsList
            :   wavelength
            :   pathEnds
            :   pathIndex
            :   lightalpha_r
    ];
    

}

- (void) generateEyePaths
        : (const Ray3D *)               cameraPixelRay
        : (ArNode <ArpCamera>  *)       sampling_ray
        : (ArPathVertexDynArray *)      lightPathsList
        : (const ArWavelength *)        wavelength
        : (ArPathVertex *)              currentState
        : (uint32_t* )                  pathEnds
        : (      ArLightAlphaSample *)  lightalpha_r
        : (uint32_t )                   pathIndex
        
{

    [self traceRayPathTracing
            :cameraPixelRay
            :sampling_ray
            :lightPathsList
            :wavelength
            :currentState
            : pathEnds
            : lightalpha_r
            : pathIndex
    ];
    
}


- (ArPDFValue) PdfWtoA
        : (ArPDFValue) pdfW
        : (double) distance
        : (double) cos
{
    ArPDFValue temp = pdfW;
    ArSpectralSample pdfW_s = SPS4(fabs(cos) / M_SQR(distance));

    arpdfvalue_s_mul_p(&pdfW_s, &temp);

    return temp;
}

- (BOOL) directIllumination
        : (ArPathVertex *) eyeState
        : (ArLightSample *) lightSample
        : (ArAttenuationSample *) connectionSample
{

    float lightCount = LIGHTSOURCE_COLLECTION.numberOfLights;
    float lightPickProbability = 1.0f / lightCount;

    ArcSurfacePoint * lightSourcePoint;
    ArDirectionCosine lightDirection;
    ArSamplingRegion samplingRegion;
    ArPDFValue emissionPDF, directPDF;

    double distance;
    ArLightSample * contrib= arlightsample_alloc(art_gv);
    [LIGHTSOURCE_COLLECTION sampleLightsource
            : eyeState->worldHitPoint
            : &lssc
            : &eyeState->outgoingWavelength
            : &samplingRegion
            :&lightSourcePoint
            :&lightDirection
            : &directPDF
            : &emissionPDF
            : contrib
    ];

    Vec3D directionToLight;
    vec3d_v_negate_v(&lightDirection.vector, &directionToLight);

    double distanceT;
    if ([self isOccluded
                : eyeState->worldHitPoint
                : &directionToLight
                : lightSourcePoint
                : &distanceT] == YES)
    {
        return NO;
    }


    ArNode<ArpVolumeMaterial> * volumeMaterial;
    ArPDFValue eyeForwardPDF_W;
    ArPDFValue eyeReversePDF_W;
    ArAttenuationSample *tempSample = arattenuationsample_alloc(art_gv);

    double toLightcosine = vec3d_vv_dot(
            &eyeState->worldNormal,
            &directionToLight);

    [eyeState->worldHitPoint evaluateScattering
            : & directionToLight
            :   arpathdirection_from_eye
            : & sgc
            : & eyeState->incomingWavelength
            : & eyeState->outgoingWavelength
            : & toLightcosine
            : & volumeMaterial
            : & eyeForwardPDF_W
            : & eyeReversePDF_W
            :   tempSample
    ];


    float wLight = ARPDFVALUE_MAIN(eyeForwardPDF_W)
            / (lightPickProbability * ARPDFVALUE_MAIN(directPDF));

//    arpdfvalue_d_mul_p(toLightcosine, &emissionPDF);
//    arpdfvalue_d_mul_p(lightDirection.cosine, &directPDF);
//
//    ArPDFValue ratioED;
//    arpdfvalue_pp_div_p(&emissionPDF, &directPDF, &ratioED);

    double wCamera = ( (toLightcosine * ARPDFVALUE_MAIN(emissionPDF)) /
            (lightDirection.cosine * ARPDFVALUE_MAIN(directPDF)) ) *
            eyeState->dVCM + eyeState->dVC * ARPDFVALUE_MAIN(eyeReversePDF_W);


    float misWeight = 1.0 / (1.0 + wLight + wCamera);

    double contribLeft = ((misWeight * toLightcosine) / (lightPickProbability * ARPDFVALUE_MAIN(directPDF)));

    arattenuationsample_a_init_a(art_gv, tempSample, connectionSample);
    arlightsample_a_mul_l(art_gv, tempSample, contrib);

    arlightsample_d_mul_l(art_gv, contribLeft, contrib);

    arlightsample_l_init_l(art_gv, contrib, lightSample);

    return YES;
}

- (BOOL) connectVertices
    : (ArPathVertex *) eyeState
    : (ArPathVertex *) lightVertex
    : (ArLightSample *) lightSample
    : (ArAttenuationSample *) connectionSample
{

    Vec3D direction;
    Vec3D directionTo;

    vec3d_pp_sub_v(
            &eyeState->worldHitPoint->worldspace_point,
            &lightVertex->worldHitPoint->worldspace_point,
            &direction);

    const double dist2 = vec3d_v_sqrlen(&direction);
    const double dist = sqrt(dist2);

    vec3d_norm_v(&direction);
    vec3d_v_negate_v(&direction, &directionTo);

    double distanceT;
    if ([self isOccluded
            : eyeState->worldHitPoint
                : &direction
                : lightVertex->worldHitPoint
            : &distanceT] == YES)
    {
        return NO;
    }

    double cameraCosine =
            vec3d_vv_dot(&eyeState->worldNormal,
                         &direction);

    ArNode<ArpVolumeMaterial> * volumeMaterial;
    ArPDFValue eyeForwardPDF_W;
    ArPDFValue eyeReversePDF_W;
    ArAttenuationSample *tempSample = arattenuationsample_alloc(art_gv);
    [eyeState->worldHitPoint evaluateScattering
            : & direction
            :   arpathdirection_from_eye
            : & sgc
            : & eyeState->incomingWavelength
            : & eyeState->outgoingWavelength
            : & cameraCosine
            : & volumeMaterial
            : & eyeForwardPDF_W
            : & eyeReversePDF_W
            :   tempSample
    ];

    ArNode<ArpVolumeMaterial> * l_volumeMaterial;
    ArPDFValue lightForwardPDF_W;
    ArPDFValue lightReversePDF_W;
    ArAttenuationSample *tempSampleLight = arattenuationsample_alloc(art_gv);

    double lightCosine = vec3d_vv_dot(&lightVertex->worldNormal, &directionTo);
    [eyeState->worldHitPoint evaluateScattering
            : & directionTo
            :   arpathdirection_from_light
            : & sgc
            : & lightVertex->incomingWavelength
            : & lightVertex->outgoingWavelength
            : & lightCosine
            : & l_volumeMaterial
            : & lightForwardPDF_W
            : & lightReversePDF_W
            :   tempSampleLight
    ];


    double geometryTerm = lightCosine * cameraCosine / dist2;
    if(geometryTerm < 0)
        return NO;


    ArPDFValue cameraPdfA = [self PdfWtoA : eyeForwardPDF_W : dist : cameraCosine];
    ArPDFValue lightPdfA = [self PdfWtoA : lightForwardPDF_W : dist : lightCosine];

    double wLight = ARPDFVALUE_MAIN(cameraPdfA) *
            (lightVertex->dVCM + lightVertex->dVC * ARPDFVALUE_MAIN(lightReversePDF_W));

    double wCamera = ARPDFVALUE_MAIN(lightPdfA) *
                    (eyeState->dVCM + eyeState->dVC * ARPDFVALUE_MAIN(eyeReversePDF_W));

    double misWeight = 1.0 / (1.0 + wLight + wCamera);

    arattenuationsample_a_mul_a(art_gv, tempSample, tempSampleLight);
    arattenuationsample_d_mul_a(art_gv, misWeight * geometryTerm, tempSampleLight);

    arattenuationsample_a_init_a(art_gv, tempSampleLight, connectionSample);


    return YES;
}


- (bool) traceRayPathTracing
        : (const Ray3D *)               cameraPixelRay
        : (ArNode <ArpCamera>  *)       camera
        : (ArPathVertexDynArray *)      lightPathsList
        : (const ArWavelength*)         wavelength
        : (ArPathVertex *)              currentState
        : (uint32_t* )                 pathEnds
        : (      ArLightAlphaSample *)  lightalpha_r
        : (uint32_t )                  pathIndex

{
    ASSERT_ALLOCATED_LIGHTALPHA_SAMPLE(lightalpha_r);

    ArcIntersection * intersection = 0;

    Ray3D cray;
    [camera getCameraRay: &cray];

    ArcPointContext* originPoint = eyePoint;
    ArcPointContext<ArpRayEndpoint> * currentPoint;

    ArWavelength currentWavelength = *wavelength;
    ArWavelength previousWavelength = currentWavelength;

    Ray3D ray = *cameraPixelRay;

    for (unsigned int pathLength = 0; pathLength < maximalRecursionLevel; pathLength++)
    {

        intersection =
                [ RAYCASTER firstRayObjectIntersection
                        :   entireScene
                        :   originPoint
                        : & ray
                        :   MATH_HUGE_DOUBLE
                ];

        currentPoint = intersection;

        if(! currentPoint)
        {
            break;
        }

        [ currentPoint prepareForUse: PHASE_INTERFACE_CACHE ];


        //update VCM values
        double cosTheta = [currentPoint getThetaFix];
        {
            currentState->dVCM *= M_SQR(intersection->t);
            currentState->dVCM /= cosTheta;
            currentState->dVC /= cosTheta;
        }

        ArLightSample *lightSample = arlightsample_alloc(art_gv);
        if( [ self calculateEmissionContribution
                :   0
                :   false
                :   originPoint
                :   intersection
                : & currentWavelength
                : & previousWavelength
                :   0
                :   0
                :   0
                :   lightSample
        ] )
        {
            arlightsample_d_mul_l(art_gv, currentState->throughput, lightSample);
            arlightsample_l_add_l(art_gv, lightSample, lightalpha_r->light);
            break;
        }

        {

            ArLightSample *lightSampleDirect = arlightsample_alloc(art_gv);
            ArAttenuationSample *connectionSample = arattenuationsample_alloc(art_gv);

            [self directIllumination
                    : currentState
                    : lightSampleDirect
                    : connectionSample
            ];

            arlightsample_d_mul_l(art_gv,
                                  currentState->throughput,
                                  lightSampleDirect);

            arlightsample_l_add_l(art_gv, lightSampleDirect, lightalpha_r->light);
        }

        uint32_t rangeX, rangeY;
        rangeX = 0;

        if(pathIndex != 0)
        {
           rangeX = pathEnds[pathIndex - 1];
        }
        rangeY = pathEnds[pathIndex];

        for (uint32_t i = rangeX; i < rangeY; ++i)
        {

            ArPathVertex lightVertex = arpvdynarray_i(lightPathsList, i);

            ArLightSample *lightSampleConnection = arlightsample_alloc(art_gv);
            ArAttenuationSample *connectionSampleConnection = arattenuationsample_alloc(art_gv);
            if([self connectVertices
                    : currentState
                    : &lightVertex
                    : lightSampleConnection
                    : connectionSampleConnection
            ])
            {
                double weight = currentState->throughput * lightVertex.throughput;

                arattenuationsample_d_mul_a(art_gv,
                                          weight,
                                          connectionSampleConnection);

                arlightsample_l_init_l(art_gv,
                                       lightVertex.lightSample->light,
                                       lightSampleConnection);

                arlightsample_a_mul_l(art_gv,
                                      connectionSampleConnection,
                                      lightSampleConnection);

                arlightsample_l_add_l(art_gv,
                                      lightSampleConnection,
                                      lightalpha_r->light);
            }
            //BREAK for minPathLength

            //BREAK fro maxPathLength
        }




        originPoint = currentPoint;
    }



}


- (bool) traceRay
        : (const Ray3D *)               cameraPixelRay
        : (ArNode <ArpCamera>  *)       camera
        : (ArPathVertexDynArray *)      lightPathsList
        : (const ArWavelength*)         wavelength
        : (uint32_t* )                  pathEnds
        : (uint32_t )                   pathIndex
        : (      ArLightAlphaSample *)  lightalpha_r
{
    ASSERT_VALID_WAVELENGTH(wavelength);

    // initial ra
    ArcIntersection * rayOriginIntersection = 0; // special variable for purposes of deallocating
    ArcRayEndpoint * rayOriginScatteringEvent = 0; // special variable for purposes of deallocating
    ArcIntersection * intersection = 0; // outside of loop for easier early termination of loop
    ArcRayEndpoint * scatteringEvent = 0; // outside of loop for easier early termination of loop
    // initial volume
    ArNode<ArpVolumeMaterial> * volumeMaterial =
            ARCSURFACEPOINT_VOLUME_MATERIAL_INSIDE(eyePoint);

    ArAttenuationSample *temporaryMediaAttenuation = arattenuationsample_alloc(art_gv);
//    ArPDFValue pathPDF = ARPDFVALUE_UNIT_INFINITY;
    ArPDFValue directionSamplingPDF = ARPDFVALUE_UNIT_INFINITY;
    ArPDFValue lightSourceSamplingPartialPDF = ARPDFVALUE_UNIT_INFINITY;

    //TODO: TEMP: GENERATE DIRECTION FORM A SINGLE LIGHT SOURCE
//    [ LIGHTSOURCE_COLLECTION[]

    ArcSurfacePoint * incomingSourcePoint;
    ArDirectionCosine incomingDirection = ARDIRECTIONCOSINE(VEC3D_INVALID, 0);
    ArSamplingRegion samplingRegion;
    
    ArWavelength currentWavelength = *wavelength;
    ArWavelength previousWavelength;

    ArLightSample* lightSample = arlightsample_alloc(art_gv);
    ArLightAlphaSample lightAlphaSample;
    ArPDFValue lightSourcePDF;
    ArPDFValue samplingCosinePDF;
    if( ![ LIGHTSOURCE_COLLECTION generateRandomDirection
            : & lssc
            : & samplingRegion
            : & incomingSourcePoint
            : & incomingDirection
            : & lightSourcePDF /* optional */
            : & samplingCosinePDF
            : & currentWavelength
            :   lightSample
    ])
    {
        return NO;
    }
    double ss = arlightsample_l_max(art_gv, lightSample);
    ss;
    
    ARLIGHTALPHASAMPLE_LIGHT(lightAlphaSample) = lightSample;
    ARLIGHTALPHASAMPLE_ALPHA(lightAlphaSample) = 1.0f;
    
    
    Ray3D ray;

    RAY3D_P(ray) = ARCSURFACEPOINT_WORLDSPACE_POINT(incomingSourcePoint);
    RAY3D_V(ray) = ARDIRECTIONCOSINE_VECTOR(incomingDirection);

    
    
    
    bool shouldBreak = false;
    
    int lastNonzeroIndex = -1;
    nonzeroContributions[0] = 0;

    Vec3D intersectionNormal;
    Vec3D originNormal = ARCINTERSECTION_WORLDSPACE_NORMAL(incomingSourcePoint);

    ArcPointContext* originPoint =  incomingSourcePoint;
    ArcPointContext<ArpRayEndpoint> * currentPoint;

    ArPathVertex* currentState = ALLOC(ArPathVertex);
  
    for(unsigned int pathLength = 0; pathLength < 6; ++pathLength)
    {
        
        ArPathVertex * lightVertex = ALLOC(ArPathVertex);

        if(pathLength == 0)
        {
            currentState->pathPDF = lightSourcePDF;
            currentState->throughput = incomingDirection.cosine;
//
            arpdfvalue_d_init_p(incomingDirection.cosine / M_PI, &samplingCosinePDF);
            arpdfvalue_p_mul_p(&samplingCosinePDF, &currentState->pathPDF);

            //UPDATE THE VERTEX CONNECTION and VCM VALUES
            currentState->dVC = incomingDirection.cosine / ARPDFVALUE_MAIN(currentState->pathPDF);

            ArPDFValue vcm;
            arpdfvalue_pp_div_p(&lightSourcePDF, &currentState->pathPDF, &vcm);
            currentState->dVCM = ARPDFVALUE_MAIN(vcm);


            currentState->lightSample = arlightalphasample_alloc(art_gv);
            currentState->cameraLightSample = arlightalphasample_alloc(art_gv);
            
            arlightsample_l_init_l(art_gv, lightSample, currentState->lightSample->light);
            
        }

        currentState->totalPathLength = pathLength;

        currentState->lightSample->alpha = 1.0f;
        currentState->cameraLightSample->alpha = 1.0f;
        
        intersection =
                [ RAYCASTER firstRayObjectIntersection
                        :   entireScene
                        :   originPoint
                        : & ray
                        :   MATH_HUGE_DOUBLE
                ];

        currentPoint = intersection;

        if(! currentPoint)
        {
            break;
        }

        [ currentPoint prepareForUse: PHASE_INTERFACE_CACHE ];

        ARPV_HITPOINT(*currentState) = intersection;
        
        ArSpectralSample mediumReflectivity; // to store the reflectivity divided by their respective pdfs
        ArPDFValue distanceProbability, volumeProbability;
        unsigned int volumeHasContribution;
        
    
        [ self sampleVolumeTransmittanceAndDistance
            :   volumeMaterial
            : & ray
            :   arpathdirection_from_eye
            :   !intersection ? MATH_HUGE_DOUBLE : ARCINTERSECTION_T(intersection)
            :   wavelength
            : & distanceProbability
            : & volumeProbability
            :   temporaryMediaAttenuation
            : & mediumReflectivity
            : & currentState->isClearMediaAttenuation
            :   temporaryContribution
            : & volumeHasContribution
            ];
        
        if ( volumeHasContribution) {
                
            arlightsample_l_add_l(art_gv, temporaryContribution, currentState->lightSample->light);
            
            arattenuationsample_a_mul_a(art_gv, temporaryMediaAttenuation, currentState->attenuationSample);
        }
        
//        arpdfvalue_p_reverse_concat_p(&distanceProbability, &currentState->pathPDF);
        
        intersectionNormal = ARCINTERSECTION_WORLDSPACE_NORMAL(intersection);
        originNormal = intersectionNormal;

        if ( [ ARCINTERSECTION_SHAPE(intersection)
              isMemberOfClass
              :   [ ArnInfSphere class ] ] )
        {
            break; // we cannot return from infinite sphere
        }

        //UPDATE VCM values
        double cosTheta = [intersection getThetaFix];
        {
            currentState->dVCM *= M_SQR(intersection->t);
            currentState->dVC /= cosTheta;
            currentState->dVCM /= cosTheta;
        }

        lightVertex->pathPDF = currentState->pathPDF;
        lightVertex->throughput = currentState->throughput;
        lightVertex->lightSample = currentState->lightSample;
        lightVertex->worldHitPoint = currentState->worldHitPoint;
        lightVertex->attenuationSample = currentState->attenuationSample;


        if(true)
        {
            [self connectToCamera: intersection
                    : camera
                    : currentState
                    : lightVertex
                    : wavelength
            ];
            
            if(pathLength > 0 && !lightVertex->occluded)
            {
//                arattenuationsample_a_mul_a(art_gv,
//                                            currentState->attenuationSample,
//                                            lightVertex->cameraDirectionAttenuationSample);
                 
            }
        }
        else
        {
            lightVertex->occluded = true;
        }

        // continue only if there is a possibility to encounter any more light samples
        if ( pathLength < 6 - 1 )
        {

            if(pathLength > 1)
            {
                
            }
            previousWavelength = currentWavelength;

            ArAttenuationSample* tempAtten = arattenuationsample_alloc(art_gv);
            bool continueExploring = true;
            
            double cos;
            //conduct random walk step, generating new ray and wavelength
            if( ! [ self randomWalk
                    :   currentPoint
                    :   0
                    : & previousWavelength // passes in the current wavelength
                    : & currentWavelength // stores the new wavelength
                    : & directionSamplingPDF
                    : & lightSourceSamplingPartialPDF
                    : & ray
                    : & volumeMaterial
                    : tempAtten
                    : & cos
                    : currentState

            ] )
            {
                continueExploring = false;
                shouldBreak = true;
            }
//
            ARPV_INCOMINGWAVELENGTH(*currentState) = previousWavelength;
            ARPV_OUTGOINGWAVELENGTH(*currentState) = currentWavelength;
//
            
            if(continueExploring)
            {

                if(pathLength  == 0)
                {
                    currentState->attenuationSample = arattenuationsample_alloc(art_gv);
                    arattenuationsample_a_init_a(art_gv, tempAtten, currentState->attenuationSample);
                }
                else
                {
                    arattenuationsample_a_mul_a(art_gv,
                                                tempAtten,
                                                currentState->attenuationSample);
                }

                arpdfvalue_p_concat_p(&directionSamplingPDF, &currentState->pathPDF);

            }

            pathEnds[pathIndex] = arpvdynarray_size(lightPathsList);
            arpvdynarray_push(lightPathsList, *lightVertex);

            
            if(shouldBreak)
            {
            
                break;
            }

            originPoint = currentPoint;
            
            
//
//            if( ! ARPDFVALUE_IS_INFINITE(directionSamplingPDF) )
//                specularOnlyPath = NO;
//
//            // release the last intersection, but don't touch eyePoint
//
//            if(rayOriginScatteringEvent)
//            {
//                [ RAYENDPOINT_FREELIST releaseInstance
//                :   rayOriginScatteringEvent
//                ];
//                rayOriginScatteringEvent = 0;
//            }
//
//            // store the ray origin according to its type, so that we properly deallocate it
//            // at this point, only one of them is nonnull
//            if(scatteringEvent)
//            {
//                rayOriginScatteringEvent = scatteringEvent;
//                scatteringEvent = 0;
//            }
//            else
//            {
//                rayOriginIntersection = intersection;
//                intersection = 0;
//            }
//
            
            if(!continueExploring)
                break;
        }


    }

    
    unsigned int last = arpvdynarray_size(lightPathsList);

    // release any leftover intersections or ray endpoints
    if ( rayOriginIntersection )
    {
        [ INTERSECTION_FREELIST releaseInstance
        :   rayOriginIntersection
        ];
    }

    
    if ( rayOriginScatteringEvent )
    {
        [ RAYENDPOINT_FREELIST releaseInstance
        :   rayOriginScatteringEvent
        ];
    }
    
    if ( scatteringEvent )
    {
        [ RAYENDPOINT_FREELIST releaseInstance
        :   scatteringEvent
        ];
    }

//#ifdef FOUNDATION_ASSERTIONS
//    // check, whether the reference frame of the result matches the queried ray
//    Vec3D  checkVec;
//
//    vec3d_v_negate_v( & RAY3D_V(*viewRay_worldspace), & checkVec );
//
//    ASSERT_COAXIAL_SAMPLE_REFERENCE_FRAMES_VL(
//        & checkVec,
//          ARLIGHTALPHASAMPLE_LIGHT(*lightalpha_r),
//          0 DEGREES
//        );
//
//#endif
//
//    ASSERT_VALID_LIGHTALPHA_SAMPLE(lightalpha_r)
}


- (const char *) descriptionString
{
    return "vertex connection and merging";
}

- (void) code
        : (ArcObject <ArpCoder> *) coder
{
    [ super code: coder ];

    [ coder codeUInt: & mode ];
    
    if ( [ coder isReading ] )
        [ self _setupVCM ];
}


- (BOOL) requiresLightsourceCollection
{
    return YES;
}



@end
