import json
import os
import socket
import subprocess
import tempfile
import time
import unittest
import uuid
from pathlib import Path

CTL = Path(__file__).resolve().parents[1] / 'scripts/stratactl'


class StrataControlTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(prefix='stratactl-test-')
        self.root = Path(self.directory.name)
        self.unit = 'stratactl-test-' + uuid.uuid4().hex + '.service'
        self.env = dict(os.environ, XDG_CONFIG_HOME=str(self.root / 'config'), XDG_STATE_HOME=str(self.root / 'state'))
        self.socket = socket.socket()
        self.socket.bind(('127.0.0.1', 0))
        self.url = 'http://127.0.0.1:' + str(self.socket.getsockname()[1])
        self.launcher = self.root / 'launch.sh'

    def tearDown(self):
        subprocess.run(['systemctl', '--user', 'stop', self.unit], capture_output=True)
        subprocess.run(['systemctl', '--user', 'reset-failed', self.unit], capture_output=True)
        self.socket.close()
        self.directory.cleanup()

    def command(self, *args, check=True):
        return subprocess.run([str(CTL), *args], env=self.env, capture_output=True, text=True, check=check, timeout=15)

    def configure(self, body):
        self.launcher.write_text('#!/bin/sh\n' + body)
        self.launcher.chmod(0o755)
        self.command('configure', str(self.launcher), '--unit', self.unit, '--url', self.url)

    def state(self):
        return json.loads(self.command('status', '--json').stdout)['state']

    def wait_state(self, expected):
        for _ in range(50):
            if self.state() == expected:
                return
            time.sleep(0.1)
        self.fail(f'Expected {expected}, got {self.state()}')

    def test_unconfigured_and_reject_remote_url(self):
        self.assertEqual(self.state(), 'unconfigured')
        self.launcher.write_text('#!/bin/sh\nexit 0\n')
        self.launcher.chmod(0o755)
        result = self.command('configure', str(self.launcher), '--url', 'http://example.com', check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.state(), 'unconfigured')

    def test_occupied_port_is_preserved(self):
        self.socket.listen()
        self.configure('sleep 300\n')
        result = self.command('start', check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('occupied', result.stderr)
        self.assertEqual(self.state(), 'off')
        client = socket.create_connection(self.socket.getsockname(), timeout=1)
        client.close()

    def test_failed_service_stays_visible(self):
        self.socket.close()
        self.configure('exit 17\n')
        self.command('start', check=False)
        self.wait_state('failed')
        self.command('stop', '--wait')
        self.wait_state('off')

    def test_concurrent_start_and_stop_entire_process_group(self):
        self.socket.close()
        pid_file = self.root / 'child.pid'
        self.configure(f'sleep 300 &\necho $! > "{pid_file}"\nwait\n')
        processes = [subprocess.Popen([str(CTL), 'start'], env=self.env, stdout=subprocess.PIPE, stderr=subprocess.PIPE) for _ in range(2)]
        for process in processes:
            output, error = process.communicate(timeout=15)
            self.assertEqual(process.returncode, 0, error.decode())
        self.wait_state('loading')
        for _ in range(50):
            if pid_file.exists():
                break
            time.sleep(0.1)
        child = int(pid_file.read_text())
        self.assertTrue(Path(f'/proc/{child}').exists())
        self.command('toggle', '--wait')
        self.wait_state('off')
        self.assertFalse(Path(f'/proc/{child}').exists())


if __name__ == '__main__':
    unittest.main()
