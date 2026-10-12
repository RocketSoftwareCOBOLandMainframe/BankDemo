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

Description:  A series of utility functions for updating resource defs. 
"""

import os
import sys
import requests
import json
from utilities.misc import create_headers, check_http_error, get_eds_port
from utilities.input import read_json, read_txt
from utilities.output import write_log
from utilities.session import get_session, save_cookies
from utilities.exceptions import ESCWAException, InputException, HTTPException

def add_sit(session, region_name, ip_address, sit_details):
    uri = 'native/v1/regions/{}/{}/{}/sit'.format(ip_address, get_eds_port(), region_name)
    req_body = sit_details
    res = session.post(uri, req_body, 'Unable to complete Update Startup API request.')
    return res

def add_Startup_list(session, region_name, ip_address, startup_details):
    uri = 'native/v1/regions/{}/{}/{}/startup'.format(ip_address, get_eds_port(), region_name)
    req_body =startup_details
    res = session.post(uri, req_body, 'Unable to complete Update Startup API request.')
    return res

def add_groups(session, region_name, ip_address, group_details):
    uri = 'native/v1/regions/{}/{}/{}/groups'.format(ip_address, get_eds_port(), region_name)
    for new_group in group_details['ResourceGroups']:
        req_body =new_group
        write_log('Adding Resource Group {}'.format(req_body["resNm"]))
        res = session.post(uri, req_body, 'Unable to complete Update Group API request.')
    return res

def add_fct(session, region_name, ip_address, fct_details):
    for fct_entry in fct_details['FCT_Entries']:
        req_body = fct_entry
        uri = 'v2/native/regions/{}/{}/{}/fct/defined'.format(ip_address, get_eds_port(), region_name)
        res = session.post(uri, req_body, 'Unable to complete Update FCT API request.')
    return res

def add_ppt(session, region_name, ip_address, ppt_details):
    for ppt_entry in ppt_details['PPT_Entries']:
        req_body = ppt_entry
        uri = 'v2/native/regions/{}/{}/{}/ppt/defined'.format(ip_address, get_eds_port(), region_name)
        res = session.post(uri, req_body, 'Unable to complete Update PPT API request.')
    return res

def add_pct(session, region_name, ip_address, pct_details):
    for pct_entry in pct_details['PCT_Entries']:
        req_body = pct_entry
        uri = 'v2/native/regions/{}/{}/{}/pct/defined'.format(ip_address, get_eds_port(), region_name)
        res = session.post(uri, req_body, 'Unable to complete Update PCT API request.')
    return res

def update_sit_in_use(session, region_name, ip_address, sit_name):
    uri = 'native/v1/regions/{}/{}/{}'.format(ip_address, get_eds_port(), region_name)
    sit_attribute ='{\"mfCASCICSSIT\": \"' + sit_name + '\"}'
    req_body = json.loads(sit_attribute)
    res = session.put(uri, req_body, 'Unable to complete Update region attribute request.')
    return res