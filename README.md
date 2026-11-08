# GANGSTER: NEW YORK — Godot Edition

An offline-first 3D Android action-game prototype built with Godot 4.5.1.

## Current build: 0.2.0 (version code 2)

This build includes the expanded New York street layout and first smartphone interface. It is still an early prototype; these changes do not yet constitute a full Payback 2-level graphics or gameplay upgrade.

## Playable milestone: Mission 01 — The Stolen Package
- Third-person 3D character movement and camera
- Procedurally assembled city street, warehouse and safehouse
- Three hostile guards with chase and melee AI
- Hitscan combat
- Mission progression: reach warehouse, defeat guards, collect package, escape to safehouse
- On-screen Android movement and action controls
- No network permission; designed for offline play

## Controls
Desktop: WASD or arrow keys to move, F to fire, E or Space to interact.
Android: on-screen direction buttons, FIRE and ACTION.

## Build
Open project.godot in Godot 4.5.1 or later. Android export requires matching Godot export templates and Android SDK. GitHub Actions exports build/GangsterNewYork.apk and uploads it as an artifact.

Android package: com.nexusdev.gny

This is an early playable foundation, not a finished commercial open-world game. Vehicle driving, animations, police pursuit, audio, larger city areas and more missions are planned next.
