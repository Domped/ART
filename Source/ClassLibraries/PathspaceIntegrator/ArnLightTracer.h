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

#include "ART_Foundation.h"

ART_MODULE_INTERFACE(ArnLightTracer)

#import "ART_Scenegraph.h"
#import "ArnPathspaceIntegrator.h"

#define LIGHTTRACER_MAX_SCATTERING_EVENTS    128

#define LT_ATTENUATIONS_ARRAY_LENGTH   LIGHTTRACER_MAX_SCATTERING_EVENTS + 1
#define LT_CONTRIBUTIONS_ARRAY_LENGTH  LIGHTTRACER_MAX_SCATTERING_EVENTS + 1

typedef enum ArLightTracerMode
{
    arlighttracermode_uni         = 0x01
} ArLightTracerMode;

@interface ArnLightTracer
: ArnPathspaceIntegrator
< ArpConcreteClass, ArpCoding >
{
    ArLightTracerMode       mode;

// temporary samples that are used throughout methods to compute
// the final results for that step/approach
ArAttenuationSample  * temporaryAttenuation;
ArAttenuationSample  * temporaryMediaAttenuation;
ArLightSample        * temporaryContribution;
ArLightSample        * temporaryMediaContribution;

ArLightSample *tempEmissionSample;
ArLightSample *lightSampleConnection;

ArAttenuationSample *connectionSampleConnection;

ArAttenuationSample *cvtempSample;

ArAttenuationSample *cvtempSampleLight;
// stores the intermediate results at individual path steps
// the final result is computed as L_0, with
//     L_i = C_i + M_i * A_i * L_(i+1)
ArAttenuationSample  * allAttenuations[LT_ATTENUATIONS_ARRAY_LENGTH]; // A_i
ArAttenuationSample  * allMediaAttenuations[LT_ATTENUATIONS_ARRAY_LENGTH]; // M_i
ArLightSample        * allContributions[LT_CONTRIBUTIONS_ARRAY_LENGTH]; // C_i

// indicates, whether the M_i is something else than a free transmission
//    - if it isn't, the actual value of allMediaAttenuations[i] is undefined
//        and should not be used
unsigned int    nonclearMediaAttenuations[LT_ATTENUATIONS_ARRAY_LENGTH];
// indicates, whether the C_i is something else than a zero contribution
//    - if it isn't, the actual value of allContributions[i] is undefined
//        and should not be used
unsigned int    nonzeroContributions[LT_CONTRIBUTIONS_ARRAY_LENGTH];
    int DEBUG_PL;


    int DEBUG_COUNT_RADIANCE;
}

- (id) init
: (ArNode <ArpRayCaster> *) newRayCaster
: (unsigned int) newMaximalRecursion
: (ArDistanceTrackingMode) newDistanceTrackingMode
;

@end

// ===========================================================================
