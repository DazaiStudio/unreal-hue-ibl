# Hue Bridge Setup

The bridge uses the Philips Hue Entertainment Streaming API, not regular scene updates.

The Hue Bridge does not receive DMX or Art-Net directly. The Python bridge translates Unreal Engine Art-Net output into Hue Entertainment stream data before sending anything to the Hue Bridge.

Required Hue-side setup:

1. A Philips Hue Bridge on the same local network.
2. A configured Hue Entertainment Area.
3. Hue API credentials:

```text
ip_address
identification
rid
username
clientkey
```

Copy `bridge/config.example.json` to `bridge/config.json`, then fill in the local values. Keep `bridge/config.json` private.

Use the Hue Bridge's local network IP for `hue.ip_address`, for example:

```json
{
  "hue": {
    "ip_address": "192.168.1.100"
  }
}
```

Treat that value as local setup information. It can be shown as an example, but the real address should live in `bridge/config.json`.

## Standard Hue Bridge vs Hue Bridge Pro

The communication path remains the same:

```text
Unreal Engine -> Art-Net -> Python Bridge -> Hue Entertainment API -> Hue Bridge -> Lights
```

Latency depends on the Art-Net sender, Python receiver loop, Hue Entertainment stream, Hue Bridge processing, and the lights themselves.
