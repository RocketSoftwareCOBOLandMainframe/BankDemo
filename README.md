# Bankdemo Application
This project provides tutorials and demonstrations of features in the Rocket&reg; Enterprise Developer and Rocket&reg; Enterprise Server products.
To use these materials, download the assets of the project [release](https://github.com/RocketSoftware/BankDemo/releases) that matches the version of the product you will be using. Check and follow the appropriate READMEs for instructions.

## Contents

1. [Introduction](#intro)
1. [License](#license)
1. [Using The Bankdemo Application](#using)
    1. [Enterprise Developer Introductory Tutorial](#tutorial)
    1. [On Premises Enterprise Server Capabilities](#onprem)


## <a name="intro"></a>Introduction

The Bankdemo application is a simplified mainframe "green screen" banking application which runs under Rocket
Enterprise Server. This project provides demonstrations and tutorials of several ways you can configure or modify the application
to suit differing requirements which could then be used as a template for running and configuring your own application.

The project demonstrates a selection of the capabilities of Rocket Enterprise Server and these options will be extended over time. 
It demonstrates applications running on premises and includes introductory tutorials for the use of
the Rocket Enterprise Developer for Eclipse and Visual Studio integrated development environments.

In the simplest configuration, it demonstrates an IBM&reg; CICS&reg; and an JCL COBOL applications that access banking data held in indexed (VSAM) files on disk. However, it can also be configured to access data from a PostgreSQL database and database hosted VSAM files using the Rocket Database File Handler. Further demonstrations would be added in the future to show more complex deployments such as scale-out and cloud deployments.

The Rocket Enterprise Suite supports IBM&reg; technologies including IBM&reg; MVS&trade;, IBM&reg; COBOL, IBM&reg; Enterprise PL/I for z/OS&reg;, IBM&reg; Assembler, IBM&reg; CICS&reg;, IBM&reg; IMS&trade;, IBM&reg; JCL, IBM&reg; DB2&reg;, IBM&reg; z/OS&reg;, IBM&reg; WebSphere MQ&trade;, and IBM&reg; zEnterprise&reg;, all of which are trademarks of International Business Machines Corporation, registered in various jurisdictions worldwide.

## <a name="license"></a>License

Copyright 2010 – 2025 Rocket Software, Inc. or its affiliates. 
This software may be used, modified, and distributed 
(provided this notice is included without modification)
solely for internal demonstration purposes with other 
Rocket® products, and is otherwise subject to the EULA at
https://www.rocketsoftware.com/company/trust/agreements.

THIS SOFTWARE IS PROVIDED "AS IS" AND ALL IMPLIED
WARRANTIES, INCLUDING THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE,
SHALL NOT APPLY.
TO THE EXTENT PERMITTED BY LAW, IN NO EVENT WILL 
ROCKET SOFTWARE HAVE ANY LIABILITY WHATSOEVER IN CONNECTION
WITH THIS SOFTWARE.


## <a name="using"></a>Using the Bankdemo Application
To use the project, download the **source.zip** or **source.tar.gz** from the [release](https://github.com/RocketSoftware/BankDemo/releases) that matches the product version you want to use, then follow the relevant readme instructions. You can use the project in one of the following ways:
1. <a name="tutorial"></a> As the basis of the introductory tutorials for the Rocket Enterprise Developer for Eclipse and Visual Studio integrated development environments.
    - Prerequisite software: 
        - Rocket Enterprise Developer for Eclipse or Rocket Enterprise Developer for Visual Studio 2022
    - Available tutorials:
        - [Getting Started with Enterprise Developer for Eclipse (Windows)](tutorial/gettingstarted/eclipse/README.md)
        - [Getting Started with Enterprise Developer for Eclipse (Linux)](tutorial/gettingstarted/eclipseux/readme.md)
        - [Getting Started with Enterprise Developer for Visual Studio](tutorial/gettingstarted/visualstudio/readme.md)
        - [Open PL/I Bankdemo Application in Enterprise Developer for Eclipse](tutorial/gettingstarted/eclipse/PLIDemo.md)
        - [Open PL/I Bankdemo Application in Enterprise Development for Visual Studio](tutorial/gettingstarted/visualstudio/PLIDemo.md)
    - Requirements: 
        - Ensure that the Directory Server (MFDS) service is running
        <!-- The service is still called Microfocus Directory Server-->
        - Ensure that the Enterprise Server Common Web Administration (ESCWA) service is running and listening on the default localhost port - 10086.

2. <a name="onprem"></a> Demonstrations of the Rocket Enterprise Server capabilities in "on premises" scenarios:
    - Prerequisite software: 
        - Rocket Enterprise Server or Enterprise Developer on Windows or on a supported Linux distribution.
        - Python 3 with the `requests` and for the PostgreSQL demo `psycopg2-binary` packages (use the following command to install the packages: `python -m pip install requests psycopg2-binary`)
        - Check the tutorial or demonstration instruction for any additional requirements
    - Available demonstrations:
        - [Deploying and running Bankdemo with VSAM data](demos/onprem/vsam/README.md) 
        - [Deploying and running Bankdemo with PostgreSQL](demos/onprem/psql/README.md) 
        - [Deploying and running Bankdemo with VSAM stored in PostgreSQL using MFDBFH](demos/onprem/psqlmfdbfh/README.md) 
        - [Deploying and running Bankdemo in a Performance and Availability Cluster with PostgreSQL](demos/onprem/psqlpac/README.md) 
    - Requirements: 
        - Ensure that the Directory Server (mfds) service is running
        - Ensure that the Enterprise Server Common Web Administration (ESCWA) service is running and listening on the default localhost port - 10086.

Use the **Issues** tab to report issues, or to raise questions.
