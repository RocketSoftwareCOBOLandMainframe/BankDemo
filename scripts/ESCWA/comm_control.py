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

Description:  Functions to setup JES and RFA listeners on the server region. 
"""

from utilities.input import read_json, read_txt
from utilities.misc import get_elem_with_prop
import os

def set_jes_listener(session, region_name, ip_address, port):
    """ Sets a JES listener on the server region. """
    uri = 'native/v1/regions/{}/{}/{}/commsserver'.format(ip_address, os.getenv("CCITCP2_PORT","86"), region_name)
    res = session.get(uri, 'Unable to get Comm Server information.')
    comm_server = res.json()
    uri += '/{}/listener'.format(comm_server[0]['mfServerUID'])
    res = session.get(uri, 'Unable to get Comm Server Listener information.')
    listener_list = res.json()
    req_body = {'mfRequestedEndpoint': 'tcp:127.0.0.1:{}'.format(port)}
    listener = get_elem_with_prop(listener_list, 'CN', 'Web Services and J2EE')
    uri += '/{}'.format(listener['mfUID'])
    res = session.put(uri, req_body, 'Unable to update Web Services and J2EE Listener.')
    return res

def add_listener(session, region_name, ip_address, listener_config):
    """ Adds a listener to the server region. """
    uri = 'native/v1/regions/{}/{}/{}/commsserver'.format(ip_address, os.getenv("CCITCP2_PORT","86"), region_name)
    res = session.get(uri, 'Unable to get Comm Server information.')
    comm_server = res.json()
    req_body = read_json(listener_config)
    uri += '/{}/listener'.format(comm_server[0]['mfUID'])
    res = session.post(uri, req_body, 'Unable to add listener.')
    return res

def set_commsserver_local(session, region_name, ip_address):
    """ Sets a Communications Server to localhost. """

    uri = 'native/v1/regions/{}/{}/{}/commsserver'.format(ip_address, os.getenv("CCITCP2_PORT","86"), region_name)
    res = session.get(uri, 'Unable to get Comm Server information.')

    comm_server = res.json()
    uri += '/{}'.format(comm_server[0]['mfUID'])
    req_body = {'mfRequestedEndpoint': 'tcp:127.0.0.1:*'}

    res = session.put(uri, req_body, 'Unable to update Comm Server.')
    return res	