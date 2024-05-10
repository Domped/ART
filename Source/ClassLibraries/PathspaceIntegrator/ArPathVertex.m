
#define ART_MODULE_NAME     ArPathVertex

#include "ArPathVertex.h"
#import "ArcPointContext.h"
#import "ArpRayEndpoint.h"

ART_NO_MODULE_INITIALISATION_FUNCTION_NECESSARY
ART_NO_MODULE_SHUTDOWN_FUNCTION_NECESSARY

@implementation ArPV

- (void) dealloc
{

    [super dealloc];
}

@end;

ArPathVertex _pv_retain(
        ArPathVertex pv
)
{
    return pv;
}

ArPathVertex _pv_release(
        ArPathVertex pv
)
{

//    RELEASE_OBJECT(pv.worldHitPoint);
//    if(pv.attenuationSample)
//        arattenuationsample_free(pv.art_gv, pv.attenuationSample);


//    [pv.worldHitPoint dealloc];
    return pv;
}


ARDYNARRAY_IMPLEMENTATION_FOR_MANAGED_TYPE(
        ArPathVertex,PathVertex,pv,pv, ARPV_EMPTY,
        _pv_retain,,_pv_release
);

ARDYNARRAY_IMPLEMENTATION_FOR_ARTYPE_PTR(PathVertex,pv,pv,0);


void arpv_free_pv(const ART_GV *art_gv, ArPathVertex *pv)
{
    if(pv->lightSample && arlightalphasample_l_valid(art_gv, pv->lightSample))
    {
        arlightalphasample_free(art_gv, pv->lightSample);
        pv->lightSample = 0;
    }

//    if(pv->cameraLightSample)
//    {
//        arlightalphasample_free(art_gv, pv->cameraLightSample);
//        pv->cameraLightSample = 0;
//    }

    if(pv->attenuationSample && pv->totalPathLength)
    {
        arattenuationsample_free(art_gv, pv->attenuationSample);
        pv->attenuationSample = 0;
    }

    if(pv->worldHitPoint)
    {
        RELEASE_OBJECT(pv->worldHitPoint);
        pv->worldHitPoint = 0;
    }

}
void arpv_free_arr_itrsc(const ART_GV  * art_gv, ArPathVertexptrDynArray *arr)
{
    unsigned int size = arpvptrdynarray_size(arr);

    for (unsigned int i = 0; i < size; i++)
    {

        ArPathVertex *pv = arpvptrdynarray_i(arr, i);

        arpv_free_pv(art_gv, pv);
        FREE(pv);
        pv = 0;
    }
}

ArPathVertex* arpv_alloc(const ART_GV *art_gv)
{
    ArPathVertex *pv = ALLOC(ArPathVertex);

    pv->lightSample = 0;
    pv->cameraLightSample = 0;
    pv->attenuationSample = 0;
    pv->worldHitPoint = 0;

    return pv;
}