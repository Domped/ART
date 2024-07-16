//
// Created by domin on 28.11.2023.
//

#import "ArPDFValue.h"
#import "ArcPointContext.h"
#import "ArpRayEndpoint.h"

@class ArcIntersection;

ART_MODULE_INTERFACE(ArPathVertex)


@interface ArPV
        : ArcObject {
@public

    ArcIntersection *worldHitPoint;

//    ArcRayEndpoint *worldHitPoint;
//    ArcPointContext<ArpRayEndpoint> *worldHitPoint;



    uint totalPathLength;

    //TODO: BRDF?

    double throughput;
    ArLightAlphaSample *lightSample;
    ArAttenuationSample *attenuationSample;
//    ArAttenuationSample* mediaAttenuationSample;

    ArLightAlphaSample *cameraLightSample;
//    ArAttenuationSample* cameraDirectionAttenuationSample;

    //TODO: SPECTRA
    double basicPDF;
    double misVCM;
    double misBPT;

    ArPDFValue cameraConnectionPDF;
    ArPDFValue pathPDF;

    ArWavelength incomingWavelength;
    ArWavelength outgoingWavelength;
    ArWavelength cameraWavelength;

    bool occluded;

    double cameraThroughput;
    unsigned int isClearMediaAttenuation;

    bool isEND;

    double dVCM;
    double dVC;
    double dVM;
    Vec3D worldNormal;

    Vec3D incomingDirection;
}
@end;



typedef struct ArVCMGlobalValues
{

    double vmNormalization;
    double VMweight;
    double VCweight;

} ArVCMGlobalValues;

typedef struct ArPathVertex
{

    ArcIntersection* worldHitPoint;

//    ArcRayEndpoint *worldHitPoint;
//    ArcPointContext<ArpRayEndpoint> *worldHitPoint;



    uint totalPathLength;

    double throughput;
    ArLightAlphaSample* lightSample;
    ArAttenuationSample* attenuationSample;
//    ArAttenuationSample* mediaAttenuationSample;

    ArLightAlphaSample* cameraLightSample;
//    ArAttenuationSample* cameraDirectionAttenuationSample;

    double basicPDF;
    double misVCM;
    double misBPT;

    ArPDFValue cameraConnectionPDF;
    ArPDFValue pathPDF;

    ArWavelength incomingWavelength;
    ArWavelength outgoingWavelength;
    ArWavelength cameraWavelength;
    
    bool occluded;
    
    double cameraThroughput;
    unsigned int isClearMediaAttenuation;
    
    bool isEND;

    double dVCM;
    double dVC;
    double dVM;
    Vec3D worldNormal;

    Vec3D incomingDirection;

    ArWavelength initialWavelength;

    bool isSpecular;
}

ArPathVertex;

typedef struct ArSubPathStateMin
{
    double dVCM;
    double dVC;
    double dVM;

    double throughput;
    ArPDFValue pathPDF;

} ArSubPathStateMin;

#define ARPV_HITPOINT(__pv)  (__pv).worldHitPoint
#define ARPV_PATHLENGTH(__pv)  (__pv).totalPathLength
#define ARPV_LIGHTSAMPLE(__pv) (__pv).lightSample
#define ARPV_ATTENUATIONSAMPLE(__pv) (__pv).attenuationSample
#define ARPV_THROUGHPUT(__pv)  (__pv).throughput
#define ARPV_PATHPDF(__pv)  (__pv).pathPDF
#define ARPV_BASICPDF(__pv)  (__pv).basicPDF
#define ARPV_MISVCM(__pv)  (__pv).misVCM
#define ARPV_MISBPT(__pv)  (__pv).misBPT
#define ARPV_CAMERAPDF(__pv)  (__pv).cameraConnectionPDF
#define ARPV_CAMERAATTEN(_pv)  (_pv).cameraDirectionAttenuationSample
#define ARPV_CAMERALIGHT(_pv)  (_pv).cameraLightSample
#define ARPV_INCOMINGWAVELENGTH(_pv)  (_pv).incomingWavelength
#define ARPV_OUTGOINGWAVELENGTH(_pv)  (_pv).outgoingWavelength
#define ARPV_OCCLUDED(_pv)            (_pv).occluded
#define ARPV_CAMERAWAVELENGTH(_pv) (_pv).cameraWavelength

#define ARPV_EMPTY \
((ArPathVertex){NULL, 0, 1.0f, NULL, NULL, NULL, 1.0f, 0.0f, 0.0f, ARPDFVALUE_ONE, ARPDFVALUE_ONE})

ARDYNARRAY_INTERFACE_FOR_ARTYPE(PathVertex,pv,pv);
ARDYNARRAY_INTERFACE_FOR_ARTYPE_PTR(PathVertex,pv,pv);


ArPathVertex* arpv_alloc(const ART_GV *art_gv);
void arpv_free_pv(const ART_GV *art_gv, ArPathVertex *pv);
void arpv_free_arr_itrsc(const ART_GV  * art_gv, ArPathVertexptrDynArray *arr);