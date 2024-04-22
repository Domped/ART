
#define ART_MODULE_NAME     ArPathVertex

#include "ArPathVertex.h"
#import "ArcPointContext.h"
#import "ArpRayEndpoint.h"

ART_NO_MODULE_INITIALISATION_FUNCTION_NECESSARY
ART_NO_MODULE_SHUTDOWN_FUNCTION_NECESSARY

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

    RELEASE_OBJECT(pv.worldHitPoint);
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

void arpv_free_arr_itrsc(const ART_GV  * art_gv, ArPathVertexDynArray *arr)
{
    ArPathVertex pv = arpvdynarray_i(arr, 0);

    if(pv.attenuationSample)
    {
        arattenuationsample_free(art_gv, pv.attenuationSample);
    }

    pv = arpvdynarray_i(arr, 1);
    if(pv.lightSample)
    {
        arlightalphasample_free(art_gv, pv.lightSample);
    }


    return;

    pv = arpvdynarray_i(arr, 5);
    if(pv.attenuationSample)
    {
        arattenuationsample_free(art_gv, pv.attenuationSample);
    }


    unsigned int size = arpvdynarray_size(arr);

    for (unsigned int i = 0; i < size; i++)
    {
        if(i == 2)
            continue;

        ArPathVertex pv = arpvdynarray_i(arr, i);

//        pv.worldHitPoint = 0;

//        NSLog(@"Freeing PathVertex");

        if(pv.lightSample)
        {

        }

        if(pv.attenuationSample)
        {
            arattenuationsample_free(art_gv, pv.attenuationSample);
        }

    }
}