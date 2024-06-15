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
#import "ArnStochasticBackwardsSampler.h"

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


    if( !pathAttenuation)
    {
        pathAttenuation = arattenuationsample_alloc(art_gv);
    }

    if( !generatedLightSample)
    {
        generatedLightSample = arlightsample_alloc(art_gv);
    }

    if( !initialLightSample )
    {
        initialLightSample = arlightsample_alloc(art_gv);
    }

    if( !lightSampleConnection)
    {
        lightSampleConnection = arlightsample_alloc(art_gv);
    }

    if(!connectionSampleConnection)
    {
        connectionSampleConnection = arattenuationsample_alloc(art_gv);
    }

    if(!tempEmissionSample)
    {
        tempEmissionSample = arlightsample_alloc(art_gv);
    }

    if (!cvtempSampleLight)
    {
        cvtempSampleLight = arattenuationsample_alloc(art_gv);
    }

    if (!cvtempSample)
    {
        cvtempSample = arattenuationsample_alloc(art_gv);
    }

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

}

- (void) dealloc
{

    if ( pathAttenuation )
    {
        arattenuationsample_free(art_gv, pathAttenuation);
        pathAttenuation = 0;
    }

    if ( generatedLightSample )
    {
        arlightsample_free(art_gv, generatedLightSample);
        generatedLightSample = 0;
    }

    if ( initialLightSample )
    {
        arlightsample_free(art_gv, initialLightSample);
        initialLightSample = 0;
    }

    if ( lightSampleConnection )
    {
        arlightsample_free(art_gv, lightSampleConnection);
        lightSampleConnection = 0;
    }

    if ( connectionSampleConnection )
    {
        arattenuationsample_free(art_gv, connectionSampleConnection);
        connectionSampleConnection = 0;
    }

    if ( tempEmissionSample )
    {
        arlightsample_free(art_gv, tempEmissionSample);
        tempEmissionSample = 0;
    }

    if ( cvtempSampleLight )
    {
        arattenuationsample_free(art_gv, cvtempSampleLight);
        cvtempSampleLight = 0;
    }

    if ( cvtempSample )
    {
        arattenuationsample_free(art_gv, cvtempSample);
        cvtempSample = 0;
    }



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

- (int)  getIntegratorMode
{
    return mode;
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
        : (      ArPathVertex *)            currentState
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
        : (      double *)            misWeight
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
//        if( [ self isEmissionDisregarded
//                :   specularOnlyPath
//                :   ARPDFVALUE_IS_INFINITE(*directionPDF)
//                : & lightSamplingRegion
//                ])
//            return NO;

        // calculate the MIS weight



        BOOL weighed = NO;
        ArDirectionCosine lightDirection;
        vec3d_v_negate_v(
                & ARCINTERSECTION_WORLDSPACE_VECTOR(hitPoint),
                & ARDIRECTIONCOSINE_VECTOR(lightDirection)
        );

        ARDIRECTIONCOSINE_COSINE(lightDirection) =fabs(
                ARCINTERSECTION_WORLDSPACE_COSINE(hitPoint));

        ArPDFValue directPDFA, emissionPDW;

        if([ LIGHTSOURCE_COLLECTION sampleProbability
                :   emitter
                :   originPoint
                :   hitPoint
                : & lightDirection
                :   wavelength
                : & lightSamplingRegion
                : & directPDFA
                : &emissionPDW
        ])
        {

            if(ARPDFVALUE_MAIN(emissionPDW) < 0)
                return NO;

            double wCamera = ARPDFVALUE_MAIN(directPDFA) * currentState->dVCM
                             + ARPDFVALUE_MAIN(emissionPDW) * currentState->dVC;

            *misWeight = 1.f / (1.f + wCamera);

            return YES;
        }

        return NO;

        // else // weight = 1, keep the contribution
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
        : (      Pnt3D *)               pointTo
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
                pointTo,
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

    RELEASE_OBJECT(occlusion);

    return result;
}

- (BOOL) randomWalkPT
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
        : (     ArVCMGlobalValues *)                vcmGlobalValues {

    ASSERT_ALLOCATED_ATTENUATION_SAMPLE(attenuation);

    ArDirectionCosine sampledDirection;
    ArPDFValue reversePDF;
    if (![currentPoint sampleScattering
            :arpathdirection_from_eye
            :&sgc
            :wavelength
            :newWavelength
            :&sampledDirection
            :volumeMaterial
            :samplePDF
            :&reversePDF
            :attenuation
    ])
        return NO;

    double cos_factor = ARDIRECTIONCOSINE_COSINE(sampledDirection);
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


    currentState->dVC = (cos_factor / ARPDFVALUE_MAIN(*samplePDF)) *
                        (currentState->dVC * ARPDFVALUE_MAIN(reversePDF)
                         + currentState->dVCM + vcmGlobalValues->VMweight);

    currentState->dVM = (cos_factor / ARPDFVALUE_MAIN(*samplePDF)) *
                        (currentState->dVM * ARPDFVALUE_MAIN(reversePDF)
                         + currentState->dVCM * vcmGlobalValues->VCweight + 1.f );

    currentState->dVCM = 1.0f / ARPDFVALUE_MAIN(*samplePDF);
//    currentState->throughput *= cos_factor;
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
        : (      ArSubPathStateMin *)               currentState
        : (     ArVCMGlobalValues *)                vcmGlobalValues
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


//    arpdfvalue_d_mul_p(
//            1.f / (2 * 100 NM),
//            samplePDF
//    );
//
//    arattenuationsample_d_mul_a(
//            art_gv,
//            1.f / (2 * 100 NM),
//            attenuation
//    );
//    //Mollify the sampling PDF
    if(!(MODE & arvcmmode_lt)) {
        arpdfvalue_d_mul_p(
                1.f / (2 * 10 NM),
                samplePDF
        );
        arpdfvalue_d_mul_p(
                1.f / (2 * 10 NM),
                &reversePDF
        );
    }

    currentState->dVC = (cos_factor / ARPDFVALUE_MAIN(*samplePDF)) *
                        (currentState->dVC * ARPDFVALUE_MAIN(reversePDF)
                         + currentState->dVCM + vcmGlobalValues->VMweight);

    currentState->dVM = (cos_factor / ARPDFVALUE_MAIN(*samplePDF)) *
                        (currentState->dVM * ARPDFVALUE_MAIN(reversePDF)
                         + currentState->dVCM * vcmGlobalValues->VCweight + 1.f );

    currentState->dVCM = 1.0f / ARPDFVALUE_MAIN(*samplePDF);
//    currentState->throughput *= cos_factor;
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
        : (ArcIntersection*)                  currentPoint
        : (Vec3D *)                           normal
        : (ArNode <ArpCamera>  *)             camera
        : (const ArWavelength *)              incomingWavelength
        : (ArWavelength *)                    outgoingWavelength
        : (ArPDFValue *)                      pdf
        : (ArPDFValue *)                      wavelengthPDF
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
    if( ! [ currentPoint sampleWavelengthShift
            :   arpathdirection_from_light
            : & sgc
            :   incomingWavelength
            : & newWavelength
            :   wavelengthPDF
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

//    arpdfvalue_p_reverse_concat_p(
//            & wavelengthPDF,
//            & cameraPDF
//    );


    *pdf = reverseCameraPDF;
    *outgoingWavelength = newWavelength;


    return YES;
}

- (void) connectToCamera
        : (ART_GV *)                     gv
        : (      ArcIntersection *)      intersection
        : (ArNode <ArpCamera>  *)        camera
        : (ArSubPathStateMin *)          currentState
        : (ArPathVertex *)               connectionVertex
        : (ArcIntersection*)             worldHitPoint
        : (unsigned int)                          pathLength
        : (const ArWavelength *)         incomingWavelength
        : (ArVCMGlobalValues *)          pArVcmGlobalValues
{

    Ray3D cameraDirectionVector;
    [camera getCameraRay: &cameraDirectionVector];

    Vec3D cameraDirection;
    vec3d_pp_sub_v(&intersection->worldspace_point, &cameraDirectionVector.point, &cameraDirection);

    vec3d_norm_v(&cameraDirection);
    ARPV_OCCLUDED(*connectionVertex) = true;

    double distanceT;
    if ([self isOccluded
            : intersection
                : &cameraDirection
                : &cameraDirectionVector.point
                : &distanceT] == NO)
    {

        Vec3D directionFromCameraOcclusion;
        Vec3D cameraForward;

        vec3d_v_norm_v(&cameraDirectionVector.vector, &cameraForward);
        vec3d_v_negate_v(&cameraDirection, &directionFromCameraOcclusion);

        if(vec3d_vv_dot(&directionFromCameraOcclusion, &cameraForward) > 0) {
            ARPV_OCCLUDED(*connectionVertex) = false;

//            ArAttenuationSample* tempAtten = arattenuationsample_alloc(art_gv);
            ArWavelength outgoingWavelength;
            ArPDFValue wavelengthPDF;
            ArPDFValue cameraReversePDF = ARPDFVALUE_UNIT_INFINITY;
            if( ! [self calculateCameraAttenuationContributions
                    :temporaryAttenuation
                    :intersection
                    :&ARCINTERSECTION_WORLDSPACE_NORMAL(intersection)
                    :camera
                    :incomingWavelength
                    :&outgoingWavelength
                    :&cameraReversePDF
                    :&wavelengthPDF
            ])
            {
                connectionVertex->occluded = true;
                return;
            }

            connectionVertex->cameraWavelength = outgoingWavelength;

            ArPDFValue cameraHitPdf;
            Vec3D directionFromCamera;
            Ray3D cameraRay;

            [camera getCameraRay:&cameraRay];

            vec3d_pp_sub_v(&cameraRay.point, &worldHitPoint->worldspace_point,
                           &directionFromCamera);

            vec3d_norm_v(&directionFromCamera);

            double cameraPDFA;

            double surfaceFactor =
                    [camera getSurfaceFactor
                            : &directionFromCamera
                            : &worldHitPoint->worldspace_point
                            : &worldHitPoint->worldspace_normal
                            :&cameraPDFA
                    ];

            double div = 512 * 512;
            double wLight = (cameraPDFA / div) *
                            ( pArVcmGlobalValues->VMweight + currentState->dVCM + currentState->dVC * ARPDFVALUE_MAIN(cameraReversePDF));

            double hwssWeight = [self mis : &currentState->pathPDF];

            double misWeight = 1.f / (wLight + 1.f);
            if(MODE & arvcmmode_lt)
            {
                misWeight = 1;
            }

            ArSpectralSample sample = SPS4(currentState->throughput);

            if(!ARPDFVALUE_IS_INFINITE(wavelengthPDF))
            {
                arpdfvalue_p_div_s(&wavelengthPDF, &sample);
            }

            arpdfvalue_p_div_s(&currentState->pathPDF, &sample);

            div *= surfaceFactor;

            if(pathLength > 0)
            {
                arattenuationsample_a_mul_a(gv, pathAttenuation, temporaryAttenuation);
            }

            arattenuationsample_d_mul_a(gv,
                                        ( SPS_CI(sample, 0) * misWeight  * hwssWeight) / div,
                                        temporaryAttenuation);

//            arlightsample_d_mul_l(art_gv,
//                                  hwssWeight,
//                                  connectionVertex->cameraLightSample->light);

            arlightsample_l_init_l(gv, generatedLightSample, connectionVertex->cameraLightSample->light);
            arlightsample_a_mul_l(gv,
                                  temporaryAttenuation,
                                  connectionVertex->cameraLightSample->light);


            connectionVertex->worldHitPoint = worldHitPoint;
//            arlightsample_l_init_l(art_gv, init, connectionVertex->cameraLightSample->light);

        }



    }

}


- (void) generateLightPaths
        : (ART_GV *)                   art_gv
        : (const Ray3D *)              cameraPixelRay
        : (ArNode <ArpCamera> *)       camera
        : (ArPathVertexptrDynArray *)     lightPathsList
        : (const ArWavelength *)       wavelength
        : (uint32_t* )                 pathEnds
        : (uint32_t )                  pathIndex
        : (      ArLightAlphaSample *)  lightalpha_r
        : (ArVCMGlobalValues *)        pArVcmGlobalValues
{

    [ self traceRay
            :   art_gv
            :   cameraPixelRay
            :   camera
            :   lightPathsList
            :   wavelength
            :   pathEnds
            :   pathIndex
            :   lightalpha_r
            :   pArVcmGlobalValues
    ];


}

- (void) generateEyePaths
        : (const Ray3D *)               cameraPixelRay
        : (ArNode <ArpCamera>  *)       sampling_ray
        : (ArPathVertexptrDynArray *)      lightPathsList
        : (const ArWavelength *)        wavelength
        : (ArPathVertex *)              currentState
        : (uint32_t* )                  pathEnds
        : (      ArLightAlphaSample *)  lightalpha_r
        : (uint32_t )                   pathIndex
        : (ArcHashgrid *)               hashgrid
        :(ArVCMGlobalValues *)        pArVcmGlobalValues

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
            : hashgrid
            : pArVcmGlobalValues
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
        : (ArVCMGlobalValues *) pArVcmGlobalValues
{

    float lightCount = LIGHTSOURCE_COLLECTION.numberOfLights;
    float lightPickProbability = 1.0f / lightCount;

    ArcSurfacePoint * lightSourcePoint;
    ArDirectionCosine lightDirection;
    ArSamplingRegion samplingRegion;
    ArPDFValue emissionPDF, directPDF;

    ArWavelength newWavelength;
    ArPDFValue wavelengthPDF;
    if(![eyeState->worldHitPoint sampleWavelengthShift
            :   arpathdirection_from_eye
            : & sgc
            : & eyeState->incomingWavelength
            : & newWavelength
            : & wavelengthPDF
    ])
    {
        return NO;
    };

    double distance;
    if(![LIGHTSOURCE_COLLECTION sampleLightsource
            : eyeState->worldHitPoint
            : &lssc
            : &newWavelength
            : &samplingRegion
            : &lightSourcePoint
            : &lightDirection
            : &directPDF
            : &emissionPDF
            : temporaryContribution
    ])
    {
        RELEASE_OBJECT(lightSourcePoint);
        return NO;
    };


    arpdfvalue_p_reverse_concat_p(&wavelengthPDF, &emissionPDF);
    arpdfvalue_p_reverse_concat_p(&wavelengthPDF, &directPDF);

    Vec3D directionToLight;
    vec3d_v_negate_v(&lightDirection.vector, &directionToLight);

    double distanceT;
    if ([self isOccluded
            : eyeState->worldHitPoint
                : &directionToLight
                : &lightSourcePoint->worldspace_point
                : &distanceT])
    {
        RELEASE_OBJECT(lightSourcePoint);
        return NO;
    }


    ArNode<ArpVolumeMaterial> * volumeMaterial;
    ArPDFValue eyeForwardPDF_W;
    ArPDFValue eyeReversePDF_W;


    double toLightcosine = fabs(vec3d_vv_dot(
            &eyeState->worldNormal,
            &directionToLight));

    if(![eyeState->worldHitPoint evaluateScattering
            : & directionToLight
            :   arpathdirection_from_eye
            : & sgc
            : & eyeState->incomingWavelength
            : & newWavelength
            : & toLightcosine
            : & volumeMaterial
            : & eyeForwardPDF_W
            : & eyeReversePDF_W
            :   temporaryAttenuation
    ])
    {
        RELEASE_OBJECT(lightSourcePoint);
        return NO;
    };


    float wLight = ARPDFVALUE_MAIN(eyeForwardPDF_W)
                   / (lightPickProbability * ARPDFVALUE_MAIN(directPDF));


//    arpdfvalue_d_mul_p(toLightcosine, &emissionPDF);
//    arpdfvalue_d_mul_p(lightDirection.cosine, &directPDF);
//
//    ArPDFValue ratioED;
//    arpdfvalue_pp_div_p(&emissionPDF, &directPDF, &ratioED);

    double wCamera = ( ARPDFVALUE_MAIN(emissionPDF) * toLightcosine /
                       (lightDirection.cosine * ARPDFVALUE_MAIN(directPDF)) ) *
                     ( pArVcmGlobalValues->VMweight + eyeState->dVCM + eyeState->dVC * ARPDFVALUE_MAIN(eyeReversePDF_W));


    double misWeight = 1.0f / (1.0 + wLight + wCamera);
    double contribLeft = (misWeight * toLightcosine / (lightPickProbability * ARPDFVALUE_MAIN(directPDF)));

    double hwssWeight = [self mis : &eyeState->pathPDF];

    arattenuationsample_a_init_a(art_gv, temporaryAttenuation, connectionSample);
    if(eyeState->totalPathLength > 0)
    {
        arattenuationsample_a_mul_a(art_gv, eyeState->attenuationSample, connectionSample);
    }

    arlightsample_a_mul_l(art_gv, connectionSample, temporaryContribution);

    arlightsample_d_mul_l(art_gv, contribLeft * hwssWeight, temporaryContribution);

    arlightsample_l_init_l(art_gv, temporaryContribution, lightSample);

//    arlightsample_free(art_gv, temporaryContribution);

    RELEASE_OBJECT(lightSourcePoint);

    return YES;
}

- (BOOL) connectVertices
        : (ArPathVertex *) eyeState
        : (ArPathVertex *) lightVertex
        : (ArAttenuationSample *) connectionSample
        : (ArVCMGlobalValues *)        pArVcmGlobalValues
{

    Vec3D direction;
    Vec3D directionTo;

    if(!lightVertex->worldHitPoint)
    {
        return NO;
    }
    vec3d_pp_sub_v(
            &eyeState->worldHitPoint->worldspace_point,
            &lightVertex->worldHitPoint->worldspace_point,
            &direction
    );

    const double dist2 = vec3d_v_sqrlen(&direction);
    const double dist = sqrt(dist2);

    vec3d_norm_v(&direction);
    vec3d_v_negate_v(&direction, &directionTo);

    double distanceT;
    if ([self isOccluded
            : eyeState->worldHitPoint
            : &direction
            : &lightVertex->worldHitPoint->worldspace_point
            : &distanceT])
    {
        return NO;
    }

    double cameraCosine =
            fabs(vec3d_vv_dot(&eyeState->worldNormal,
                              &direction));

    ArWavelength newWavelengthPT;
    ArPDFValue wavelengthPDFPT;
    if( ! [ eyeState->worldHitPoint sampleWavelengthShift
            :   arpathdirection_from_eye
            : & sgc
            :  &eyeState->incomingWavelength
            : & newWavelengthPT
            : & wavelengthPDFPT
    ])
        return NO;

    if(fabs(ARWL_WI(newWavelengthPT, 0) - ARWL_WI(lightVertex->incomingWavelength, 0)) > 10 NM)
        return NO;

    ArNode<ArpVolumeMaterial> * volumeMaterial;
    ArPDFValue eyeForwardPDF_W;
    ArPDFValue eyeReversePDF_W;
    bool validPT = [eyeState->worldHitPoint evaluateScattering
            : & direction
            :   arpathdirection_from_eye
            : & sgc
            : & eyeState->incomingWavelength
            : & newWavelengthPT
            : & cameraCosine
            : & volumeMaterial
            : & eyeForwardPDF_W
            : & eyeReversePDF_W
            :   cvtempSample
    ];

    if (!validPT)
        return NO;

//    if(!ARPDFVALUE_IS_INFINITE(wavelengthPDFPT))
//    {
//        arpdfvalue_p_reverse_concat_p(
//                & wavelengthPDFPT,
//                & eyeForwardPDF_W
//        );
//
//        arpdfvalue_p_reverse_concat_p(
//                & wavelengthPDFPT,
//                & eyeReversePDF_W
//        );
//
//    }


    arpdfvalue_d_mul_p(
            1.f / (2 * 10 NM),
            &eyeForwardPDF_W
    );

    arpdfvalue_d_mul_p(
            1.f / (2 * 10 NM),
            &eyeReversePDF_W
    );

    ArNode<ArpVolumeMaterial> * l_volumeMaterial;
    ArPDFValue lightForwardPDF_W;
    ArPDFValue lightReversePDF_W;

    double lightCosine = fabs(vec3d_vv_dot(&lightVertex->worldNormal, &directionTo));
    bool valid = [lightVertex->worldHitPoint evaluateScattering
            : & directionTo
            :   arpathdirection_from_light
            : & sgc
            : & newWavelengthPT
            : & newWavelengthPT
            : & lightCosine
            : & l_volumeMaterial
            : & lightForwardPDF_W
            : & lightReversePDF_W
            :   cvtempSampleLight
    ];

    if(!valid)
        return NO;

//    NSLog(@"%b", valid);
//    NSLog(@"%f", arattenuationsample_a_max(art_gv, cvtempSampleLight));

    double geometryTerm = (lightCosine * cameraCosine) / dist2;
    if(geometryTerm < 0)
        return NO;

    ardirectattenuationsample_d_mul_a(
            art_gv, 1.0/( 2 * 10 NM),
            cvtempSample->directAttenuation);

    ArPDFValue cameraPdfA = [self PdfWtoA : eyeForwardPDF_W : dist : cameraCosine];
    ArPDFValue lightPdfA = [self PdfWtoA : lightForwardPDF_W : dist : lightCosine];

    double wLight = ARPDFVALUE_MAIN(cameraPdfA) *
                    (pArVcmGlobalValues->VMweight + lightVertex->dVCM + lightVertex->dVC * ARPDFVALUE_MAIN(lightReversePDF_W));

    double wCamera = ARPDFVALUE_MAIN(lightPdfA) *
                     (pArVcmGlobalValues->VMweight + eyeState->dVCM + eyeState->dVC * ARPDFVALUE_MAIN(eyeReversePDF_W));

    double misWeight = 1.0 / (1.0 + wLight + wCamera);


    arattenuationsample_a_mul_a(art_gv, cvtempSample, cvtempSampleLight);

    double hwssWeight = [self mis : &eyeState->pathPDF];
    double hwssWeightLight = [self mis : &lightVertex->pathPDF];

    arattenuationsample_d_mul_a(art_gv, misWeight * geometryTerm * hwssWeight, cvtempSampleLight);



    arattenuationsample_a_init_a(art_gv, cvtempSampleLight, connectionSample);

    return YES;
}

- (bool) getDirectRadiance
        : (ArPathVertex *) currentState
        : (      ArcPointContext *)   originPoint
        : (      ArcIntersection *)   intersection
        : (ArLightSample *) lightSample
{

    ArLightSample * emissionSample_temp = arlightsample_alloc(art_gv);

    double emissionMisWeight = 0;
    bool succ = [ self calculateEmissionContribution
            :  currentState
            :   0
            :   false
            :   originPoint
            :   intersection
            : & currentState->incomingWavelength
            : & currentState->outgoingWavelength
            :   0
            :   0
            :   0
            :   emissionSample_temp
            : & emissionMisWeight
    ];

    if(succ)
    {
        double hwssWeight = [self mis : &currentState->pathPDF];
        if(HERO_SAMPLES_TO_SPLAT == 1)
        {
            hwssWeight = 1;
        }

        if(currentState->totalPathLength > 0)
        {
//            arlightsample_a_mul_l(art_gv, currentState->attenuationSample, emissionSample_temp);
//            arlightsample_d_mul_l(art_gv, (currentState->throughput / ARPDFVALUE_MAIN(currentState->pathPDF)) * emissionMisWeight * hwssWeight, emissionSample_temp);
//            arlightsample_l_add_l(art_gv, emissionSample_temp, lightSample);
        }
        else
        {
            arlightsample_d_mul_l(art_gv, (currentState->throughput / ARPDFVALUE_MAIN(currentState->pathPDF) * hwssWeight), emissionSample_temp);
            arlightsample_l_init_l(art_gv, emissionSample_temp, lightSample);

        }


    }

    arlightsample_free(art_gv, emissionSample_temp);
    return succ;
}


- (bool) traceRayPathTracing
        : (const Ray3D *)               cameraPixelRay
        : (ArNode <ArpCamera>  *)       camera
        : (ArPathVertexptrDynArray *)   lightPathsList
        : (const ArWavelength*)         wavelength
        : (ArPathVertex *)              currentState
        : (uint32_t* )                  pathEnds
        : (      ArLightAlphaSample *)  lightalpha_r
        : (uint32_t )                   pathIndex
        : (ArcHashgrid *)               hashgrid
        : (ArVCMGlobalValues *)         pArVcmGlobalValues

{
    ASSERT_ALLOCATED_LIGHTALPHA_SAMPLE(lightalpha_r);

    ArcIntersection * intersection = 0;
    ArNode<ArpVolumeMaterial> * volumeMaterial =
            ARCSURFACEPOINT_VOLUME_MATERIAL_INSIDE(eyePoint);
    Ray3D cray;
    [camera getCameraRay: &cray];
    ArPDFValue directionSamplingPDF = ARPDFVALUE_UNIT_INFINITY;
    ArPDFValue lightSourceSamplingPartialPDF = ARPDFVALUE_UNIT_INFINITY;
    ArcPointContext* originPoint = eyePoint;
    ArcPointContext<ArpRayEndpoint> * currentPoint;
    ArcIntersection * rayOriginIntersection = 0;

    Ray3D ray = *cameraPixelRay;
    currentState->dVC = 0;
    currentState->dVM = 0;

    currentState->throughput = 1;
    currentState->pathPDF = ARPDFVALUE_ONE;

    bool pushed = false;
    for (unsigned int pathLength = 0; pathLength < 9; pathLength++)
    {

        currentState->totalPathLength = pathLength;
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

        currentState->worldNormal = ARCINTERSECTION_WORLDSPACE_NORMAL(intersection);

        currentState->worldHitPoint = intersection;
        currentState->incomingDirection = intersection->worldspace_incoming_ray.vector;

        if ( [ ARCINTERSECTION_SHAPE(intersection)
                isMemberOfClass
                :   [ ArnInfSphere class ] ] )
        {

            break; // we cannot return from infinite sphere
        }
        //update VCM values
        double cosTheta = fabs([currentPoint getThetaFix]);
        {
            currentState->dVCM *= M_SQR(intersection->t);
            currentState->dVCM /= cosTheta;
            currentState->dVC /= cosTheta;
            currentState->dVM /= cosTheta;
        }
//
        if([self getDirectRadiance
                : currentState
                : originPoint
                : intersection
                : lightalpha_r->light
        ])
        {
            break;
        }
//
//        {
//
//            if([self directIllumination
//                    : currentState
//                    : temporaryContribution
//                    : temporaryMediaAttenuation
//                    : pArVcmGlobalValues
//            ])
//            {
//                arlightsample_d_mul_l(art_gv,
//                                      currentState->throughput,
//                                      temporaryContribution);
//
//                arlightsample_d_div_l(art_gv, ARPDFVALUE_MAIN(currentState->pathPDF), temporaryContribution);
//
//                arlightsample_l_add_l(art_gv, temporaryContribution, lightalpha_r->light);
//            }
//
//        }


//        uint32_t rangeX, rangeY;
//        rangeX = 0;
//
//        if(pathIndex > 0)
//        {
//            rangeX = pathEnds[pathIndex - 1];
//
//        }
//        rangeX;
//        rangeY = pathEnds[pathIndex];

        for (uint32_t i = pathIndex; i < arpvptrdynarray_size(lightPathsList); ++i)
        {

            ArPathVertex *lightVertex = arpvptrdynarray_i(lightPathsList, i);
//
//            int res = arwavelength_ww_equal_ranged(art_gv, &lightVertex.outgoingWavelength, &currentState->incomingWavelength);
//
//            if(!res)
//            {
//                continue;
//            }

            if(lightVertex->totalPathLength + pathLength + 1 > 16)
                break;

            if([self connectVertices
                    : currentState
                    : lightVertex
                    : connectionSampleConnection
                    : pArVcmGlobalValues
            ])
            {
                double weight = (currentState->throughput / ARPDFVALUE_MAIN(currentState->pathPDF))
                                * (lightVertex->throughput / ARPDFVALUE_MAIN(lightVertex->pathPDF));

                if(pathLength > 0)
                {
                    arattenuationsample_a_mul_a(art_gv, currentState->attenuationSample, connectionSampleConnection);
                }

                if(lightVertex->totalPathLength > 0)
                {
                    arattenuationsample_a_mul_a(art_gv, lightVertex->attenuationSample, connectionSampleConnection);
                }


                arattenuationsample_d_mul_a(art_gv,
                                            weight,
                                            connectionSampleConnection);

                arlightsample_l_init_l(art_gv,
                                       lightVertex->lightSample->light,
                                       lightSampleConnection);

//                NSLog(@"%f", arattenuationsample_a_max(art_gv, connectionSampleConnection));

//                arattenuationsample_d_init_a(art_gv, 1.0f, connectionSampleConnection);


                arlightsample_a_mul_l(art_gv,
                                      connectionSampleConnection,
                                      lightSampleConnection);

                arlightsample_l_add_l(art_gv,
                                      lightSampleConnection,
                                      lightalpha_r->light);

            }
        }

        currentState->incomingWavelength = currentState->outgoingWavelength;

        if(pathLength + 1< 9) {
            double cos;
            //conduct random walk step, generating new ray and wavelength
            if (![self randomWalkPT
                    :currentPoint
                    :0
                    :&currentState->incomingWavelength // passes in the current wavelength
                    :&currentState->outgoingWavelength // stores the new wavelength
                    :&directionSamplingPDF
                    :&lightSourceSamplingPartialPDF
                    :&ray
                    :&volumeMaterial
                    :temporaryAttenuation
                    :&cos
                    :currentState
                    :pArVcmGlobalValues

            ]) {
                break;
            }

            if (pathLength == 0) {
                currentState->attenuationSample = arattenuationsample_alloc(art_gv);
                arattenuationsample_a_init_a(art_gv, temporaryAttenuation, currentState->attenuationSample);
            } else {
                arattenuationsample_a_mul_a(art_gv,
                                            temporaryAttenuation,
                                            currentState->attenuationSample);
            }

            arpdfvalue_p_concat_p(&directionSamplingPDF, &currentState->pathPDF);
            currentState->throughput *= cos;

            if (rayOriginIntersection)
            {
                [INTERSECTION_FREELIST releaseInstance
                :rayOriginIntersection
                ];
                rayOriginIntersection = 0;
            }

            rayOriginIntersection = intersection;
            intersection = 0;

            originPoint = currentPoint;
        }
    }


    if( rayOriginIntersection )
    {
        RELEASE_OBJECT(rayOriginIntersection);
    }

    if ( intersection )
    {
        RELEASE_OBJECT(intersection);
    }
}

- (bool) traceRay
        : (ART_GV*)                     gv
        : (const Ray3D *)               cameraPixelRay
        : (ArNode <ArpCamera>  *)       camera
        : (ArPathVertexptrDynArray *)   lightPathsList
        : (const ArWavelength*)         wavelength
        : (uint32_t* )                  pathEnds
        : (uint32_t )                   pathIndex
        : (      ArLightAlphaSample *)  lightalpha_r
        : (ArVCMGlobalValues *)        pArVcmGlobalValues

{
    ASSERT_VALID_WAVELENGTH(wavelength);
    // initial ra
    ArcIntersection * rayOriginIntersection = 0;
    ArcIntersection * intersection = 0; // outside of loop for easier early termination of loop
    ArcRayEndpoint * scatteringEvent = 0; // outside of loop for easier early termination of loop
    // initial volume
    ArNode<ArpVolumeMaterial> * volumeMaterial =
            ARCSURFACEPOINT_VOLUME_MATERIAL_INSIDE(eyePoint);

    ArAttenuationSample *temporaryMediaAttenuation = arattenuationsample_alloc(gv);
//    ArPDFValue pathPDF = ARPDFVALUE_UNIT_INFINITY;
    ArPDFValue directionSamplingPDF = ARPDFVALUE_UNIT_INFINITY;
    ArPDFValue lightSourceSamplingPartialPDF = ARPDFVALUE_UNIT_INFINITY;

    ArcSurfacePoint * incomingSourcePoint;
    ArDirectionCosine incomingDirection = ARDIRECTIONCOSINE(VEC3D_INVALID, 0);
    ArSamplingRegion samplingRegion;

    ArWavelength currentWavelength = *wavelength;
    ArWavelength previousWavelength = currentWavelength;

    ArLightAlphaSample lightAlphaSample;

    ArPDFValue emitPDF;
    ArPDFValue directPDF;

    arlightsample_d_init_unpolarised_l(art_gv, 0.0, initialLightSample);

    if( ![ LIGHTSOURCE_COLLECTION generateRandomDirection
            : & lssc
            : & samplingRegion
            : & incomingSourcePoint
            : & incomingDirection
            : & emitPDF /* optional */
            : & directPDF
            : & currentWavelength
            :   initialLightSample
    ])
    {
        return NO;
    }

    ARLIGHTALPHASAMPLE_LIGHT(lightAlphaSample) = initialLightSample;
    ARLIGHTALPHASAMPLE_ALPHA(lightAlphaSample) = 1.0f;
    Ray3D ray;

    RAY3D_P(ray) = ARCSURFACEPOINT_WORLDSPACE_POINT(incomingSourcePoint);
    RAY3D_V(ray) = ARDIRECTIONCOSINE_VECTOR(incomingDirection);

    bool shouldBreak = false;

    int lastNonzeroIndex = -1;

    Vec3D intersectionNormal;
    Vec3D originNormal = ARCINTERSECTION_WORLDSPACE_NORMAL(incomingSourcePoint);

    ArcPointContext* originPoint =  incomingSourcePoint;
    bool gotPushed = false;

    ArSubPathStateMin currentSubPathState;

    unsigned int pathLength = 0;

    for(; pathLength < 9; ++pathLength)
    {
        gotPushed = false;
        if(pathLength == 0)
        {
            currentSubPathState.pathPDF = emitPDF;
            currentSubPathState.throughput = incomingDirection.cosine;
//
            //UPDATE THE VERTEX CONNECTION and VCM VALUES
            currentSubPathState.dVC = incomingDirection.cosine / ARPDFVALUE_MAIN(emitPDF);

            ArPDFValue vcm;
//            arpdfvalue_pp_div_p(&lightSourcePDF, &currentState->pathPDF, &vcm);
            currentSubPathState.dVCM = ARPDFVALUE_MAIN(directPDF) / ARPDFVALUE_MAIN(emitPDF);

            currentSubPathState.dVM = currentSubPathState.dVC * pArVcmGlobalValues->VCweight;

            arlightsample_l_init_l(gv, initialLightSample, generatedLightSample);

        }

        intersection =
                [ RAYCASTER firstRayObjectIntersection
                        :   entireScene
                        :   originPoint
                        : & ray
                        :   MATH_HUGE_DOUBLE
                ];

        ArcPointContext<ArpRayEndpoint> * currentPoint = intersection;

        if(! intersection)
        {
            shouldBreak = true;
            break;
        }

        [ currentPoint prepareForUse: PHASE_INTERFACE_CACHE ];

//        ArSamplingRegion lightSamplingRegion;
//        ArLightSample *temporaryEmission = arlightsample_alloc(gv);
//        ArNode * emitter;
//        if( [ self getEmission
//                :   originPoint
//                :   intersection
//                :   &currentWavelength
//                : & emitter
//                : & lightSamplingRegion
//                :   temporaryEmission
//        ] )
//        {
//            shouldBreak = true;
//            arlightsample_free(gv, temporaryEmission);
//            break;
//        }
//        arlightsample_free(gv, temporaryEmission);
//        arpdfvalue_p_reverse_concat_p(&distanceProbability, &currentState->pathPDF);

        intersectionNormal = ARCINTERSECTION_WORLDSPACE_NORMAL(intersection);
        originNormal = intersectionNormal;

        if ( [ ARCINTERSECTION_SHAPE(intersection)
                isMemberOfClass
                :   [ ArnInfSphere class ] ] )
        {

            shouldBreak = true;
            break; // we cannot return from infinite sphere
        }

        //UPDATE VCM values
        double cosTheta = [intersection getThetaFix];
        {
            currentSubPathState.dVCM *= M_SQR(intersection->t);

            currentSubPathState.dVCM /= cosTheta;
            currentSubPathState.dVM /= cosTheta;
            currentSubPathState.dVC /= cosTheta;
        }

        ArPathVertex * lightVertex = ALLOC(ArPathVertex);
        lightVertex->incomingDirection = intersection->worldspace_incoming_ray.vector;

        lightVertex->pathPDF = currentSubPathState.pathPDF;
        lightVertex->throughput = currentSubPathState.throughput;
        lightVertex->lightSample = arlightalphasample_alloc(gv);
        arlightsample_l_init_l(gv, generatedLightSample, lightVertex->lightSample->light);
        lightVertex->lightSample->alpha = 1.0f;
        lightVertex->cameraLightSample = arlightalphasample_alloc(gv);
        lightVertex->cameraLightSample->alpha = 1.0f;

        lightVertex->worldHitPoint = intersection;

        if(pathLength > 0)
        {
            lightVertex->attenuationSample = arattenuationsample_alloc(gv);
            arattenuationsample_a_init_a(gv, pathAttenuation, lightVertex->attenuationSample);
        }

        lightVertex->totalPathLength = pathLength;

        lightVertex->dVCM = currentSubPathState.dVCM;
        lightVertex->dVC = currentSubPathState.dVC;
        lightVertex->dVM = currentSubPathState.dVM;
        lightVertex->incomingWavelength = previousWavelength;

        [self connectToCamera
                : gv
                : intersection
                : camera
                : &currentSubPathState
                : lightVertex
                : intersection
                : pathLength
                :& currentWavelength
                : pArVcmGlobalValues
        ];

        arpvptrdynarray_push(lightPathsList, lightVertex);
        gotPushed = true;

        // continue only if there is a possibility to encounter any more light samples
        {
            previousWavelength = currentWavelength;
            bool continueExploring = true;
            double cos;
            ArAttenuationSample *temporaryAttenuation2 = arattenuationsample_alloc(gv);
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
                    : temporaryAttenuation2
                    : & cos
                    : &currentSubPathState
                    : pArVcmGlobalValues

            ] )
            {
                continueExploring = false;
            }

            if(continueExploring)
            {
                lightVertex->outgoingWavelength = currentWavelength;
                if(pathLength == 0)
                {
                    arattenuationsample_a_init_a(gv, temporaryAttenuation2, pathAttenuation);
                }
                else
                {
                    arattenuationsample_a_mul_a(gv,
                                                temporaryAttenuation2,
                                                pathAttenuation);
                }

                arpdfvalue_p_concat_p(&directionSamplingPDF, &currentSubPathState.pathPDF);
                currentSubPathState.throughput *= cos;

            }

            arattenuationsample_free(gv, temporaryAttenuation2);


            if(!continueExploring)
            {
                shouldBreak = true;
                break;
            }


            originPoint = currentPoint;
        }


    }

    RELEASE_OBJECT(incomingSourcePoint);
    pathEnds[pathIndex] = arpvptrdynarray_size(lightPathsList);

    arattenuationsample_free(gv, temporaryMediaAttenuation);

    if(shouldBreak && !gotPushed)
    {
        if(intersection)
        {
            RELEASE_OBJECT(intersection);
            intersection = 0;
        }

    }

    if(!gotPushed)
    {
        if(intersection)
        {
            RELEASE_OBJECT(intersection);
            intersection = 0;
        }

    }

    // release any leftover intersections or ray endpoints
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

- (void) evaluatePhotonMaps
        : (ART_GV *)                    gv
        : (const Ray3D *)               cameraPixelRay
        : (ArPathVertex *)              currentState
        : (ArLightAlphaSample *)        lightalpha_r
        : (ArcHashgrid *)               hashgrid
        : (ArPathVertexptrDynArray *)   lightPathsList
        : (ArVCMGlobalValues *)         pArVcmGlobalValues
{
    ASSERT_ALLOCATED_LIGHTALPHA_SAMPLE(lightalpha_r);

    ArcIntersection * intersection = 0;
    ArNode<ArpVolumeMaterial> * volumeMaterial =
            ARCSURFACEPOINT_VOLUME_MATERIAL_INSIDE(eyePoint);
    ArPDFValue directionSamplingPDF = ARPDFVALUE_UNIT_INFINITY;
    ArPDFValue lightSourceSamplingPartialPDF = ARPDFVALUE_UNIT_INFINITY;
    ArcPointContext* originPoint = eyePoint;
    ArcPointContext<ArpRayEndpoint> * currentPoint;
    ArcIntersection * rayOriginIntersection = 0;

    Ray3D ray = *cameraPixelRay;
    currentState->dVC = 0;
    currentState->dVM = 0;

    currentState->throughput = 1;
    currentState->pathPDF = ARPDFVALUE_ONE;

    bool pushed = false;
    for (unsigned int pathLength = 0; pathLength < 9; pathLength++)
    {

        currentState->totalPathLength = pathLength;
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

        currentState->worldNormal = ARCINTERSECTION_WORLDSPACE_NORMAL(intersection);

        currentState->worldHitPoint = intersection;
        currentState->incomingDirection = intersection->worldspace_incoming_ray.vector;

        if ( [ ARCINTERSECTION_SHAPE(intersection)
                isMemberOfClass
                :   [ ArnInfSphere class ] ] )
        {

            break; // we cannot return from infinite sphere
        }
        //update VCM values
        double cosTheta = fabs([currentPoint getThetaFix]);
        if(cosTheta > 0)
        {
            currentState->dVCM *= M_SQR(intersection->t);
            currentState->dVCM /= cosTheta;
            currentState->dVC /= cosTheta;
            currentState->dVM /= cosTheta;
        }
        else
        {
            break;
        }

        {
            ArLightAlphaSample* vmContribution = arlightalphasample_alloc(gv);
            arlightsample_d_init_unpolarised_l(gv, 0.0, vmContribution->light);

            if([hashgrid Process: currentState : intersection->worldspace_point : lightPathsList : vmContribution : &sgc : gv])
            {

                double hwssWeight = [self mis : &currentState->pathPDF];
                arlightsample_d_mul_l(gv, currentState->throughput * hashgrid->vmNormalization * hwssWeight, vmContribution->light);
                arlightsample_d_div_l(gv, ARPDFVALUE_MAIN(currentState->pathPDF), vmContribution->light);
//
                if(currentState->totalPathLength > 0)
                {
                    arlightsample_a_mul_l(gv, currentState->attenuationSample, vmContribution->light);
                }


                arlightsample_l_add_l(gv, vmContribution->light, lightalpha_r->light);
            }

            arlightalphasample_free(gv, vmContribution);
        }

        currentState->incomingWavelength = currentState->outgoingWavelength;

        if( pathLength + 1< 9) {
            double cos;
            //conduct random walk step, generating new ray and wavelength
            if (![self randomWalkPT
                    :currentPoint
                    :0
                    :&currentState->incomingWavelength // passes in the current wavelength
                    :&currentState->outgoingWavelength // stores the new wavelength
                    :&directionSamplingPDF
                    :&lightSourceSamplingPartialPDF
                    :&ray
                    :&volumeMaterial
                    :temporaryAttenuation
                    :&cos
                    :currentState
                    :pArVcmGlobalValues

            ]) {
                break;
            }

            if (pathLength == 0) {
                currentState->attenuationSample = arattenuationsample_alloc(gv);
                arattenuationsample_a_init_a(gv, temporaryAttenuation, currentState->attenuationSample);
            } else {
                arattenuationsample_a_mul_a(gv,
                                            temporaryAttenuation,
                                            currentState->attenuationSample);
            }

            arpdfvalue_p_concat_p(&directionSamplingPDF, &currentState->pathPDF);
            currentState->throughput *= cos;

            if (rayOriginIntersection)
            {
                [INTERSECTION_FREELIST releaseInstance
                :rayOriginIntersection
                ];
                rayOriginIntersection = 0;
            }

            rayOriginIntersection = intersection;
            intersection = 0;

            originPoint = currentPoint;
        }
    }


    if( rayOriginIntersection )
    {
        RELEASE_OBJECT(rayOriginIntersection);
    }

    if ( intersection )
    {
        RELEASE_OBJECT(intersection);
    }
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
