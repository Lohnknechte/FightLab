# Audio structure

- `audio/sfx/footsteps/`: step sounds for movement
- `audio/sfx/player/`: player action sounds like jump, land, hit
- `audio/sfx/environment/`: world interaction sounds like box break
- `audio/sfx/weapons/shotgun/`: shotgun fire and pump layers
- `audio/music/`: background music
- `audio/ui/`: menu and interface sounds
- `audio/ambience/`: ambient layer sounds

The game now uses the `AudioManager` autoload singleton and creates `SFX`, `Music`, `UI`, and `Ambience` buses on startup.
Keep new sounds grouped by system so the project stays easy to scale like a real game audio setup.
