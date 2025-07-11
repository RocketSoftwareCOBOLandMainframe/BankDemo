# Open PL/I Development by Using Enterprise Developer for Eclipse

Rocket&reg; Enterprise Suite products provide a proprietary runtime engine to enable compatibility for customers’ IBM CICS applications. IBM and CICS are registered trademarks of International Business Machines Corp. Rocket Enterprise Suite products do not include an IBM CICS engine and are not affiliated with IBM. 

## Contents
- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [How to Run the Demonstration](#how-to-run-the-demonstration)

## Overview
This demonstration shows you how to compile, link and debug an Open PL/I BANK CICS application by using the Eclipse IDE.  
The demo instructions assume you already have a basic understanding of how to use Eclipse and some basic familiarity with Enterprise Server.
If you decide to use the remote debug instructions, check with your system administrator for connection details (computer name, port, connection type, credentials) before starting.

## Prerequisites

You must have the following software installed:

- Rocket&reg; Enterprise Developer for Eclipse. [*Click here*](https://docs.rocketsoftware.com/bundle?cluster=true&labelkey=prod_enterprise_developer) to access the documentation for Enterprise Developer.
- A TN3270 terminal emulator to run the CICS application.
>**Note:** This tutorial uses the Rocket Software Secure Host Access (SHA) TN3270 emulator, which is installed with Enterprise Developer, but you can use an alternative terminal emulator.

Before running this demo remotely, verify that you have an RDO and MFDS agent already configured and running on the remote UNIX/Linux system. For more details, see the Rocket product documentation.

### Disable the Default Enterprise Server Security Configuration

>**Note**: If you have already imported the BANKDEMO enterprise server as part of the "Getting started with Rocket Enterprise Developer for Visual Studio 2022" tutorial, and HA Cloud service is running, you can skip these steps.

The Enterprise Server security features are enabled by default. However, tutorials that use enterprise server regions assume that Enterprise Server security is not configured. To perform this tutorial without modification, you must disable the default configured Enterprise Server security. See *To Disable the Default Enterprise Server Security Configuration* for more information. 

> **Important**: Rocket Software does not recommend disabling Enterprise Server security permanently. If you disable the default Enterprise Server security to facilitate running tutorials, then this should be performed on a network-isolated machine. Re-enable security as soon as possible after completing the tutorial. For more details, see *To Recreate the Default Enterprise Server Security Configuration* in the product documentation. 

1. In an Enterprise Developer command prompt, run the command:

    Windows: `DisableESDefaultSecurity.cmd`

    UNIX: `DisableESDefaultSecurity.sh`
      
 A series of messages appear as the script disables default security.

2. Restart the Directory server (MFDS) and ESCWA services to pick up the configuration changes. 

     You can now use ESCWA without having to log in.

3. Restart any running enterprise server regions so that they pick up the configuration changes. 
 
   Regions no longer require credentials for starting/stopping and other actions.

## How to Run the Demonstration

### Connect to the Default ESCWA Server

Ensure that **Server Explorer** contains a connection to the default Enterprise Server Common Web Administration (ESCWA) server. Existing workspaces might already have this connection.

1. In the **Server Explorer** view, right-click and select **New > Enterprise Server Common Web Administration Connection**.

    The **New Enterprise Server Common Web Administration Connection** dialog box opens.
2. In the **Name** field, type `Local`.
3. In the **Server address** field, type `localhost`.
4. In the **Server port** field, leave the default `10086`.
5. If the server connection is TLS-enabled, select **TLS Enabled**, click **Browse** and select the appropriate certificate.
>**Note**: If you select **TLS Enabled**, but you do not specify a certificate, the default Java keystore is searched for a valid one.
6. Click **Finish**.
The new connection appears at the top level, in **Server Explorer**.

### Import the BANKDEMO Enterprise Server Region

**Note:** If you have already imported the BANKDEMO enterprise server region for the IDE Getting Started tutorial, you scan skip these steps.

**Create the BANKDEMO Region Definition File**

Windows:

1.  Open Windows PowerShell and navigate to the `C:\MFETDUSER\tutorial` folder.
2.  Run `set-ExecutionPolicy RemoteSigned -Scope CurrentUser`.
3.  (Optional) Unblock the script.

    At times, for security reasons, when you have downloaded files by using a browser, the files can be blocked and you might not be able to run the script. To unblock the script:

    a. Open File Explorer and navigate to the `C:\MFETDUSER\tutorial` folder.

    b. Right-click the **createdefinition.ps1** file and select **Properties**.

    c. Select the **Unblock** check box and click **Apply**. 

4.  Run the PowerShell script provided with the sample: `.\createdefinition.ps1`. 

UNIX: 


1.  Navigate to the `/home/*username*/MFETDUSER/tutorial` directory and open a terminal from this location.
2.  Run the following script: 

     ```
        ./createdefinition.sh
        
     ``` 

    > **Note**: You might have to give execute permissions to this script. To do this, run: 
    
       ```
        chmod +x createdefinition.sh

       ```

This runs the script and creates the Enterprise Server region definition file, `BANKDEMO.xml`, in the same folder. The file is configured for the location in which you saved the sample files.

**Import the BANKDEMO Enterprise Server**
  
1. On the **Server Explorer** tab, right-click **Local** and select **Import Server**.
2. Click **Browse**, select the `tutorial/BANKDEMO.xml` file and click **Finish**.
    The BANKDEMO server appears under **Local** in Server Explorer.

### Start the SHA Session Server

You must start the Secure Host Access session server before attempting to use the SHA TN3270 terminal emulator. To do this, start the Windows service (Windows) or the `startsessionserver.sh` script (UNIX).

**Windows**

1. From the Windows **Start** menu open the Services application.

2. Navigate to the HA Cloud service and check whether its status is set to **Running**.

3. If it is not running, right-click the service and select **Start**.
4. Alternatively, you can start the session by opening a command prompt as administrator and executing the following command:

    ```
    net start mfhacloud
    ```

**UNIX**

1. Ensure that the installed Java is added to the PATH environment variable. 
adding JAVA to the PATH environment variable resulted in the emulator not opening as expected when running the demo (step 5 in Execute the BANKDEMO application). When I attempted to go through it a second time, I did not configure this and the emulator opened on its own. -->
2. Start the enterprise server region that runs the application you want to connect to.
3. Open a terminal and set up the COBOL environment in it.
4. Run the following to start the session server:

    ```
    startsessionserver.sh
    ```

### Import the INCLUDES, FETCHABLES, and BANKMAIN Projects into an Eclipse Workspace

1. After opening Enterprise Developer for Eclipse, either create a new workspace or open an existing one.
2. If it's not already open, open the PL/I perspective in the Eclipse IDE by clicking **Window > Perspective > Open Perspective > Other > PL/I**.
3. To start the project import process, open the **File** menu and select **Import**, or righ-click in the **PL/I Explorer** tab and select **Import > Import**.
4. In the **Import** pop-up window, expand **General**, select **Existing Projects into Workspace**, and click **Next**.
5. Next to **Select root directory**, click **Browse**, navigate to the location of the `tutorial\projects\Eclipse\pli` directory, select it, and click **Select Folder**.
 The **BANKMAIN**, **FETCHABLES** and **INCLUDES** projects should now be visible on the **Projects** list.
6. Verify that **Copy projects into workspace** is not selected and click **Finish**.
  
    Once the import is complete, the **BANKMAIN**, **FETCHABLES**, and **INCLUDES** projects should display in the **PL/I Explorer** tab.
7. Click **Project > Properties**, expand **Rocket Software**, click **Build Configurations**, and verify that the active build configuration is set to 'x64'[Active], as this demo is designed to run only in 64-bit mode.
8.  Ensure the project is built. If Auto-build is enabled, it builds automatically, or you can build it manually by clicking **Project>Build**.


### Configure the BANKDEMO Enterprise Server for PL/I

1. In the **Server Explorer** tab, expand **Local>Default**, right-click **BANKDEMO**, and click **Open Administration Page**. 

   This opens the **Enterprise Server Common Web Administration** (ESCWA)  page outside of Eclipse.
2. Click the **CICS** drop-down list, and select **Configuration**.
3. Change the **System Initialization Table** from `CBLVSAM` to `PLIVSAM` and click **Apply**.

      This configures the server to use some PL/I CICS resources.

### Associate the Projects with the BANKDEMO Enterprise Server

1. In the **Server Explorer** tab, right-click the **BANKDEMO** server, select **Associate with Project**, and click **BANKMAIN**.
2. Repeat the process for the **FETCHABLES** project. 

Making these associations before you start the server enables the executables built by the projects to be used.

### Start the BANKDEMO Enterprise Server

1. On the **Server Explorer** tab, right-click the **BANKDEMO** server and click **Start**.
2. Click **OK** in the **Enterprise Server Sign On** dialog (you can leave the fields blank). You can check the **Output** view to see the progress of starting the server. This also starts the **Enterprise Server Console Daemon** window which also provides information about the server start-up.

### Execute the BANKDEMO Application

1. To prepare for debugging in Eclipse, create a debug configuration by clicking **Run>Debug Configurations**.
2. On the Debug Configurations dialog, right-click **PL/I Enterprise Server** and click **New Configuration**.
3. In the **Name** field, type a meaningful name, for example `BANK`.
4. In PL/I project, type `BANKMAIN`, in **ESCWA**, enter `Local`, in **Directory Server**, enter `Default`, and in Region, enter `BANKDEMO`.
5. Click **Apply** and then click **Debug**.
6. Open a TN3270 emulation program like Rocket Software Secure Host Access (SHA), and connect to **localhost** (or **127.0.0.1**) on port **9023**.  
7. If you receive a dialog asking whether to automatically switch to the debug perspective, select **Remember my decision**, and click **Yes**.
8. Eclipse should automatically open the `SBANK00P.PLI` source file with the `SBANK00P PROC` line highlighted as the current line of execution.
9. If line numbers are not turned on in the source window, right-click in the left column of the source pane, and click **Show Line Numbers**.
10. You can step through the `SBANK00P` program, set breakpoints, and evaluate variables.

     Once you are ready to run the program, select **Resume/&lt;F8&gt;** as many times as necessary to run the program to completion.
11. In the TN3270 emulator window, type a User id of `b0001` and anything for the password, and press **Enter**.
    
    Eclipse restarts debugging so you can debug through the `SBANK10P` program.          
12. Once you are ready to run the program, click **Resume/&lt;F8&gt;** as many times as necessary to run the program to completion.      

    As this application is pseudo-conversational, debugging will start and end with the invocation and completion of each transaction in the application.  Since this is a small demo, all of the CICS programs after the Banking main options screen are not built for debugging and the sources are not provided.
13. Once you are ready to leave the application, press **F3** to end the application in the TN3270 window.
14. You can now disconnect your TN3270 terminal to end the demo.

### Stop the Enterprise Server
When you have finished running the demo, you can stop the associated enterprise server instance:

1. In Eclipse, right-click the **BANKDEMO** server in **Server Explorer** and click **Stop**.
2. Check the **Output** view for messages that the server has stopped.

    A number of messages also appear in the **Enterprise Server Console Daemon** window before it closes.

> **Note**: You should re-enable Enterprise Server security if you have not already done so. See *Recreate the Default Enterprise Server Security Configuration* in the product documentation for steps on how to re-enable security. 
