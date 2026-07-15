extends Control
class_name HubUI

## ── Hub Screen ──────────────────────────────────────────────────────────────
## Between-days hub showing player stats and navigation to gigs/upgrades.
## Flows: main_menu → hub → gig_select → cook → day_summary → hub (loop)

@onready var day_label: Label = $MarginContainer/VBox/HeaderRow/DayLabel
@onready var money_label: Label = $MarginContainer/VBox/HeaderRow/MoneyLabel
@onready var rep_label: Label = $MarginContainer/VBox/HeaderRow/RepLabel
@onready var fame_label: Label = $MarginContainer/VBox/HeaderRow/FameLabel
@onready var stats_panel: Panel = $MarginContainer/VBox/StatsPanel

@onready var take_gig_btn: Button = $MarginContainer/VBox/ActionRow/TakeGigBtn
@onready var upgrade_btn: Button = $MarginContainer/VBox/ActionRow/UpgradeBtn
@onready var save_btn: Button = $MarginContainer/VBox/ActionRow/SaveBtn
@onready var quit_btn: Button = $MarginContainer/VBox/ActionRow/QuitBtn
@onready var prep_station_btn: Button = $MarginContainer/VBox/ActionRow/PrepStationBtn

@onready var day_history_container: VBoxContainer = $MarginContainer/VBox/StatsPanel/MarginContainer/VBox/HistoryList
@onready var event_history_label: Label = $MarginContainer/VBox/StatsPanel/MarginContainer/VBox/HistoryList/EventHistoryLabel

signal gig_selected

func _ready() -> void:
	take_gig_btn.pressed.connect(_on_take_gig)
	upgrade_btn.pressed.connect(_on_upgrade)
	save_btn.pressed.connect(_on_save)
	quit_btn.pressed.connect(_on_quit)
	prep_station_btn.pressed.connect(_on_prep_station)

	# Listen for game state changes
	GameManager.state_changed.connect(_on_game_state_changed)
	EconomyManager.money_changed.connect(_refresh_display)
	ReputationManager.reputation_changed.connect(_refresh_display)

func _on_game_state_changed(new_state: int, _old_state: int) -> void:
	if new_state == GameManager.GameState.HUB:
		_refresh_display(0.0, 0.0)
		_update_history()

func _refresh_display(_new_balance: float = 0.0, _delta: float = 0.0) -> void:
	day_label.text = "Day %d" % GameManager.current_day
	money_label.text = "$%.0f" % EconomyManager.money
	rep_label.text = "Rep: %d" % GameManager.reputation
	fame_label.text = "🏆 %s" % GameManager.get_fame_level_name()

func _update_history() -> void:
	# Clear previous history items (keep EventHistoryLabel as template)
	for child in day_history_container.get_children():
		if child != event_history_label:
			child.queue_free()

	# Show recent event history from EventManager
	var history = EventManager.get_event_history()
	if history.is_empty():
		event_history_label.text = "No gigs completed yet. Take one below!"
		return

	# Show last 5 events
	var start = max(0, history.size() - 5)
	for i in range(start, history.size()):
		var entry = history[i]
		var entry_label = Label.new()
		var day_num = entry.get("day", "?")
		var name = entry.get("event_name", "Unknown")
		var result = entry.get("result", {})
		var score = result.get("score", 0.0)
		entry_label.text = "Day %d: %s — Score: %.0f" % [day_num, name, score]
		entry_label.theme_override_font_sizes = {"font_size": 12}
		entry_label.theme_override_colors = {"font_color": Color(0.85, 0.75, 0.5)}
		day_history_container.add_child(entry_label)

	event_history_label.text = ""

func _on_take_gig() -> void:
	# Transition to gig selection scene
	get_tree().change_scene_to_file("res://scenes/gig_select.tscn")

func _on_upgrade() -> void:
	# Transition to upgrade shop scene
	get_tree().change_scene_to_file("res://scenes/upgrade_shop.tscn")

func _on_save() -> void:
	GameManager.save_game()
	save_btn.text = "✅ Saved!"
	await get_tree().create_timer(1.5).timeout
	save_btn.text = "💾 Save Game"

func _on_prep_station() -> void:
	get_tree().change_scene_to_file("res://scenes/recipe_crafting.tscn")

func _on_quit() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
