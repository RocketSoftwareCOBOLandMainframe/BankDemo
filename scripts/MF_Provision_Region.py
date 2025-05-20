#!/usr/bin/python3

"""
Copyright 2010 – 2024 Rocket Software, Inc. or its affiliates. 
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

Description:  A script to create a server region. 
"""

import os
import sys
import glob
from ESCWA.escwa_session import EscwaSession
from utilities.pac import install_region_into_pac_by_name, create_crossregion_database, create_region_database
from utilities.misc import parse_args, set_MF_environment, get_EclipsePluginsDir, get_CobdirAntDir, check_elevation, check_esuid
from utilities.input import read_json, read_txt
from utilities.output import write_json, write_log 
from utilities.filesystem import create_new_system, deploy_application, deploy_system_modules, deploy_partitioned_data
from utilities.resource import add_postgresxa, catalog_datasets, write_secret
from utilities.deploy import deploy_application_option, deploy_dfhdrdat_postgres_pac, create_db_vault_secrets, catalog_pac_datasets
from database.odbc import check_odbc_driver_installed
from ESCWA.region_control import add_region, start_region, del_region, confirm_region_status, stop_region
from ESCWA.region_config import update_region, update_region_attribute, update_alias, add_initiator, check_security
from ESCWA.comm_control import set_jes_listener, set_commsserver_local
from utilities.exceptions import ESCWAException
from ESCWA.resourcedef import  add_sit, add_Startup_list, add_groups, add_fct, add_ppt, add_pct, update_sit_in_use
from ESCWA.mq_config import add_mq_listener
from build.MFBuild import  run_ant_file
from pathlib import Path
from MF_Create_PAC import create_pac

import shutil
import subprocess
if not sys.platform.startswith('win32'):
    from pwd import getpwuid
    from os  import stat

def powershell(cmd):
    completed = subprocess.run(["powershell", "-Command", cmd], capture_output=True)
    return completed

def checkElevation():
    # Check if the current process is running as administator role
    isAdmin = '$user = [Security.Principal.WindowsIdentity]::GetCurrent();if ((New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {exit 1} else {exit 0}'
    completed = powershell(isAdmin)
    return completed.returncode == 1

def createWindowsDSN(database_connection, is_64bit, dsn_name, database_name):
    driverBitism="32-bit"
    if is_64bit == True:
        driverBitism="64-bit"

    findDriver='$Drivers = Get-OdbcDriver -Name "PostgreSQL*ANSI*" -Platform {};\n '.format(driverBitism)
    ##findDSN='$DSN = Get-OdbcDsn -Name "{}" -Platform {} -DsnType System;\n'.format(dsn_name, driverBitism)
    deleteDSN ='Remove-OdbcDSN -Name "{}" -Platform {} -DsnType System;\n '.format(dsn_name, driverBitism)
    addDSN ='Add-OdbcDSN -Name "{}" -Platform {} -DsnType System -DriverName $Drivers[0].Name'.format(dsn_name, driverBitism) 
    addDSNProperties = ' -SetPropertyValue "Database={}","ServerName={}","Port={}","Username={}","Password={}"\n'.format(database_name, database_connection['server_name'],database_connection['server_port'],database_connection['user'],database_connection['password'])
    fullCommand=findDriver + deleteDSN + addDSN + addDSNProperties
    write_log(fullCommand)
    powershell(fullCommand)

def find_owner(filename):
    return getpwuid(stat(filename,follow_symlinks=False).st_uid).pw_name

def create_region(main_configfile):
    #set current working directory
    cwd = os.getcwd()
    
    #determine where the product has been installed
    if sys.platform.startswith('win32'):
        os_type = 'Windows'
        os_distribution =''
        install_dir = set_MF_environment (os_type)
        if install_dir is None:
            write_log('COBOL environment not found')
            exit(1)
        cobdir = str(Path(install_dir).parents[0])
        os.environ['COBDIR'] = cobdir
        pathMfAnt = Path(os.path.join(cobdir, 'bin', 'mfant.jar')) 
    else:
        os_type = 'Linux'
        os_distribution = '' #distro.id()
        install_dir = set_MF_environment (os_type)
        if install_dir is None:
            write_log('COBOL environment not set - run cobsetenv')
            exit(1)
        cobdir = str(Path(install_dir).parents[0])
        if cobdir == '':
            write_log('COBOL environment not set - run cobsetenv')
            exit(1)
        pathMfAnt = Path(os.path.join(cobdir,'lib', 'mfant.jar')) 

    write_log('COBDIR={}'.format(cobdir))
    write_log('Provision Process starting')
   
    config_dir = os.path.join(cwd, 'config')
    options_dir = os.path.join(cwd, 'options')

    #read demo configuration file
    write_log('Reading deployment config file {}'.format(main_configfile))
    main_config = read_json(main_configfile)

    #retrieve the demo configuration settings
    ip_address = main_config["ip_address"]
    region_name = main_config["region_name"]
    pac_name = main_config["pac_name"]

    if main_config["product"] != '':
        mf_product = main_config["product"]
    else:
        mf_product = 'EDz'
    # Override if compiler is mfant.jar is not found
    if mf_product == 'EDz':
        if pathMfAnt.is_file() != True:
            mf_product = 'ES'
        elif os_type == 'Windows':
            # Use the product JDK if possible
            pathJDK = Path(os.path.join(cobdir,'AdoptOpenJDK'))
            if pathJDK.is_dir():
                os.environ["JAVA_HOME"] = str(pathJDK)
                write_log('Using JAVA_HOME={}'.format(str(pathJDK)))
            elif "JAVA_HOME" not in os.environ:
                write_log('JAVA_HOME not set, cannot build application')
                mf_product = 'ES'
            else:
                pathJDK = Path(os.environ["JAVA_HOME"])
                if pathJDK.is_dir() != True:
                    write_log('JAVA_HOME invalid, cannot build application')
                    mf_product = 'ES'
        else:
            if "JAVA_HOME" not in os.environ:
                write_log('JAVA_HOME not set, cannot build application')
                mf_product = 'ES'

    write_log('Configured for product: {}'.format(mf_product))

    cics_region = main_config["CICS"]
    jes_region = main_config["JES"]
    mq_region = main_config["MQ"]

    is64bit = main_config["is64bit"]
    if os_type == 'Linux':
        path32 = Path(os.path.join(install_dir,'casstart32'))
        if path32.is_file() == False:
            # No 32bit executables
            is64bit = True;

    if 'database' not in main_config:
        database_type = 'none'
        dataversion = 'vsam'
    else:
        database_type= main_config["database"]
        sql_folder= os.path.join(cwd, 'config', 'database', database_type)
        if database_type.split('_')[0] == 'VSAM':
            dataversion = 'vsam'
        else:
            dataversion = 'sql'

    if sys.platform.startswith('win32'):
        if  database_type != 'VSAM':
            if check_elevation() != True:
                write_log('ERROR: Script must be Run As Administrator to create ODBC connections')
                sys.exit(1)
        esuid = ''
    else:
        casstart = os.path.join(os.environ['COBDIR'], 'bin', 'casstart')
        esuid = find_owner(casstart)
        if check_esuid(esuid) != True:
            write_log('ERROR: Script must be run by the ES user: {}'.format(esuid))
            sys.exit(1)
        if database_type != 'VSAM':
            if check_odbc_driver_installed('postgres') != True:
                write_log('ERROR: PostgreSQL ODBC driver not found')
                sys.exit(1)
 
    #determine the individual component configuration files to be used
    configuration_files = main_config["configuration_files"]

    #base_config is used for settings to create the base region definition
    base_config = configuration_files["base_config"]

    #update_config is used to amend the base settings for the region definition
    update_config = configuration_files["update_config"]

    #env_config is used to set the environment space details for the region
    env_config = configuration_files["env_config"]

    #secrets_config is used to set the secrets details for the region
    secrets_config = configuration_files["secrets_config"]

    #alias_config and JES Alias updates that are region for a region - this setting is optional
    if 'alias_config' not in configuration_files:
        alias_config = 'none'
    else:
        alias_config = configuration_files["alias_config"]

    #init_config contains the details of any JES initiators that need to be configured - this settings is optional
    if 'init_config' not in configuration_files:
        init_config ='none'
    else:
        init_config = configuration_files["init_config"]

    region_port = main_config['regionPort']
    jes_port = main_config['jesPort']

    #start the provision of the region
    parentdir = str(Path(cwd).parents[0])
    template_base = os.path.join(parentdir, 'system')
    sys_base = os.path.join(parentdir, region_name, 'system')

    create_new_system(template_base,sys_base)
    
    mfdbfh_config=''
    # Update the mfdbfh.cfg file with the database user id
    if 'mfdbfh_config' in main_config:
        mfdbfh_config = os.path.join(sys_base, 'config', main_config['mfdbfh_config'])
        if 'database_connection' in main_config:
            database_connection = main_config['database_connection']

            # Set the user id mfdbfh.cfg
            f_in = open(mfdbfh_config, "rt")
            data = f_in.read()
            f_in.close()
            new_data = data.replace('$$user$$', database_connection['user'])
            f_out = open(mfdbfh_config, "wt")
            f_out.write(new_data)
            f_out.close()

    if len(pac_name) > 0 and 'PAC' in main_config:
        pac_config = main_config['PAC']
    else:
        pac_config = None

    if len(pac_name) > 0 and pac_config is None:
        write_log ('No PAC config, skipping resource definition file creation')
    else:
        #create an empty resource definition file
        caspcrd = os.path.join(install_dir, 'caspcrd')
        rdef = os.path.join(sys_base, 'rdef')
        create_dfhdrdat =  '\"' +caspcrd + '\" /c /dp=' + rdef
        write_log ('Create resource definition file {}'.format(create_dfhdrdat))
        caspcrd_process = os.system(create_dfhdrdat)
        #change ownership to match ES user
        if os_type == 'Linux':
            dfhdrdat = os.path.join(rdef, 'dfhdrdat')
            shutil.chown(dfhdrdat, esuid, esuid)
            write_log ('Set owner of {} to {}'.format(dfhdrdat, esuid))
        create_db_vault_secrets(os_type, main_config, esuid)
    
    base_config = os.path.join(config_dir, base_config)
    update_config = os.path.join(config_dir, update_config)
    alias_config = os.path.join(config_dir, alias_config)
    init_config = os.path.join(config_dir, init_config)
    env_config = os.path.join(config_dir, env_config)
    secrets_config = os.path.join(config_dir, secrets_config)
    resourcedef_dir = os.path.join(config_dir, 'CSD')

    session = EscwaSession("http", ip_address, 10086)
        
    try:
        write_log ('check if VSAM ESM is enabled')
        check_security(session)
    except ESCWAException as exc:
        write_log(exc)
        try:
            write_log('logon to ESCWA.')
            try:
                req_body = read_json(secrets_config)
                login_secrets_location=req_body["login_location"]
            except InputException as exc:
                raise ESCWAException('Unable to read template file: {}.'.format(secrets_config)) from exc
            if os_type == 'Linux':
                mfsecretsadmin = os.path.join(install_dir, 'mfsecretsadmin')
            else:
                mfsecretsadmin = os.path.join(install_dir, 'mfsecretsadmin.exe')
            session.logon(mfsecretsadmin, login_secrets_location)
        except ESCWAException as exc:
            write_log('Unable to logon to ESCWA.')
            write_log(exc)
            sys.exit(1)

    try:
        write_log ('Region \033[1m{}\033[0m being added'.format(region_name))
        add_region(session, region_name, region_port, base_config, is64bit)
    except ESCWAException as exc:
        write_log('Unable to create region.')
        write_log(exc)
        sys.exit(1)

    try:
        write_log ('Region {} being updated with requested settings'.format(region_name))
        catalog_file=None
        if database_type == 'VSAM_Postgres_PAC': 
            catalog_file="sql://BankPAC/VSAM/catalog.dat?folder=/"
        update_region(session, region_name, update_config, env_config, 'Test Region', sys_base, catalog_file)
    except ESCWAException as exc:
        write_log('Unable to update region.')
        write_log(exc)
        sys.exit(1)

    try:
        write_log ('Communications Server set to localhost')
        set_commsserver_local(session, region_name, ip_address)
    except ESCWAException as exc:
        write_log('Unable to set update Comms Server.')
        write_log(exc)
        sys.exit(1)

    try:
        write_log ('Web Services and J2EE listener port set to {}'.format(jes_port))
        set_jes_listener(session, region_name, ip_address, jes_port)
    except ESCWAException as exc:
        write_log('Unable to set JES listener.')
        write_log(exc)
        sys.exit(1)

    if len(pac_name) > 0:
        if database_connection is None:
            write_log ('Skipping database creation, no connection')
        else:
            create_regiondb = database_connection['create_regiondb'] 
            if create_regiondb == True:
                write_log ('Creating database')
                create_region_database(main_config)

    if  init_config != 'none':
        write_log('JES initiator configuration found. Initiators being added')
        try:
            add_initiator(session, region_name, ip_address, init_config)
        except ESCWAException as exc:
            write_log('Unable to add initiator.')
            write_log(exc)
            sys.exit(1)

    rdef_sit = os.path.join(resourcedef_dir, 'rdef_sit.json')

    if os.path.isfile(rdef_sit):
        sit_details = read_json(rdef_sit)
        new_sit_name = sit_details['resNm']
    else:
        sit_details = None
        new_sit_name = ''

    if len(pac_name) > 0 and pac_config is None:
        write_log ('No PAC config, skipping catalog datasets and resource file updates')
    else:
        try:
            write_log('Region {} being started before further configuration'.format(region_name))
            start_region(session, region_name, ip_address)
        except ESCWAException as exc:
            write_log('Unable to start region.')
            write_log(exc)
            sys.exit(1)
    
        try:
            write_log('Checking region {} started successfully'.format(region_name))
            confirmed = confirm_region_status(session, region_name, 1, 'Started')
        except ESCWAException as exc:
            write_log('Unable to check region status.')
            write_log(exc)
            sys.exit(1)
    
        if not confirmed:
            write_log('Region Failed to start. Environment being rewound')
    
            del_res = del_region(session, region_name)
    
            if del_res.status_code == 204:
                write_log('Environment cleaned successfully')
            
            sys.exit(1)
        else:
            write_log('Region {} started successfully'.format(region_name))

        if  alias_config != 'none':
            write_log ('JES Alias configuration found. Aliases being added')
            try:
                update_alias(session, region_name, ip_address, alias_config)
            except ESCWAException as exc:
                write_log('Unable to update aliases.')
                write_log(exc)
                sys.exit(1)

        #data_dir_1 hold the directory name, under the cwd that contains definitions of any datasets to be catalogued - this setting is optional
        catalog_dir = os.path.join(sys_base, 'catalog')
        catalog_datasets(session, cwd, region_name, ip_address, configuration_files, 'data_dir_1', None, catalog_dir)

        #data_dir_3 hold the directory name, under the cwd that contains definitions of extra datasets to be catalogued - this setting is optional
        catalog_datasets(session, cwd, region_name, ip_address, configuration_files, 'data_dir_3', None, catalog_dir)

        ## The following code updates the CICS Resource Definitions

        rdef_startup = os.path.join(resourcedef_dir, 'rdef_startup.json')

        if os.path.isfile(rdef_startup):
            startup_details = read_json(rdef_startup)
            write_log('Adding Startup List {}'.format(startup_details["resNm"]))
            add_Startup_list(session, region_name,ip_address,startup_details)

        rdef_sit = os.path.join(resourcedef_dir, 'rdef_sit.json')

        if sit_details is not None:
            write_log('Adding SIT {}'.format(sit_details["resNm"]))
            add_sit(session, region_name,ip_address,sit_details)

        rdef_group = os.path.join(resourcedef_dir, 'rdef_groups.json')

        if os.path.isfile(rdef_group):
                group_details = read_json(rdef_group)
                add_groups(session, region_name,ip_address,group_details)  
                
        #The FCT entries are only required if the VSAM version of the application is in use
        if dataversion == 'vsam':

            write_log ('VSAM version selected - FCT entries being added')
            fct_match_pattern = os.path.join(resourcedef_dir, 'rdef_fct_*.json')
            fct_filelist = glob.glob(fct_match_pattern)

            if fct_filelist != '':
                for filename in fct_filelist:
                    fct_details = read_json(filename)
                    add_fct(session, region_name,ip_address,fct_details)
            else:
                write_log('fct match pattern failed')
        ppt_match_pattern = os.path.join(resourcedef_dir, 'rdef_ppt_*.json')
        ppt_filelist = glob.glob(ppt_match_pattern)

        if ppt_filelist != '':
           write_log ('CICS Resource PPT definitions found - being added') 
           for filename in ppt_filelist:
               ppt_details = read_json(filename)
               add_ppt(session, region_name,ip_address, ppt_details)
        else:
            write_log('ppt match pattern failed')
        pct_match_pattern = os.path.join(resourcedef_dir, 'rdef_pct_*.json')
        pct_filelist = glob.glob(pct_match_pattern)

        if pct_filelist != '':
           write_log ('CICS Resource PCT definitions found - being added')  
           for filename in pct_filelist:
               pct_details = read_json(filename)
               add_pct(session, region_name,ip_address,pct_details)
        else:
            write_log('pct match pattern failed')

        ## The following code adds MQ listeners as defined in mq.json
        if  main_config['MQ'] == True:
            write_log('Region requires MQ settings - being added')
            mq_config = os.path.join(config_dir, 'mq.json')

            mq_details = read_json(mq_config)

            mq_details["mfMQTrigger"] = 'MQ_Q_' + region_name
            mq_details["mfMQManager"] = 'MQ_QM_' + region_name

            try: 
                add_mq_listener(session, region_name, ip_address, mq_details)
            except ESCWAException as exc:
                print('Unable to add MQ Listener.')
                write_log(exc)
                sys.exit(1)
        write_log ('Partitioned datasets being deployed')
        deploy_partitioned_data(parentdir,sys_base, esuid)

    ## Update the SIT setting for this region
    if new_sit_name != '': 
        write_log ('SIT {} previously added - setting this as the default for region {}'.format(new_sit_name, region_name))
        update_sit_in_use(session, region_name, ip_address, new_sit_name)
        write_log ('Region restart now required')

    
    ## The following code deploys the application
    deploy_application_option(session, database_type, os_type, main_config, cwd, mfdbfh_config, esuid)
    if  database_type == 'SQL_Postgres':
        loadlibDir = 'SQL_Postgres'
    else:
        loadlibDir = 'VSAM'

    if mf_product != 'EDz':
        write_log('The Rocket {} product does not contain a compiler. Precompiled executables therefore being deployed'.format(mf_product))
        deploy_application(parentdir, sys_base, os_type, is64bit, loadlibDir)
    else:
        ant_home = None
        if 'ant_home' in main_config:
            ant_home = main_config['ant_home']
        elif "ANT_HOME" in os.environ:
            ant_home = os.environ["ANT_HOME"]
        else:
            eclipsInstallDir = get_EclipsePluginsDir(os_type)
            if eclipsInstallDir is not None:
                for file in os.listdir(eclipsInstallDir):
                    if file.startswith("org.apache.ant_"):
                        ant_home = os.path.join(eclipsInstallDir, file)
            if ant_home is None:
                antdir = get_CobdirAntDir(os_type)
                if antdir is not None:
                    for file in os.listdir(antdir):
                        if file.startswith("apache-ant-"):
                            ant_home = os.path.join(eclipsInstallDir, file)

        if ant_home is None:
            write_log('ANT_HOME not set. Precompiled executables therefore being deployed')
            deploy_application(parentdir, sys_base, os_type, is64bit, loadlibDir)
        else:
            write_log('Application being built')

            build_file = os.path.join(cwd, 'build', 'build.xml')
            parentdir = str(Path(cwd).parents[0])
            source_dir = os.path.join(parentdir, 'sources')
            load_dir = os.path.join(parentdir, region_name,'system','loadlib')
            full_build = True

            run_ant_file(build_file,source_dir,load_dir,ant_home, full_build, dataversion, is64bit)

    write_log('Precompiled system executables being deployed'.format(mf_product))
    deploy_system_modules(parentdir, sys_base, os_type, is64bit, loadlibDir)

    ## Following the update of the SIT and other attributes, the region must be restarted
    try:
        write_log('Stopping region {}'.format(region_name))
        stop_region(session, region_name)
    except ESCWAException as exc:
        write_log('Unable to execute stop request for region.')
        write_log(exc)
        sys.exit(1)

    try:
        write_log('Checking region {} stopped successfully'.format(region_name))
        confirmed = confirm_region_status(session, region_name, 1, 'Stopped')
    except ESCWAException as exc:
        write_log('Unable to check region status.')
        write_log(exc)
        sys.exit(1)

    if not confirmed:
        print('Region Failed to stop.')
        sys.exit(1)
    else:
        write_log ('Region stopped successfully')

    ## The following code sets the region to be part of a PAC
    if len(pac_name) > 0:
        if pac_config is not None:
            pac_enabled = pac_config['enabled']
            if pac_enabled == True:
                psor_type=pac_config['PSOR_type']
                psor_connection=pac_config['PSOR_connection']
                pac_description=pac_config['description']
                create_pac(session, config_dir, pac_name, psor_connection, pac_description, psor_type)
                deploy_dfhdrdat_postgres_pac(session, os_type, main_config, mfdbfh_config, rdef)

        update_region_attribute(session, region_name, {"mfCASTXRDTP": "sql://BankPAC/VSAM?type=folder;folder=/system"})
        update_region_attribute(session, region_name, {"mfCASJCLALLOCLOC": "sql://BankPAC/VSAM?type=folder;folder=/data"})

        install_region_into_pac_by_name(session, ip_address, region_name, pac_name, config_dir)
    else:
        write_log('Not using PAC.')

    try:
        write_log('Restarting region {}'.format(region_name))
        start_region(session, region_name, ip_address)
    except ESCWAException as exc:
        write_log('Unable to start region.')
        write_log(exc)
        sys.exit(1)

    try:
        write_log('Checking region {} restarted successfully'.format(region_name))
        confirmed = confirm_region_status(session, region_name, 1, 'Started')
    except ESCWAException as exc:
        write_log('Unable to check region status.')
        write_log(exc)
        sys.exit(1)

    if not confirmed:
        print('Region Failed to start. Environment being rewound')
        sys.exit(1)

        del_res = del_region(session, region_name)

        if del_res.status_code == 204:
            print('Environment cleaned successfully')
        
        sys.exit(1)
    else:
        write_log('Region {} restarted successfully'.format(region_name))

    write_log('Rocket Demo environment has been provisioned')

if __name__ == '__main__':

    cwd = os.getcwd()
    if len(sys.argv) < 2:
        config_dir = os.path.join(cwd, 'config')
        config_fullpath = os.path.join(config_dir, "demo.json")
    else:
        options_dir = os.path.join(cwd, 'options')
        config_file = sys.argv[1] + '.json'
        config_fullpath = os.path.join(options_dir, config_file)
        if os.path.isfile(config_fullpath) == False:
            write_log('File {} could not be found'.format(config_fullpath))
            write_log('Valid options are:')
            for f in os.listdir(options_dir):
                if os.path.isfile(os.path.join(options_dir, f)):
                    write_log('    {}'.format(f))
            sys.exit(1)

    create_region(config_fullpath)
