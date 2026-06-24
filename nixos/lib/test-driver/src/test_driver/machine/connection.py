import base64
import os
import select
import shlex
import subprocess
import time
from collections.abc import Callable

from test_driver.errors import MachineError

DEFAULT_READY_MARKER = b"Spawning backdoor root shell..."


class Connection:
    """A duplex byte channel to a guest backdoor shell, speaking the base64
    framing protocol from test-instrumentation.nix's backdoor.service.

    Owns one fd (a PTY master or a socket) and closes it on `close()`.
    """

    fd: int
    name: str
    log: Callable[[str], None]
    ready_marker: bytes
    _ready: bool

    def __init__(
        self,
        fd: int,
        *,
        name: str,
        log: Callable[[str], None],
        ready_marker: bytes = DEFAULT_READY_MARKER,
    ) -> None:
        self.fd = fd
        self.name = name
        self.log = log
        self.ready_marker = ready_marker
        self._ready = False

    def fileno(self) -> int:
        return self.fd

    def close(self) -> None:
        if self.fd >= 0:
            try:
                os.close(self.fd)
            except OSError:
                pass
            self.fd = -1

    def send(self, data: bytes) -> None:
        os.write(self.fd, data)

    def _read_chunk(self, size: int = 4096) -> bytes:
        return os.read(self.fd, size)

    def _read_until_newline(self) -> str:
        output_buffer: list[str] = []
        while True:
            chunk = self._read_chunk(4096)
            if not chunk:
                break
            decoded = chunk.decode()
            output_buffer.append(decoded)
            if decoded.endswith("\n"):
                break
        return "".join(output_buffer)

    def wait_until_ready(self, poll_timeout: float = 30.0) -> None:
        if self._ready:
            return
        tic = time.time()
        while True:
            (ready, _, _) = select.select([self.fd], [], [], poll_timeout)
            if not ready:
                self.log("guest root shell did not produce any data yet...")
                self.log(
                    "  To debug, enter the machine and run 'systemctl status backdoor.service'."
                )
                continue
            chunk = self._read_chunk(1024)
            if not chunk:
                raise MachineError(
                    f"shell on {self.name} disconnected before signalling readiness"
                )
            self.log(f"guest shell says: {chunk!r}")
            if self.ready_marker in chunk:
                break
        toc = time.time()
        self.log("connected to guest root shell")
        self.log(f"(connecting took {toc - tic:.2f} seconds)")
        self._ready = True

    def reset_ready(self) -> None:
        # after a reboot the backdoor will re-announce itself
        self._ready = False

    def run(
        self,
        command: str,
        *,
        check_return: bool = True,
        check_output: bool = True,
        timeout: int | None = 900,
    ) -> tuple[int, str]:
        command = f"set -euo pipefail; {command}"
        timeout_str = f"timeout {timeout}" if timeout is not None else ""
        out_command = (
            f"{timeout_str} bash -c {shlex.quote(command)} | (base64 -w 0; echo)\n"
        )
        self.send(out_command.encode())

        if not check_output:
            return (-2, "")

        output = base64.b64decode(self._read_until_newline())

        if not check_return:
            return (-1, output.decode())

        self.send(b"echo ${PIPESTATUS[0]}\n")
        rc = int(self._read_until_newline().strip())
        return (rc, output.decode(errors="replace"))

    def interact(self, address: str | None = None) -> None:
        if address is None:
            address = "READLINE,prompt=$ "
            self.log("Terminal is ready (there is no initial prompt):")
        try:
            subprocess.run(
                ["socat", address, f"FD:{self.fd}"],
                pass_fds=[self.fd],
            )
        except KeyboardInterrupt:
            pass
