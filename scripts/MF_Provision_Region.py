#!/usr/bin/python3

"""
Copyright 2010 – 2026 Rocket Software, Inc. or its affiliates. 
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
from utilities.misc import parse_args, set_MF_environment, get_EclipsePluginsDir, get_CobdirAntDir, check_elevation, check_esuid, get_eds_port
from utilities.input import read_json, read_txt
from utilities.output import write_json, write_log 
from utilities.filesystem import create_new_system, deploy_application, deploy_system_modules, deploy_partitioned_data
from utilities.resource import add_postgresxa, catalog_datasets, write_secret
from utilities.deploy import deploy_application_option, deploy_dfhdrdat_postgres_pac, create_db_vault_secrets, catalog_pac_datasets
from database.odbc import check_odbc_driver_installed
from ESCWA.region_control import add_region, start_region, del_region, confirm_region_status, stop_region, get_region_status
from ESCWA.region_config import update_region, update_region_attribute, update_alias, add_initiator, check_security
from ESCWA.comm_control import set_jes_listener, set_commsserver_local, add_listener, confirm_listener_started
from utilities.exceptions import ESCWAException, InputException
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


class ProvisionError(Exception):
    """ Raised when a provisioning step fails. """


def step(description, func, *args, **kwargs):
    """ Logs and runs a single provisioning step, turning any failure into a
        ProvisionError so that the caller can roll back and report consistently.
    """
    write_log(description)
    try:
        return func(*args, **kwargs)
    except Exception as exc:
        raise ProvisionError('{} - FAILED: {}'.format(description, exc)) from exc


def region_exists(session, region_name):
    """ Returns True if ESCWA already holds a definition for the named region. """
    try:
        get_region_status(session, region_name)
        return True
    except ESCWAException:
        return False


def remove_region_definition(session, region_name, reason):
    """ Best effort removal of an ESCWA region definition, stopping it first. """
    try:
        stop_region(session, region_name)
        confirm_region_status(session, region_name, 1, 'Stopped')
    except ESCWAException as exc:
        write_log('Region {} could not be stopped (it may already be stopped): {}'.format(region_name, exc))
    try:
        del_region(session, region_name)
        write_log('Region definition {} deleted ({})'.format(region_name, reason))
    except ESCWAException as exc:
        write_log('Unable to delete region definition {}: {}'.format(region_name, exc))


def rollback_region(rollback):
    """ Undoes a partial provision so that the next run starts from a clean state. """
    session = rollback.get('session')
    region_name = rollback.get('region_name')
    region_dir = rollback.get('region_dir')

    has_region_definition = rollback.get('region_added') and session is not None and region_name is not None
    has_region_directory = region_dir is not None and os.path.isdir(region_dir)
    if not has_region_definition and not has_region_directory:
        return

    write_log('Rolling back partially provisioned region')

    if has_region_definition:
        remove_region_definition(session, region_name, 'rollback of this run')

    if has_region_directory:
        try:
            shutil.rmtree(region_dir)
            write_log('Region directory {} removed'.format(region_dir))
        except OSError as exc:
            write_log('Unable to remove region directory {}: {}'.format(region_dir, exc))
            write_log('Delete it manually before provisioning again.')


def create_region(main_configfile, force=False):
    """ Provisions a region, rolling back any partial work if a step fails. """
    rollback = {}
    try:
        provision_region(main_configfile, force, rollback)
    except ProvisionError as exc:
        write_log('ERROR: {}'.format(exc))
        rollback_region(rollback)
        write_log('Provisioning failed. No changes have been left behind; correct the error above and run the script again.')
        sys.exit(1)
    except Exception as exc:
        write_log('ERROR: Unexpected failure during provisioning: {}'.format(exc))
        rollback_region(rollback)
        raise


def provision_region(main_configfile, force, rollback):
    #all paths are derived from the script location, not the working directory
    script_dir = os.path.dirname(os.path.abspath(__file__))
    repo_dir = str(Path(script_dir).parent)
    
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
   
    config_dir = os.path.join(script_dir, 'config')
    options_dir = os.path.join(script_dir, 'options')

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
        sql_folder= os.path.join(repo_dir, 'scripts', 'config', 'database', database_type)
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

    #rfa_config is used to set the remote file access listener details for the region - this setting is optional
    if 'rfa_config' not in configuration_files:
        rfa_config = 'none'
    else:
        rfa_config = configuration_files["rfa_config"]

    #init_config contains the details of any JES initiators that need to be configured - this settings is optional
    if 'init_config' not in configuration_files:
        init_config ='none'
    else:
        init_config = configuration_files["init_config"]

    region_port = main_config['regionPort']
    jes_port = main_config['jesPort']

    #resolve the component configuration file paths
    base_config = os.path.join(config_dir, base_config)
    update_config = os.path.join(config_dir, update_config)
    if  alias_config != 'none':
        alias_config = os.path.join(config_dir, alias_config)
    init_config = os.path.join(config_dir, init_config)
    env_config = os.path.join(config_dir, env_config)
    secrets_config = os.path.join(config_dir, secrets_config)
    resourcedef_dir = os.path.join(config_dir, 'CSD')
    if  rfa_config != 'none':
        rfa_config = os.path.join(config_dir, rfa_config)

    session = EscwaSession("http", ip_address, 10086)
    rollback['session'] = session
    rollback['region_name'] = region_name

    try:
        write_log('Checking that ESCWA is reachable')
        session.ping()
    except ESCWAException as exc:
        raise ProvisionError(
            'Unable to contact ESCWA at {}. Make sure ESCWA and EDS are running before '
            'provisioning this region. Last error: {}'.format(session.get_uri_start(), exc)) from exc

    security_enabled = False
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
            security_enabled = True
        except ESCWAException as exc:
            raise ProvisionError('Unable to logon to ESCWA: {}'.format(exc)) from exc

    # Checked after logon because the directory server query needs an authenticated
    # session, and before anything is created so a wrong port costs nothing.
    try:
        write_log('Checking that EDS is reachable')
        session.ping_eds(ip_address)
    except ESCWAException as exc:
        raise ProvisionError(
            'Unable to contact EDS on port {}. Make sure EDS is running, and that '
            'CCITCP2_PORT names the directory server you want to provision into. '
            'Last error: {}'.format(get_eds_port(), exc)) from exc

    # The ESCWA region is removed before the directory, because a running region
    # holds its catalog files open and would block the directory from being deleted.
    if region_exists(session, region_name):
        if not force:
            raise ProvisionError(
                'Region {} is already defined in ESCWA. Delete it first, or re-run this '
                'script with --force to have it removed automatically.'.format(region_name))
        write_log('--force specified, removing existing region definition {}'.format(region_name))
        remove_region_definition(session, region_name, 'pre-existing, removed by --force')
        if region_exists(session, region_name):
            raise ProvisionError('Region {} could not be removed from ESCWA.'.format(region_name))

    #start the provision of the region
    parentdir = str(Path(script_dir).parent)
    template_base = os.path.join(parentdir, 'system')
    region_dir = os.path.join(parentdir, region_name)
    sys_base = os.path.join(region_dir, 'system')

    if os.path.exists(region_dir):
        if not force:
            write_log('ERROR: Region directory already exists: {}'.format(region_dir))
            write_log('A region must be provisioned into a clean directory. Either delete it,')
            write_log('or re-run this script with --force to have it removed automatically.')
            sys.exit(1)
        write_log('--force specified, removing existing region directory {}'.format(region_dir))
        try:
            shutil.rmtree(region_dir)
        except OSError as exc:
            write_log('ERROR: Unable to remove {}: {}'.format(region_dir, exc))
            write_log('Make sure the region is stopped and no files are open, then try again.')
            sys.exit(1)

    rollback['region_dir'] = region_dir
    step('Creating region directory {}'.format(region_dir), create_new_system, template_base, sys_base)

    mfdbfh_config=''
    database_connection = None
    # Update the mfdbfh.cfg file with the database user id
    if 'mfdbfh_config' in main_config:
        mfdbfh_config = os.path.join(sys_base, 'config', main_config['mfdbfh_config'])
        if 'database_connection' in main_config:
            database_connection = main_config['database_connection']

            def set_mfdbfh_user():
                with open(mfdbfh_config, 'rt') as f_in:
                    data = f_in.read()
                with open(mfdbfh_config, 'wt') as f_out:
                    f_out.write(data.replace('$$user$$', database_connection['user']))

            step('Setting the database user in {}'.format(mfdbfh_config), set_mfdbfh_user)

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

        def create_dfhdrdat():
            completed = subprocess.run([caspcrd, '/c', '/dp=' + rdef], capture_output=True, text=True)
            if completed.returncode != 0:
                detail = completed.stderr.strip() or completed.stdout.strip()
                if detail:
                    raise RuntimeError('{} returned rc={}: {}'.format(caspcrd, completed.returncode, detail))
                raise RuntimeError('{} returned rc={}'.format(caspcrd, completed.returncode))

        step('Creating resource definition file in {}'.format(rdef), create_dfhdrdat)

        #change ownership to match ES user
        if os_type == 'Linux':
            dfhdrdat = os.path.join(rdef, 'dfhdrdat')
            step('Setting owner of {} to {}'.format(dfhdrdat, esuid), shutil.chown, dfhdrdat, esuid, esuid)
        step('Creating database vault secrets', create_db_vault_secrets, os_type, main_config, esuid)

    step('Region \033[1m{}\033[0m being added'.format(region_name),
         add_region, session, region_name, region_port, base_config, is64bit)
    rollback['region_added'] = True

    catalog_file=None
    if database_type == 'VSAM_Postgres_PAC':
        catalog_file="sql://BankPAC/VSAM/catalog.dat?folder=/"
    step('Region {} being updated with requested settings'.format(region_name),
         update_region, session, region_name, update_config, env_config, 'Test Region', sys_base, catalog_file)

    step('Communications Server set to localhost', set_commsserver_local, session, region_name, ip_address)

    step('Web Services and J2EE listener port set to {}'.format(jes_port),
         set_jes_listener, session, region_name, ip_address, jes_port)

    if security_enabled == True and rfa_config != 'none':
        step('RFA listener configuration found. Listener being added',
             add_listener, session, region_name, ip_address, rfa_config)

    if len(pac_name) > 0:
        if database_connection is None:
            write_log ('Skipping database creation, no connection')
        else:
            create_regiondb = database_connection['create_regiondb'] 
            if create_regiondb == True:
                step('Creating database', create_region_database, main_config)

    if  init_config != 'none':
        step('JES initiator configuration found. Initiators being added',
             add_initiator, session, region_name, ip_address, init_config)

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
        step('Region {} being started before further configuration'.format(region_name),
             start_region, session, region_name, ip_address)

        confirmed = step('Checking region {} started successfully'.format(region_name),
                         confirm_region_status, session, region_name, 1, 'Started')

        if not confirmed:
            raise ProvisionError('Region {} failed to start.'.format(region_name))
        write_log('Region {} started successfully'.format(region_name))

        # The region reports Started before its listeners are accepting requests;
        # the configuration calls below fail with 503 until this one is up.
        if not step('Waiting for the Web Services and J2EE listener to start',
                    confirm_listener_started, session, region_name, ip_address, 'Web Services and J2EE'):
            raise ProvisionError(
                'The Web Services and J2EE listener for region {} did not start.'.format(region_name))

        if  alias_config != 'none':
            step('JES Alias configuration found. Aliases being added',
                 update_alias, session, region_name, ip_address, alias_config)

        ## The following code updates the CICS Resource Definitions
        rdef_startup = os.path.join(resourcedef_dir, 'rdef_startup.json')

        if os.path.isfile(rdef_startup):
            startup_details = read_json(rdef_startup)
            step('Adding Startup List {}'.format(startup_details["resNm"]),
                 add_Startup_list, session, region_name, ip_address, startup_details)

        if sit_details is not None:
            step('Adding SIT {}'.format(sit_details["resNm"]),
                 add_sit, session, region_name, ip_address, sit_details)

        rdef_group = os.path.join(resourcedef_dir, 'rdef_groups.json')

        if os.path.isfile(rdef_group):
            group_details = read_json(rdef_group)
            step('Adding CICS resource groups', add_groups, session, region_name, ip_address, group_details)

        #The FCT entries are only required if the VSAM version of the application is in use
        if dataversion == 'vsam':
            fct_filelist = glob.glob(os.path.join(resourcedef_dir, 'rdef_fct_*.json'))

            if fct_filelist:
                write_log ('VSAM version selected - FCT entries being added')
                for filename in fct_filelist:
                    fct_details = read_json(filename)
                    step('Adding FCT from {}'.format(os.path.basename(filename)),
                         add_fct, session, region_name, ip_address, fct_details)
            else:
                raise ProvisionError('No FCT resource definitions (rdef_fct_*.json) found in {}'.format(resourcedef_dir))

        ppt_filelist = glob.glob(os.path.join(resourcedef_dir, 'rdef_ppt_*.json'))

        if ppt_filelist:
            write_log ('CICS Resource PPT definitions found - being added')
            for filename in ppt_filelist:
                ppt_details = read_json(filename)
                step('Adding PPT from {}'.format(os.path.basename(filename)),
                     add_ppt, session, region_name, ip_address, ppt_details)
        else:
            raise ProvisionError('No PPT resource definitions (rdef_ppt_*.json) found in {}'.format(resourcedef_dir))

        pct_filelist = glob.glob(os.path.join(resourcedef_dir, 'rdef_pct_*.json'))

        if pct_filelist:
            write_log ('CICS Resource PCT definitions found - being added')
            for filename in pct_filelist:
                pct_details = read_json(filename)
                step('Adding PCT from {}'.format(os.path.basename(filename)),
                     add_pct, session, region_name, ip_address, pct_details)
        else:
            raise ProvisionError('No PCT resource definitions (rdef_pct_*.json) found in {}'.format(resourcedef_dir))

        ## The following code adds MQ listeners as defined in mq.json
        if  main_config['MQ'] == True:
            mq_config = os.path.join(config_dir, 'mq.json')

            mq_details = read_json(mq_config)

            mq_details["mfMQTrigger"] = 'MQ_Q_' + region_name
            mq_details["mfMQManager"] = 'MQ_QM_' + region_name

            step('Region requires MQ settings - being added',
                 add_mq_listener, session, region_name, ip_address, mq_details)

        step('Partitioned datasets being deployed', deploy_partitioned_data, parentdir, sys_base, esuid)

    ## Update the SIT setting for this region
    if new_sit_name != '': 
        step('SIT {} previously added - setting this as the default for region {}'.format(new_sit_name, region_name),
             update_sit_in_use, session, region_name, ip_address, new_sit_name)
        write_log ('Region restart now required')

    ## The following code deploys the application
    step('Deploying the application', deploy_application_option,
         session, database_type, os_type, main_config, script_dir, mfdbfh_config, esuid)

    if len(pac_name) > 0 and pac_config is None:
        write_log ('No PAC config, skipping additional catalog datasets')
    else:
        #data_dir_1 hold the directory name, under the cwd that contains definitions of any datasets to be catalogued - this setting is optional
        #data_dir_3 holds extra datasets, data_dir_4 holds PS (sequential) datasets - these settings are optional
        catalog_dir = os.path.join(sys_base, 'catalog')
        for data_dir in ('data_dir_1', 'data_dir_3', 'data_dir_4'):
            step('Cataloguing datasets from {}'.format(data_dir), catalog_datasets,
                 session, script_dir, region_name, ip_address, configuration_files, data_dir, None, catalog_dir)

    if  database_type == 'SQL_Postgres':
        loadlibDir = 'SQL_Postgres'
    else:
        loadlibDir = 'VSAM'

    if mf_product != 'EDz':
        write_log('The Rocket {} product does not contain a compiler. Precompiled executables therefore being deployed'.format(mf_product))
        step('Deploying precompiled executables', deploy_application, parentdir, sys_base, os_type, is64bit, loadlibDir)
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
                            ant_home = os.path.join(antdir, file)

        if ant_home is None:
            write_log('ANT_HOME not set. Precompiled executables therefore being deployed')
            step('Deploying precompiled executables', deploy_application, parentdir, sys_base, os_type, is64bit, loadlibDir)
        else:
            build_file = os.path.join(script_dir, 'build', 'build.xml')
            source_dir = os.path.join(parentdir, 'sources')
            load_dir = os.path.join(sys_base, 'loadlib')
            full_build = True

            step('Application being built', run_ant_file,
                 build_file, source_dir, load_dir, ant_home, full_build, dataversion, is64bit)

    step('Precompiled system executables being deployed', deploy_system_modules,
         parentdir, sys_base, os_type, is64bit, loadlibDir)

    ## Following the update of the SIT and other attributes, the region must be restarted
    step('Stopping region {}'.format(region_name), stop_region, session, region_name)

    confirmed = step('Checking region {} stopped successfully'.format(region_name),
                     confirm_region_status, session, region_name, 1, 'Stopped')

    if not confirmed:
        raise ProvisionError('Region {} failed to stop.'.format(region_name))
    write_log ('Region stopped successfully')

    ## The following code sets the region to be part of a PAC
    if len(pac_name) > 0:
        if pac_config is not None:
            pac_enabled = pac_config['enabled']
            if pac_enabled == True:
                psor_type=pac_config['PSOR_type']
                psor_connection=pac_config['PSOR_connection']
                pac_description=pac_config['description']
                step('Creating PAC {}'.format(pac_name), create_pac,
                     session, config_dir, pac_name, psor_connection, pac_description, psor_type)
                step('Deploying resource definition file to the PAC', deploy_dfhdrdat_postgres_pac,
                     session, os_type, main_config, mfdbfh_config, rdef)

        step('Setting PAC region attributes', update_region_attribute,
             session, region_name, {"mfCASTXRDTP": "sql://BankPAC/VSAM?type=folder;folder=/system"})
        step('Setting PAC JCL allocation attributes', update_region_attribute,
             session, region_name, {"mfCASJCLALLOCLOC": "sql://BankPAC/VSAM?type=folder;folder=/data"})

        step('Installing region {} into PAC {}'.format(region_name, pac_name),
             install_region_into_pac_by_name, session, ip_address, region_name, pac_name, config_dir)
    else:
        write_log('Not using PAC.')

    step('Restarting region {}'.format(region_name), start_region, session, region_name, ip_address)

    confirmed = step('Checking region {} restarted successfully'.format(region_name),
                     confirm_region_status, session, region_name, 1, 'Started')

    if not confirmed:
        raise ProvisionError('Region {} failed to restart.'.format(region_name))
    write_log('Region {} restarted successfully'.format(region_name))

    # Wait for the listener so that the region is actually usable, not merely running.
    if not step('Waiting for the Web Services and J2EE listener to start',
                confirm_listener_started, session, region_name, ip_address, 'Web Services and J2EE'):
        raise ProvisionError(
            'The Web Services and J2EE listener for region {} did not start.'.format(region_name))

    write_log('Rocket Demo environment has been provisioned')

if __name__ == '__main__':

    script_dir = os.path.dirname(os.path.abspath(__file__))
    args = sys.argv[1:]
    force = '--force' in args
    args = [arg for arg in args if arg != '--force']

    if len(args) < 1:
        config_dir = os.path.join(script_dir, 'config')
        config_fullpath = os.path.join(config_dir, "demo.json")
    else:
        options_dir = os.path.join(script_dir, 'options')
        config_file = args[0] + '.json'
        config_fullpath = os.path.join(options_dir, config_file)
        if os.path.isfile(config_fullpath) == False:
            write_log('File {} could not be found'.format(config_fullpath))
            write_log('Valid options are:')
            for f in os.listdir(options_dir):
                if os.path.isfile(os.path.join(options_dir, f)):
                    write_log('    {}'.format(f))
            sys.exit(1)

    create_region(config_fullpath, force)
