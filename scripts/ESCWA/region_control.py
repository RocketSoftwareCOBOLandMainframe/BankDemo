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

Description:  Functions for control of a server region. 
"""

import time
import requests
import os

from utilities.session import get_session, save_cookies
from utilities.misc import create_headers, check_http_error
from utilities.input import read_json
from utilities.exceptions import ESCWAException, InputException, HTTPException
from utilities.output import write_log 

def add_region(session, region_name, port, template_file, is64bit):
    """ Adds a region to the server region. """
    uri = 'native/v1/regions/{}/{}'.format('127.0.0.1',os.getenv("CCITCP2_PORT","86"))
    try:
        req_body = read_json(template_file)
    except InputException as exc:
        raise ESCWAException('Unable to read template file: {}.'.format(template_file)) from exc
    
    req_body['CN'] = region_name
    req_body['mfTN3270ListenerPort'] = port
    if is64bit == True:
        req_body['mfCAS64Bit'] = 1
    res = session.post(uri, req_body, 'Unable to complete Add Region API request')
    return res

def start_region(session, region_name, ip_address):
    """ Starts a previously created region on the server region. """
    uri = 'native/v1/regions/{}/{}/{}/start'.format('127.0.0.1', os.getenv("CCITCP2_PORT","86"), region_name)
    req_body = {
        'mfUser': 'SYSAD',
        'mfPassword': 'SYSAD',
        'mfUseSession': True,
        'mfStartMode': 'cold'
    }
    res = session.post(uri, req_body, 'Unable to complete Start Region API request.')
    return res

def stop_region(session, region_name):
    """ Stops a previously created region on the server region. """
    uri = 'native/v1/regions/{}/{}/{}/stop'.format('127.0.0.1', os.getenv("CCITCP2_PORT","86"), region_name)
    req_body = {
        'mfUser': 'SYSAD',
        'mfPassword': 'SYSAD',
        'mfUseSession': True,
        'mfClearDynamic': True,
        'mfForceStop': True
    }
    res = session.post(uri, req_body, 'Unable to complete Stop Region API request.')
    return res

def mark_region_stopped(session, region_name):
    """ Marks a previously created region as stopped on the server region. """
    uri = 'native/v1/regions/{}/{}/{}'.format('127.0.0.1', os.getenv("CCITCP2_PORT","86"), region_name)
    req_body = {
        'mfServerStatus': 'Stopped'
    }
    res = session.put(uri, req_body, 'Unable to complete Mark Region Stopped API request.')
    session = get_session()
    return res

def del_region(session, region_name):
    """ Deletes a region from the server region. """
    uri = 'native/v1/regions/{}/{}/{}'.format('127.0.0.1', os.getenv("CCITCP2_PORT","86"), region_name)
    res = session.delete(uri, 'Unable to complete Delete Region API request.')
    return res

def get_region_status(session, region_name):
    """ Checks a previously created region's status on the server region. """
    uri = 'native/v1/regions/{}/{}/{}/status'.format('127.0.0.1', os.getenv("CCITCP2_PORT","86"), region_name)
    res = session.get(uri, 'Unable to complete Region Check API request.')
    return res

def confirm_region_status(session, region_name, mins_allowed, expected):
    """ Checks a previously created region's status for a given value on the server region. """
    timeout_seconds=mins_allowed*60
    while timeout_seconds >= 0:
        status_res = get_region_status(session, region_name)
        status_res = status_res.json()

        if status_res['mfServerStatus'] == expected:
            return True
        if timeout_seconds > 0:
            time.sleep(10)
        timeout_seconds -= 10
    
    return False