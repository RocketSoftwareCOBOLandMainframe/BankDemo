# Deploying and running Bankdemo in a Performance and Availability Cluster with PostgreSQL
This demonstration configures the Bankdemo application to run in a Performance and Availability Cluster (PAC), storing banking data in VSAM datasets stored within a PostgreSQL database. The database is accessed from COBOL programs using `EXEC CICS` statements such as: `STARTBR FILE`, `READ FILE`, and `WRITE FILE`. The cluster is composed of two Enterprise Server instances that are running on the same machine.

The COBOL modules used to access the data are stored in the `sources/cobol/data/vsam` directory of this project and are unchanged from when the data is stored in indexed sequential files on disk and when not running in a PAC.

The Rocket Secrets Vault is used to store the database credentials.

## Prerequisites
- Rocket® Enterprise Developer or Rocket® Enterprise Server.
- A TN3270 terminal emulator. The Rocket® Host Access for the Cloud session server and TN3270 emulator is included with both Enterprise Developer and Enterprise Server.
- Ensure that the Rocket Directory Server (mfds) is running and listening on the default port (86).
- Ensure that the Enterprise Server Common Web Administration (ESCWA) service is running and listening on the default port (10086).
- Ensure that a Redis server is installed and running.
   - The Rocket Enterprise Developer products on Windows include AdoptRedis which is suitable for testing and demonstration purposes. 
- Verify that a PostgreSQL version 12 or later is installed and running.
- Ensure that the PostgreSQL `psql` command is available on the PATH.
- Install and configure a PostgreSQL ODBC driver: 
   - Windows: [install appropriate driver](https://www.postgresql.org/ftp/odbc/versions/msi/)
   - Ubuntu: `sudo apt-get install unixodbc unixodbc-dev odbc-postgresql`
   - RedHat: `sudo yum install unixODBC postgresql-odbc`
   - Amazon Linux 2: `sudo yum install unixODBC postgresql-odbc`
   - SuSE: `sudo zypper install unixODBC psqlODBC`
- Ensure that you installed Python 3.*n* and the `requests` package. You can install the package after installing Python with the following command: 
       `python -m pip install requests`

## Demonstration overview
This demonstration shows a simple COBOL IBM® CICS® "green screen" application accessing VSAM data using `EXEC CICS` statements where that data is actually stored in a PostgreSQL database.
A Performance and Availability Cluster (PAC) is created containing two enterprise server instances.

The demonstration includes a Python script that helps create the enterprise server instances.

   - The script creates the enterprise server instances in the `BANKPAC1` and `BANKPAC2` subdirectories of this project.
   - The script creates the enterprise server instances by using (almost exclusively) the ESCWA Admin API.
   - A single command-line utility, `caspcrd`, is used to create the default IBM CICS resource definition file.
   - The script configures the enterprise server instances for use with JCL and with the catalogued VSAM datasets. 
   - The enterprise server instances are configured as 64-bit servers and can be reconfigured to deploy a 32-bit server (see the next section).
   - The enterprise server instances use pre-built application modules.
   - Two ODBC system data sources called `PG.MASTER`, `PG.VSAM`, `PG.CROSSREGION` and `PG.REGION` are created.<!-- Two sources with four names? -->
   - The VSAM data is uploaded to the database using `dbfhdeploy add` commands.
   - The server instances are configured to use the Rocket Database File Handler (MFDBFH) by:
       - The credentials vault is populated with database credentials (using the `mfsecretsadmin` command).
        - Specifying the XA switch module espgsqlxa (its source is in the `src/enterpriseserver/xa` directory of the Enterprise Developer installation location).
        - The `esxaextcfg` module provides encrypted credentials to `espgsqlxa`.        
        - Setting the environment variables `MFDBFH_CONFIG` and `ES_DB_FH`.
        - Configuring the `CICS File Path` setting to point use an `MFDBFH` location (i.e., `sql://...`).
        - Cataloguing the VSAM datasets with MFDBFH locations (i.e. `sql:/...`).
        - Defining a PAC scale-out repository (BANKPSOR) in the Redis server.
        - Configuring the servers to be members of a Performance and Availability Cluster (BANKPAC) using scale-out repository BANKPSOR. <!-- Are the servers configured to be members of a PAC "by using" a scale out repository or "that uses a scale out repository"? -->

The demonstration also includes some instructions to build the application from the sources (see the next section).


## Running the demonstration
1. Expand the demonstration archive on your machine.
 
   Ensure that there is no `BANKPAC1` or `BANKPAC2` subdirectory in the location in which you expanded the archive. If there is one, you must delete it.
2. Load the ESCWA UI by entering http://localhost:10086 in a browser. 

   a. In the ESCWA UI, click **Native**, expand **Directory Servers** and click **Default** in the left pane.

   b. Ensure there is no region called **BANKPAC1** or **BANKPAC2** already defined. If there is one, delete it.

3. Ensure that there are no other demonstration servers running. This is to ensure no other servers use the same ports. The server for this demonstration uses a common server definition with many of the same listener ports as the ones other servers in this repository might use.
4. Start an administrator's command prompt (Windows) or a terminal for user under which Enterprise Servers run (Linux).

   **Note:** You need administrator's rights to configure the ODBC data source on Windows. On Linux they are created in the user .odbc.ini file.

5. Navigate to the `scripts` directory in the demonstration files.
6. Edit the file `scripts/options/vsam_postgres_pac1.json` with a text editor:

    - Verify and, if required, modify the values within the `database_connection` section to match the setting of the database you are using.
    - Verify and, if required, modify the values within the `PAC` section to match the setting of the Redis server you are using.
    
    - If you want to deploy a 32-bit enterprise server instance, or build the application from source, you need to change the configuration first as follows:
      - Change the `is64bit` and/or the `product` options as required. For example, `"product"="EDz"` indicates you are going to build the application from the sources, `"product"="ES"` indicates that the pre-built programs will be used.

7. Execute the following command at the command prompt or the terminal. This executes the `MF_Provision_Region.py` script which creates a PAC called BANKPAC including the BANKPAC1 server, and deploys the desired application configuration.

    ```
    python MF_Provision_Region.py vsam_postgres_pac1
    ```
8. A PAC with a single Enterprise Server instance is now running, to create a second Enterprise Server instance within the same PAC edit the file `scripts/options/vsam_postgres_pac2.json` with a text editor:
    - Verify and, if required, modify the values within the `database_connection` section to match the setting of the database you are using.
    - Verify and, if required, modify the values within the `PAC` section to match the setting of the Redis server you are using.
    
    - If you deployed a 32-bit enterprise server instance in set 6, or build the application from source, you need to change the configuration first as follows:
      - Change the `is64bit` and/or the `product` options as required. For example, `"product"="EDz"` indicates you are going to build the application from the sources, `"product"="ES"` indicates that the pre-built programs will be used.

9. Execute the following command at the command prompt or the terminal. This executes the `MF_Provision_Region.py` script which creates an additional BANKPAC2 server within the same BANKPAC, and deploys the desired application configuration.

    ```
    python MF_Provision_Region.py vsam_postgres_pac2
    ```
10. Start a TN3270 terminal emulator, and connect to port 9023 or 9024. N.B. A load balancer would usually be used to share the load between the instances.

   The Bankdemo application login screen should load.

11. Enter a valid user-id - a suitable user-id is **B0001** with any characters for the password as the password is not validated.

12. In ESCWA, select the BANKPSOR under **SORs**. Expand BANKPAC and note the two Enterprise Server instances BANKPAC1 and BANKPAC2
    
13. The `sources\jcl\ZBNKSTMT.jcl` file can be used to run a JCL batch job via the **JES**, **Control** ESCWA dropdown menu.
