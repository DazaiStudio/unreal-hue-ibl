# DMX Mapping

The default bridge maps each Hue light fixture to four DMX channels:

| Channel offset | Meaning |
| --- | --- |
| `+0` | Dimmer |
| `+1` | Red |
| `+2` | Green |
| `+3` | Blue |

For fixture `1`, the channel layout is:

```text
Channel 1: Dimmer
Channel 2: Red
Channel 3: Green
Channel 4: Blue
```

For fixture `2`, the layout continues:

```text
Channel 5: Dimmer
Channel 6: Red
Channel 7: Green
Channel 8: Blue
```

With the default `fixture_count` of `11`, the bridge reads `44` DMX channels.
