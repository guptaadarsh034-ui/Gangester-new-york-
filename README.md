A lightweight 2D open-world game set in New York City, built in Java for Android — inspired by classic top-down GTA-style gameplay. Fan project, not affiliated with Rockstar Games.
# Gangster New York

A lightweight 2D top-down open-world game built for Android, set in a
stylized New York City. Inspired by classic top-down GTA-style gameplay,
built from scratch in plain Java with no game engine — optimized to run
on low-end devices (Android 4.4+, 512MB RAM).

> This is a fan-made, non-commercial project inspired by the GTA series.
> Not affiliated with or endorsed by Rockstar Games or Take-Two Interactive.

## Features
- Tile-based NYC map (Financial District, Midtown, Central Park)
- On-screen joystick movement with building/water collision
- In-game phone system with mission tracking
- Redeem codes menu (speed boost, god mode toggle)
- Mission system with location-based objectives

## Requirements
- minSdkVersion 19 (Android 4.4 KitKat and up)
- Built with Gradle, no external dependencies

## Building
This project builds via GitHub Actions — push to this repo and the
workflow compiles the APK automatically. Built APKs are available under
the Actions tab after each run.

To build locally instead:
## Status
Work in progress — personal/hobby project.

## License
Personal project — all original code here is provided as-is for
educational and personal use


## 3D OpenGL engine

A separate Java / LibGDX / OpenGL ES 3.0 engine prototype is available in [engine/](engine/). It adds a third-person 3D New York starter district, original low-poly OBJ models, a basic drivable sedan and Android touch controls. See [engine/README.md](engine/README.md). GitHub Actions workflow: [Build GNY OpenGL Android APK](.github/workflows/build-opengl-android.yml).

**Status note:** the 3D track is an early prototype. The seven-region connected world, full traffic and pedestrian AI, advanced missions and animation are not yet complete.
