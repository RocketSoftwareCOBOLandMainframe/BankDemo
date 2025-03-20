# Open PL/I Development using Enterprise Developer for Eclipse
## Contents
- [Overview](#overview)
- [How to Run this Demonstration](#how-to-run-the-demonstration)

## Overview
This demonstration shows you how to compile, link and debug an Open PL/I BANK IBM® CICS® application by using the Eclipse IDE.  
The demo instructions assume you already have a basic understanding of how to use Eclipse and some basic familiarity with Enterprise Server.
If you decide to use the remote debug instructions, check with your system administrator for connection details (computer name, port, connection type, credentials) before starting.

You must have the following software installed:

- Rocket® Enterprise Developer for Eclipse. [*Click here*](https://docs.rocketsoftware.com/bundle?cluster=true&labelkey=prod_enterprise_developer) to access the product Help and the release notes of Enterprise Developer.
- A TN3270 terminal emulator to run the IBM CICS application.

**Note:** A license for Rocket® Host Access for the Cloud (HACloud) Session Server TN3270 emulator is included with Enterprise Developer. 

Before running this demo remotely, verify that you have an RDO and MFDS agent already configured and running on the remote UNIX/Linux system. See the Rocket product documentation for more information.

## How to Run the Demonstration

### Connect to the default ESCWA server

Ensure that **Server Explorer** contains a connection to the default Enterprise Server Common Web Administration (ESCWA) server. Existing workspaces might already have this connection.

1. In the **Server Explorer** view, right-click and select **New > Enterprise Server Common Web Administration Connection**.

    The **New Enterprise Server Common Web Administration Connection** dialog box opens.
2. In the **Name** field, type **Local**.
3. In the **Server address** field, type **localhost**.
4. In the **Server port** field, leave as the default 10086.
5. If the server connection is TLS-enabled, select **TLS Enabled**, and then click **Browse** and select the appropriate certificate.
>**Note**: If you select **TLS Enabled**, but you do not specify a certificate, the default Java keystore is searched for a valid one.
6. Click **Finish**.
The new connection appears at the top level, in **Server Explorer**.

### Import the supplied BANKDEMO enterprise server

**Note:** If you have already imported the BANKDEMO enterprise server region for the IDE Getting Started tutorial, you scan skip these steps.

1. Run the `tutorial\createdefinition.ps1` Powershell script (Windows) or `tutorial/createdefinition.sh` shell script (Linux) to create the `BANKDEMO.xml` region definition file. 
2. On the **Server Explorer** tab, right-click **Local** and select **Import Server**.
4. Click **Browse**, select the `tutorial/BANKDEMO.xml` file, and then click **Finish**.
    The BANKDEMO server appears under **Local** in Server Explorer.

### Start the HACloud session server

You must start the HACloud session server before attempting to use the HACloud TN3270 terminal emulator. To do this, start the Windows service (Windows) or the `startsessionserver.sh` script (UNIX).

**Windows**

1. Ensure you have a 64-bit Java installed and added to the PATH environment variable.
2. Open the Windows Service Manager.
3. Go to **Rocket HA Cloud** and click **Start the service**. 
4. Alternatively, you can start the session by opening a command prompt as administrator and executing the following command:

    ```
    net start mfhacloud
    ```

**UNIX**

1. Ensure that the installed Java is added to the PATH environment variable.
2. Start the Enterprise Server region that runs the application you want to connect to.
3. Open a terminal and set up the COBOL environment in it.
4. Run the following to start the session server:

    ```
    startsessionserver.sh
    ```

### Import the INCLUDES, FETCHABLES, and BANKMAIN projects into an Eclipse workspace:

1. After opening Enterprise Developer for Eclipse, either create a new workspace or open an existing one.
2. If it's not already open, open the PL/I perspective in the Eclipse IDE by clicking **Window > Perspective > Open Perspective > Other > PL/I**.
3. Start the project import process by selecting **Import** from the **File** menu or right clicking in the **PL/I Explorer** tab, and selecting **Import > Import**
4. On the import pop-up window, expand **General**, select **Existing Projects into Workspace**, and click **Next**.
5. In **Select root directory**, click **Browse** to navigate to the location of the `tutorial\projects\Eclipse\pli` directory, select it, and click **Select Folder**.
6. The **BANKMAIN**, **FETCHABLES** and **INCLUDES** projects should now be visible on the **Projects** list.
7. Verify that **Copy projects into workspace** is not selected, and click **Finish**.
8. Once the import is complete, the **BANKMAIN**, **FETCHABLES**, and **INCLUDES** projects should display in the **PL/I Explorer** tab.
9. Verify that the active build configuration is 'x64' in the project properties before continuing, as this demo is designed to run only in 64-bit mode.
10.  Ensure the project has been built (either because Auto-build is enabled) or by clicking **Build** on the **Project** menu.

### Disable the default Enterprise Server security configuration

The Enterprise Server security features are enabled by default. Tutorials that use enterprise server regions, however, assume that Enterprise Server security is not configured. To perform this tutorial without modification, you must disable the default configured Enterprise Server security. See *To Disable the Default Enterprise Server Security Configuration* for more information.

> **Important**: Rocket Software does not recommend disabling Enterprise Server security permanently. If you disable the default Enterprise Server security to facilitate running tutorials then this should be performed on a network isolated machine. Re-enable security as soon as possible after completing the tutorial. For more details, see *To recreate the Default Enterprise Server Security Configuration* in the product documentation. 

1. In an Enterprise Developer command prompt, run the command `DisableESDefaultSecurity.cmd`. A series of messages appear as the script disables default security.
2. Restart MFDS and ESCWA to pick up the configuration changes. You can now use ESCWA without having to log in.
3. Restart any running enterprise server regions so that they pick up the configuration changes. 
   Regions no longer require credentials for starting/stopping and other actions.

### Connect to the default ESCWA server

Verify that **Server Explorer** contains a connection to the default Enterprise Server Common Web Administration (ESCWA) server. Existing workspaces might already have this connection.

1. In the **Server Explorer** view, right-click and select **New > Enterprise Server Common Web Administration Connection**.

    The **New Enterprise Server Common Web Administration Connection** dialog box is displayed.
2. In the **Name** field, type **Local**.
3. In the **Server address** field, type **localhost**.
4. In the **Server port** field, leave as the default 10086.
5. If the server connection is TLS-enabled, select **TLS Enabled**, and then click **Browse** and select the appropriate certificate.
>**Note**: If **TLS Enabled** is selected, but you do not specify a certificate, the default Java keystore is searched for a valid one.
6. Click **Finish**.
The new ESCWA connection is displayed at the top level, in the **Server Explorer**.

### Configure the BANKDEMO enterprise server for PL/I:

1. In the **Server Explorer** tab, right-click on **BANKDEMO** under **Local**, and click **Open Administration Page**. This opens the **Enterprise Server Common Web Administration** (ESCWA for short)  page outside of Eclipse.
2. Click the **CICS** drop-down list, and select **Configuration**.
3. Change the **System Initialization Table** from **CBLVSAM** to **PLIVSAM**, and click **Apply**. This configures the server to use some PL/I IBM CICS resources.

### Associate the projects with the BANKDEMO enterprise server:

1. In the **Server Explorer** tab, right-click the **BANKDEMO** server, and select **Associate with Project**, and click **BANKMAIN**.
2. Repeat the process for the **FETCHABLES** project. 

Making these associations before you start the server enables the executables built by the projects to be used.

### Start the BANKDEMO enterprise server:

1. On the **Server Explorer** tab, right-click the **BANKDEMO** server, and click **Start**.
2. Click **OK** in the **Enterprise Server Sign On** dialog (you can leave the fields blank). You can check the **Output** view to see the progress of starting the server. This also starts the **Enterprise Server Console Daemon** window which also provides information about the server start-up.

### Execute the BANKDEMO application:

1. To prepare for debugging in Eclipse, create a debug configuration by selecting **Debug Configurations** from the **Run** menu.
2. On the Debug Configurations dialog, right-click **PL/I Enterprise Server**, and click **New Configuration**.
3. Change the **Name** from **New_configuration** to something meaningful like **BANK**.
4. Type **BANKMAIN** in PL/I project, enter **Local** in **ESCWA**, **Default** in **Directory Server**, and **BANKDEMO** in **Region**. Click **Apply** and then click **Debug**.
5. Open a TN3270 emulation program like Rocket Host Access for the Cloud, and connect to **localhost** (or **127.0.0.1**) on port **9023**.
6. If you receive a dialog asking whether to automatically switch to the debug perspective, select **Remember my decision**, and click **Yes**.
7. Eclipse should automatically open the `SBANK00P.PLI` source file with the SBANK00P PROC line highlighted as the current line of execution.
8. If line numbers are not turned on in the source window, right-click in the left-hand column of the source pane, and click **Show Line Numbers**.
9. You can step through the SBANK00P program, set breakpoints, and evaluate variables.  Once you're ready to run the program to completion, select **Resume/&lt;F8&gt;** as many times as necessary to run the program to completion.
10. In the TN3270 emulator window, type a User id of **b0001**, and anything for the password, and press **Enter**.
    
    Eclipse restarts debugging so you can debug through the SBANK10P program.          
12. Once you are ready to run the program to completion, select **Resume/&lt;F8&gt;** as many times as necessary to run the program to completion.      

    As this application is psuedo-conversational, debugging will start and end with the invocation and completion of each transaction in the application.  Since this is a small demo, all of the IBM CICS programs after the Banking main options screen are not built for debug and the sources are not provided.
13. Once you are ready to leave the application, press **F3** to end the application in the TN3270 window.
14. You can now disconnect your TN3270 terminal to end the demo.

### Stop the enterprise server:
When you have finished running the demo, you can stop the associated the enterprise server as follows:

1. In Eclipse, right-click the **BANKDEMO** server in **Server Explorer**, and click **Stop**.
2. Check the **Output** view for messages that the server has been stopped. A number of messages also appear in the **Enterprise Server Console Daemon** window before it closes down.

> **Note**: You should re-enable Enterprise Server security if you have not already done so. See *To recreate the Default Enterprise Server Security Configuration* in the product documentation for steps on how to re-enable security. 
