# GANGSTER: NEW YORK — Graphics Rebuild 0.6.0

Offline-first Godot 4.5.1 Android open-world prototype.

## Graphics rebuild

This milestone changes the rendering baseline from GL Compatibility to Godot's Mobile renderer and enables 2× 3D MSAA with a 2048 directional shadow map. The Android CI job fetches and imports CC0 Kenney City Kit Suburban and City Kit Roads GLB assets before running Godot's import pass.

The streamed world now attempts to instantiate imported building models and street-light props, with a procedural fallback if an asset is unavailable. Buildings receive simple static collision volumes. Asset downloads are pinned to a source repository commit for reproducibility.

## Asset sources and licences

See [ASSET_SOURCES.md](ASSET_SOURCES.md). Kenney City Kit Suburban and City Kit Roads are CC0 1.0 assets. The CI workflow fetches the selected source directories from the public asset repository before import/export; the binary source assets are therefore packaged into the APK even though they are not duplicated in this repository.

## Existing gameplay systems

- New York City, San Francisco, London, Edinburgh, Kent, Gloucester and Sussex region destinations
- Streamed regional chunks, airports, taxi travel and generated shop interiors
- Wanted levels, police dispatch radio messages and basic pursuing officers
- Original New York Mission 01
- Mobile joystick, camera drag, aim, fire, jump, sprint and action controls

## Honest limitations

This is a visual foundation milestone, not a finished GTA/Payback 2 equivalent. The imported Kenney city assets are optimized stylized models, not photoreal scans. The cities remain compact procedural regions with fast-travel connections, not one continuous real-world-scale map. This branch still needs device testing, better character and vehicle models, PBR surface materials, traffic/pedestrian systems, richer interiors, animation, audio, mission content and extensive profiling.

The Mobile renderer may require Vulkan-capable Android hardware. Device compatibility and frame rate must be checked on target phones before merging this branch.

## Build

GitHub Actions downloads the CC0 assets, imports the Godot project, validates scripts, exports an ARM64 debug APK and uploads it as a workflow artifact.

Android package: `com.nexusdev.gny`
