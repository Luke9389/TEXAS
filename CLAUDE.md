# Claude Code Guidelines for TEXAS Game Project

## Scene File (.tscn) Rules
- **DO NOT EDIT .tscn files directly** - These are binary/text hybrid files that can become corrupted
- If code changes require scene modifications (like attaching scripts, changing node types, adding nodes, etc.), **ASK THE USER** to make those changes in the Godot editor instead
- Only create new .gd script files and let the user attach them manually
- **Allow the engine to create and manage uid files (and tscn files)**

## When to Ask for Manual Changes
Ask the user to handle these tasks in the Godot editor:
- Attaching scripts to nodes
- Changing node types (e.g. Node2D to Control)
- Adding new nodes to scenes
- Modifying scene structure
- Setting export variables in the inspector
- Adding resources or textures

## GDScript Style Guidelines
- **class_name comes BEFORE extends** - Always put `class_name` on the first line, then `extends` on the second line
- Follow this order: `class_name` → `extends` → `@export` variables → other variables → functions

## What I Can Do
- Create and edit .gd script files
- Write new standalone scripts
- Modify existing GDScript code
- Suggest scene structure changes
- Debug code logic

## Communication Style
When scene changes are needed, say something like:
"Please attach this script to the [NodeName] node in the Godot editor"
or
"In the Godot editor, please change the root node type from X to Y"

This prevents corruption and maintains clean scene files.

# Architecture: Call Down, Signal Up

Following Godot's "Call Down, Signal Up" principle:

## Main Scene Coordination
**Main.gd** acts as the central coordinator:
- **Calls Down**: Direct method calls to managers for state changes
- **Signals Up**: Listens to UI signals for user requests
- **Data Flow**: Converts between node references and Resource data

```gdscript
# Example flow:
# 1. UI signals up: vote_requested
# 2. Main calls down: voting_manager.start_voting(districts, pips)
# 3. Manager emits progress: SignalBus.voting_started
# 4. UI reacts: _on_voting_started() updates button state
```

## SignalBus: Minimal Event Broadcasting
**Purpose**: Simple event broadcasting for reactive UI updates
**NOT for**: Complex coordination or business logic
**Signals**:
- Level generation: `regenerate_map_requested`, `set_generation_strategy_requested`
- Voting progress: `vote_requested`, `voting_started`
- District changes: `districts_modified(districts: Array[DistrictData])`

## UI Classes: Pure Reactive Subscribers
- **DistrictCounterUI**: Emits `vote_requested` up, subscribes to `districts_modified`
- **HouseSeatsUI**: Pure SignalBus subscriber for seat updates
- **DevToolsUI**: Emits requests up via SignalBus, owns its logic

## Manager Classes: Business Logic Only
- **VotingManager**: Handles voting simulation, emits progress via SignalBus
- **SeatManager**: Manages seat assignments, reactive to district changes
- **GeometryManager**: Pure static functions for polygon operations


## Current Signal Flow Design

### "Call Down, Signal Up" Pattern
```
UI Layer (Signals Up):
  DistrictCounterUI.vote_requested → Main
  DevToolsUI.regenerate_map_requested → Main (via SignalBus)

Coordination Layer (Main.gd):
  Receives UI signals
  Calls down to managers
  Converts node data ↔ Resource data

Business Logic Layer (Managers):
  VotingManager.start_voting(districts, pips)
  SeatManager.assign_seats(districts)
  GeometryManager.clip_polygon() [static]

Reactive UI Layer (SignalBus subscribers):
  SignalBus.districts_modified → DistrictCounterUI
  SignalBus.voting_started → DistrictCounterUI
  SignalBus.seat_assignments_updated → HouseSeatsUI
```


### Benefits of This Architecture
- **Testable**: Each manager class is pure business logic
- **Modular**: UI components are independent subscribers
- **Predictable**: Clear data flow from UI → Main → Managers → SignalBus → UI
- **Maintainable**: No circular dependencies or complex signal webs

## Implementation Strategy
- **Signal-first approach**: All new classes communicate via signals, no direct dependencies
- **Type-safe data structures**: Create Resource classes for all data shapes (DistrictData, PipData, etc.)
- **Pure functions**: Utility classes take data in, return data out (no side effects)
- **Data-driven**: Pass serializable Resource objects, never node references
- **Test isolation**: Each manager class should be unit testable in isolation
- **Maintain testability**: Each refactor should be independent and reversible  
- **Low risk first**: File organization and utilities before architectural changes
- **Update paths**: Remember to update NodePath exports and preload paths

## Known Technical Debt / Future Improvements

### Max Seats Configuration Duplication
**Issue**: `max_seats` is currently defined in both:
- `SeatManager` (default 5)
- `DistrictManager.DEFAULT_MAX_DISTRICTS` (also 5)

**Future Solution**: When implementing a level system, create a `Game` autoload with level configuration:
```gdscript
# Future Game autoload
class_name Game
extends Node

var current_level: LevelData
var max_districts: int
var max_house_seats: int

# Level data would contain all game parameters
```

**Current Status**: Both systems work independently but may get out of sync if changed manually. This will be resolved when implementing the level/game state system.