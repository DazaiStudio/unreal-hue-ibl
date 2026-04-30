# Unreal Engine Setup

Enable the Unreal Engine DMX plugins needed for Art-Net output:

```text
DMXEngine
DMXProtocol
DMXPixelMapping
DMXFixtures
DMXControlConsole
```

Use these Art-Net output settings when the Python bridge is running on the same machine:

```text
Protocol: Art-Net
Destination IP: 127.0.0.1
Port: 6454
Universe: 1
```

If the Python bridge runs on another machine, set the destination IP to that machine's LAN IP address.

The full Unreal Engine template project should be distributed as a GitHub Release asset or external download link when it contains large `.uasset` or `.umap` files.
