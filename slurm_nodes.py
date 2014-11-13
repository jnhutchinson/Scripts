#!/usr/bin/env python
"""Prints a comma separated list of SLURM compute nodes that have excessive CPU load.
Output is suitable for using as value for -x option.

Usage: $ python slurm_nodes.py

Depends on scontrol command.

"""
import subprocess
import sys


def stop_err(msg, returncode=1):
    sys.stderr.write(msg)
    sys.exit(returncode)


cmd = 'scontrol -o show node'

try:
    output = subprocess.check_output(cmd.split())
except subprocess.CalledProcessError as e:
    stop_err("Error executing '{}'".format(cmd), e.returncode)

node_list = []
for node_str in output.splitlines():
    for param_str in node_str.split():
        param = param_str.split('=')
        try:
            if param[0] == 'NodeName':
                node_name = param[1]
            elif param[0] == 'CPUTot':
                cpu_total = int(param[1])
            elif param[0] == 'CPULoad':
                cpu_load = float(param[1])
        except ValueError:
            break
    try:
        if cpu_load > cpu_total * 1.05:
            node_list.append(node_name)
    except UnboundLocalError:  # some value is missing
        continue

print ','.join(node_list)
