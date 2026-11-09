# GANGSTER: NEW YORK — Godot Edition

An offline-first 3D Android action-game prototype built with Godot 4.5.1.

## Current build: 0.4.0 (version code 4)

This milestone adds a touch-first gameplay layer, analog movement joystick, right-side camera drag, hold-to-fire and aim, sprint and jump buttons, a main menu, and a staged city/game loading screen. The player now has camera-relative movement, sprinting, jumping, aiming zoom and a basic procedural walk/run animation. The procedural graphics pass adds vehicle glazing, wheel hubs, player gear and more street furniture.

The renderer remains Godot's mobile-compatible GL Compatibility renderer. This project currently uses procedural geometry rather than licensed, production-grade character/car/environment asset packs, so it should be treated as a stronger playable prototype—not a claim of Payback 2 visual parity.

## Playable milestone: Mission 01 — The Stolen Package
- Third-person character movement and touch camera control
- Analog mobile joystick, fire, aim, action, jump and sprint controls
- Main menu and in-game loading screen
- Procedurally assembled New York-style district, warehouse and safehouse
- Three hostile guards with chase and melee AI
- Hitscan combat
- Mission progression: reach warehouse, defeat guards, collect package, escape to safehouse
- Drivable car
- Smartphone/GPS panel
- No network permission; designed for offline play

## Controls
Desktop: WASD/arrow keys to move, F to fire, Q to aim, Shift to sprint, Space to jump, E to interact.
Android: left analog joystick to move, drag the right side to rotate the camera, and use FIRE, AIM, ACTION, JUMP and SPRINT.

## Build
Open project.godot in Godot 4.5.1 or later. Android export requires matching Godot export templates and Android SDK. GitHub Actions exports build/GangsterNewYork.apk and uploads it as an artifact.

Android package: com.nexusdev.gny

This remains an early playable foundation. Production-quality art, full animation rigs, traffic/pedestrian systems, police pursuit, audio, more interiors and additional missions still require further work and testing on target phones.
