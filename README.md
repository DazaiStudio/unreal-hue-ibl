# hue-dmx-IBL

`hue-dmx-IBL` is an architecture reference and bridge template for driving Philips Hue lights from Unreal Engine using DMX over Art-Net.

![Hue Image-Based Lighting Workflow](docs/images/communication-workflow.png)

## Communication Workflow

```text
Unreal Engine DMX / Art-Net Output
-> Art-Net UDP 127.0.0.1:6454
-> Python Hue Art-Net Bridge
-> Philips Hue Entertainment Streaming API
-> Hue Bridge
-> Philips Hue Lights
```

The repository is intentionally focused on the workflow and reproducible bridge setup. The full Unreal Engine project/template can be distributed separately as a release or external download link instead of committing the entire UE project into Git.

## Repository Layout

```text
bridge/
  hue_artnet_bridge.py       Public bridge script without private credentials
  config.example.json        Example Hue/Art-Net configuration
  requirements.txt

docs/
  communication-workflow.md  Mermaid workflow and signal path notes
  dmx-mapping.md             DMX channel layout
  hue-bridge-setup.md        Hue Entertainment setup notes
  troubleshooting.md
  unreal-setup.md
  images/

unreal-template/
  README.md                  Template distribution notes and download link slot
```

## Default Signal Settings

| Layer | Setting |
| --- | --- |
| Protocol | Art-Net |
| UDP port | `6454` |
| Unreal destination IP | `127.0.0.1` when bridge runs on the same machine |
| Universe | `1` |
| Fixture layout | `Dimmer, Red, Green, Blue` |
| Default fixture count | `11` |

## Quick Start

1. Configure a Hue Entertainment Area in the Philips Hue app.
2. Copy `bridge/config.example.json` to `bridge/config.json`.
3. Fill in your Hue Bridge `ip_address`, `identification`, `rid`, `username`, and `clientkey`.
4. Install Python dependencies:

```bash
pip install -r bridge/requirements.txt
```

5. Start the bridge:

```bash
python bridge/hue_artnet_bridge.py --config bridge/config.json
```

6. In Unreal Engine, output Art-Net to `127.0.0.1`, UDP port `6454`, universe `1`.

## Security Note

Do not commit your real Hue Bridge `username`, `clientkey`, local bridge config, or private network details. Use `config.example.json` for public documentation and keep `config.json` local.
