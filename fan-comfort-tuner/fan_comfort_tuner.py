#!/usr/bin/env python3
"""Audition an NVIDIA GPU fan speed and save a safe LACT fan curve."""

from __future__ import annotations

import copy
import json
import socket

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Adw, GLib, Gtk


SOCKET_PATH = "/run/lactd.sock"


class LactError(RuntimeError):
    pass


class LactClient:
    def request(self, command: str, args: dict | None = None):
        payload = {"command": command}
        if args is not None:
            payload["args"] = args

        try:
            with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as stream:
                stream.settimeout(3)
                stream.connect(SOCKET_PATH)
                stream.sendall((json.dumps(payload) + "\n").encode())
                chunks = bytearray()
                while not chunks.endswith(b"\n"):
                    chunk = stream.recv(65536)
                    if not chunk:
                        break
                    chunks.extend(chunk)
        except OSError as error:
            raise LactError(
                f"Cannot connect to LACT at {SOCKET_PATH}: {error}. "
                "Make sure lactd is running and your user is in the wheel group."
            ) from error

        if not chunks:
            raise LactError("LACT returned an empty response")

        response = json.loads(chunks)
        if response.get("status") != "ok":
            detail = response.get("data", "unknown LACT error")
            if isinstance(detail, dict):
                detail = detail.get("message", json.dumps(detail))
            raise LactError(str(detail))
        return response.get("data")

    def list_devices(self):
        return self.request("list_devices")

    def get_config(self, gpu_id: str):
        return self.request("get_gpu_config", {"id": gpu_id}) or {}

    def get_stats(self, gpu_id: str):
        return self.request("device_stats", {"id": gpu_id})

    def set_config(self, gpu_id: str, config: dict) -> int:
        return int(
            self.request("set_gpu_config", {"id": gpu_id, "config": config})
        )

    def resolve_pending(self, keep: bool):
        command = "confirm" if keep else "revert"
        return self.request("confirm_pending_config", {"command": command})


class FanComfortWindow(Adw.ApplicationWindow):
    def __init__(self, app: Adw.Application):
        super().__init__(application=app, title="Fan Comfort Tuner")
        self.set_default_size(650, 610)

        self.client = LactClient()
        self.gpu_id = ""
        self.gpu_name = "GPU"
        self.starting_config: dict = {}
        self.preview_seconds = 0
        self.preview_active = False
        self.last_stats: dict = {}

        toolbar = Adw.ToolbarView()
        toolbar.add_top_bar(Adw.HeaderBar())
        self.set_content(toolbar)

        outer = Gtk.Box(
            orientation=Gtk.Orientation.VERTICAL,
            spacing=18,
            margin_top=20,
            margin_bottom=20,
            margin_start=24,
            margin_end=24,
        )
        toolbar.set_content(outer)

        self.gpu_label = Gtk.Label(xalign=0)
        self.gpu_label.add_css_class("title-2")
        outer.append(self.gpu_label)

        stats_grid = Gtk.Grid(column_spacing=28, row_spacing=7)
        outer.append(stats_grid)
        self.temp_value = self._stat_row(stats_grid, 0, "GPU temperature")
        self.hotspot_value = self._stat_row(stats_grid, 1, "Hotspot")
        self.fan_value = self._stat_row(stats_grid, 2, "Fan")

        separator = Gtk.Separator()
        outer.append(separator)

        heading = Gtk.Label(label="1. Find your comfortable fan speed", xalign=0)
        heading.add_css_class("title-3")
        outer.append(heading)

        explanation = Gtk.Label(
            label=(
                "Choose a speed and press Preview. It runs for five seconds, then LACT "
                "automatically restores your curve—even if this app closes. Listen for "
                "the fastest speed you are happy to hear during normal gaming."
            ),
            xalign=0,
            wrap=True,
        )
        outer.append(explanation)

        self.speed_label = Gtk.Label(xalign=0)
        self.speed_label.add_css_class("title-1")
        outer.append(self.speed_label)

        adjustment = Gtk.Adjustment(
            value=50, lower=30, upper=100, step_increment=1, page_increment=5
        )
        self.speed_scale = Gtk.Scale(
            orientation=Gtk.Orientation.HORIZONTAL, adjustment=adjustment
        )
        self.speed_scale.set_draw_value(False)
        self.speed_scale.set_hexpand(True)
        for value in (30, 40, 50, 60, 70, 80, 100):
            self.speed_scale.add_mark(value, Gtk.PositionType.BOTTOM, str(value))
        self.speed_scale.connect("value-changed", self._speed_changed)
        outer.append(self.speed_scale)

        button_row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        outer.append(button_row)
        self.preview_button = Gtk.Button(label="Preview for 5 seconds")
        self.preview_button.add_css_class("suggested-action")
        self.preview_button.connect("clicked", self._preview)
        button_row.append(self.preview_button)

        self.stop_button = Gtk.Button(label="Stop preview")
        self.stop_button.set_sensitive(False)
        self.stop_button.connect("clicked", self._stop_preview)
        button_row.append(self.stop_button)

        use_current = Gtk.Button(label="Use current speed")
        use_current.connect("clicked", self._use_current_speed)
        button_row.append(use_current)

        curve_heading = Gtk.Label(label="2. Save it as your normal ceiling", xalign=0)
        curve_heading.add_css_class("title-3")
        outer.append(curve_heading)

        self.curve_summary = Gtk.Label(xalign=0, wrap=True)
        outer.append(self.curve_summary)

        save_row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        outer.append(save_row)
        self.save_button = Gtk.Button(label="Save comfort curve")
        self.save_button.add_css_class("suggested-action")
        self.save_button.connect("clicked", self._save_curve)
        save_row.append(self.save_button)

        restore_button = Gtk.Button(label="Restore curve from app start")
        restore_button.connect("clicked", self._restore_starting_curve)
        save_row.append(restore_button)

        self.status = Gtk.Label(xalign=0, wrap=True)
        self.status.add_css_class("dim-label")
        outer.append(self.status)

        try:
            self._initialize()
        except Exception as error:
            self._show_error(error)
            self.preview_button.set_sensitive(False)
            self.save_button.set_sensitive(False)

        GLib.timeout_add_seconds(1, self._tick)

    @staticmethod
    def _stat_row(grid: Gtk.Grid, row: int, title: str) -> Gtk.Label:
        name = Gtk.Label(label=title, xalign=0)
        name.add_css_class("dim-label")
        value = Gtk.Label(label="—", xalign=0)
        value.add_css_class("title-4")
        grid.attach(name, 0, row, 1, 1)
        grid.attach(value, 1, row, 1, 1)
        return value

    def _initialize(self):
        devices = self.client.list_devices()
        dedicated = [d for d in devices if d.get("device_type") == "Dedicated"]
        device = dedicated[0] if dedicated else devices[0]
        self.gpu_id = device["id"]
        self.gpu_name = device["name"]
        self.gpu_label.set_label(self.gpu_name)
        self.starting_config = copy.deepcopy(self.client.get_config(self.gpu_id))

        initial_speed = round(
            self.starting_config.get("fan_control_settings", {}).get(
                "static_speed", 0.50
            )
            * 100
        )
        self.speed_scale.set_value(max(30, min(100, initial_speed)))
        self._refresh_stats()
        self._speed_changed(self.speed_scale)
        self.status.set_label("Ready. No changes are made until you press a button.")

    def _speed(self) -> int:
        return round(self.speed_scale.get_value())

    def _speed_changed(self, _scale):
        speed = self._speed()
        self.speed_label.set_label(f"{speed}%")
        high_speed = min(100, max(speed + 15, 80))
        self.curve_summary.set_label(
            f"20–40°C: 30%  •  65–70°C: {speed}%  •  "
            f"75°C: {high_speed}%  •  82°C: 100%\n"
            "The fan ramps up to your comfort ceiling, and exceeds it only after 70°C."
        )

    def _config_with_static_speed(self, speed: int) -> dict:
        config = copy.deepcopy(self.client.get_config(self.gpu_id))
        settings = config.setdefault("fan_control_settings", {})
        settings.update(
            {
                "mode": "static",
                "static_speed": speed / 100,
                "temperature_key": "edge",
                "interval_ms": 500,
                "spindown_delay_ms": 5000,
                "change_threshold": 2,
            }
        )
        settings.setdefault("curve", {"20": 0.5, "70": 0.5, "82": 1.0})
        config["fan_control_enabled"] = True
        return config

    def _config_with_comfort_curve(self, speed: int) -> dict:
        config = copy.deepcopy(self.client.get_config(self.gpu_id))
        high_speed = min(100, max(speed + 15, 80))
        settings = config.setdefault("fan_control_settings", {})
        settings.update(
            {
                "mode": "curve",
                "static_speed": speed / 100,
                "temperature_key": "edge",
                "interval_ms": 500,
                "curve": {
                    "20": 0.30,
                    "40": 0.30,
                    "55": max(30, speed - 10) / 100,
                    "65": speed / 100,
                    "70": speed / 100,
                    "75": high_speed / 100,
                    "82": 1.0,
                },
                "spindown_delay_ms": 5000,
                "change_threshold": 2,
            }
        )
        config["fan_control_enabled"] = True
        return config

    def _preview(self, _button):
        try:
            delay = self.client.set_config(
                self.gpu_id, self._config_with_static_speed(self._speed())
            )
            self.preview_seconds = delay
            self.preview_active = True
            self.preview_button.set_sensitive(False)
            self.save_button.set_sensitive(False)
            self.stop_button.set_sensitive(True)
            self.status.set_label(
                f"Previewing {self._speed()}% — automatic restore in {delay} seconds."
            )
        except Exception as error:
            self._show_error(error)

    def _stop_preview(self, _button):
        if not self.preview_active:
            return
        try:
            self.client.resolve_pending(False)
            self._finish_preview("Preview stopped; the saved curve is active again.")
        except Exception as error:
            self._show_error(error)

    def _finish_preview(self, message: str):
        self.preview_active = False
        self.preview_seconds = 0
        self.preview_button.set_sensitive(True)
        self.save_button.set_sensitive(True)
        self.stop_button.set_sensitive(False)
        self.status.set_label(message)

    def _save_curve(self, _button):
        if self.preview_active:
            self.status.set_label("Stop the preview or wait for it to finish first.")
            return
        try:
            self.client.set_config(
                self.gpu_id, self._config_with_comfort_curve(self._speed())
            )
            self.client.resolve_pending(True)
            self.status.set_label(
                f"Saved: normal-use ceiling {self._speed()}%, then the safety ramp."
            )
        except Exception as error:
            self._show_error(error)

    def _restore_starting_curve(self, _button):
        if self.preview_active:
            self.status.set_label("Stop the preview or wait for it to finish first.")
            return
        try:
            current = self.client.get_config(self.gpu_id)
            for key in ("fan_control_enabled", "fan_control_settings"):
                if key in self.starting_config:
                    current[key] = copy.deepcopy(self.starting_config[key])
                else:
                    current.pop(key, None)
            self.client.set_config(self.gpu_id, current)
            self.client.resolve_pending(True)
            self.status.set_label("Restored the fan settings captured when the app opened.")
        except Exception as error:
            self._show_error(error)

    def _use_current_speed(self, _button):
        fan = self.last_stats.get("fan", {})
        pwm = fan.get("pwm_current")
        maximum = fan.get("pwm_max") or 255
        if pwm is None:
            self.status.set_label("LACT is not currently reporting fan PWM.")
            return
        self.speed_scale.set_value(round(pwm / maximum * 100))

    def _refresh_stats(self):
        if not self.gpu_id:
            return
        stats = self.client.get_stats(self.gpu_id)
        self.last_stats = stats
        temps = stats.get("temps", {})
        gpu_temp = temps.get("GPU", {}).get("current")
        hotspot = temps.get("GPU Hotspot", {}).get("current")
        fan = stats.get("fan", {})
        rpm = fan.get("speed_current")
        pwm = fan.get("pwm_current")
        pwm_max = fan.get("pwm_max") or 255
        percent = round(pwm / pwm_max * 100) if pwm is not None else None
        self.temp_value.set_label(f"{gpu_temp:.0f}°C" if gpu_temp is not None else "—")
        self.hotspot_value.set_label(
            f"{hotspot:.0f}°C" if hotspot is not None else "—"
        )
        if percent is None:
            self.fan_value.set_label("—")
        else:
            rpm_text = f" / {rpm} RPM" if rpm is not None else ""
            self.fan_value.set_label(f"{percent}%{rpm_text}")

    def _tick(self):
        try:
            self._refresh_stats()
        except Exception as error:
            self.status.set_label(str(error))

        if self.preview_active:
            if self.preview_seconds > 0:
                self.preview_seconds -= 1
                if self.preview_seconds > 0:
                    self.status.set_label(
                        f"Previewing {self._speed()}% — automatic restore in "
                        f"{self.preview_seconds} seconds."
                    )
                else:
                    self.status.set_label("LACT is restoring the saved curve…")
            elif self.preview_seconds == 0:
                # LACT performs the actual timeout/revert. Give it one extra poll
                # before allowing another config transaction.
                self.preview_seconds = -1
            else:
                self._finish_preview("Preview complete; the saved curve is active again.")
        return GLib.SOURCE_CONTINUE

    def _show_error(self, error: Exception):
        self.status.set_label(f"Error: {error}")


class FanComfortApp(Adw.Application):
    def __init__(self):
        super().__init__(application_id="dev.local.FanComfortTuner")

    def do_activate(self):
        window = self.props.active_window
        if window is None:
            window = FanComfortWindow(self)
        window.present()


if __name__ == "__main__":
    app = FanComfortApp()
    raise SystemExit(app.run())
