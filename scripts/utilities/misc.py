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

Description:  Miscelaneous utility functions. 
"""

import os
import sys
import getopt
if sys.platform.startswith('win32'):
    import winreg
from utilities.output import write_log 
from utilities.exceptions import HTTPException
from pathlib import Path
import subprocess

def get_elem_with_prop(arr, key, value):
    """ Gets an array object with a specific property"""
    for elem in arr:
        if elem[key] == value:
            return elem


def get_eds_port():
    """ Returns the port of the Enterprise Directory Server to work with.

        A machine can run several directory servers, so CCITCP2_PORT selects
        which one the scripts use. It forms part of the path of every region
        API request, so the default matches the product default of 86.
    """
    return os.getenv('CCITCP2_PORT', '86')


def create_headers(requested_with, ip_address):
    """ Creates headers for sending API requests to the server region. """

    headers = {
        'accept': 'application/json',
        'X-Requested-With': requested_with,
        'Content-Type': 'application/json',
        'Origin': 'http://{}:10086'.format(ip_address)
        #'Origin': 'http://{}:10086'.format('127.0.0.1')
    }

    return headers


def check_http_error(res):
    """ Error handling for HTTP status codes. """
    if res.status_code >= 400 and res.status_code < 600:
        # The response body carries the reason the request was rejected, so it is
        # included (collapsed onto one line) rather than discarded.
        detail = ' '.join(res.text.split()) if res.text else ''
        if len(detail) > 300:
            detail = detail[:300] + '...'
        message = 'HTTP {} {}'.format(res.status_code, res.reason)
        if detail:
            message = '{} - {}'.format(message, detail)
        raise HTTPException(message)


def parse_args(arg_list, short_map, long_map):
    """ Parses arguments passed on the command line. """
    short_opts = "".join([key.lstrip('-') for key in short_map.keys()])
    long_opts = [key.lstrip('-') for key in long_map.keys()]
    try:
        opts, args = getopt.getopt(arg_list, short_opts, long_opts)
    except getopt.GetoptError as error:
        print(error)
        return None
    short_map = {key.rstrip(':'): val for key, val in short_map.items()}
    long_map = {key.rstrip('='): val for key, val in long_map.items()}
    arg_map = {**short_map, **long_map}

    kwargs = {arg_map[opt[0]]: opt[1] for opt in opts}

    return kwargs

def set_MF_environment (os_type):

    if os_type == 'Windows':
        localMachineKey = winreg.ConnectRegistry(None, winreg.HKEY_LOCAL_MACHINE)
        cobolKey = winreg.OpenKey(localMachineKey, r"SOFTWARE\\Micro Focus\\Visual COBOL")
        defaultVersion = winreg.QueryValueEx(cobolKey, "DefaultVersion")
        installKeyString =  r'{}\\COBOL\\Install'.format(defaultVersion[0])
        write_log('Found COBOL version: {}'.format(defaultVersion[0]))
        installKey = winreg.OpenKey(cobolKey, installKeyString)
        install_dir = winreg.QueryValueEx(installKey, "BIN")
        winreg.CloseKey(installKey)
        winreg.CloseKey(cobolKey)
        winreg.CloseKey(localMachineKey)
        return install_dir[0]
    else:
        if "COBDIR" in os.environ:
           return os.path.join(os.environ["COBDIR"], "bin")

        pathCOBDIR = Path("/opt/rocketsoftware/EnterpriseDeveloper/bin")
        if pathCOBDIR.is_dir():
            return str(pathCOBDIR)
        pathCOBDIR = Path("/opt/rocketsoftware/EnterpriseServer/bin")
        if pathCOBDIR.is_dir():
            return str(pathCOBDIR)
        pathCOBDIR = Path("/opt/microfocus/EnterpriseDeveloper/bin")
        if pathCOBDIR.is_dir():
            return str(pathCOBDIR)
        pathCOBDIR = Path("/opt/microfocus/EnterpriseServer/bin")
        if pathCOBDIR.is_dir():
            return str(pathCOBDIR)

    return None

def get_EclipsePluginsDir (os_type):
    if os_type == 'Windows':
       localMachineKey = winreg.ConnectRegistry(None, winreg.HKEY_LOCAL_MACHINE)
       cobolKey = winreg.OpenKey(localMachineKey, r"SOFTWARE\\Micro Focus\\Visual COBOL")
       defaultVersion = winreg.QueryValueEx(cobolKey, "DefaultVersion")
       installKeyString =  r'{}'.format(defaultVersion[0])
       installKey = winreg.OpenKey(cobolKey, installKeyString)
       try:
           install_dir = winreg.QueryValueEx(installKey, "ECLIPSEINSTALLDIR")
           pluginsDir = os.path.join(install_dir[0], "eclipse", "plugins")   
       except FileNotFoundError as exc:
           pluginsDir = None
       winreg.CloseKey(installKey)
       winreg.CloseKey(cobolKey)
       winreg.CloseKey(localMachineKey)
       return pluginsDir
    else:
       installDir = set_MF_environment(os_type)
       if installDir is not None:
           cobdir = Path(installDir).parents[0]
           if cobdir is not None:
               pluginsDir = os.path.join(cobdir, "eclipse", "eclipse", "plugins")
               pathPluginsDir = Path(pluginsDir)
               if pathPluginsDir.is_dir():
                   return pluginsDir

    return None

def get_CobdirAntDir (os_type):
    if os_type == 'Windows':
       return None
    else:
       cobdir = set_MF_environment(os_type)
       if cobdir is not None:
           antDir = os.path.join(cobdir, "remotedev", "ant")
           pathAntDir = Path(antDir)
           if pathAntDir.is_dir():
               return antDir

    return None
    
def get_cobdir_bin(is64bit):
    if sys.platform.startswith('win32') and is64bit:
        bin = 'bin64'
    else:
        bin = 'bin'
    cobdir = os.path.join(os.environ['COBDIR'], bin)
    return cobdir

def powershell(cmd):
    completed = subprocess.run(["powershell", "-Command", cmd], capture_output=True)
    return completed

def check_elevation():
    # Check if the current process is running as administator role
    isAdmin = '$user = [Security.Principal.WindowsIdentity]::GetCurrent();if ((New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {exit 1} else {exit 0}'
    completed = powershell(isAdmin)
    return completed.returncode == 1

def check_esuid(esuid):
    myuid = subprocess.getoutput("whoami")
    return esuid==myuid

