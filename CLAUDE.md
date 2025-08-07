# Claude Code Guidelines for TEXAS Game Project

## Scene File (.tscn) Rules
- **DO NOT EDIT .tscn files directly** - These are binary/text hybrid files that can become corrupted
- If code changes require scene modifications (like attaching scripts, changing node types, adding nodes, etc.), **ASK THE USER** to make those changes in the Godot editor instead
- Only create new .gd script files and let the user attach them manually

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