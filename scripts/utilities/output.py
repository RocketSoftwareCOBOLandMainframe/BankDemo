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

Description:  A series of utility functions for writing output to files. 
"""

import json
from utilities.exceptions import InputException


def write_json(file_path, json_obj):
    try:
        with open(file_path, 'w') as file:
            json.dump(json_obj, file, indent=4)
    except IOError as exc:
        raise InputException from exc

def write_log(log_message):
    # Flushed so that log lines stay in order with output from sub-processes.
    print (log_message, flush=True)