#!/usr/bin/env python3
"""Waybar status for RiseupVPN, with or without its optional local API."""
import json
import subprocess
from pathlib import Path
from urllib.request import Request, urlopen


def run(*args):
    return subprocess.run(args, capture_output=True, text=True, timeout=2)


state = None
try:
    token = Path('/tmp/bitmask-token').read_text()
    request = Request('http://127.0.0.1:18766/vpn/status',
                      headers={'X-Auth-Token': token})
    with urlopen(request, timeout=0.7) as response:
        state = response.read().decode().strip()
except (OSError, ValueError):
    pass

# Require a real tunnel and Riseup's OpenVPN helper before showing green.
try:
    tunnel = json.loads(run('ip', '-j', 'address', 'show', 'dev', 'tun0').stdout or '[]')
    addressed = any(a.get('scope') == 'global'
                    for link in tunnel for a in link.get('addr_info', []))
    riseup = run('pgrep', '-x', 'riseup-vpn').returncode == 0
    helper = run('pgrep', '-f', '^/usr/(sbin|bin)/openvpn --setenv LEAPOPENVPN 1').returncode == 0
    connected = addressed and riseup and helper and state in (None, 'on')
except (OSError, ValueError, subprocess.TimeoutExpired):
    connected = False

if connected:
    label, css = 'Connected', 'connected'
elif state in ('starting', 'stopping'):
    label, css = ('Connecting' if state == 'starting' else 'Disconnecting'), 'connecting'
elif state == 'failed':
    label, css = 'Connection failed', 'disconnected'
else:
    label, css = 'Disconnected', 'disconnected'
print(json.dumps({'text': '', 'tooltip': f'RiseupVPN: {label}\nClick to open connection controls', 'class': css}))
