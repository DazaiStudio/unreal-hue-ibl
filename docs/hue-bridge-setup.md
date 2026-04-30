# Hue Bridge Setup

The bridge uses the Philips Hue Entertainment Streaming API, not regular scene updates.

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

## Standard Hue Bridge vs Hue Bridge Pro

The communication path remains the same:

```text
Unreal Engine -> Art-Net -> Python Bridge -> Hue Entertainment API -> Hue Bridge -> Lights
```

Latency depends on the Art-Net sender, Python receiver loop, Hue Entertainment stream, Hue Bridge processing, and the lights themselves.
