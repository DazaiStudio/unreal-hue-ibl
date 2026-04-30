"""
Art-Net to Philips Hue Entertainment Bridge.

Listens for ArtDMX packets and maps DMX channels to Philips Hue
Entertainment Streaming RGB updates.
"""

import argparse
import asyncio
import json
import socket
import struct
from pathlib import Path

import urllib3
from hue_entertainment_pykit import Entertainment, Streaming, create_bridge


urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)


def load_config(path):
    with Path(path).open("r", encoding="utf-8") as file:
        return json.load(file)


def parse_artdmx_packet(data, universe):
    if data[:8] != b"Art-Net\x00":
        return None

    opcode = struct.unpack("<H", data[8:10])[0]
    if opcode != 0x5000:
        return None

    packet_universe = struct.unpack("<H", data[14:16])[0]
    if packet_universe != universe:
        return None

    length = struct.unpack(">H", data[16:18])[0]
    return data[18 : 18 + length]


def get_rgb_from_dmx(dmx, start_address):
    if len(dmx) <= start_address + 3:
        return (0, 0, 0)

    dimmer = dmx[start_address] / 255.0
    red = int(dmx[start_address + 1] * dimmer)
    green = int(dmx[start_address + 2] * dimmer)
    blue = int(dmx[start_address + 3] * dimmer)
    return (red, green, blue)


def create_streaming_session(hue_config):
    bridge = create_bridge(
        identification=hue_config["identification"],
        rid=hue_config["rid"],
        ip_address=hue_config["ip_address"],
        swversion=hue_config["swversion"],
        username=hue_config["username"],
        hue_app_id=hue_config.get("hue_app_id", "hue-dmx-ibl"),
        clientkey=hue_config["clientkey"],
        name=hue_config.get("name", "Hue Bridge"),
    )

    entertainment_service = Entertainment(bridge)
    entertainment_configs = entertainment_service.get_entertainment_configs()
    entertainment_config = list(entertainment_configs.values())[0]

    streaming = Streaming(
        bridge,
        entertainment_config,
        entertainment_service.get_ent_conf_repo(),
    )
    streaming.set_color_space("rgb")
    return streaming


async def artnet_listener(streaming, artnet_config):
    host = artnet_config.get("host", "0.0.0.0")
    port = int(artnet_config.get("port", 6454))
    universe = int(artnet_config.get("universe", 1))
    fixture_count = int(artnet_config.get("fixture_count", 11))
    channels_per_fixture = int(artnet_config.get("channels_per_fixture", 4))
    minimum_channels = fixture_count * channels_per_fixture

    loop = asyncio.get_event_loop()
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.bind((host, port))
    sock.setblocking(False)

    last_rgbs = [(0, 0, 0)] * fixture_count

    print(f"Listening for Art-Net on {host}:{port}, universe {universe}")

    while True:
        try:
            data = await loop.sock_recv(sock, 1024)
            dmx = parse_artdmx_packet(data, universe)
            if not dmx or len(dmx) < minimum_channels:
                continue

            updated = False
            for index in range(fixture_count):
                address = index * channels_per_fixture
                rgb = get_rgb_from_dmx(dmx, address)
                if rgb != last_rgbs[index]:
                    last_rgbs[index] = rgb
                    streaming.set_input((*rgb, index))
                    print(f"Light {index + 1} updated: {rgb}")
                    updated = True

            if not updated:
                await asyncio.sleep(0.01)

        except Exception as exc:
            print(f"Error: {exc}")

        await asyncio.sleep(0.01)


async def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--config",
        default="config.json",
        help="Path to bridge config JSON.",
    )
    args = parser.parse_args()

    config = load_config(args.config)
    streaming = create_streaming_session(config["hue"])

    print("Connecting to Hue Entertainment Stream")
    streaming.start_stream()
    try:
        await artnet_listener(streaming, config["artnet"])
    finally:
        streaming.stop_stream()


if __name__ == "__main__":
    asyncio.run(main())
