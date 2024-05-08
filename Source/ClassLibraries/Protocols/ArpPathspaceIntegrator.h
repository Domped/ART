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

ART_MODULE_INTERFACE(ArpPathspaceIntegrator)

#import "ART_MiscellaneousStructs.h"
#import "ArpPathspaceIntegratorCore.h"
#import "ArPathVertex.h"
#import "ArcHashgrid.h"

@protocol ArpCamera;

@protocol ArpPathspaceIntegrator <ArpPathspaceIntegratorCore>

- (void) setGatheringResultFreelist
        : (ArFreelist *) newGatheringResultFreelist
        ;

- (int) numberOfSeparateEstimates
        ;

- (void) calculateLightSamples
        : (const Ray3D *)               sampling_ray
        : (const ArWavelength *)        wavelength
        : (      ArPathspaceResult **)  result
        ;

- (void) generateLightPaths
        : (ArNode <ArpCamera>  *)      sampling_ray
        : (ArPathVertexDynArray *)     lightPathsList
        : (const ArWavelength *)       wavelength
        ;

- (void) generateLightPaths
        : (const Ray3D *)              cameraPixelRay
        : (ArNode <ArpCamera>  *)      sampling_ray
        : (ArPathVertexDynArray *)     lightPathsList
        : (const ArWavelength *)       wavelength
        ;

- (void) generateLightPaths
        : (const Ray3D *)              cameraPixelRay
        : (ArNode <ArpCamera>  *)      sampling_ray
        : (ArPathVertexDynArray *)     lightPathsList
        : (const ArWavelength *)       wavelength
        : (ArLightAlphaSample *)       tempLightSample
        : (ArVCMGlobalValues *)        pArVcmGlobalValues
        ;

- (void) generateLightPaths
        : (const Ray3D *)              cameraPixelRay
        : (ArNode <ArpCamera>  *)      sampling_ray
        : (ArPathVertexptrDynArray *)  lightPathsList
        : (const ArWavelength *)       wavelength
        : (uint32_t* )                 pathEnds
        : (uint32_t )                  pathIndex
        : (ArLightAlphaSample *)       lightalpha_r
        : (ArVCMGlobalValues *)        pArVcmGlobalValues
;

- (void) generateLightPaths
        : (ART_GV *)                   art_gv
        : (const Ray3D *)              cameraPixelRay
        : (ArNode <ArpCamera>  *)      sampling_ray
        : (ArPathVertexptrDynArray *)     lightPathsList
        : (const ArWavelength *)       wavelength
        : (uint32_t* )                 pathEnds
        : (uint32_t )                  pathIndex
        : (ArLightAlphaSample *)       lightalpha_r
        : (ArVCMGlobalValues *)        pArVcmGlobalValues
;



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
        : (ArVCMGlobalValues *)         pArVcmGlobalValues
        ;

@end

// ===========================================================================
