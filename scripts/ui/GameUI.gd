extends Control

## Main game HUD controller

@onready var day_label: Label = $HUD/DayLabel
@onready var money_label: Label = $HUD/MoneyLabel
@onready var rep_label: Label = $HUD/RepLabel
@onready var time_label: Label = $HUD/TimeLabel
@onready var phase_label: Label = $HUD/PhaseLabel

func _ready() -> void:
	_update_display()
	GameManager.day_changed.connect(_on_day_changed)
	EconomyManager.money_changed.connect(_on_money_changed)
	ReputationManager.reputation_changed.connect(_on_rep_changed)
	TimeManager.time_advanced.connect(_on_time_advanced)

func _update_display() -> void:
	day_label.text = "Day %d" % GameManager.current_day
	money_label.text = "$%.0f" % EconomyManager.money
	rep_label.text = "Rep: %.0f" % GameManager.reputation
	time_label.text = TimeManager.get_time_of_day_string()
	phase_label.text = ReputationManager.get_fame_level_name()

func _on_day_changed(day: int) -> void:
	_update_display()

func _on_money_changed(balance: float, delta: float) -> void:
	_update_display()

func _on_rep_changed(value: float, delta: float) -> void:
	_update_display()

func _on_time_advanced(hours: float) -> void:
	_update_display()