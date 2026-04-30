# Troubleshooting

## No Art-Net Input

Check that Unreal Engine is sending Art-Net to the machine running the bridge:

```text
Destination IP: 127.0.0.1
Port: 6454
Universe: 1
```

Use `127.0.0.1` only when Unreal and the Python bridge run on the same machine.

## Port Already In Use

The Python bridge binds to UDP port `6454`:

```python
sock.bind(("0.0.0.0", 6454))
```

Only one process can receive the same Art-Net port on the same interface. Close other Art-Net receivers before starting the bridge.

## Lights Do Not Match DMX

Confirm the fixture count and DMX channel layout:

```text
Fixture 1: Dimmer, Red, Green, Blue
Fixture 2: Dimmer, Red, Green, Blue
...
```

With `fixture_count: 11`, Unreal should output at least `44` DMX channels.

## Do Not Commit Hue Credentials

Keep these values out of Git:

```text
username
clientkey
bridge/config.json
```
