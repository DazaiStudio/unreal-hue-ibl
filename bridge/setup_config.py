"""
Interactive setup helper for config.json.

This script is called by run_hue_artnet_bridge.bat when config.json is missing
or still contains placeholder values. It keeps the bridge launcher simple while
letting Python handle JSON safely.
"""

import json
import sys
from pathlib import Path


BASE_DIR = Path(__file__).resolve().parent
CONFIG_PATH = BASE_DIR / "config.json"
EXAMPLE_PATH = BASE_DIR / "config.example.json"
REQUIRED_HUE_FIELDS = (
    "ip_address",
    "username",
    "clientkey",
    "rid",
    "identification",
)

PLACEHOLDER_PREFIXES = (
    "your-",
    "<",
)


def is_placeholder(value):
    if not isinstance(value, str):
        return False

    stripped = value.strip()
    return not stripped or stripped.startswith(PLACEHOLDER_PREFIXES)


def prompt_value(label, current):
    if current and not is_placeholder(current):
        prompt = f"{label} [{current}]: "
    else:
        prompt = f"{label}: "

    value = input(prompt).strip()
    return value or current


def prompt_int(label, current):
    while True:
        value = prompt_value(label, str(current))
        try:
            return int(value)
        except ValueError:
            print(f"Please enter a whole number for {label}.")


def load_config():
    if CONFIG_PATH.exists():
        with CONFIG_PATH.open("r", encoding="utf-8") as file:
            return json.load(file)

    if not EXAMPLE_PATH.exists():
        raise FileNotFoundError("Missing config.example.json.")

    with EXAMPLE_PATH.open("r", encoding="utf-8") as file:
        return json.load(file)


def needs_setup(config):
    hue = config.get("hue", {})
    return any(is_placeholder(hue.get(field, "")) for field in REQUIRED_HUE_FIELDS)


def missing_hue_fields(config):
    hue = config.get("hue", {})
    return [field for field in REQUIRED_HUE_FIELDS if is_placeholder(hue.get(field, ""))]


def main():
    config = load_config()

    if "--check" in sys.argv:
        return 1 if needs_setup(config) else 0

    hue = config.setdefault("hue", {})
    artnet = config.setdefault("artnet", {})

    print("")
    print("Hue Art-Net Bridge setup")
    print("------------------------")
    print("Press Enter to keep an existing value.")
    print("")

    hue["ip_address"] = prompt_value(
        "Hue Bridge IP address, for example 192.168.1.100",
        hue.get("ip_address", ""),
    )
    hue["username"] = prompt_value("Hue API username", hue.get("username", ""))
    hue["clientkey"] = prompt_value(
        "Hue Entertainment clientkey",
        hue.get("clientkey", ""),
    )
    hue["rid"] = prompt_value(
        "Hue Entertainment Area rid",
        hue.get("rid", ""),
    )
    hue["identification"] = prompt_value(
        "Hue Bridge identification",
        hue.get("identification", ""),
    )

    artnet["host"] = prompt_value("Art-Net listen host", artnet.get("host", "0.0.0.0"))
    artnet["port"] = prompt_int("Art-Net listen port", artnet.get("port", 6454))
    artnet["universe"] = prompt_int("Art-Net universe", artnet.get("universe", 1))
    artnet["fixture_count"] = prompt_int(
        "Hue fixture/light count",
        artnet.get("fixture_count", 11),
    )
    artnet["channels_per_fixture"] = prompt_int(
        "DMX channels per fixture",
        artnet.get("channels_per_fixture", 4),
    )

    with CONFIG_PATH.open("w", encoding="utf-8") as file:
        json.dump(config, file, indent=2)
        file.write("\n")

    print("")
    print("Saved bridge\\config.json.")

    missing = missing_hue_fields(config)
    if missing:
        print("")
        print("Config is still missing required Hue values:")
        for field in missing:
            print(f"- hue.{field}")
        print("")
        print("Open bridge\\config.json or run this launcher again after you have them.")
        return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
