# Deploying and Running Bankdemo with PostgreSQL

This demonstration configures the Bankdemo application to store banking data in a PostgreSQL database. The database is accessed from COBOL programs using `EXEC SQL` statements. These COBOL programs are stored in the `sources\cobol\data\sql` (Windows) and `sources/cobol/data/sql` (Linux) directory of this project.

The SQL database is populated with bank account data.

Rocket&reg; Enterprise Suite products provide a proprietary runtime engine to enable compatibility for customers’ IBM CICS applications. IBM and CICS are registered trademarks of International Business Machines Corp. Rocket Enterprise Suite products do not include an IBM CICS engine and are not affiliated with IBM. 


## Prerequisites

- Rocket&reg; Enterprise Developer or Rocket&reg; Enterprise Server.
- A TN3270 terminal emulator. 
   You can use the Rocket Software Secure Host Access (SHA) session server and the TN3270 emulator included with both Enterprise Developer and Enterprise Server.
- Ensure that the Directory Server service (MFDS) is running and listening on the default port (86).
- Ensure that the Enterprise Server Common Web Administration (ESCWA) service is running and listening on the default port (10086).
- PostgreSQL version 12 or later.
- Ensure that you add the PostgreSQL `bin` directory path to the PATH environmental variable, so that you can use `psql`.
- Ensure that you install and configure a PostgreSQL ODBC driver: 
   - Windows: [install the appropriate driver](https://www.postgresql.org/ftp/odbc/releases/)
   - Ubuntu: run `sudo apt-get install unixodbc unixodbc-dev odbc-postgresql`
   - RedHat: run `sudo yum install unixODBC postgresql-odbc`
   - Amazon Linux 2: run `sudo yum install unixODBC postgresql-odbc`
   - SUSE: run `sudo zypper install unixODBC psqlODBC`
- Python 3.*n* and the `requests psycopg2-binary` packages. You can install the packages after installing Python with the following command: 
  ```
  python -m pip install requests psycopg2-binary
  ```

## Demonstration Overview

This demonstration shows a simple COBOL CICS "green screen" application which accesses data using `EXEC SQL` statements. 

The demonstration includes a Python script that helps you create the enterprise server instance. The script:

   - Creates the enterprise server instance in the `BANKSQL` subdirectory of this project.
   - Creates the enterprise server instance by using the ESCWA Admin API (almost exclusively).
   - Uses a single command-line utility, `caspcrd`, to create the default CICS resource definition file. 
   - Configures the enterprise server instance for use with JCL and the VSAM datasets are cataloged.
   - Configures the enterprise server instance as a 64-bit server. You can change the configuration and deploy a 32-bit server (see *Step 6* in the procedure below).
   - Uses pre-built application modules.
   - Creates an ODBC system data source called `bank`.
   - Populates the database tables with sample data.
   - Configures the enterprise server instance to use PostgreSQL:
      - The credentials vault is populated with database credentials (using the `mfsecretsadmin` command)
      - Builds the PostgreSQL RM switch module `esxaextcfg`. By default, the source COBOL file is in:
         - The `src/enterpriseserver/xa` directory of the Enterprise Developer installation location on Linux.
         - The `src\enterpriseserver\xa ` directory of the Enterprise Developer installation location on Windows.
      - The `esxaextcfg` module provides encrypted credentials to `espgsqlxa`.

The demonstration also includes some instructions on how to build the application from the sources.

## Running the Demonstration

1. Extract the demonstration archive on your machine.

   Ensure that there is no `BANKSQL` subdirectory in the location in which you extracted the archive. If there is one, delete it.

2. In a web browser, open the ESCWA UI by entering `http://localhost:10086`. 

   a. In the ESCWA UI, click **Operation**, expand **Directory Servers**, and in the left pane click **Default**.

   b. Ensure that there is no region called **BANKSQL** already defined. If there is one, delete it.

3. Verify that there are no other demonstration servers running. This is to ensure that no other servers use the same ports. 

   The server for this demonstration uses a common server definition with many of the same listener ports as the ones other servers in this repository might use.

4. Start a command prompt as an administrator (Windows) or a terminal for a user under which Enterprise Servers run (Linux).

   > **Note:** You must have administrator privileges to configure the ODBC data source on Windows. On Linux the ODBC data source is created in the user `.odbc.ini` file.

5. Navigate to the `scripts` directory of the demonstration.

   For example, if you have created a `C:\MFETDUSER` directory (Windows) or `/home/username/MFETDUSER` (Linux) and stored the Bankdemo folders in it, the `scripts` directory would be:
   
   - Windows: `C:\MFETDUSER\scripts` 
   - Linux: `/home/username/MFETDUSER/scripts` 

6. Edit the JSON configuration file `sql_postgres.json` with a text editor. The file is located in the `options` subdirectory:

   - Windows: `C:\MFETDUSER\scripts\options` 
   - Linux: `/home/username/MFETDUSER/scripts/options` 

    a.  Verify and, if required, modify the values within the `database_connection` section to match the settings of the database you are using.

    b.  If you want to deploy a 32-bit enterprise server instance, or build the application from the source, you must change the configuration by updating the `is64bit` and/or the `product` options as required. 
       
    For example, `"product"="EDz"` indicates that you will build the application from the sources and `"product"="ES"` indicates that the pre-built applications will be used.

7. Run the following python script from the `scripts` directory with the specified option to create the enterprise server instance, and to deploy the application:

   ```
   python MF_Provision_Region.py sql_postgres
   ``` 
8. Start a TN3270 terminal emulator and connect it to port 9023.

   The Bankdemo application login screen loads.

7. Enter a valid user ID, for example, `b0001` with any characters for the password as the password is not validated.

8. In the ESCWA UI, under **Directory Servers > Default**, select the BANKSQL server and explore the options on the **General** tab.

   Click the **General** menu, and select any option from the menu to explore the server configuration.
    
9. You can use the `sources\jcl\ZBNKSTMS.jcl` file (Windows) and `sources/jcl/ZBNKSTMS.jcl` file (Linux) to run a JCL batch job from the ESCWA UI JCL control page. To open it click **JES > Control**.

