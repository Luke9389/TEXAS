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

# Planned Refactors

Based on comprehensive code audit, here are the refactoring phases to improve architecture:

## Phase 1: Extract Business Logic from UI (HIGH PRIORITY)

### 1.1 Create VotingManager Class
**Location**: `scenes/utilities/voting_manager.gd`
**Purpose**: Extract voting simulation logic from DistrictCounterUI with zero dependencies

**Requirements**:
- Create new class extending Node (for signals and timers)
- Move voting simulation methods from DistrictCounterUI:194-335
- **NO DIRECT DEPENDENCIES** - communicate only via signals
- Input signals: `start_voting(districts_data: Array, pips_data: Array)`
- Output signals: `voting_started`, `district_voting_started(district_id)`, `pip_voted(pip_id, status)`, `district_voting_complete(district_id, winning_party)`, `runoff_needed(district_ids: Array)`, `all_voting_complete`
- Accept pure data structures (not node references)
- Handle runoff election logic internally

**Type-Safe Data Structures**:
```gdscript
# Input data format using Resource classes
func start_voting(districts: Array[DistrictData], pips: Array[PipData]) -> void

# Signal emissions with typed data
signal district_voting_complete(result: VotingResult)
signal pip_voted(pip_data: PipData)
```

**Integration**:
- DistrictCounterUI connects to VotingManager signals
- DistrictCounterUI converts nodes to data and emits to VotingManager
- Other systems listen to VotingManager signals for state changes
- VotingManager is completely unit testable with mock data

### 1.2 Create GeometryManager Class  
**Location**: `scenes/utilities/geometry_manager.gd`
**Purpose**: Pure geometric operations with no node dependencies

**Requirements**:
- Create static utility class extending RefCounted
- Move methods from DistrictManager:129-187 (`_clip_district_to_all_boundaries`)
- **Pure functions only** - no node references, only geometry data
- Add methods: `clip_polygon_to_boundaries()`, `intersect_polygons()`, `subtract_polygon()`
- Input: polygon arrays, boundary arrays (PackedVector2Array)
- Output: modified polygon arrays
- All coordinate transformations handled by caller

**Type-Safe API Design**:
```gdscript
static func clip_district_to_boundaries(
    district_data: DistrictData,
    boundary_polygon: PackedVector2Array, 
    existing_districts: Array[DistrictData]
) -> DistrictData
```

**Integration**:
- DistrictManager prepares polygon data and calls GeometryManager
- DistrictManager handles coordinate transformations
- GeometryManager is completely unit testable with polygon data

### 1.3 Fix DevToolsManager.remove_district Issue
**Location**: `scenes/main/dev_tools_manager.gd:26`
**Problem**: Calls non-existent `district_manager.remove_district()`
**Solution**: Replace with `district_manager.delete_district()`

### 1.4 Create SeatManager Class
**Location**: `scenes/utilities/seat_manager.gd`
**Purpose**: Handle seat assignment logic with signal-based communication

**Requirements**:
- Create class extending RefCounted (pure logic, no scene tree)
- Move logic from HouseSeatsUI:75-122 but make it data-driven
- **NO UI DEPENDENCIES** - work with abstract seat/district data
- Input signals: `district_created(district_data)`, `district_deleted(district_id)`, `districts_cleared()`
- Output signals: `seat_assignment_changed(seat_index, party)`, `seats_reset()`
- Manage district-to-seat mapping internally
- Provide query methods for current state

**Type-Safe API Design**:
```gdscript
class_name SeatManager
extends RefCounted

signal seat_assignment_changed(seat_data: SeatData)
signal seats_reset()

func assign_district_to_seat(district_data: DistrictData) -> void
func remove_district_from_seat(district_id: String) -> void
func get_seat_assignments() -> Array[SeatData]
func clear_all_seats() -> void
```

**Integration**:
- HouseSeatsUI creates SeatManager and connects to its signals
- HouseSeatsUI connects district signals to SeatManager methods
- SeatManager emits changes, UI updates visuals accordingly
- SeatManager is unit testable with mock district data

## Phase 2: Animation Separation (MEDIUM PRIORITY)

### 2.1 Create VotingAnimator Class
**Location**: `scenes/utilities/voting_animator.gd`
**Purpose**: Handle all voting-related animations with signal-based triggering

**Requirements**:
- Create class extending Node for animation capabilities
- **NO BUSINESS LOGIC DEPENDENCIES** - only respond to animation signals
- Input signals: `animate_district_voting(district_id)`, `animate_pip_vote(pip_id)`, `animate_seat_voting(seat_index)`, `stop_all_animations()`
- Uses node lookup by ID/name rather than direct references
- Work with AnimationUtilities for complex animation sequences
- Provide animation state queries for testing

**Signal-Driven Design**:
```gdscript
# VotingAnimator listens to these signals:
VotingManager.district_voting_started.connect(_animate_district)
VotingManager.pip_voted.connect(_animate_pip_vote)
HouseSeatsUI.seat_voting_started.connect(_animate_seat)
```

**Integration**:
- VotingAnimator connects to VotingManager signals
- UI components emit animation requests via signals
- Animator finds nodes by path/ID and animates them
- No direct coupling between business logic and animation

### 2.2 Enhance AnimationUtilities
**Location**: `scenes/utilities/animation_utilities.gd`
**Purpose**: Add more complex animation patterns found in the codebase

**Requirements**:
- Add `looping_pulse()` method for voting seat animations
- Add `sequential_flash()` for animating multiple nodes in sequence
- Add `voting_flash_sequence()` specifically for district voting
- Ensure all animation methods are static and reusable

## Phase 3: Optional Scene Extraction (LOW PRIORITY)

### 3.1 Consider HouseSeats Scene Extraction
**Evaluation Criteria**: If HouseSeatsUI grows beyond 200 lines or adds complex interactions
**Current State**: 207 lines - borderline for extraction
**If Extracted**:
- Create `scenes/ui/house_seats.tscn` and `house_seats.gd`
- Move seat management logic to dedicated scene
- Update main.tscn to instance the new scene
- Ensure proper signal connections to district management

### 3.2 DevTools Scene Consideration
**Current State**: Simple enough to remain in main scene
**Future**: Extract if dev tools become more complex or need their own UI

## Phase 4: Add Signal Bus (ENHANCEMENT)

### 4.1 Create GameEventBus
**Location**: `scenes/utilities/game_event_bus.gd`
**Purpose**: Centralized event system for cross-system communication

**Requirements**:
- Singleton autoload for global access
- **PURE EVENT ROUTING** - no business logic or state storage
- Define signals for major game events: `map_regenerated`, `voting_phase_changed`, `district_limit_reached`, `pip_spawned`, `district_created`
- Provide event subscription/unsubscription methods
- Include event data validation for robust communication
- Support event replay for debugging/testing

**Decoupled Design**:
```gdscript
# Systems connect through the bus, never directly:
# DevToolsManager -> GameEventBus.map_regenerated -> DistrictManager
# DistrictManager -> GameEventBus.district_created -> HouseSeatsUI
# VotingManager -> GameEventBus.voting_complete -> Multiple listeners
```

**Integration**:
- Replace remaining direct NodePath references with bus events
- Systems emit to bus, never call methods directly on other systems
- Bus provides event history for unit test verification
- Enable/disable bus for testing isolated components

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

## Dependency-Free Architecture Goals
```
VotingManager (signals only) ← DistrictCounterUI
SeatManager (data only) ← HouseSeatsUI  
GeometryManager (static functions) ← DistrictManager
VotingAnimator (signals only) ← Multiple UI components
GameEventBus (pure routing) ← All systems
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