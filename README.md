# unreal-hue-ibl

`unreal-hue-ibl` is an Unreal Engine to Philips Hue lighting bridge reference. It shows how Unreal Engine DMX output can drive Hue lights through a small Python translator.

## Quick Start For New Users

This is the shortest path from a fresh repo download to a running Hue bridge.

### 1. Prepare The Hue System

1. Connect the computer and Philips Hue Bridge to the same router / local network.
2. Open the Philips Hue app.
3. Create or confirm a Hue Entertainment Area.
4. Keep the physical Hue Bridge nearby because one setup step requires pressing its button.

### 2. Download This Repo And The UE Demo Project

Download or clone this repository, then open the folder:

```text
unreal-hue-ibl/bridge/
```

The Unreal Engine demo project is distributed separately because Unreal assets are too large for this lightweight bridge repo:

```text
https://drive.google.com/drive/folders/1Sp-gb3ZxKqR5yZtDikvC2sumbx9yYsh3?usp=drive_link
```

On Windows, the file to run is:

```text
run_hue_artnet_bridge.bat
```

### 3. Find The Hue Bridge IP

The Hue Bridge IP is assigned by the router and can change. `192.168.1.100` is only an example.

Use one of these methods:

```powershell
Invoke-RestMethod https://discovery.meethue.com/
```

Or check:

```text
Hue app -> Bridge settings
Router admin page -> Connected devices / DHCP clients
```

The value you need looks like:

```text
192.168.1.xxx
```

### 4. Generate `username` And `clientkey`

Press the physical Hue Bridge button, then run this within about 30 seconds from a computer on the same network:

```powershell
curl.exe -k -X POST "https://<bridge-ip>/api" `
  -H "Content-Type: application/json" `
  -d '{"devicetype":"unreal-hue-ibl#laptop","generateclientkey":true}'
```

The response gives you:

```text
username
clientkey
```

These values are generated from the user's own Hue Bridge. They are not downloaded from this GitHub repo and should not be shared publicly.

### 5. Get `identification`

Use the `username` from the previous step:

```powershell
curl.exe -k "https://<bridge-ip>/api/<username>/config"
```

Use:

```text
bridgeid -> Hue Bridge identification
```

### 6. Get The Entertainment Area `rid`

Run:

```powershell
curl.exe -k "https://<bridge-ip>/clip/v2/resource/entertainment_configuration" `
  -H "hue-application-key: <username>"
```

Use the selected Entertainment Area's top-level `id` as:

```text
Hue Entertainment Area rid
```

### 7. Run The Windows Launcher

Double-click:

```text
bridge/run_hue_artnet_bridge.bat
```

The launcher will install or find Python, create a local `.venv`, install dependencies, create `bridge/config.json`, and ask for setup values.

When prompted, enter:

| Prompt | What To Enter |
| --- | --- |
| Hue Bridge IP address | Current Hue Bridge IP, for example `192.168.1.112` |
| Hue API username | `username` from step 4 |
| Hue Entertainment clientkey | `clientkey` from step 4 |
| Hue Entertainment Area rid | Entertainment Area `id` from step 6 |
| Hue Bridge identification | `bridgeid` from step 5 |
| Art-Net listen host | `0.0.0.0` |
| Art-Net listen port | `6454` |
| Art-Net universe | `1` |
| Hue fixture/light count | Number of Hue lights in the Entertainment Area |
| DMX channels per fixture | `4` |

### 8. Set Unreal Engine Art-Net Output

If Unreal Engine and the Python bridge are running on the same computer:

```text
Destination IP: 127.0.0.1
Port: 6454
Universe: 1
Fixture layout: Dimmer, Red, Green, Blue
```

If Unreal Engine is on a different computer, set the destination IP to the computer running `run_hue_artnet_bridge.bat`.

### Troubleshooting Start-Up

If the launcher times out while connecting to the Hue Bridge, the Hue Bridge IP is probably wrong or the computer cannot reach the bridge on the local network.

Check:

```powershell
ping <bridge-ip>
Test-NetConnection <bridge-ip> -Port 443
```

## Manual Run

The Windows launcher is recommended for most users. Use this manual path only if you already have Python installed and want to run the bridge from a terminal.

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

Set the Hue Bridge's local network IP in `bridge/config.json` as `hue.ip_address`. Use an example such as `192.168.1.100` in docs, not your personal bridge IP. For long-term setups, reserve a fixed DHCP address for the Hue Bridge in your router so this value does not keep changing.

## Docs

| Document | Purpose |
| --- | --- |
| [Hue Bridge Setup](docs/hue-bridge-setup.md) | Hue Entertainment setup notes |
| [Unreal Setup](docs/unreal-setup.md) | Unreal Engine DMX / Art-Net setup notes |
| [DMX Mapping](docs/dmx-mapping.md) | DMX channel mapping |
| [Troubleshooting](docs/troubleshooting.md) | Common setup issues |

## Repository Layout

```text
bridge/             Python Art-Net to Hue bridge
docs/               Setup and troubleshooting notes
```

## Security

Do not commit your real Hue Bridge `username`, `clientkey`, `bridge/config.json`, or private network details. Keep local credentials out of Git.
