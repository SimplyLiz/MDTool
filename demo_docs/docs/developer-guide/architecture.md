# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a procedurally generated 2D platformer inspired by N Game, built with Godot 4.4+. The game features a modern **"Neon Synthesis"** visual style - a cyberpunk-minimalist fusion that reimagines N Game's aesthetic with holographic effects, energy fields, and dynamic lighting. 100% procedural graphics with no external assets, using advanced GDScript drawing techniques for all visual generation.
dfdf
## Key Development Commands

### Running the Game
- Open project in Godot 4.4+
- Run main scene: `Main.tscn` (automatically set as main scene)
- **Main Menu Navigation**: Use WASD/Arrow keys + Enter to navigate
- **Level Select**: Choose from classic levels or procedural generation
- **Options Menu**: Configure graphics, audio, and control settings

### Project Requirements
- Godot 4.4+ (Mobile/Forward+ renderer)
- No external dependencies required
- Graphics primarily procedural with selective audio assets
- JSON-based level system with comprehensive format specification

## Project Structure

### Organized Scene Architecture
```
📁 tynk's-journey/
├── Main.tscn                    # Root main scene (entry point)
├── 📁 scenes/
│   ├── 📁 menus/               # Menu system scenes
│   │   ├── MainMenu.tscn       # Main menu with Neon Synthesis UI
│   │   ├── LevelSelect.tscn    # Level selection with previews
│   │   ├── OptionsMenu.tscn    # Settings and configuration
│   │   └── ProceduralGenerator.tscn # Procedural level generator UI
│   └── 📁 game/               # Gameplay scenes  
│       ├── Demo.tscn          # Interactive component demo
│       ├── MainGame.tscn      # Legacy main game scene
│       └── NGameMain.tscn     # Current main game scene
├── 📁 scripts/                # All GDScript files
├── 📁 assets/                 # Asset folders with sounds and fonts
│   ├── 📁 sounds/             # Audio files (synthwave_loop.ogg)
│   ├── 📁 fonts/              # Font resources
│   └── 📁 textures/           # Texture assets
├── 📁 level_data/             # JSON level definitions
├── 📁 docs/                   # Documentation files
├── 📁 shaders/                # Custom shader files
├── 📁 effects/                # Visual effect scenes
└── 📁 autoload/               # Global singleton scripts
```

## Architecture Overview

### Core System Design
The project follows a modular, component-based architecture where each game element is a self-contained procedural generator:

1. **Utility Layer**: `ProceduralUtils.gd` provides shared drawing functions, texture creation, and visual effects
2. **Level Generation**: `NGameLevelGenerator.gd` creates N Game-style platformer levels with collision detection
3. **Entity System**: Individual procedural components for player, enemies, and interactive objects
4. **Scene Management**: `MainGame.gd` orchestrates all components and handles entity spawning/management

### Key Components

**ProceduralUtils.gd** - Advanced visual effects utility class providing:
- **Neon Synthesis color palette** with synthwave/cyberpunk colors
- **Procedural circuit board patterns** and energy effects
- **Holographic shimmer effects** with RGB color shifting
- **Energy beam/particle systems** for dynamic visual feedback
- **Scan line effects** for retro-futuristic aesthetics
- **Procedural noise patterns** for surface textures

**NGameLevelGenerator.gd** - Modern level generation with Neon Synthesis aesthetics:
- Enhanced tile system (TileType enum: EMPTY, PLATFORM, SLOPE_UP, SLOPE_DOWN, SPIKE, GOAL, GOLD)
- **Animated circuit board backgrounds** with energy conduits
- **Neon platform rendering** with edge lighting and gradient effects
- **Holographic goals** with particle effects and scanning beams
- **Energy spikes** with warning pulse effects
- **Dynamic scan lines** and ambient lighting

**Menu System** - Modern Neon Synthesis interface:
- **MainMenu.gd**: Cyberpunk main menu with holographic buttons and animated circuits
- **LevelSelect.gd**: Level selection with miniature level previews and difficulty indicators
- **OptionsMenu.gd**: Comprehensive settings with graphics/audio/control customization
- **ProceduralGeneratorUI.gd**: Interactive procedural level generator with real-time preview
- **GameManager.gd**: Global autoload singleton for save data, settings, and scene transitions

**Advanced Systems**:
- **NGameManager.gd**: Core game state management and player lifecycle
- **NGamePlayer.gd**: Enhanced player controller with authentic N Game physics
- **SynthwavePostProcessor.gd**: Global post-processing effects system
- **ProceduralLevelGenerator.gd**: JSON-based level loading and generation system

**MainGame.gd** - Main scene controller:
- Entity container management (enemies_container, bombs_container)
- Random spawning system with platform-aware positioning
- Runtime entity management (add/clear functions)
- Enemy targeting and proximity trigger system

### Neon Synthesis Entity Pattern
All game entities follow the modern cybernetic aesthetic:
- **Multi-layered energy effects** with core, field, and glow components
- **Holographic color shifting** for dynamic visual interest
- **Energy particle systems** and animated trails
- **Procedural scan lines** and circuit patterns
- **State-based visual intensity** (alert modes, energy levels)
- **Real-time animation timing** synchronized across all effects

### Authentic N Game AI System (Integrated)
The AI system is now fully integrated with the game manager and active in gameplay:

- **NGameAI.gd**: Core AI behavior system with finite state machines for authentic enemy behaviors
  - TurretAI: Predictable targeting with consistent firing patterns
  - DroneAI: Patrol patterns with player detection and pursuit
  - MineAI: Proximity triggering with arm/trigger/explosion states
  - DeathballAI: Intentionally chaotic movement for unpredictable challenge

- **NGameAIManager.gd**: Global autoload singleton coordinating all enemy AI
  - Automatic enemy registration during spawning
  - Centralized player detection and state updates
  - Authentic N Game coordination (turrets can hit other enemies)
  - Difficulty scaling and performance tracking

- **NGameManager.gd Integration**: 
  - Enemies automatically register with AI manager on spawn
  - AI manager handles all targeting and proximity detection
  - Clean unregistration during level transitions
  - AI statistics reset between levels

- **Entity AI Integration**:
  - **ProceduralTurret.gd**: Uses TurretAI for predictable firing patterns (extends Node2D)
  - **ProceduralDrone.gd**: Uses DroneAI for patrol and chase behaviors (extends Node2D)
  - **ProceduralMine.gd**: Uses MineAI for proximity detection and timing (extends Node2D)
  - **ProceduralBomb.gd**: Physics-based explosive entities with particle effects (extends Node2D)
  - **ProceduralBackground.gd**: Dynamic animated background system (extends Node2D)
  - All entities automatically register with AI manager and update via centralized brain

## Development Workflow

### Project Setup
1. **Open in Godot 4.4+**: Load project.godot file
2. **Main Scene**: Set Main.tscn as main scene (auto-configured)
3. **Autoloads**: GameManager, NGameAIManager, SynthwavePostProcessor configured automatically
4. **Build Settings**: Mobile renderer configured for optimal performance

### Development Commands
```bash
# Test specific level (in Godot editor)
# Run Main.tscn -> Main Menu -> Level Select -> Choose level

# Test procedural generation
# Run Main.tscn -> Main Menu -> "Generate Level" option

# Test component isolation
# Run scenes/game/Demo.tscn for isolated component testing

# Validate level JSON files
# Use ProceduralGenerator scene for JSON validation and preview
```

### Adding New Entities
1. Create new script extending appropriate Godot base class (`Node2D`, `CharacterBody2D`, etc.)
2. Add customization exports (colors, scale, behavior settings) for editor integration
3. Implement `_draw()` method using ProceduralUtils functions for consistent visual style
4. Register with NGameAIManager if AI behavior needed
5. Add spawning logic to MainGame.gd entity containers if needed
6. Test in Demo.tscn for isolated component validation

### Creating New Levels
1. **JSON Method** (Recommended):
   - Copy existing level from `level_data/` as template
   - Modify using schema in `docs/level-json-format.md`
   - Test load via LevelSelect menu
   
2. **Procedural Method**:
   - Use ProceduralGenerator scene for interactive design
   - Adjust parameters and preview in real-time
   - Export to JSON when satisfied with result

### Level Design

#### JSON Level System
- Create levels using JSON format in `level_data/` directory
- Comprehensive schema supports platforms, hazards, collectibles, and visual effects
- See `docs/level-json-format.md` for complete specification
- Examples: `level_01.json` through `level_05.json` demonstrate progressive difficulty

#### Procedural Generation
- Use `ProceduralGeneratorUI.gd` for interactive level creation
- Real-time preview and parameter adjustment
- Export generated levels to JSON format
- Seed-based reproducible generation

#### Level Generator API
- Load levels: `NGameLevelGenerator.load_level_from_file(path)`
- Grid-based coordinate system (grid_width x grid_height)
- Collision detection: `is_solid_at_position()`, `is_spike_at_position()`, `is_goal_at_position()`
- Spawn positioning: `get_random_spawn_position()` for entity placement

### Neon Synthesis Visual System
- **Synthwave color palette** with electric blues, plasma purples, and energy greens
- **Holographic effects** using `get_holographic_color()` for RGB shifting
- **Energy particle systems** with `draw_energy_particles()` for ambient effects
- **Dynamic lighting** through `draw_energy_beam()` and glow effects
- **Procedural surface patterns** using noise generation and circuit designs
- **State-responsive visuals** that change based on gameplay conditions
- **Animation synchronization** with unified timing systems across all entities

## Control Scheme

### Gameplay Controls
- **A/D or Arrow Keys**: Move left/right
- **W/Space/Up Arrow**: Jump
- **ESC**: Pause menu

### Demo Scene Controls (Testing)
- **Mouse**: Click UI buttons and interactive elements
- **1-5**: Spawn different entity types
- **C**: Clear all spawned entities
- **R**: Regenerate level and entities

### Menu Navigation
- **WASD/Arrow Keys**: Navigate menu options
- **Enter/Space**: Select menu item
- **ESC**: Return to previous menu

## Advanced Features

### Shader System
Custom shaders for enhanced visual effects:
- **neon_object.gdshader**: Neon glow effects for game objects
- **retro_synthwave.gdshader**: Synthwave aesthetic backgrounds
- **crt_scanline.gdshader**: CRT monitor simulation effects
- **bomb_glow.gdshader**: Specialized explosion and energy effects

### Audio Integration
- **synthwave_loop.ogg**: Ambient synthwave soundtrack
- Dynamic audio processing via SynthwavePostProcessor
- Audio-visual synchronization for enhanced immersion

### Performance Systems
- **Autoload Architecture**: GameManager, NGameAIManager, SynthwavePostProcessor
- **Entity Pooling**: Efficient spawning and cleanup via container management
- **Modular Effects**: Selective visual effect enabling for performance scaling

## Troubleshooting

### Common Issues

#### Scene Loading Problems
- **Main scene not set**: Ensure `Main.tscn` is set as main scene in Project Settings
- **Missing autoloads**: Verify GameManager, NGameAIManager, SynthwavePostProcessor in autoload list
- **Scene path errors**: Check scene references use `res://` prefixed paths

#### Level Loading Errors
- **JSON validation fails**: Use docs/level-json-format.md to verify schema compliance
- **Grid coordinate errors**: Ensure spawn positions within grid bounds
- **Missing required fields**: Check metadata and spawns sections are complete

#### Performance Issues
- **Frame drops with effects**: Disable expensive shaders in GameManager settings
- **Too many entities**: Limit simultaneous spawned entities in MainGame containers
- **Shader compilation**: Verify Godot 4.4+ compatibility and mobile renderer settings

#### AI System Problems
- **Entities not responding**: Check NGameAIManager registration and player reference
- **Inconsistent behavior**: Verify AI settings enable deterministic patterns
- **Missing targeting**: Ensure player node properly set in AI manager

## Code Conventions
- Use `class_name` declarations for reusable utility classes (ProceduralUtils, ProceduralLevelGenerator)
- Export variables for runtime customization and editor integration
- Implement `queue_redraw()` when visual state changes
- Use static functions in ProceduralUtils for shared functionality
- Follow Godot naming conventions (snake_case for variables/functions)
- Document complex systems with comprehensive inline comments
- Maintain singleton pattern for global managers (autoload scripts)