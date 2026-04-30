# System Architecture

This view explains what each part of the system actually does.

## Responsibilities

| Component | Responsibility | Does not do |
| --- | --- | --- |
| Unreal Engine | Generates lighting/DMX values and outputs Art-Net | Does not call the Hue API |
| Python Bridge | Receives Art-Net, parses ArtDMX, maps DMX to RGB, streams Hue updates | Does not generate lighting content |
| Router / LAN | Moves network packets between the laptop and Hue Bridge | Does not translate protocols |
| Hue Bridge | Receives Hue Entertainment stream data and controls Hue lights | Does not receive DMX or Art-Net directly |
| Hue Lights | Display brightness/color output | Do not parse Art-Net |

## Translation Boundary

The Python bridge is the protocol translation boundary:

```text
DMX / Art-Net side
  Unreal Engine -> Python Bridge

Hue side
  Python Bridge -> Hue Entertainment API -> Hue Bridge -> Hue Lights
```

This separation keeps Unreal Engine focused on lighting authoring and keeps Hue-specific networking in one small bridge script.
