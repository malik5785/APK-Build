# City Freedom — Makkah V11 RealMap: Godot 3.6 GLES2 compatibility kit

**Source:** the user-supplied `CityFreedom_Makkah_V11_RealMap_Kit(1).zip`.

## What is included
- Native Godot 3.6 project (`project.godot`, `main.tscn`, `game.gd`) targeting GLES2 for older Mali GPUs.
- The original V11 map dataset (`data/city.json`), textures and WAV assets, copied without modification.
- The original V11 Godot 4 scene, source, settings and notes under `original_v11_reference/`, preserved for further porting.
- GitHub Actions workflow that builds a debug-signed Android APK using Godot 3.6.3.

## Compatibility port scope
The Godot 3 scene currently implements real map roads and nearby building footprints, roofs, trees, Kaaba, simplified clock tower, basic player/car, driving, walking, simple road-following traffic, day/night lighting and camera modes. **This is a functional compatibility foundation, not the complete original V11 game.** The original V11 wardrobe, full UI, NPC systems, sounds, weather, city-wide streaming, collisions and full models are not yet ported. Audio/textures are retained but not yet wired into all gameplay systems. World geometry is currently built near the start position only.

## Build an APK
1. Upload the *contents of this folder* to a GitHub repository `main` branch.
2. Open **Actions → Build V11 GLES2 Android APK → Run workflow**.
3. After the workflow succeeds, download the `CityFreedom-Makkah-V11-GLES2-APK` artifact.

Alternatively, open this folder in Godot 3.6.3 and export using the Android preset after configuring Android SDK and signing.

## Important
The build workflow has **not been run for this kit**. Do not assume successful export or Xiaomi Mi Box runtime compatibility until checked. No APK is included in this ZIP.
