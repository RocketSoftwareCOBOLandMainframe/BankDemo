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
from utilities.exceptions import HTTPException
from utilities.output import write_log 
from pathlib import Path
import shutil

def create_new_system(template_base, sys_base):

    parentdir = str(Path(sys_base).parents[0])
    os.mkdir(parentdir)
    os.mkdir(sys_base)
    
    shutil.copytree(template_base, sys_base, dirs_exist_ok=True)
    

def deploy_application (repo_dir, sys_base, os_type, is64bit, database_type):

    target_load = os.path.join(sys_base, 'loadlib')

    if is64bit:
        chip = 'x64'
    else:
        chip = 'x86'
    exec_load = os.path.join(repo_dir, 'executables', os_type, chip)
    
    source_load = os.path.join(exec_load, 'data', database_type)
    shutil.copytree(source_load, target_load, dirs_exist_ok=True)

    source_load = os.path.join(exec_load, 'core')
    shutil.copytree(source_load, target_load, dirs_exist_ok=True)

def deploy_system_modules (repo_dir, sys_base, os_type, is64bit, database_type):

    target_load = os.path.join(sys_base, 'loadlib')

    if is64bit:
        chip = 'x64'
    else:
        chip = 'x86'
    exec_load = os.path.join(repo_dir, 'executables', os_type, chip)
    
    source_load = os.path.join(exec_load, 'system')
    shutil.copytree(source_load, target_load, dirs_exist_ok=True)

def deploy_vsam_data (repo_dir, sys_base, os_type, esuid):

    target_load = os.path.join(sys_base, 'catalog', 'data')
    source_load = os.path.join(repo_dir, 'datafiles')

    shutil.copytree(source_load, target_load, dirs_exist_ok=True)
    if esuid != '':
        shutil.chown(target_load, esuid, esuid)
        for file in os.scandir(target_load):
            shutil.chown(file, esuid, esuid)

def deploy_partitioned_data (repo_dir, sys_base, esuid):

    target_load = os.path.join(sys_base, 'catalog', 'data', 'proclib')
    source_load = os.path.join(repo_dir, 'sources', 'proclib')
    shutil.copytree(source_load, target_load, dirs_exist_ok=True)
    if esuid != '':
        shutil.chown(target_load, esuid, esuid)
        for file in os.scandir(target_load):
            shutil.chown(file, esuid, esuid)

    target_load = os.path.join(sys_base, 'catalog', 'data', 'ctlcards')
    source_load = os.path.join(repo_dir, 'sources', 'ctlcards')
    shutil.copytree(source_load, target_load, dirs_exist_ok=True)
    if esuid != '':
        shutil.chown(target_load, esuid, esuid)
        for file in os.scandir(target_load):
            shutil.chown(file, esuid, esuid)

def dbfhdeploy_vsam_data (repo_dir, os_type, is64Bit, configuration_files, mfdbfh_location):
    dataset_dir = os.path.join(repo_dir, 'datafiles')

    if os_type == 'Windows':
        if is64Bit == True:
            bin = 'bin64'
        else:
            bin = 'bin'
    else:
        bin = 'bin'
    dbfhdeploy = os.path.join(os.environ['COBDIR'], bin, 'dbfhdeploy')
    db = mfdbfh_location.split('{')
    dbfhdeploy_cmd = '\"{}\" create \"{}\"'.format(dbfhdeploy, db[0])
    write_log(dbfhdeploy_cmd)
    subprocess.run([dbfhdeploy, "create", db[0]], check=True)

    for file in os.scandir(dataset_dir):
        if file.name.endswith(".dat"):
            catalog_location = mfdbfh_location.format(file.name)

            dbfhdeploy_cmd = '\"{}\" add \"{}\" \"{}\"'.format(dbfhdeploy, file.path, catalog_location)
            write_log(dbfhdeploy_cmd)
            subprocess.run([dbfhdeploy, "add", file.path, catalog_location], check=True)

def dbfhdeploy_dataset (os_type, is64Bit, source_location, mfdbfh_location, filename):
    if os_type == 'Windows':
        if is64Bit == True:
            bin = 'bin64'
        else:
            bin = 'bin'
    else:
        bin = 'bin'
        
    dbfhdeploy = os.path.join(os.environ['COBDIR'], bin, 'dbfhdeploy')
    db = mfdbfh_location.split('{')
    dbfhdeploy_cmd = '\"{}\" create \"{}\"'.format(dbfhdeploy, db[0])
    write_log(dbfhdeploy_cmd)
    subprocess.run([dbfhdeploy, "create", db[0]], check=True)

    catalog_location = mfdbfh_location.format(filename)
    source_file = "{}/{}".format(source_location, filename)

    dbfhdeploy_cmd = '\"{}\" add \"{}\" \"{}\"'.format(dbfhdeploy, source_file, catalog_location)
    write_log(dbfhdeploy_cmd)
    subprocess.run([dbfhdeploy, "add", source_file, catalog_location], check=True)
            