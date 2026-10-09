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

Description:  Functions for control of jobs sent to the server region. 
"""

import time
import os
from utilities.misc import get_eds_port

def submit_jcl(session, region_name, ip_address, jcl_file):
    """ Submits a JCL to the JES Server. """
    uri = 'native/v1/regions/{}/{}/{}/jescontrol'.format(ip_address, get_eds_port(), region_name)
    req_body = {
        'ctlSubmit': 'Submit',
        'subJes': 2,
        'xatSwitch': jcl_file
    }
    res = session.post(uri, req_body, 'Unable to complete JCL Submit API request.')
    return res


def check_job(session, region_name, ip_address, job_id):
    """ Checks on the status of a job previously submitted to the JES server. """
    uri = 'native/v1/regions/{}/{}/{}/jobview/{}'.format(ip_address, get_eds_port(), region_name, job_id)
    for i in range(3):
        res = session.get(uri, 'Unable to complete Job Check API request.')
        if res.json()['JobStatus'] == 'Complete ':
            return res
        if i != 0:
            time.sleep(60)
    return res


def get_output(session, region_name, ip_address, job_id, charset):
    """ Gets the output of a job previously submitted to the JES server. """
    uri = 'native/v1/regions/{}/{}/{}/spool/{}/display'.format(ip_address, get_eds_port(), region_name, job_id)
    req_params = {
        'jSvStart': 1,
        'jSvFor': 10000,
        'jSvCode': charset
    }
    res = session.get(uri, 'Unable to complete Job Ouput API request.', req_params)
    return res