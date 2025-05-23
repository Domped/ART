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

#define ART_LIBRARY_NAME     ART_ImageSampler

#import "ART_ImageSampler.h"

ART_LIBRARY_INITIALISATION_FUNCTION
(
    ART_PERFORM_MODULE_INITIALISATION( ArnReconstructionKernel )
 
    ART_PERFORM_MODULE_INITIALISATION( ArnImageSamplerBase )
    ART_PERFORM_MODULE_INITIALISATION( ArnImageSampler )
    ART_PERFORM_MODULE_INITIALISATION( ArnStochasticImageSampler )
    ART_PERFORM_MODULE_INITIALISATION ( ArnStochasticBackwardsSampler)
    ART_PERFORM_MODULE_INITIALISATION( ArnMidpointImageSamplerRGBA )
    ART_PERFORM_MODULE_INITIALISATION( ArnStochasticImageSamplerRGBA )

    ART_PERFORM_MODULE_INITIALISATION( ArnStochasticSampler )

    ART_PERFORM_MODULE_INITIALISATION( ArnStochasticSamplerVerticalMirror )
)

ART_AUTOMATIC_LIBRARY_SHUTDOWN_FUNCTION


// ===========================================================================
