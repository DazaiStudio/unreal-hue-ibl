@echo off
cd /d "%~dp0"

python -X utf8 hue_artnet_bridge.py --config config.json

pause
