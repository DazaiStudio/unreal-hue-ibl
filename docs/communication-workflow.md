# Communication Workflow

This project connects Unreal Engine DMX output to Philips Hue Entertainment streaming through a small Python Art-Net receiver.

Important distinction: the Hue Bridge does **not** receive DMX or Art-Net directly. DMX/Art-Net exists only between Unreal Engine and the Python bridge. The Python bridge then sends Hue Entertainment API messages to the Hue Bridge.

```mermaid
flowchart LR
  subgraph LOCAL[Local Computer]
    UE[Unreal Engine<br/>DMX / Art-Net Output]
    ARTNET[Art-Net UDP<br/>127.0.0.1:6454<br/>Universe 1]
    PY[Python Bridge<br/>Parse ArtDMX<br/>Map Dimmer + RGB]
  end

  API[Hue Entertainment API<br/>Streaming RGB]
  BRIDGE[Hue Bridge]
  LIGHTS[Philips Hue Lights]

  UE --> ARTNET
  ARTNET -->|internal Art-Net bridge| PY
  PY -->|LAN / HTTPS + DTLS| API
  API --> BRIDGE
  BRIDGE -->|Hue light control| LIGHTS
```

## Data Path

1. Unreal Engine and the Python bridge run on the same local computer.
2. Unreal Engine sends DMX frames using Art-Net to `127.0.0.1:6454`.
3. The Python bridge listens for ArtDMX UDP packets on port `6454`.
4. The bridge filters packets by universe.
5. DMX channels are mapped into Hue RGB values.
6. RGB updates are sent through the Hue Entertainment Streaming API over the LAN.
7. The Hue Bridge receives Hue Entertainment stream data, not DMX.
8. The Hue Bridge forwards the real-time lighting state to Hue lights.

## Why `127.0.0.1`

Use `127.0.0.1` as the Unreal Art-Net destination when Unreal Engine and the Python bridge are running on the same computer. Use the receiver machine's LAN IP only when Unreal and the Python bridge run on different machines.

## Related Workflow Views

- [Hardware Workflow](hardware-workflow.md)
- [System Architecture](system-architecture.md)

## Public Overview Image

The rendered overview image lives at:

```text
docs/images/communication-workflow.png
```
