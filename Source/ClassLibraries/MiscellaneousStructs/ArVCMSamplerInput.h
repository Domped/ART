//
// Created by domped on 4.6.24.
//
#include "ART_Foundation.h"
#include "ArPathVertex.h"
#include "ArcUnsignedInteger.h"

ART_MODULE_INTERFACE(ArcVCMSamplerInput)

typedef struct ArcVCMSamplerInput
{
    ArcUnsignedInteger* threadIndex;
    ArPathVertexptrDynArray *lightPaths;
} ArcVCMSamplerInput;
