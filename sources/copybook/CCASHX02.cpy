      *****************************************************************
      *                                                               *
      * Copyright 2010-2024 Rocket Software, Inc. or its affiliates.  *
      * This software may be used, modified, and distributed          *
      * (provided this notice is included without modification)       *
      * solely for internal demonstration purposes with other         *
      * Rocket® products, and is otherwise subject to the EULA at     *
      * https://www.rocketsoftware.com/company/trust/agreements.      *
      *                                                               *
      * THIS SOFTWARE IS PROVIDED "AS IS" AND ALL IMPLIED             *
      * WARRANTIES, INCLUDING THE IMPLIED WARRANTIES OF               *
      * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE,         *
      * SHALL NOT APPLY.                                              *
      * TO THE EXTENT PERMITTED BY LAW, IN NO EVENT WILL              *
      * ROCKET SOFTWARE HAVE ANY LIABILITY WHATSOEVER IN CONNECTION   *
      * WITH THIS SOFTWARE.                                           *
      *                                                               *
      *****************************************************************

      *****************************************************************
      * CCASHX02.CPY (CICS Version)                                   *
      *---------------------------------------------------------------*
      * This copybook is used to provide an common means of calling   *
      * data access module DCASH02P so that the that module using     *
      * this copy book is insensitive to it environment.              *
      * There are different versions for CICS, IMS and INET.          *
      *****************************************************************
      * by default use CICS commands to call the module
           EXEC CICS LINK PROGRAM('DCASH02P')
                          COMMAREA(CD02-DATA)
                          LENGTH(LENGTH OF CD02-DATA)
           END-EXEC
      *    CALL 'DCASH02P' USING CD02-DATA

      * $ Version 5.99c sequenced on Wednesday 3 Mar 2011 at 1:00pm
