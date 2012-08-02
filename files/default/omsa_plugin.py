#!/usr/bin/env python

# cookbook:: hardware
# file:: omsa_plugin.py
#
# Copyright 2012 Rackspace US, Inc.
#
# Licensed under the Apache License, Version 2.0 (the 'License');
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an 'AS IS' BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# I'm not a python guy.  This is likely offensively
# problematic.  My bad.  - Ron

import subprocess
import sys
import traceback

from string import maketrans
from xml.dom.minidom import parse, parseString

IN_COLLECTD = False
try:
    import collectd
    IN_COLLECTD = True
except Exception:
    pass

OMREPORT='/opt/dell/srvadmin/bin/omreport'
PLUGIN="omsa"

class CollectdLogger:
    def warning(self, msg):
        collectd.warning(msg)

    def error(self, msg):
        collectd.error(msg)

    def info(self, msg):
        collectd.info(msg)

    def debug(self, msg):
        collectd.debug(msg)


def parse_ssv(report):
    got_format = 0
    table_format = 0
    output = ''
    last_data = ''
    input_lines = []

    # first, fix up the busted-ass format

    for line in report:
        line = line.rstrip()

        atokens = line.split(';')
        if len(atokens) < 2:
            continue

        if not got_format:
            got_format = 1
            if atokens[0] == 'Index':
                logger.debug('K/V format')
                # appears to be k/v format, rather than table
                table_format = 0
                output = {}
            else:
                logger.debug('Table format')
                table_format = 1
                output = []
                keys = atokens
        else:
            # this is a data line
            if line[0] == ';': # continuation
                last_data = last_data + line
            else:
                if(last_data):
                    input_lines.append(last_data)
                last_data = line

    if last_data != '':
        input_lines.append(last_data)

    logger.debug('Resolved into %d lines' % len(input_lines))

    for x in range(len(input_lines)):
        atokens = input_lines[x].split(';')

        # we'll treat it as a data element
        if table_format:
            keyhash = {}

            for x in range(min(len(keys), len(atokens))):
                keyhash[keys[x]] = atokens[x]

            output.append(keyhash)

        else:
            output[atokens[0]] = atokens[1]

    logger.debug('Returning %d results' % len(output))
    return output

def get_omsa_report(fmt, *args):
    cmd = '%s %s -fmt %s' % (OMREPORT, ' '.join(args), fmt)
    logger.info('Running %s' % cmd)

    returncode = 1
    xmldoc = None

    try:
        obj = subprocess.Popen(cmd,
                               shell=True,
                               stdout=subprocess.PIPE,
                               close_fds=True)

        if(fmt == 'xml'):
            xmldoc = parse(obj.stdout)
        else:
            xmldoc = parse_ssv(obj.stdout)

        obj.wait()
        returncode = obj.returncode

    except OSError as e:
        logger.error('Exception running command: %s' % e)
        for line in traceback.format_exception(sys.exc_type, sys.exc_value, sys.exc_traceback):
            logger.error(line)

    # except xml.parsers.expat.ExpatError:
    #     logger.warning('Malformed XML output')

    except Exception as e:
        logger.error('Uncaught exception')
        for line in traceback.format_exception(sys.exc_type, sys.exc_value, sys.exc_traceback):
            logger.error(line)

    if returncode != 0:
        logger.warning('Error %d running external command %s' % (returncode, cmd))
        xmldoc = None

    return xmldoc

def normalize_string(str):
    badchars='"\'[]{}!@#$%^&*()+=:;/?.,<>~`'
    replacechars='_' * len(badchars)
    table = maketrans(badchars, replacechars)

    str = '_'.join(str.lower().split(' '))
    return str.translate(table)

def get_xml_text(nodelist):
    rc = []
    for node in nodelist:
        if node.nodeType == node.TEXT_NODE:
            rc.append(node.data)
        elif node.firstChild.nodeType == node.TEXT_NODE:
            rc.append(node.firstChild.data)

    return ''.join(rc).strip().encode('latin-1')

def get_stats():
    stats = {}
    global_health = 1

    # get chassis information
    chassis_info = get_omsa_report('ssv', 'chassis')
    chassis_healthy = 1

    if chassis_info:
        for component in chassis_info:
            key = 'hardware.chassis.alarm.%s' % normalize_string(component['COMPONENT'])

            value = 0 if component['SEVERITY'] == 'Ok' else 1

            stats[key] = value
            if value:
                chassis_healthy = 0

        stats['hardware.chassis.healthy'] = chassis_healthy

    # get memory info
    memory_info = get_omsa_report('xml', 'chassis', 'memory')

    if memory_info:
        memory_healthy = 1

        for element in memory_info.getElementsByTagName('MemDevObj'):
            loc = get_xml_text(element.getElementsByTagName('DeviceLocator'))
            err = get_xml_text(element.getElementsByTagName('errCount'))
            key = 'hardware.memory.%s.errors' % normalize_string(loc)
            stats[key] = err
            if(err != "0"):
                memory_healthy = 0

        stats['hardware.memory.healthy'] = memory_healthy

    # get physical disk information
    pdisks = []

    controller_info = get_omsa_report('ssv', 'storage', 'controller')
    if controller_info:
        for controller in controller_info:
            controller_id = controller['ID']
            controller_status = 1 if controller['State'] == 'Online' else 0

            stats['hardware.controller.%s.healthy' % controller_id]  = controller_status

            tempdisks = get_omsa_report('ssv', 'storage', 'pdisk', 'controller=%s' % (controller['ID']))

            if tempdisks:
                for disk in tempdisks:
                    pdisks.append(disk)

        for disk in pdisks:
            metric = 'hardware.disks.%s' % normalize_string(disk['ID'])

            fail_predicted = 0 if disk['Failure Predicted'] == 'No' else 1
            online_state = 1 if disk['State'] == 'Online' else 0
            disk_okay = 1 if disk['Status'] == 'Ok' else 0

            stats[metric + '.predicted_failure'] = fail_predicted
            stats[metric + '.online'] = online_state
            stats[metric + '.healthy'] = disk_okay

            if(fail_predicted or not online_state or not disk_okay):
                global_health = 0

        stats['hardware.disks.healthy'] = global_health

    return stats

def read_callback():
    stats = get_stats()

    for key in stats.keys():
        path = key;
        val = collectd.Values(plugin=path)
        val.type = 'gauge'
        val.values = [ int(stats[key]) ]
        val.dispatch()

def configure_callback(conf):
    logger.warning("Got config callback")
    pass


if(IN_COLLECTD):
    logger = CollectdLogger()
    collectd.register_config(configure_callback)
else:
    import logging
    logger = logging

logger.warning("Loading %s" % PLUGIN)

if(IN_COLLECTD):
    collectd.register_read(read_callback)
else:
    stats = get_stats()
    print stats
