# FightLab

## Import and develop

1. Clone the repository
2. Open the folder "FightLab" from Godot

### Pull Request Standard

Before submitting your changes, ensure your PR adheres to these three subjects:
1. Atomicity: Keep PRs minimal
    - Good: Add hitbox detection for light attacks.
    - Bad: Fixed hitboxes, updated UI textures, and refactored player movement.
2. Stability: Keep PRs functional
    - Good: No console errors, correct code and file formatting (https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html)
    - Bad: Errors, program not executable, spaghetti code
3. Clarity: Keep PRs comprehensible
    - Good commit message:
    ```
    What does this PR do?
    Adds a small Hitbox to the character.

    Why is this change necessary?
    Concerns Issue #4

    How was this tested?
    Tested manually in Godot.
    ```
    - Bad commit message:
    ```
    I finally got that one thing working. Also, I changed some colors because the old ones were bothering me. I might have broken the physics engine, but I’ll fix it in the next PR. Don't look too closely at player.gd, it's a mess lol.
    ```



## Filesystem Structure (WIP)

The project is structured into the following folders. 

* assets/: Raw, external media files (PNGs, WAVs, TTFs)
  * audio/
  * fonts/
  * sprites/
  * sfx/
* resources/: Data-only `.tres` files for stats, item definitions, or saved configurations
* src/: The primary root for all game logic and Godot scenes
  * actors/: Self-contained scenes for characters (Player, Enemies)
  * autoload/: Global singletons (GameManager, GlobalAudio, SaveSystem)
  * common/: Shared utilities, base classes, global shaders, and UI themes
  * levels/: Playable map scenes and level-specific logic
  * objects/: Environmental interactables (Platforms, Hazards, Pickups)
  * ui/: Interface elements (HUD, Menus, Pause Screens)
  * weapons/: Shooting logic, projectiles, and weapon-specific scenes
  * components: Components used across different entities or scenes (Hitbox, Hurtbox, Velocity, Health, ... ).
  * states/: Contains the State Machine logic and individual state scripts (e.g., Idle, Attack, Hitstun, ... ).