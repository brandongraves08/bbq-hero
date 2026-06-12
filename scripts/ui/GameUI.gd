extends Control

## Main game HUD — event-bus driven.
## Subscribes to EventBus for all display updates.

@onready var day_label: Label = $HUD/DayLabel
@onready var money_label: Label = $HUD/MoneyLabel
@onready var rep_label: Label = $HUD/RepLabel
@onready var time_label: Label = $HUD/TimeLabel
@onready var phase_label: Label = $HUD/PhaseLabel

func _ready() -> void:
	_update_display()
	# Core state changes
	GameManager.day_changed.connect(_update_display)
	TimeManager.time_advanced.connect(_update_display)
	# Economy and reputation via EventBus for consistency
	EventBus.on("money_changed", _on_money_changed)
	EventBus.on("reputation_changed", _on_rep_changed)
	EventBus.on("fame_level_changed", _on_fame_changed)
	# Initial state broadcast
	_broadcast_current()

func _broadcast_current() -> void:
	EventBus.emit("money_changed", {"balance": EconomyManager.money, "delta": 0})
	EventBus.emit("reputation_changed", {"value": ReputationManager.reputation, "delta": 0})

func _update_display() -> void:
	day_label.text = "Day %d" % GameManager.current_day
	money_label.text = "$%.0f" % EconomyManager.money
	rep_label.text = "Rep: %.0f" % GameManager.reputation
	time_label.text = TimeManager.get_time_of_day_string()
	phase_label.text = ReputationManager.get_fame_level_name()

func _on_money_changed(data: Dictionary) -> void:
	_update_display()

func _on_rep_changed(data: Dictionary) -> void:
	_update_display()

func _on_fame_changed(_level) -> void:
	_update_display()