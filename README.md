Getting started with Bluetooth Low Energy (BLE) on iOS

This is a small project to guide you on how to:
- Use iPhone as a beacon, to broadcast value to other devices
- Discover, connect to, and retreive data from BLE devices

When using iPhone as beacon, there are two modes
- Active: beacon will keep broadcasting new value to subscribed devices
- Passive: beacon will return a new value when there is read request from other device

When scanning for devices, there are two modes using when connecting
- Subscribe: this device will subscribe to beacon, then notify every time value is updated inside beacon
- Read request: this device will connect to beacon and keep sending read request to get value inside beacon