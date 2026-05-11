# unreal-hue-ibl

`unreal-hue-ibl` is an Unreal Engine to Philips Hue lighting bridge reference. It shows how Unreal Engine DMX output can drive Hue lights through a small Python translator.

![unreal-hue-ibl Overview](docs/images/overview-workflow.png)

## Architecture At A Glance

```text
Laptop
  Unreal Engine --Art-Net UDP 127.0.0.1:6454--> Python Bridge

Network / Hue System
  Python Bridge --Hue Entertainment Stream--> Router / LAN --> Hue Bridge --> Hue Lights
```

The important boundary is the Python bridge:

```text
DMX / Art-Net side: Unreal Engine -> Python Bridge
Hue side:          Python Bridge -> Hue Bridge -> Hue Lights
```

The Hue Bridge does **not** receive DMX or Art-Net directly. It receives Hue Entertainment stream data from the Python bridge.

Art-Net is the local protocol link from Unreal Engine to Python. It is not a separate hardware device or app in this setup.

## How To Use This Repo

1. Start with the overview above to understand the high-level hardware path.
2. Read [Communication Workflow](docs/communication-workflow.md) to understand the exact protocol path.
3. Read [Hardware Workflow](docs/hardware-workflow.md) to understand the laptop, router, Hue Bridge, and Hue lights setup.
4. Use the public Python bridge in [bridge/](bridge/) as the runnable Art-Net to Hue translator.
5. Use [unreal-template/](unreal-template/) as the placeholder for the downloadable Unreal Engine template project.

This repository is intentionally not a full Unreal Engine project backup. Large UE assets should be distributed through a GitHub Release or external template download link.

## Run The Bridge

### One-Click Windows Launcher

On Windows, open the `bridge/` folder and double-click:

```text
run_hue_artnet_bridge.bat
```

The launcher will create a local Python virtual environment, install Python dependencies, create `bridge/config.json` when needed, and prompt for Hue Bridge settings the first time it runs.

You still need your Hue Bridge values: `ip_address`, `username`, `clientkey`, and Entertainment Area `rid`. See [Hue Bridge Setup](docs/hue-bridge-setup.md) for how to find or generate them.

### Manual Run

1. Configure a Hue Entertainment Area in the Philips Hue app.
2. Copy `bridge/config.example.json` to `bridge/config.json`.
3. Fill in your Hue Bridge values in `bridge/config.json`. See [Hue Bridge Setup](docs/hue-bridge-setup.md) for how to generate `username`, `clientkey`, and `rid`.
4. Install dependencies:

```bash
pip install -r bridge/requirements.txt
```

5. Start the bridge:

```bash
python bridge/hue_artnet_bridge.py --config bridge/config.json
```

6. In Unreal Engine, send Art-Net to:

```text
Destination IP: 127.0.0.1
Port: 6454
Universe: 1
Fixture layout: Dimmer, Red, Green, Blue
```

Use `127.0.0.1` when Unreal Engine and the Python bridge are running on the same laptop.

Set the Hue Bridge's local network IP in `bridge/config.json` as `hue.ip_address`. Use an example such as `192.168.1.100` in docs, not your personal bridge IP.

## Docs

| Document | Purpose |
| --- | --- |
| [Overview](docs/overview.md) | Project concept and component responsibilities |
| [Communication Workflow](docs/communication-workflow.md) | Protocol flow from Unreal Engine to Hue lights |
| [Hardware Workflow](docs/hardware-workflow.md) | Physical laptop, router, bridge, and light setup |
| [System Architecture](docs/system-architecture.md) | What each component does and does not do |
| [Unreal Setup](docs/unreal-setup.md) | Unreal Engine DMX / Art-Net setup notes |
| [Hue Bridge Setup](docs/hue-bridge-setup.md) | Hue Entertainment setup notes |
| [DMX Mapping](docs/dmx-mapping.md) | DMX channel mapping |
| [Troubleshooting](docs/troubleshooting.md) | Common setup issues |

## Repository Layout

```text
bridge/             Python Art-Net to Hue bridge
docs/               Architecture, workflow, and setup documentation
docs/images/        Generated workflow diagrams
unreal-template/    Unreal Engine template distribution notes
```

## Security

Do not commit your real Hue Bridge `username`, `clientkey`, `bridge/config.json`, or private network details. Keep local credentials out of Git.
