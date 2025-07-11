# Deploying and Running Bankdemo in a Performance and Availability Cluster with PostgreSQL
This demonstration configures the Bankdemo application to run in a Performance and Availability Cluster (PAC). Banking data is recorded in VSAM datasets that are stored in a PostgreSQL database. The database is accessed from COBOL programs by using `EXEC CICS` statements such as: `STARTBR FILE`, `READ FILE`, and `WRITE FILE`. The cluster is composed of two enterprise server instances that are running on the same machine.

The COBOL modules that are used to access the data are stored in the `sources/cobol/data/vsam` directory of this project and are unchanged from when the data is stored in indexed sequential files on disk and when not running in a PAC.

The Rocket Secrets Vault is used to store the database credentials.

Rocket&reg; Enterprise Suite products provide a proprietary runtime engine to enable compatibility for customers’ IBM CICS applications. IBM and CICS are registered trademarks of International Business Machines Corp. Rocket Enterprise Suite products do not include an IBM CICS engine and are not affiliated with IBM.


## Prerequisites
- Rocket&reg; Enterprise Developer or Rocket&reg; Enterprise Server.
- A TN3270 terminal emulator.
   The Rocket Software Secure Host Access (SHA) session server and TN3270 emulator is included with both Enterprise Developer and Enterprise Server.
- Ensure that the Directory Server (mfds) service is running and listening on the default port (86).
- Ensure that the Enterprise Server Common Web Administration (ESCWA) service is running and listening on the default port (10086).
- Ensure that a Redis server is installed and running.
- Verify that a PostgreSQL version 12 or later is installed and running.
- Ensure that you add the PostgreSQL `bin` directory path to the PATH environmental variable, so that you can use `psql`.
- Install and configure a PostgreSQL ODBC driver: 
   - Windows: [install appropriate driver](https://www.postgresql.org/ftp/odbc/releases/)
   - Ubuntu: `sudo apt-get install unixodbc unixodbc-dev odbc-postgresql`
   - RedHat: `sudo yum install unixODBC postgresql-odbc`
   - Amazon Linux 2: `sudo yum install unixODBC postgresql-odbc`
   - SuSE: `sudo zypper install unixODBC psqlODBC`
- Ensure that you installed Python 3.*n* and the `requests` package. You can install the package after installing Python with the following command: 
       `python -m pip install requests`

## Demonstration Overview
This demonstration shows a simple COBOL CICS "green screen" application that accesses VSAM data by using `EXEC CICS` statements in a scenario where that data is stored in a PostgreSQL database.

A Performance and Availability Cluster (PAC) is created containing two enterprise server instances.

The demonstration includes a Python script that helps create the enterprise server instances.

   - The script creates the enterprise server instances in the `BANKPAC1` and `BANKPAC2` subdirectories of this project.
   - The script creates the enterprise server instances by using (almost exclusively) the ESCWA Admin API.
   - A single command-line utility, `caspcrd`, is used to create the default CICS resource definition file.
   - The script configures the enterprise server instances for use with JCL and with the catalogued VSAM data sets. 
   - The script configures the enterprise server instance as a 64-bit server. You can change the configuration and deploy a 32-bit server (see Step 6 in the procedure below).
   - The script uses pre-built application modules.
   - Creates ODBC system data sources called `PG.MASTER`, `PG.VSAM`, `PG.CROSSREGION` and `PG.REGION`. 
   - The VSAM data is uploaded to the database by using `dbfhdeploy add` commands.
   - The script configures the enterprise server instances to use the Rocket Database File Handler (MFDBFH):
        - The credentials vault is populated with database credentials (using the `mfsecretsadmin` command).
        - Specifying the XA switch module `espgsqlxa` (its source is in the `src/enterpriseserver/xa` directory of the Enterprise Developer installation location).
        - The `esxaextcfg` module provides encrypted credentials to `espgsqlxa`.        
        - Setting the environment variables `MFDBFH_CONFIG` and `ES_DB_FH`.
        - Configuring the `CICS File Path` setting to point use an `MFDBFH` location (i.e., `sql:/...`).
        - Cataloguing the VSAM datasets with MFDBFH locations (i.e. `sql:/...`).
        - Defining a PAC scale-out repository (BANKPSOR) in the Redis server.
        - Configuring the servers to be members of a Performance and Availability Cluster (BANKPAC) that uses scale-out repository BANKPSOR.

The demonstration also includes some instructions to build the application from the sources (see the next section).


## Running the Demonstration
1. Expand the demonstration archive on your machine.
 
   Ensure that there is no `BANKPAC1` or `BANKPAC2` subdirectory in the location in which you expanded the archive. If there is one, delete it.

2. To open the ESCWA UI, type `http://localhost:10086` in a browser. 

   a. In the ESCWA UI, click **Operation**, expand **Directory Servers** and click **Default** in the left pane.

   b. Ensure there is no region called **BANKPAC1** or **BANKPAC2** already defined. If there is one, delete it.

3. Verify that there are no other demonstration servers running. This is to ensure no other servers use the same ports.

   The server for this demonstration uses a common server definition with many of the same listener ports as the ones that other servers in this repository might use.

4. Start a command prompt as an administrator (Windows) or a terminal for user under which Enterprise Servers run (Linux).

   **Note:** You need administrator's rights to configure the ODBC data source on Windows. On Linux they are created in the user `.odbc.ini` file.

5. Navigate to the `scripts` directory in the demonstration files.

   For example, if you have created a `C:\MFETDUSER` directory (Windows) or `/home/username/MFETDUSER` (Linux) and stored the Bankdemo folders in it, the `scripts` directory would be:

   Windows: `C:\MFETDUSER\scripts`
   
   Linux: `/home/username/MFETDUSER/scripts`

6. Edit the file `scripts/options/vsam_postgres_pac1.json` with a text editor. 

    - Verify and, if required, modify the values within the `database_connection` section to match the setting of the database that you are using.
    - Verify and, if required, modify the values within the `PAC` section to match the setting of the Redis server that you are using.
    - If you want to deploy a 32-bit enterprise server instance, or build the application from source, you need to change the configuration first as follows:
      - Change the `is64bit` and/or the `product` options as required. For example, `"product"="EDz"` indicates you are going to build the application from the sources, `"product"="ES"` indicates that the pre-built programs will be used.

7. Run the following command at the command prompt or the terminal. 

    ```
    python MF_Provision_Region.py vsam_postgres_pac1
    ```
    The command executes the `MF_Provision_Region.py` script which creates a PAC called BANKPAC including the BANKPAC1 server, and deploys the desired application configuration.

    A PAC with a single enterprise server instance is now running.

8. To create a second enterprise server instance within the same PAC, edit the file `scripts/options/vsam_postgres_pac2.json` with a text editor.
    - Verify and, if required, modify the values within the `database_connection` section to match the setting of the database that you are using.
    - Verify and, if required, modify the values within the `PAC` section to match the setting of the Redis server that you are using.
    
    - If you configured the deployment of a 32-bit enterprise server instance in step 6, or you build the application from source, you need to change the configuration first as follows:
      - Change the `is64bit` and/or the `product` options as required. For example, `"product"="EDz"` indicates you are going to build the application from the sources, `"product"="ES"` indicates that the pre-built programs will be used.

9. Run the following command at the command prompt or the terminal. 

    ```
    python MF_Provision_Region.py vsam_postgres_pac2
    ```
    This executes the `MF_Provision_Region.py` script that creates an additional BANKPAC2 server within the same BANKPAC, and deploys the desired application configuration.

10. Start a TN3270 terminal emulator, and connect to port 9023 or 9024. 

**Note:** A load balancer would usually be used to share the load between the instances.

   The Bankdemo application login screen loads.

11. Enter a valid user ID - a suitable one is `b0001`. You can use any character for the password because the password is not validated.

12. In ESCWA, select the BANKPSOR under **SORs**. Expand BANKPAC and note the two Enterprise Server instances BANKPAC1 and BANKPAC2.
    
13. You can use the `sources\jcl\ZBNKSTM.jcl` file (Windows) and `sources/jcl/ZBNKSTM.jcl` file (Linux) to run a JCL batch job from the ESCWA UI JCL control page. To open it, click **JES > Control**. 