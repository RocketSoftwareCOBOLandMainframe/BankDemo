 /****************************************************************
 *
 *  Copyright(C) 1998-2010 Micro Focus. All Rights Reserved.
 *
 ****************************************************************/

 /****************************************************************
 * CABENDD.inc
 *---------------------------------------------------------------
 * Work areas for abend routine
 ****************************************************************/
 DCL 1 ABEND_DATA,
    05  ABEND_CODE                            CHAR(4)
        INIT(''),
    05  ABEND_CULPRIT                         CHAR(8)
        INIT(''),
    05  ABEND_REASON                          CHAR(50)
        INIT(''),
    05  ABEND_MSG                             CHAR(72)
        INIT('');
