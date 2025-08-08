class_name DevToolsManager
extends Node

@export var district_manager: DistrictManager
@export var pip_spawner: PipSpawner
@export var district_counter_ui: DistrictCounterUI

var current_strategy: String = "Random"

func _ready() -> void:
	print("[DevTools] Manager initialized")

func regenerate_map() -> void:
	_clear_all_districts()
	_respawn_pips()
	_reset_ui()
	print("[DevTools] Map regenerated with strategy: ", current_strategy)

func _clear_all_districts() -> void:
	if not district_manager:
		push_error("[DevTools] DistrictManager not found")
		return
	
	var districts = district_manager.get_all_districts()
	for district in districts:
		district_manager.remove_district(district)
	
	print("[DevTools] Cleared ", districts.size(), " districts")

func _respawn_pips() -> void:
	if not pip_spawner:
		push_error("[DevTools] PipSpawner not found")
		return
	
	pip_spawner.clear_pips()
	
	var strategy = _get_strategy_for_name(current_strategy)
	if strategy:
		pip_spawner.spawn_strategy = strategy
		pip_spawner.spawn_pips()
		print("[DevTools] Spawned pips using ", current_strategy, " strategy")
	else:
		push_error("[DevTools] Invalid strategy: ", current_strategy)

func _get_strategy_for_name(strategy_name: String) -> SpawnStrategy:
	match strategy_name:
		"Random":
			return RandomSpawnStrategy.new()
		"Grid":
			return GridSpawnStrategy.new()
		"Clustered":
			return ClusteredSpawnStrategy.new()
		_:
			return RandomSpawnStrategy.new()

func _reset_ui() -> void:
	if not district_counter_ui:
		push_error("[DevTools] DistrictCounterUI not found")
		return
	
	district_counter_ui.reset_counters()
	print("[DevTools] UI counters reset")

func set_spawn_strategy(strategy_name: String) -> void:
	current_strategy = strategy_name
	print("[DevTools] Strategy set to: ", strategy_name)
	regenerate_map()
