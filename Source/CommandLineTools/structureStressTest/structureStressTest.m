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

#import "AdvancedRenderingToolkit.h"

void readInputImageAndPlaceOnNodeStack(
        ART_GV            * art_gv,
        char             ** argv,
        unsigned int        argv_position,
        const char        * imageID,
        IVec2D            * imageSize,
        BOOL              * imageIsRaw
)
{
    *imageIsRaw = NO;

    const char  * originalInputFileName = argv[argv_position];

    ArnFileImage  * originalInputImage =
            [ FILE_IMAGE
                    :   originalInputFileName
            ];

    ArnFileImage  * inputImage = 0;

    if ( [ originalInputImage imageFileIsKindOf: [ ArfTIFF class ] ] )
    {
        char  * conversionMasterFilename = 0;

        arstring_p_copy_without_extension_p(
                originalInputFileName,
                & conversionMasterFilename
        );

        ArNode <ArpNodeStack>  * conversionNodeStack =
                ARNNODESTACK( conversionMasterFilename );

        ArNode <ArpAction>  * conversionActionSequence =
                ACTION_SEQUENCE(
                        [ IMAGECONVERSION_TIFF_TO_ARTCSP
                                removeSource: NO
                        ],

                        ACTION_SEQUENCE_END
                );

        [ conversionNodeStack push
        :   HARD_NODE_REFERENCE(originalInputImage)
        ];

// -----   start stack machine   ---------------------------------------------

        [ conversionActionSequence performOn
        :   conversionNodeStack
        ];

        // TODO
//        ART_ERRORHANDLING_WARNING(
//            "the memory management of this process has to be cleared up befor release"
//            );

        id  imageFromStack = ARNODEREF_POINTER( [ conversionNodeStack pop ] );

        ART_ERRORHANDLING_MANDATORY_CLASS_MEMBERSHIP_CHECK(
                imageFromStack,
                ArnFileImage
        );

        inputImage = (ArnFileImage *)imageFromStack;
    }
#ifdef ART_WITH_OPENEXR
    else if ( [ originalInputImage imageFileIsKindOf: [ArfOpenEXRRGB class ] ] )
    {
        char  * conversionMasterFilename = 0;

        arstring_p_copy_without_extension_p(
                originalInputFileName,
                & conversionMasterFilename
        );

        ArNode <ArpNodeStack>  * conversionNodeStack =
                ARNNODESTACK( conversionMasterFilename );

        ArNode <ArpAction>  * conversionActionSequence =
                ACTION_SEQUENCE(
                        [ IMAGECONVERSION_EXR_TO_ARTCSP
                                removeSource: NO
                        ],

                        ACTION_SEQUENCE_END
                );

        [ conversionNodeStack push
        :   HARD_NODE_REFERENCE(originalInputImage)
        ];

// -----   start stack machine   ---------------------------------------------

        [ conversionActionSequence performOn
        :   conversionNodeStack
        ];

        // TODO
//        ART_ERRORHANDLING_WARNING(
//            "the memory management of this process has to be cleared up befor release"
//            );

        id  imageFromStack = ARNODEREF_POINTER( [ conversionNodeStack pop ] );

        ART_ERRORHANDLING_MANDATORY_CLASS_MEMBERSHIP_CHECK(
                imageFromStack,
                ArnFileImage
        );

        inputImage = (ArnFileImage *)imageFromStack;
    }
#endif
    else
    {
        inputImage = originalInputImage;
    }

    if ( inputImage )
    {
        *imageSize = [ inputImage size ];

        if ( [ inputImage imageFileIsKindOf: [ ArfARTCSP class ] ] )
        {
            [ ART_GLOBAL_REPORTER beginTimedAction
            :   "reading colourspace input image %s of size %d x %d"
                    ,   imageID
                    ,   XC(*imageSize)
                    ,   YC(*imageSize)
            ];

            [ ART_GLOBAL_REPORTER endAction ];
        }
        else
        {
            if ( [ inputImage imageFileIsKindOf: [ ArfRAWRasterImage class ] ] )
            {
                *imageIsRaw = YES;

//                ArfRAWRasterImage  * rawImage = (ArfRAWRasterImage *) inputImage->imageFile;
//
//                ArDataType  rawContentType = [ rawImage fileDataType ];
//
//                //   Check if the current ISR is already set to match the contents
//                //   of the RAW file
//
//                if ( rawContentType != art_isr( art_gv ) )
//                {
//                    //   If they do not match...
//
//                    [ ART_GLOBAL_REPORTER beginAction
//                        :   "automatically switching ISR to match ARTRAW contents"
//                        ];
//
//                    char  * newInputFileName;
//
//                    arstring_s_copy_s(
//                          [ inputImage fileName ],
//                        & newInputFileName
//                        );
//
//                    [ ART_GLOBAL_REPORTER printf
//                        :   "Default ISR was   : %s\n"
//                        ,   ardatatype_name( art_isr( art_gv ) )
//                        ];
//
//                    [ ART_GLOBAL_REPORTER printf
//                        :   "ARTRAW content is : %s\n"
//                        ,   ardatatype_name( rawContentType )
//                        ];
//
//                    if ( rawContentType == ardt_xyz )
//                        rawContentType = ardt_xyz;
//
//                    if ( rawContentType == ardt_xyz_polarisable )
//                        rawContentType = ardt_xyz_polarisable;
//
//                    [ ART_GLOBAL_REPORTER printf
//                        :   "ISR will be set as: %s\n"
//                        ,   ardatatype_name( rawContentType )
//                        ];
//
//                    art_set_isr( art_gv, rawContentType );
//
//                    [ ART_GLOBAL_REPORTER printf
//                        :   "ISR is now set to : %s\n"
//                        ,   ardatatype_name( art_isr( art_gv ) )
//                        ];
//
//                    [ ART_GLOBAL_REPORTER printf
//                        :   "Re-reading raw image...\n"
//                        ];
//
//                    inputImage =
//                        [ FILE_IMAGE
//                            :   newInputFileName
//                            ];
//
//                    FREE_ARRAY( newInputFileName );
//
//                    [ ART_GLOBAL_REPORTER printf
//                        :   "Done.\n"
//                        ];
//
//                    [ ART_GLOBAL_REPORTER endAction ];
//                }

                [ ART_GLOBAL_REPORTER beginTimedAction
                :   "reading RAW input image %s of size %d x %d"
                        ,   imageID
                        ,   XC(*imageSize)
                        ,   YC(*imageSize)
                ];

                [ ART_GLOBAL_REPORTER endAction ];
            }
            else
#ifdef ART_WITH_OPENEXR
                ART_ERRORHANDLING_FATAL_ERROR(
                        "Input images have to be either EXR, TIFF, ARTRAW or ARTCSP images!"
                );
#else
            ART_ERRORHANDLING_FATAL_ERROR(
                    "Input images have to be either TIFF, ARTRAW or ARTCSP images!"
                    );
#endif
        }
    }
    else
        ART_ERRORHANDLING_FATAL_ERROR(
                "invalid input image"
        );

    ART_APPLICATION_NODESTACK_PUSH(
            inputImage
    );

    RELEASE_OBJECT(inputImage);
}

void explainFunction(
        ART_GV  * art_gv
)
{
    (void) art_gv;

    printf(
            "This application is named after the Ravenous Bugblatter Beast of Traal.\n"
            "At the time the first version of this tool was written (in the early hours\n"
            "of a morning close to some conference deadline around 2004, or so), this\n"
            "particular name seemed to be the perfect choice for a difference image \n"
            "generator.\n\n"
    );
}

int structureStressTest(
        int        argc,
        char    ** argv,
        ART_GV   * art_gv
)
{

    bool allValid = true;
    for( int i = 0; i < 20; i++ )
    {
        ArPathVertexptrDynArray pathVertexptrDynArray = arpvptrdynarray_init(1);

        for(int j = 0; j < 1000000; j++)
        {
            ArPathVertex * pathVertex = ALLOC(ArPathVertex);

            pathVertex->lightSample = arlightalphasample_alloc(art_gv);
            arlightalphasample_d_init_unpolarised_l(art_gv, 1.0f,pathVertex->lightSample);
            arpvptrdynarray_push(&pathVertexptrDynArray, pathVertex);
        }

        ArcHashgrid * hashgrid = [[ArcHashgrid alloc] init];


        [hashgrid Reserve:(1000000)];
//        [hashgrid BuildHashgrid:&pathVertexptrDynArray :0.234f];

        hashgrid->vmNormalization = 1;
        hashgrid->VMweight = 1;
        hashgrid->VCweight = 1;

        for(int j = 0; j < 1000000; j++)
        {
            ArPathVertex * pathVertex = arpvptrdynarray_i(&pathVertexptrDynArray, j);
            if(arlightalphasample_l_valid(art_gv, pathVertex->lightSample) == false)
            {
                allValid = false;
            }

            arlightalphasample_free(art_gv, pathVertex->lightSample);
            FREE(pathVertex);
            pathVertex = 0;
        }

        [hashgrid dealloc];
        hashgrid = 0;
        arpvptrdynarray_free_contents(&pathVertexptrDynArray);




    }

    NSLog(@"All light samples valid? %d", allValid);

    return 0;
}

ADVANCED_RENDERING_TOOLKIT_MAIN(structureStressTest)

// ===========================================================================
