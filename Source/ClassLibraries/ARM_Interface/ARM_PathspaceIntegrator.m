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

#define ART_MODULE_NAME     ARM_PathspaceIntegrator

#import "ARM_PathspaceIntegrator.h"

ART_NO_MODULE_INITIALISATION_FUNCTION_NECESSARY

ART_NO_MODULE_SHUTDOWN_FUNCTION_NECESSARY


@implementation ArnFirstHitNormalShadingTracer ( ARM_Interface )

- (id) rayCaster
                        : (ArNode <ArpRayCaster> *) newRayCaster
{
    return
        [ self init
            :   newRayCaster
            ];
}

@end

@implementation ArnPathTracer ( ARM_Interface )

- (id) rayCaster: (ArNode <ArpRayCaster> *) newRayCaster
        maximalRecursion: (unsigned int) newMaximalRecursion
{

    return
        [ self init
            :   newRayCaster
            :   newMaximalRecursion
            :   arpathtracermode_mis
            :   ardistancetrackingmode_scattering_aware
            ];
}

- (id) rayCaster: (ArNode <ArpRayCaster> *) newRayCaster
        maximalRecursion: (unsigned int) newMaximalRecursion
        mode            : (ArPathTracerMode) newMode
{
    return
        [ self init
            :   newRayCaster
            :   newMaximalRecursion
            :   newMode
            :   ardistancetrackingmode_scattering_aware
            ];
}

- (id) rayCaster
                        : (ArNode <ArpRayCaster> *) newRayCaster
        maximalRecursion: (unsigned int) newMaximalRecursion
        mode            : (ArPathTracerMode) newMode
        distanceTracking: (ArDistanceTrackingMode) newDistanceTrackingMode
{
    return
        [ self init
            :   newRayCaster
            :   newMaximalRecursion
            :   newMode
            :   newDistanceTrackingMode
            ];
}

@end

@implementation ArnLightTracer ( ARM_Interface )

- (id) rayCaster
                : (ArNode <ArpRayCaster> *) newRayCaster
maximalRecursion: (unsigned int) newMaximalRecursion
{
    return
            [ self init
                    :   newRayCaster
                    :   newMaximalRecursion
                    :   arpathtracermode_mis
                    :   ardistancetrackingmode_scattering_aware
            ];
}

@end


@implementation ArnVCM (ARM_Interface)

- (id) rayCaster        : (ArNode <ArpRayCaster> *) newRayCaster
       maximalRecursion : (unsigned int)            newMaximalRecursion
       mode             : (ArVCMMode)               newMode
{

    return
            [ self init
                    :   newRayCaster
                    :   newMaximalRecursion
                    :   mode
                    :   ardistancetrackingmode_scattering_aware
            ];
}

@end

@implementation ArnSimplePathTracer

- (id) rayCaster             : (ArNode <ArpRayCaster> *) newRayCaster
        maximalRecursion: (unsigned int) newMaximalRecursion
{
    return
        [ self init
             :   newRayCaster
             :   newMaximalRecursion
             :   arpathtracermode_direction_sampling
             :   ardistancetrackingmode_scattering_aware
             ];
}

@end

// ===========================================================================
