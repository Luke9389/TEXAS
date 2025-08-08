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

## Implementation Priority

### Phase 1: Core Architecture (COMPLETED)
- ✅ Type-safe Resource data classes (DistrictData, PipData, etc.)
- ✅ VotingManager: Business logic separation
- ✅ SeatManager: Seat assignment logic
- ✅ GeometryManager: Pure geometry functions
- ✅ SignalBus: Minimal event broadcasting

### Phase 2: UI Simplification (IN PROGRESS)
- 🔄 DistrictCounterUI: Pure reactive UI (emit vote_requested, subscribe to districts_modified)
- ⭕ DevToolsUI: Own its logic, emit requests via SignalBus
- ⭕ Main.gd: Central coordinator for "Call Down, Signal Up"
- ⭕ Remove DevToolsManager: Logic moves to DevToolsUI

### Phase 3: Testing & Polish (PENDING)
- ⭕ Unit tests for all manager classes
- ⭕ Integration testing for signal flow
- ⭕ Animation system integration
- ⭕ Performance validation

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

### DevTools Simplification
**Old**: DevToolsManager + DevToolsUI
**New**: DevToolsUI owns regeneration logic
- Emits `SignalBus.regenerate_map_requested()`
- Emits `SignalBus.set_generation_strategy_requested(strategy)`
- Main listens and calls down to DistrictManager/PipSpawner

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

## Type-Safe Data Structures (Phase 0 - Foundation)

### Create Data Resource Classes
**Location**: `scenes/data/` directory
**Purpose**: Type-safe data containers for inter-system communication

**Required Resource Classes**:

**DistrictData** (`scenes/data/district_data.gd`):
```gdscript
class_name DistrictData
extends Resource

@export var id: String
@export var pip_ids: Array[String] = []
@export var polygon_points: PackedVector2Array = PackedVector2Array()
@export var position: Vector2 = Vector2.ZERO
@export var winning_party: PipArea.Party = PipArea.Party.NONE
@export var has_voted: bool = false

func get_pip_count() -> int:
    return pip_ids.size()

func add_pip_id(pip_id: String) -> void:
    if pip_id not in pip_ids:
        pip_ids.append(pip_id)
```

**PipData** (`scenes/data/pip_data.gd`):
```gdscript
class_name PipData
extends Resource

@export var id: String
@export var party: PipArea.Party = PipArea.Party.NONE
@export var position: Vector2 = Vector2.ZERO
@export var vote_status: PipArea.VoteStatus = PipArea.VoteStatus.NOT_VOTED

func clone() -> PipData:
    var new_pip = PipData.new()
    new_pip.id = id
    new_pip.party = party
    new_pip.position = position
    new_pip.vote_status = vote_status
    return new_pip
```

**SeatData** (`scenes/data/seat_data.gd`):
```gdscript
class_name SeatData
extends Resource

@export var seat_index: int = -1
@export var district_id: String = ""
@export var assigned_party: PipArea.Party = PipArea.Party.NONE
@export var is_voting: bool = false

func is_assigned() -> bool:
    return district_id != ""
```

**VotingResult** (`scenes/data/voting_result.gd`):
```gdscript
class_name VotingResult
extends Resource

@export var district_id: String
@export var green_votes: int = 0
@export var orange_votes: int = 0
@export var winning_party: PipArea.Party = PipArea.Party.NONE
@export var was_runoff: bool = false
@export var round_number: int = 1

func get_total_votes() -> int:
    return green_votes + orange_votes

func is_tie() -> bool:
    return green_votes == orange_votes
```

## Current Architecture State
```
UI Layer:
  DistrictCounterUI → SignalBus.vote_requested → Main
  DevToolsUI → SignalBus.regenerate_map_requested → Main
  HouseSeatsUI ← SignalBus.seat_assignments_updated

Coordination:
  Main.gd (Call Down, Signal Up coordinator)

Business Logic:
  VotingManager ← Main.start_voting()
  SeatManager ← Main.update_seats()
  GeometryManager (static utilities)

Event Broadcasting:
  SignalBus (minimal, reactive UI updates only)
```

## Testing After Each Phase
1. **Unit Tests**: Each manager class with mock data/signals
2. **Integration**: Verify district creation/deletion still works
3. **Voting**: Test voting simulation completes correctly
4. **UI**: Check house seats update properly
5. **Dev Tools**: Ensure dev tools regenerate map correctly
6. **Animation**: Confirm all animations play as expected

## Testing Strategy for New Architecture
- **VotingManager**: Create mock DistrictData/PipData Resources, verify VotingResult signals
- **SeatManager**: Test with DistrictData instances, verify SeatData assignments
- **GeometryManager**: Pure function testing with DistrictData inputs
- **VotingAnimator**: Mock Resource-typed signals, verify animation methods called
- **Data Classes**: Unit test Resource validation, cloning, and helper methods
- **Integration**: Signal connectivity and typed data flow between systems

## Benefits of Type-Safe Resource Classes
- **Compile-time error checking** for method signatures
- **IntelliSense/autocomplete** for all data properties
- **Serializable by default** for save/load and networking
- **Self-documenting** - clear contracts between systems
- **Extensible** - add helper methods and validation to data classes
- **Unit test friendly** - easy to create mock data instances

## Critical Files to Update During Refactoring
- `scenes/main/district_manager.gd` - Remove geometry operations, add signal connections
- `scenes/main/district_counter_ui.gd` - Remove voting simulation, add data conversion
- `scenes/main/house_seats_ui.gd` - Remove seat assignment logic, keep visual updates
- `scenes/main/dev_tools_manager.gd` - Fix method calls, add signal-based communication
- Add unit test files in `tests/` directory for each new manager class
- Any preload() statements pointing to moved files

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