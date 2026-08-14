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

Description:  File System utility functions. 
"""

import os
import sys
import subprocess
from utilities.misc import get_cobdir_bin
from utilities.exceptions import ESCWAException
from utilities.output import write_log
from ESCWA.pac_config import get_pacs, install_region_into_pac
from ESCWA.mfds_config import add_mfds_to_list

def install_region_into_pac_by_name(session, ip_address, region_name, pac_name, config_dir):
    pacs = get_pacs(session).json()
    for pac in pacs:
        if pac['PacName'] == pac_name: #todo
            install_config = os.path.join(config_dir, 'installpac.json')
            install_region_into_pac(session, ip_address, region_name, pac['Uid'], install_config)
            return True
    return False
    
#    try:
#        write_log ('Adding additional directory servers to ESCWA')
#        additional_directory_servers=pac_config["additional_directory_servers"]
#        for ds in additional_directory_servers:
#            name=ds['name']
#            ip=ds['ip']
#            write_log ('Adding {} {}'.format(name, ip))
#            add_mfds_to_list(session, name, ip, name)
#    except ESCWAException as exc:
#        write_log('Unable to add additional directory servers to ESCWA.')
#        write_log(exc)
        
def dbfhadmin(is64bit, cmd):
    cobdir_bin = get_cobdir_bin(is64bit)
    dbfhadmin_path = os.path.join(cobdir_bin, 'dbfhadmin')
    arg_list = [dbfhadmin_path]
    arg_list.extend(cmd.split(" "))
    write_log("{} {}".format(dbfhadmin_path, cmd))
    result = subprocess.run(arg_list, check=True)
    return result

def create_crossregion_database(main_config):
    is64bit = main_config["is64bit"]
    pac_name = main_config["pac_name"]
    database_connection = main_config["database_connection"]
    database_server = database_connection["server_name"]
    database_user = database_connection["user"]
    database_pwd = database_connection["password"]
    cmd = "-script -type:crossregion -provider:pg -name:{} -file:create_crossregion_db.sql".format(pac_name)
    dbfhadmin(is64bit, cmd)
    cmd = "-createdb -provider:pg -type:crossregion -name:{} -file:create_crossregion_db.sql -user:{} -host:{} -password:{}".format(pac_name, database_user, database_server, database_pwd)
    dbfhadmin(is64bit, cmd)

def create_region_database(main_config):
    is64bit = main_config["is64bit"]
    pac_name = main_config["pac_name"]
    pac_db = main_config["pac_db_name"]
    database_connection = main_config["database_connection"]
    database_server = database_connection["server_name"]
    database_port = database_connection["server_port"]
    database_user = database_connection["user"]
    database_pwd = database_connection["password"]
    cmd = "-script -type:region -provider:pg -name:{} -db:{} -file:create_region_db.sql".format(pac_name, pac_db)
    dbfhadmin(is64bit, cmd)
    arg_list = ["psql", "--file", "create_region_db.sql", "postgresql://{}:{}@{}:{}".format(database_user, database_pwd, database_server, database_port)]
    result = subprocess.run(arg_list, check=True)
