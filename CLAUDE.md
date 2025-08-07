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

## ✅ Completed Refactors
1. **Unused Code Removal** - Removed backward compatibility methods, unused exports, and dead code
2. **Animation Utilities** - Created reusable animation patterns, fixed tween errors
3. **Boundary Utilities** - Eliminated coordinate conversion duplication, reduced texas_boundary.gd from 140 to 86 lines
4. **Spawn Strategy Pattern** - Flexible pip spawning with 3 strategies: Random, Grid, Clustered. Reduced pip_spawner.gd complexity
5. **Input Handler Extraction** - Separated input processing from game logic. DistrictManager now focuses purely on data management
6. **Node Tree Improvements** - Organized scene hierarchy with Geography/GameplayManagement/UserInterface groupings. Fixed boundary clipping bug

## 🚧 Remaining Refactors (In Priority Order)

### 1. File System Organization
**Goal**: Better project structure for maintainability
**Impact**: High impact, low risk
**New structure:**
```
/scripts
  /managers     - district_manager.gd, pip_spawner.gd
  /areas        - district_area.gd, pip_area.gd, texas_boundary.gd  
  /ui          - district_counter_ui.gd
  /utilities   - party_colors.gd, district_statistics.gd, boundary_utilities.gd, animation_utilities.gd
  /handlers    - district_input_handler.gd
  /strategies  - spawn_strategies.gd
/scenes        - All .tscn files
/assets        - All textures
```

### 5. Node Tree Improvements
**Goal**: Clearer system organization in scene hierarchy
**Impact**: Medium impact, low risk
**Proposed main.tscn structure:**
```
GameRoot (Node2D)
├── Geography (Node2D)
│   └── TEXAS 
├── GameplayManagement (Node2D)  
│   ├── DistrictManager
│   ├── PipSpawner
│   └── InputHandler
└── UserInterface (Control)
    └── DistrictCounterUI
```

## Implementation Strategy
- **Maintain testability**: Each refactor should be independent and reversible  
- **Low risk first**: File organization and utilities before architectural changes
- **Test after each**: Verify game functionality after each refactor
- **Update paths**: Remember to update NodePath exports and preload paths
```