import requests
from utilities.misc import create_headers, check_http_error
from utilities.exceptions import ESCWAException, HTTPException, InputException
from utilities.output import write_json, write_log 
import subprocess
import json
import os

class EscwaSession:
    def __init__(self, protocol, escwa_hostname, escwa_port):
        self._protocol = protocol
        self._hostname = escwa_hostname
        self._port = escwa_port
        self._session = requests.Session()
        return

    def get_uri_start(self):
        return '{}://{}:{}'.format(self._protocol, self._hostname, self._port)

    #takes a uri path such as native/v1/regions/localhost/86/abc/commsserver
    def get(self, path, error_description='', params=None):
        uri = '{}/{}'.format(self.get_uri_start(), path)
        req_headers = create_headers('CreateRegion', self._hostname)
        try:
            res = self._session.get(uri, headers=req_headers, params=params)
            check_http_error(res)
            return res
        except requests.exceptions.RequestException as exc:
            desc = error_description if len(error_description) > 0 else "GET {} failed".format(uri)
            raise ESCWAException(desc) from exc
        except HTTPException as exc:
            desc = error_description if len(error_description) > 0 else "GET {} failed".format(uri)
            raise ESCWAException(desc) from exc

    def put(self, path, request_body, error_description=''):
        uri = '{}/{}'.format(self.get_uri_start(), path)
        req_headers = create_headers('CreateRegion', self._hostname)
        try:
            res = self._session.put(uri, headers=req_headers, json=request_body)
            check_http_error(res)
            return res
        except requests.exceptions.RequestException as exc:
            desc = error_description if len(error_description) > 0 else "PUT {} failed".format(uri)
            raise ESCWAException(desc) from exc
        except HTTPException as exc:
            desc = error_description if len(error_description) > 0 else "PUT {} failed".format(uri)
            raise ESCWAException(desc) from exc

    def post(self, path, request_body, error_description=''):
        uri = '{}/{}'.format(self.get_uri_start(), path)
        req_headers = create_headers('CreateRegion', self._hostname)
        try:
            res = self._session.post(uri, headers=req_headers, json=request_body)
            check_http_error(res)
            return res
        except requests.exceptions.RequestException as exc:
            desc = error_description if len(error_description) > 0 else "POST {} failed".format(uri)
            raise ESCWAException(desc + str(exc)) from exc
        except HTTPException as exc:
            desc = error_description if len(error_description) > 0 else "POST {} failed".format(uri)
            raise ESCWAException(desc + str(exc)) from exc

    def delete(self, path, error_description=''):
        uri = '{}/{}'.format(self.get_uri_start(), path)
        req_headers = create_headers('CreateRegion', self._hostname)
        try:
            res = self._session.delete(uri, headers=req_headers)
            check_http_error(res)
            return res
        except requests.exceptions.RequestException as exc:
            desc = error_description if len(error_description) > 0 else "DELETE {} failed".format(uri)
            raise ESCWAException(desc) from exc
        except HTTPException as exc:
            desc = error_description if len(error_description) > 0 else "DELETE {} failed".format(uri)
            raise ESCWAException(desc) from exc
            
    def logon(self, mfsecretsadmin, location):
        """ Logs on to ESCWA. """
        uri = 'logon'
        try:
            creds_body = subprocess.check_output([mfsecretsadmin, 'read', location]).decode()
            req_body = json.loads(creds_body)
        except (subprocess.SubprocessError, OSError, json.JSONDecodeError, InputException) as exc:
            raise ESCWAException('Unable to get logon credentials.') from exc

        res = self.post(uri, req_body, 'Unable to logon')
        return res
