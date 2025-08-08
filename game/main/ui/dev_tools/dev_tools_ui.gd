class_name DevToolsUI
extends Control

var dev_mode_visible: bool = false

@onready var panel: Panel = $Panel
@onready var regenerate_button: Button = $Panel/VBoxContainer/RegenerateButton
@onready var strategy_option: OptionButton = $Panel/VBoxContainer/StrategyContainer/StrategyOption
@onready var toggle_label: Label = $Panel/VBoxContainer/ToggleLabel

func _ready() -> void:
	visible = false
	_setup_ui()
	_connect_signals()

func _setup_ui() -> void:
	strategy_option.clear()
	strategy_option.add_item("Random")
	strategy_option.add_item("Grid")
	strategy_option.add_item("Clustered")
	strategy_option.selected = 0
	
	toggle_label.text = "Press F9 to toggle Dev Tools"

func _connect_signals() -> void:
	regenerate_button.pressed.connect(_on_regenerate_pressed)
	strategy_option.item_selected.connect(_on_strategy_selected)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_dev_tools"):
		toggle_visibility()

func toggle_visibility() -> void:
	dev_mode_visible = !dev_mode_visible
	visible = dev_mode_visible
	
	if dev_mode_visible:
		print("[DevTools] Opened")
	else:
		print("[DevTools] Closed")

func _on_regenerate_pressed() -> void:
	# Signal up to Main via SignalBus
	SignalBus.regenerate_map_requested.emit()
	print("[DevTools] Map regeneration requested")

func _on_strategy_selected(index: int) -> void:
	var strategy_name: String = strategy_option.get_item_text(index)
	# Signal up to Main via SignalBus
	SignalBus.set_generation_strategy_requested.emit(strategy_name)
	print("[DevTools] Spawn strategy change requested: ", strategy_name)

func get_current_strategy() -> String:
	return strategy_option.get_item_text(strategy_option.selected)