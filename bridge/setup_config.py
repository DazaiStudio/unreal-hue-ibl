"""
Interactive setup helper for config.json.

This script is called by run_hue_artnet_bridge.bat when config.json is missing
or still contains placeholder values. It keeps the bridge launcher simple while
letting Python handle JSON safely.
"""

import json
import sys
from pathlib import Path


CONFIG_PATH = Path("config.json")
EXAMPLE_PATH = Path("config.example.json")
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
    artnet["port"] = int(prompt_value("Art-Net listen port", str(artnet.get("port", 6454))))
    artnet["universe"] = int(
        prompt_value("Art-Net universe", str(artnet.get("universe", 1)))
    )
    artnet["fixture_count"] = int(
        prompt_value("Hue fixture/light count", str(artnet.get("fixture_count", 11)))
    )
    artnet["channels_per_fixture"] = int(
        prompt_value(
            "DMX channels per fixture",
            str(artnet.get("channels_per_fixture", 4)),
        )
    )

    with CONFIG_PATH.open("w", encoding="utf-8") as file:
        json.dump(config, file, indent=2)
        file.write("\n")

    print("")
    print("Saved bridge\\config.json.")


if __name__ == "__main__":
    raise SystemExit(main())
