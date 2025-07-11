# Deploying and Running Bankdemo with VSAM Stored in PostgreSQL using MFDBFH
This demonstration configures the Bankdemo application to store banking data in VSAM datasets stored within a PostgreSQL database. The database is accessed from COBOL programs by using `EXEC CICS` statements such as: `STARTBR FILE`, `READ FILE`, and `WRITE FILE`. 

The COBOL modules used to access the data are stored in the `sources/cobol/data/vsam` directory of this project and are unchanged from when the data is stored in indexed sequential files on disk.

The Rocket Secrets Vault is used to store the database credentials.

Rocket&reg; Enterprise Suite products provide a proprietary runtime engine to enable compatibility for customers’ IBM CICS applications. IBM and CICS are registered trademarks of International Business Machines Corp. Rocket Enterprise Suite products do not include an IBM CICS engine and are not affiliated with IBM.


## Prerequisites
- Rocket&reg; Enterprise Developer or Rocket&reg; Enterprise Server.
- A TN3270 terminal emulator.
   You can use the Rocket Software Secure Host Access (SHA) session server and the TN3270 emulator included with both Enterprise Developer and Enterprise Server.
- Ensure that the Directory Server (mfds) service is running and listening on the default port (86).
- Ensure that the Enterprise Server Common Web Administration (ESCWA) service is running and listening on the default port (10086).
- Verify that PostgreSQL version 12 or later is installed and running.
- PostgreSQL ODBC driver: 
   - Windows: [Install the appropriate driver](https://www.postgresql.org/ftp/odbc/releases/)
   - Ubuntu: `sudo apt-get install unixodbc unixodbc-dev odbc-postgresql`
   - RedHat: `sudo yum install unixODBC postgresql-odbc`
   - Amazon Linux 2: `sudo yum install unixODBC postgresql-odbc`
   - SuSE: `sudo zypper install unixODBC psqlODBC`
-Ensure that you installed Python 3.*n* and the `requests` package. You can install the package after installing Python with the following command: 
  
      ` python -m pip install requests`

## Demonstration Overview
This demonstration shows a simple COBOL CICS "green screen" application accessing VSAM data using `EXEC CICS` statements where that data is actually stored in a PostreSQL database. 

The demonstration includes a Python script that helps create the enterprise server instance.

   - The script creates the enterprise server instance in the `BANKMFDB` subdirectory of this project.
   - The script creates the instance by using (almost exclusively) the ESCWA Admin API.
   - A single command-line utility, `caspcrd`, is used to create the default CICS resource definition file.
   - The script configures the enterprise server instances for use with JCL and the VSAM datasets are cataloged.  
   - The script configures the enterprise server instance as a 64-bit server. You can change the configuration and deploy a 32-bit server (see Step 6 in the procedure below).
   - The enterprise server instance uses pre-built application modules.
   - Two ODBC system data sources, called `BANKVSAM.MASTER` and `BANKVSAM.VSAM`, are created.
   - The VSAM data is uploaded to the database by using `dbfhdeploy add` commands. 
   - The server instance is configured to use the Database File Handler:
        - The credentials vault is populated with database credentials (by using the `mfsecretsadmin` command).
        - Specifying the XA switch module `espgsqlxa` (its source is in the `src/enterpriseserver/xa` directory of the Enterprise Developer installation location).
        - The `esxaextcfg` module provides encrypted credentials to `espgsqlxa`.        
        - Setting the environment variables `MFDBFH_CONFIG` and `ES_DB_FH`.
        - Configuring the `CICS File Path` setting to point use an MFDBFH location (i.e., `sql:/...`).
        - Cataloging the VSAM datasets with MFDBFH locations (i.e. `sql:/...`).

The demonstration also includes some instructions to build the application from the sources (see the next section).


## Running the Demonstration
1. Expand the demonstration archive on your machine.
 
   Ensure that there is no `BANKMFDB` subdirectory in the location in which you expanded the archive. If there is one, you must delete it.
2. To open the ESCWA UI, type `http://localhost:10086` in a browser. 

   a. In the ESCWA UI, click **Operation**, expand **Directory Servers** and click **Default** in the left pane.

   b. Ensure there is no region called **BANKMFDB** already defined. If there is one, delete it.

3. Verify that there are no other demonstration servers running. This is to ensure no other servers use the same ports.

   The server for this demonstration uses a common server definition with many of the same listener ports as the ones that other servers in this repository might use.

4. Start a command prompt as an administrator (Windows) or a terminal for user under which Enterprise Servers run (Linux).

   **Note:** You need administrator's rights to configure the ODBC data source on Windows. On Linux they are created in the user `.odbc.ini` file.

5. Navigate to the `scripts` directory in the demonstration files.

   For example, if you have created a `C:\MFETDUSER` directory (Windows) or `/home/username/MFETDUSER` (Linux) and stored the Bankdemo folders in it, the `scripts` directory would be:

   Windows: `C:\MFETDUSER\scripts`
   
   Linux: `/home/username/MFETDUSER/scripts`

6. Edit the file `scripts/options/vsam_postgres.json` with a text editor:

    - Verify and, if required, modify the values within the `database_connection` section to match the setting of the database that you are using.
    
    - If you want to deploy a 32-bit enterprise server instance, or build the application from source, you need to change the configuration first as follows:
      - Change the `is64bit` and/or the `product` options as required. For example, `"product"="EDz"` indicates that you are going to build the application from the sources, `"product"="ES"` indicates that the pre-built programs will be used.

7. Run the following command at the command prompt or the terminal. 

    ```
    python MF_Provision_Region.py vsam_postgres
    ```
   This executes the `MF_Provision_Region.py` script which creates a BANKMFDB server, and deploys the desired application configuration.

8. Start a TN3270 terminal emulator, and connect to port 9023. 

   The Bankdemo application login screen loads.

9. Enter a valid user ID - a suitable one is `b0001`. You can use any character for the password because the password is not validated.

10. In ESCWA, select the BANKMFDB server under **Directory Servers > Default**. See the options on the **General** tab. Also, click the downwards arrow next to **General** and click any of the menu items to explore the server configuration.
    
11. You can use the `sources\jcl\ZBNKSTM.jcl` file (Windows) and `sources/jcl/ZBNKSTM.jcl` file (Linux) to run a JCL batch job from the ESCWA UI JCL control page. To open it, click **JES > Control**. 
