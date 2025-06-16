import os
import subprocess
import sys
from utilities.output import write_log 
from utilities.misc import powershell

def create_windows_dsn(db_type, is64bit, dsn, databaseName, database_connection):
    if db_type == 'postgres':
        driverBitism="32-bit"
        if is64bit == True:
            driverBitism="64-bit"

        findDriver='$Drivers = Get-OdbcDriver -Name "PostgreSQL*ANSI*" -Platform {};\n '.format(driverBitism)
        ##findDSN='$DSN = Get-OdbcDsn -Name "{}" -Platform {} -DsnType System;\n'.format(dsn, driverBitism)
        deleteDSN ='Remove-OdbcDSN -Name "{}" -Platform {} -DsnType System;\n '.format(dsn, driverBitism)
        addDSN ='Add-OdbcDSN -Name "{}" -Platform {} -DsnType System -DriverName $Drivers[0].Name'.format(dsn, driverBitism) 
        addDSNProperties = ' -SetPropertyValue "Database={}","ServerName={}","Port={}","Username={}","Password={}"\n'.format(databaseName, database_connection['server_name'],database_connection['server_port'],database_connection['user'],database_connection['password'])
        fullCommand=findDriver + deleteDSN + addDSN + addDSNProperties
        write_log(fullCommand)
        powershell(fullCommand)
    else:
        write_log("create_windows_dsn: invalid db_type {}".format(db_type))
        sys.exit(1)

def check_odbc_driver_installed(db_type):
    if db_type != 'postgres':
        write_log("check_odbc_driver: invalid db_type {}".format(db_type))
        sys.exit(1)
    driver_name = subprocess.getoutput("odbcinst -q -d | grep ANSI | grep PostgreSQL | sed 's/\\[//g;s/\\]//g'")
    if driver_name=='':
        driver_name = subprocess.getoutput("odbcinst -q -d | grep PostgreSQL | sed 's/\\[//g;s/\\]//g'")
    if driver_name[0:10] != 'PostgreSQL':
        write_log("check_odbc_driver: unable to find ODBC driver, running odbcinst -q -d")
        return False
    
    write_log("check_odbc_driver: found driver={}".format(driver_name))
    return True     

def create_linux_dsn(db_type, dsn_name, description, database_name, database_connection):
    if db_type != 'postgres':
        write_log("create_linux_dsn: invalid db_type {}".format(db_type))
        sys.exit(1)
    driver_name = subprocess.getoutput("odbcinst -q -d | grep ANSI | grep PostgreSQL | sed 's/\\[//g;s/\\]//g'")
    if driver_name=='':
        driver_name = subprocess.getoutput("odbcinst -q -d | grep PostgreSQL | sed 's/\\[//g;s/\\]//g'")
    if driver_name=='':
        write_log("create_linux_dsn: unable to find PostgreSQL ODBC driver\nSee 'odbcinst -q -d'")
        sys.exit(1)

    server_name=database_connection['server_name']
    port=database_connection['server_port']
    write_log("creating DSN {}".format(dsn_name))
    with open("dsn.template", 'w') as file:
        lines=[
          "[{}]".format(dsn_name),
          "Driver={}".format(driver_name),
          "Description={}".format(description),
          "Servername={}".format(server_name),
          "Port={}".format(port),
          "Database={}".format(database_name)]
        #have to add newline character at end of each line, as writelines does not automatically do this
        file.writelines(line + '\n' for line in lines)
    #-h installs user DSN (eg to /home/demouser/.odbc.ini) instead of system DSN
    waitstatus=os.system("odbcinst -install -s -h -f dsn.template")
    exitcode=os.WEXITSTATUS(waitstatus)
    write_log("exitcode={}".format(exitcode))

