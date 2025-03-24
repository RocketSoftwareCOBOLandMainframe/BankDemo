# Open PL/I Development using Enterprise Developer for Visual Studio 2022

## Contents
- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [How to Run this Demonstration](#how-to-run-the-demonstration)


## Overview
This demonstration shows how you can compile, link, and debug an Open PL/I BANK IBM&reg; CICS&reg; application by using the Visual Studio IDE. The instructions assume that you already have a basic understanding of how to use Visual Studio.

## Prerequisites

This demonstration requires:
- Rocket&reg; Enterprise Developer for Visual Studio 2022. [*Click here*](https://docs.rocketsoftware.com/bundle?cluster=true&labelkey=prod_enterprise_developer) to access the documentation for Enterprise Developer.
- A TN3270 terminal emulator to run the IBM CICS application. 

**Note:**
This tutorial uses the Host Access for the Cloud (HA Cloud) service, which is installed with Enterprise Developer, but you may use an alternative terminal emulator.

## Requirements

**Note:** If you have already imported the BANKDEMO enterprise server as part of the "[Getting started with Rocket Enterprise Developer for Visual Studio 2022](..\README.md)" tutorial, and HA Cloud service is running, you can skip these steps.

### Disable the Default Enterprise Server Security

In this release, the Enterprise Server security features are enabled by default. Tutorials that use enterprise server regions, however, assume that Enterprise Server security is not configured. To perform this tutorial without modification, you must disable the default configured Enterprise Server security. See *Disable the Default Enterprise Server Security Configuration* for more information.

**Disable the Default Enterprise Server Security Configuration**

> **Important**: Rocket Software does not recommend disabling Enterprise Server security permanently. If you disable the default Enterprise Server security to facilitate running tutorials then this should be performed on a network isolated machine. Re-enable security as soon as possible after completing the tutorial. See *To Recreate the Default Enterprise Server Security Configuration* in the product documentation for steps on how to re-enable security. 

1. In an Enterprise Developer command prompt, run the command `DisableESDefaultSecurity.cmd`. You see a series of messages as the script disables default security.
2. Restart the Directory Server (MFDS) and Enterprise Server Common Web Administration (ESCWA) services to pick up the configuration changes. You can now use ESCWA without having to log in.
3. Restart any running enterprise server regions to have them pick up the configuration changes. Regions will no longer require credentials for starting/stopping and other actions.

### Import the Supplied Bankdemo Enterprise Server:
    
1. Run the `tutorial\createdefinition.ps1` PowerShell script to create the **BANKDEMO.xml** region definition file. 
    
2. In Visual Studio, open Server Explorer, right-click **Local**, and click **Import**. 
    
3. Click **Import server definition file**, select the **tutorial\BANKDEMO.xml** file, and click **OK**.
    
   The BANKDEMO server should appear in Server Explorer under **Local**.

### Start the HA Cloud Session Server

You must start the HA Cloud session server before attempting to use the HA Cloud TN3270 terminal emulator. To do this you must start the respective Windows service.

<!--1. Ensure you have a 64-bit Java installed and added to the PATH environment variable.

If i do this step, the emulator won't start at all-->

1. From the Windows **Start** menu open the **Services** application.

2. Navigate to the HA Cloud service and check whether its status is set to **Running**. If it is not running:

   - Right-click the service and click **Start**.
   - Alternatively, you can start the service by opening a command prompt as an administrator and running the following command:

        ```
        net start mfhacloud
        ```

## Run the Demonstration

### Configure the BANKDEMO Enterprise Server for PL/I:
    
1. In Visual Studio, in Server Explorer, right-click **Rocket Enterprise Server**, and select **Administration**.
    
     This opens the Home page of **Enterprise Server Common Web Administration** in a web browser outside of the IDE.
     
2. On the **Home** page, from the top toolbar, click **Native**.
3. In the navigation bar on the left, expand **Directory Servers >  Default** and click **BANKDEMO**.
<!--4. On the **General** page of the server, note that the **PL/I enabled** check box is already selected.
This option does not exist in the UI-->
4. From the **CICS** drop-down menu, select **Configuration**.
5. Change **System Initialization Table** from **CBLVSAM** to **PLIVSAM**, and click **Apply**. 
    
    This configures the server to use some PL/I IBM CICS resources (BMS maps and programs).

### Build the Application

1. Open the solution in Visual Studio:

     a.  Click **File > Open > Project/Solution**.

     b.  Navigate to the `C:\MFEDTDUSER\tutorial\projects\Studio\pli` folder.

     c.  Select **bankdemo.sln**, and then click **Open**.
2. Check the project's active configuration:

    a.  Right-click the **bankdemo** solution in Solution Explorer and click **Properties**.

    b.  Click **Configuration Properties** and then click  **Configuration**. 
    
    You see that this demo is designed to run only in 64-bit mode. If you make any changes to the default configuration or platform that you want to keep, click **OK** to close the dialog box.  

3. From the main Visual Studio toolbar, click **Build > Build Solution**.
4. Check the **Output** window at the bottom of the IDE to verify that the solution has built successfully. The last line in the log typically looks like this: 
    ```
        "========== Build:  3 succeeded or up-to-date, 0 failed, 0 skipped =========="
    ```

### Associate the Projects with the Enterprise Server Region:

1. In Visual Studio, in Server Explorer, right-click **BANKDEMO > Associate with Project**, and select **bankmain**.

2. Repeat the step above for the **fetchables** project.

    Making these associations enables the server to use the executables built by the projects.

### Start the BANKDEMO Enterprise Server 

1.  In Server Explorer, right-click **BANKDEMO**, and click **Start**.
2.  (Optional) Click **OK** in the **Enterprise Server Sign On** dialog box, and leave the fields blank.
3.  Check the **Output** window to see the progress of starting the server.
    <!--Starting the server launches the **Enterprise Server Console Daemon** window which also provides information about the server start-up.-->

### Execute the bankmain IBM CICS Application 

1.  To start debugging in Visual Studio, press **F5**. This puts the IDE in wait mode for the BANK application to start.
2.  Open a TN3270 emulator program such as Host Access for the Cloud, and connect to **localhost** (or **127.0.0.1**) on port **9023**.

    Visual Studio should automatically open the `SBANK00P.PLI` source file with the **SBANK00P PROC** line highlighted as the current line of execution.

3.  Step through the `SBANK00P` program, set any breakpoints, and evaluate variables.  
4.  Once you are ready to run the program to completion, click **F5** (Resume) as many times as necessary to run the program to completion.
5.  In the TN3270 window, type the user id, for example `b0001` and any string for the password, and press **Enter**.

    Visual Studio debugging starts again so you can debug through the `SBANK10P` program.         
6. Once you are ready to run the program to completion, click **F5** (Resume) as many times as necessary to run the program to completion.         
  
    As this application is pseudo-conversational, debugging starts and ends with the invocation and completion of each transaction in the application. Since this is a small demo, all of the IBM CICS programs after the Banking main options screen are not built for debug and the sources are not provided.
7.  Once you are ready to leave the application, press **F3** to end the application in the TN3270 window.          
8.  You can now disconnect your TN3270 terminal to end the demo.          

### Stop the BANKDEMO Enterprise Server

Now that you have finished running the demo, you can stop the associated BANKDEMO enterprise server. To do this:
 
1.  In Server Explorer, right-click the **BANKDEMO** server, and click **Stop**.
2.  Check the **Output** window for messages that the server has been stopped successfully. 

    <!--A number of messages also appear in the **Enterprise Server Console Daemon** window outside of Visual Studio before it closes down.-->

> **Note**: You should re-enable Enterprise Server security if you have not already done so. See *To Recreate the Default Enterprise Server Security Configuration* in the product documentation for steps on how to re-enable security. 
