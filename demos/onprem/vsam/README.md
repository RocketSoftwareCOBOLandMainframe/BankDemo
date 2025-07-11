# Deploying and Running Bankdemo with VSAM Data

This demonstration shows how to configure the Bankdemo application to store banking data in VSAM datasets on disk. You access the datasets from COBOL programs using `EXEC CICS` statements such as `STARTBR FILE`, `READ FILE`, `WRITE FILE`. The COBOL modules are stored in the `sources\cobol\data\vsam` (Windows) `sources/cobol/data/vsam` (Linux) directory of this project.

Rocket&reg; Enterprise Suite products provide a proprietary runtime engine to enable compatibility for customers’ IBM CICS applications. IBM and CICS are registered trademarks of International Business Machines Corp. Rocket Enterprise Suite products do not include an IBM CICS engine and are not affiliated with IBM. 

## Prerequisites
- Rocket&reg; Enterprise Developer or Rocket&reg; Enterprise Server
- A TN3270 terminal emulator. You can use the Rocket Software Secure Host Access (SHA) session server and TN3270 emulator included with both Enterprise Developer and Enterprise Server.
- Ensure that the Directory Server service (MFDS) is running and listening on the default port (86).
- Ensure that the Enterprise Server Common Web Administration (ESCWA) service is running and listening on the default port (10086).
- Python 3.*n* and the `requests` package from Python.org. You can install the package after installing Python with the following command: 
  ```
  python -m pip install requests
  ```

## Demonstration Overview
This demonstration shows a simple COBOL CICS "green screen" application which accesses VSAM data by using `EXEC CICS` statements where the data is held in indexed sequential files on a disk. 

The demonstration includes a Python script that helps you create the enterprise server instance. The script:

   - Creates the enterprise server instance in the `BANKVSAM` subdirectory of this project
   - Creates the enterprise server instance by using the ESCWA Admin API (almost exclusively).
   - Uses a single command-line utility, `caspcrd`, to create the default CICS resource definition file. 
   - Configures the enterprise server instance for use with JCL and the VSAM datasets are cataloged.
   - Configures the enterprise server instance as a 64-bit server. You can change the configuration and deploy a 32-bit server (see *Step 5* in the procedure below).
   - Configures the enterprise server instance to use pre-built application modules.

The demonstration also includes some instructions to build the application from the sources.

## Running the Demonstration

1. Extract the demonstration archive on your machine.
 
   Ensure that there is no `BANKVSAM` subdirectory in the location in which you extracted the archive. If there is one, you must delete it.

2. In a web browser, open the ESCWA UI by entering `http://localhost:10086`.  

   a. In the ESCWA UI, click **Operation**, expand **Directory Servers**, and in the left pane click **Default**.

   b. Ensure that there is no region called **BANKVSAM** already defined. If there is one, delete it.

3. Verify that there are no other demonstration servers running. This is to ensure that no other servers use the same ports. 

   The server for this demonstration uses a common server definition with many of the same listener ports as the ones other servers in this repository might use.

4. Start a command prompt (Windows) or a terminal (Linux), and navigate to the `scripts` directory of the demonstration folder.

   For example, if you have created a `C:\MFETDUSER` directory (Windows) or `/home/username/MFETDUSER` (Linux) and stored the Bankdemo folders in it, the `scripts` directory would be:
   
   - Windows: `C:\MFETDUSER\scripts` 
   - Linux: `/home/username/MFETDUSER/scripts` 

5. If you want to deploy a 32-bit enterprise server instance, or build the application from the source, you must change the configuration first:
    
    a. Open the `vsam.json` file in a text editor. The file is located in the `options` subdirectory:

    -  Windows: `C:\MFETDUSER\scripts\options` 
    - Linux: `/home/username/MFETDUSER/scripts/options`  

    b. Change the `is64bit` and/or the `product` options as required. 
    
    For example, `"product"="EDz"` indicates you will build the application from the sources, `"product"="ES"` indicates that the pre-built programs will be used.

5. Run the following command at the command prompt or the terminal. 

    ```
    python MF_Provision_Region.py vsam
    ```
   This executes the `MF_Provision_Region.py` script which creates a BANKVSAM server, and deploys the desired application configuration.
   
   
6. Start a TN3270 terminal emulator, and connect to port 9023. 

   The Bankdemo application login screen loads.

7. Enter a valid user ID, for example, `b0001` with any characters for the password as the password is not validated.

8. In the ESCWA UI, under **Directory Servers > Default**, select the BANKVSAM server and explore the options on the **General** tab. 

   Click the **General** menu, and select any option from the menu to explore the server configuration.

9. You can use the `sources\jcl\ZBNKSTM.jcl` file (Windows) and `sources/jcl/ZBNKSTM.jcl` file (Linux) to run a JCL batch job from the ESCWA UI JCL control page. To open it click **JES > Control**.
