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

Description:  Function for configuring a server region. 
"""

import os
import sys
import requests
from utilities.output import write_log 
from utilities.misc import create_headers, check_http_error, get_eds_port
from utilities.input import read_json, read_txt
from utilities.session import get_session, save_cookies
from utilities.exceptions import ESCWAException, InputException, HTTPException

def update_region(session, region_name, template_file, env_file, region_description, region_base, catalog_file):
    """ Updates the settings of a previously created region on the  server region. """
    uri = 'native/v1/regions/{}/{}/{}'.format('127.0.0.1', get_eds_port(), region_name)
    esp_alias = '$ESP'
    if sys.platform.startswith('win32'):
        path_sep = ';'
        log_dir = os.path.join(esp_alias, 'logs')
    else:
        path_sep = ':'
        log_dir = '' # system dir unsupported on Unix/Linux

    loadlib_dir = os.path.join(esp_alias, 'loadlib')
    catalog_dir = os.path.join(esp_alias, 'catalog')
    catalog_data_dir = os.path.join(catalog_dir, 'data')
    #data_dir = os.path.join(esp_alias, 'Data')
    rdef_dir = os.path.join(esp_alias, 'rdef')

    if catalog_file == None:
        catalog_file = os.path.join(catalog_dir, 'CATALOG.DAT')
    
    lib_path = loadlib_dir

    try:
        req_body = read_json(template_file)
    except InputException as exc:
        raise ESCWAException('Unable to read template file: {}.'.format(template_file)) from exc

    try:
        env_json = read_json(env_file)
    except InputException as exc:
        raise ESCWAException('Unable to read env file: {}.'.format(env_file)) from exc

    # Flatten and format environment json into flat text
    env_key = next(iter(env_json))
    env_json[env_key]['ESP'] = region_base
    env_list = [key + '=' + val for key, val in env_json[env_key].items()]

    req_body['CN'] = region_name
    req_body['mfConfig'] = '\n'.join([env_key] + env_list)
    req_body['description'] = region_description
    req_body['mfCASSysDir'] = log_dir
    req_body['mfCASTXTRANP'] = lib_path
    req_body['mfCASTXFILEP'] = catalog_data_dir
    req_body['mfCASTXMAPP'] = lib_path
    req_body['mfCASTXRDTP'] = rdef_dir
    req_body['mfCASJCLPATH'] = lib_path
    req_body['mfCASMFSYSCAT'] = catalog_file
    req_body['mfCASJCLALLOCLOC'] = catalog_data_dir
    res = session.put(uri, req_body, 'Unable to complete Update Region API request.')
    return res

def update_region_attribute(session, region_name, attribute_details):
    uri = 'native/v1/regions/{}/{}/{}'.format('127.0.0.1', get_eds_port(), region_name)
    req_body=attribute_details
    res = session.put(uri, req_body, 'Unable to complete Update Region API request.')
    return res
    
def update_alias(session, region_name, ip_address, alias_file):
    """ Updates the aliases on a server region. """
    uri = 'native/v1/regions/{}/{}/{}/alias'.format(ip_address, get_eds_port(), region_name)
    try:
        req_body = read_json(alias_file)
    except InputException as exc:
        raise ESCWAException('Unable to read alias file: {}'.format(alias_file)) from exc
    res = session.post(uri, req_body, 'Unable to complete Update Alias API request.')
    return res

def add_initiator(session, region_name, ip_address, template_file):
    """ Adds an initiator to a server region. """
    uri = 'native/v1/regions/{}/{}/{}/initiator'.format(ip_address, get_eds_port(), region_name)
    try:
        req_body = read_json(template_file)
    except InputException as exc:
        raise ESCWAException('Unable to read initiator file: {}'.format(template_file))
    req_body['CN'] = region_name
    res = session.post(uri, req_body, 'Unable to complete Add Initiator API request.')
    return res


def add_datasets(session, region_name, ip_address, datafile_list, mfdbfh_location, catalog_dir):
    """ Adds data sets to a server region. """
    try:
        dataset_list = [read_json(data_file) for data_file in datafile_list]
    except InputException as exc:
        raise ESCWAException('Unable to read dataset files')
    responses = []
    for dataset in dataset_list:
        uri = 'v2/native/regions/{}/{}/{}/catalog'.format(ip_address, get_eds_port(), region_name)
        if mfdbfh_location is not None:
            # sql://bank_mfdbfh/VSAM/{}?folder=/data
            physicalFile = os.path.basename(dataset['physicalFile'])
            physicalFile = mfdbfh_location.format(physicalFile)
            dataset['physicalFile'] = physicalFile
        else:
            if catalog_dir is not None and 'physicalFile' in dataset:
                dataset['physicalFile'] = dataset['physicalFile'].replace('<CATALOGFOLDER>', catalog_dir)
        res = session.post(uri, dataset, 'Unable to complete Add Dataset API request.')
        responses.append(res)
    return responses

def check_security(session):
    """ check if vsam esm is enabled. """
    uri = 'validate'
    res = session.get(uri, 'Security is enabled')
    return res

