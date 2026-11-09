# GANGSTER: NEW YORK — Godot Edition

An offline-first 3D Android open-world action-game prototype built with Godot 4.5.1.

## Current development milestone: 0.5.0 (Android version code 5)

The world expansion adds seven streamed destinations:
- Major cities: New York City, San Francisco, London and Edinburgh
- Smaller regions: Kent, Gloucester and Sussex

The regional world manager streams a 3×3 area of city blocks around the player and unloads distant chunks. Regions are reached through the world map's airport flight service or long-distance taxi dispatch. Each region has a distinct procedural building palette and landmark blockout. New York's original story mission remains the starting area.

## Systems in this milestone
- Touch-first mobile controls: analog movement joystick, camera drag, fire, aim, jump, sprint and action
- Main menu and staged loading screen
- Procedural city blocks, streets, storefronts, airport terminals, taxi depots and police stations
- Enterable shop interiors with a counter and shelves (tap ACTION at a shop entrance to enter and ACTION again to leave)
- Taxi pickup and local district transfer
- Airport/flight travel between all seven regions
- Wanted level with five levels, police radio callouts, responding patrols, pursuit and damageable officers
- Original Mission 01: reach the warehouse, defeat guards, collect the package and escape
- Drivable starter car and smartphone/GPS panel
- Designed for offline play

## Controls
Desktop: WASD/arrow keys to move, F to fire, Q to aim, Shift to sprint, Space to jump, E to interact.
Android: left analog joystick to move, drag the right side to rotate the camera, and use FIRE, AIM, ACTION, JUMP and SPRINT.

## Technical scope and honest limitations
This is still a procedural prototype, not a finished GTA-scale game. The cities are stylised blockout districts, not full real-world street-accurate recreations. Travel currently uses airport/taxi fast-travel transitions; there are no continuous highways between all regions yet. Shop interiors are small generated rooms. Police pursuit is a basic prototype and still needs vehicle patrol AI, dispatch escalation, road navigation, traffic, pedestrians, emergency vehicles, economy, real shop inventories, audio and save/load. Production-grade art assets, character rigs, aircraft, cars and building interiors still need to be authored/imported and tested on Android devices.

The renderer uses Godot's mobile-compatible GL Compatibility renderer. It is tuned for mobile feasibility, not a claim of Payback 2 or GTA visual parity.

## Build
Open project.godot in Godot 4.5.1 or later. Android export requires matching Godot export templates and Android SDK. GitHub Actions exports build/GangsterNewYork.apk and uploads it as a workflow artifact.

Android package: com.nexusdev.gny
