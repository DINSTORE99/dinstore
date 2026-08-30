#!/usr/bin/env python3

import json
import os
import subprocess
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path


# ============================================================
# CONFIGURATION
# ============================================================

CFG = Path("/etc/dinstore")
USERS = CFG / "users.json"
BACKUPS = Path("/var/backups/dinstore")

API_KEY = os.getenv("API_KEY", "").strip()
HOST = os.getenv("API_HOST", "127.0.0.1")
PORT = int(os.getenv("API_PORT", "8080"))


# ============================================================
# JSON RESPONSE
# ============================================================

def json_out(handler, code, obj):
    data = json.dumps(
        obj,
        ensure_ascii=False
    ).encode()

    handler.send_response(code)
    handler.send_header(
        "Content-Type",
        "application/json"
    )
    handler.send_header(
        "Content-Length",
        str(len(data))
    )
    handler.end_headers()
    handler.wfile.write(data)


# ============================================================
# AUTHENTICATION
# ============================================================

def auth(handler):
    if not API_KEY:
        return False

    return (
        handler.headers.get("X-API-Key", "") == API_KEY
    )


# ============================================================
# HTTP HANDLER
# ============================================================

class H(BaseHTTPRequestHandler):

    def log_message(self, *args):
        pass

    # --------------------------------------------------------
    # GET
    # --------------------------------------------------------

    def do_GET(self):

        # Health check
        if self.path == "/health":
            return json_out(
                self,
                200,
                {
                    "ok": True
                }
            )

        # Authentication
        if not auth(self):
            return json_out(
                self,
                401,
                {
                    "ok": False,
                    "error": "unauthorized"
                }
            )

        # ----------------------------------------------------
        # SERVER STATUS
        # ----------------------------------------------------

        if self.path == "/api/v1/status":

            services = {}

            service_list = [
                "nginx",
                "xray",
                "dinstore-api",
                "openvpn-server@server",
            ]

            for service in service_list:
                process = subprocess.run(
                    [
                        "systemctl",
                        "is-active",
                        service,
                    ],
                    capture_output=True,
                    text=True,
                )

                services[service] = (
                    process.stdout.strip()
                    or "unknown"
                )

            return json_out(
                self,
                200,
                {
                    "ok": True,
                    "time": int(time.time()),
                    "services": services,
                }
            )

        # ----------------------------------------------------
        # USERS
        # ----------------------------------------------------

        if self.path == "/api/v1/users":

            try:
                users = json.loads(
                    USERS.read_text()
                )

                return json_out(
                    self,
                    200,
                    users
                )

            except Exception:
                return json_out(
                    self,
                    200,
                    {
                        "users": []
                    }
                )

        # ----------------------------------------------------
        # BACKUPS
        # ----------------------------------------------------

        if self.path == "/api/v1/backups":

            backups = []

            for path in sorted(
                BACKUPS.glob("dinstore-*.tar.gz")
            ):
                backups.append(
                    {
                        "name": path.name,
                        "size": path.stat().st_size,
                    }
                )

            return json_out(
                self,
                200,
                {
                    "backups": backups
                }
            )

        # ----------------------------------------------------
        # BACKUP CONFIG
        # ----------------------------------------------------

        if self.path == "/api/v1/backup/config":

            config = {}

            try:
                lines = (
                    CFG / "config.env"
                ).read_text().splitlines()

                allowed = (
                    "BACKUP_ENABLED=",
                    "BACKUP_RETENTION=",
                    "BACKUP_TIME=",
                )

                for line in lines:

                    if line.startswith(allowed):
                        key, value = line.split(
                            "=",
                            1
                        )

                        config[key] = value

            except Exception:
                pass

            return json_out(
                self,
                200,
                {
                    "ok": True,
                    **config,
                }
            )

        # ----------------------------------------------------
        # NOT FOUND
        # ----------------------------------------------------

        return json_out(
            self,
            404,
            {
                "ok": False,
                "error": "not_found",
            }
        )

    # --------------------------------------------------------
    # POST
    # --------------------------------------------------------

    def do_POST(self):

        # Authentication
        if not auth(self):
            return json_out(
                self,
                401,
                {
                    "ok": False,
                    "error": "unauthorized",
                }
            )

        # Read request body
        content_length = int(
            self.headers.get(
                "Content-Length",
                "0"
            )
        )

        raw = (
            self.rfile.read(content_length)
            if content_length
            else b"{}"
        )

        try:
            body = json.loads(
                raw or b"{}"
            )

        except Exception:
            return json_out(
                self,
                400,
                {
                    "ok": False,
                    "error": "invalid_json",
                }
            )

        # ----------------------------------------------------
        # RUN BACKUP
        # ----------------------------------------------------

        if self.path == "/api/v1/backup":

            process = subprocess.run(
                [
                    "/opt/dinstore/bin/backup.sh",
                    "api",
                ],
                capture_output=True,
                text=True,
            )

            success = process.returncode == 0

            return json_out(
                self,
                200 if success else 500,
                {
                    "ok": success,
                    "file": process.stdout.strip(),
                    "error": process.stderr.strip(),
                }
            )

        # ----------------------------------------------------
        # UPDATE BACKUP CONFIG
        # ----------------------------------------------------

        if self.path == "/api/v1/backup/config":

            config_file = CFG / "config.env"

            lines = config_file.read_text().splitlines()

            changes = (
                body
                if isinstance(body, dict)
                else {}
            )

            allowed = {
                "BACKUP_ENABLED",
                "BACKUP_RETENTION",
                "BACKUP_TIME",
                "SC_ORDER",
            }

            output = []

            for line in lines:

                if "=" in line:

                    key = line.split(
                        "=",
                        1
                    )[0]

                    if (
                        key in allowed
                        and key in changes
                    ):
                        line = (
                            key
                            + "="
                            + str(changes[key])
                        )

                output.append(line)

            config_file.write_text(
                "\n".join(output) + "\n"
            )

            subprocess.run(
                [
                    "systemctl",
                    "daemon-reload",
                ]
            )

            subprocess.run(
                [
                    "systemctl",
                    "restart",
                    "dinstore-backup.timer",
                ]
            )

            return json_out(
                self,
                200,
                {
                    "ok": True,
                    "note": (
                        "timer menggunakan nilai "
                        "BACKUP_TIME baru"
                    ),
                }
            )

        # ----------------------------------------------------
        # ADD USER
        # ----------------------------------------------------

        if self.path == "/api/v1/users":

            if (
                not isinstance(body, dict)
                or not body.get("username")
            ):
                return json_out(
                    self,
                    400,
                    {
                        "ok": False,
                        "error": "username_required",
                    }
                )

            username = str(
                body["username"]
            )

            days = int(
                body.get(
                    "days",
                    30
                )
            )

            process = subprocess.run(
                [
                    "/opt/dinstore/bin/user.sh",
                    "add",
                    username,
                    str(days),
                ],
                capture_output=True,
                text=True,
            )

            if process.returncode:
                return json_out(
                    self,
                    409,
                    {
                        "ok": False,
                        "error": (
                            process.stderr.strip()
                            or process.stdout.strip()
                        ),
                    }
                )

            user_data = dict(
                line.split("=", 1)
                for line in process.stdout.splitlines()
                if "=" in line
            )

            return json_out(
                self,
                201,
                {
                    "ok": True,
                    "user": user_data,
                }
            )

        # ----------------------------------------------------
        # DELETE USER
        # ----------------------------------------------------

        if self.path == "/api/v1/users/delete":

            username = str(
                body.get(
                    "username",
                    ""
                )
            )

            if not username:
                return json_out(
                    self,
                    400,
                    {
                        "ok": False,
                        "error": "username_required",
                    }
                )

            process = subprocess.run(
                [
                    "/opt/dinstore/bin/user.sh",
                    "del",
                    username,
                ],
                capture_output=True,
                text=True,
            )

            success = process.returncode == 0

            return json_out(
                self,
                200 if success else 500,
                {
                    "ok": success
                }
            )

        # ----------------------------------------------------
        # NOT FOUND
        # ----------------------------------------------------

        return json_out(
            self,
            404,
            {
                "ok": False,
                "error": "not_found",
            }
        )


# ============================================================
# SERVER
# ============================================================

if __name__ == "__main__":

    server = ThreadingHTTPServer(
        (HOST, PORT),
        H
    )

    print(
        f"DINSTORE API running on "
        f"http://{HOST}:{PORT}"
    )

    server.serve_forever()
