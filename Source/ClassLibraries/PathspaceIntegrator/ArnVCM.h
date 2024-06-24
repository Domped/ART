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

ART_MODULE_INTERFACE(ArnVCM)

#import "ART_Scenegraph.h"
#import "ArnPathspaceIntegrator.h"

#define VCM_MAX_SCATTERING_EVENTS    128

typedef enum ArVCMMode
{
    arvcmmode_lt         = 0x01,
    arvcmmode_vc         = 0x02,
    arvcmmode_vm         = 0x04,
    arvcmmode_vcm        = arvcmmode_vc | arvcmmode_vm
} ArVCMMode;

@interface ArnVCM
: ArnPathspaceIntegrator
< ArpConcreteClass, ArpCoding >
{
    ArVCMMode       mode;

// temporary samples that are used throughout methods to compute
// the final results for that step/approach
    ArAttenuationSample  * temporaryAttenuation;
    ArAttenuationSample  * temporaryMediaAttenuation;
    ArLightSample        * temporaryContribution;
    ArLightSample        * temporaryMediaContribution;

    ArLightSample *tempEmissionSample;
    ArLightSample *lightSampleConnection;
    ArLightSample *initialLightSample;
    ArLightSample *generatedLightSample;
    ArAttenuationSample *pathAttenuation;

    ArAttenuationSample *connectionSampleConnection;

    ArAttenuationSample *cvtempSample;

    ArAttenuationSample *cvtempSampleLight;

    ArAttenuationSample *actuallyUsedAttenuation;
    ArLightSample *actuallyUsedLightSample;

    double wavelengthMollifierParameter;
// stores the intermediate results at individual path steps
// the final result is computed as L_0, with

}

- (id) init
        : (ArNode <ArpRayCaster> *) newRayCaster
        : (unsigned int) newMaximalRecursion
        : (ArVCMMode) newMode
        : (ArDistanceTrackingMode) newDistanceTrackingMode
        ;
@end

// ===========================================================================
