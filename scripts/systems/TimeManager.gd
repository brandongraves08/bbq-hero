extends Node
class_name TimeManager

## Manages day cycle, time of day, and service phases

enum ServicePhase { PREP, COOK, SERVE, EVALUATE, DOWNTIME }

var current_day: int = 1
var time_of_day: float = 6.0
var time_scale: float = 1.0
var service_phase: int = ServicePhase.DOWNTIME
var is_paused: bool = false

signal time_advanced(hours: float)
signal phase_changed(phase: int)
signal day_ended()

func _ready() -> void:
	current_day = GameManager.current_day

func advance_time(hours: float) -> void:
	if is_paused:
		return
	time_of_day += hours * time_scale
	if time_of_day >= 24.0:
		time_of_day = 6.0
		current_day += 1
		GameManager.current_day = current_day
		emit_signal("day_ended")
		emit_signal("time_advanced", hours)
		service_phase = ServicePhase.DOWNTIME
		return
	emit_signal("time_advanced", hours)
	_update_phase()

func _update_phase() -> void:
	var new_phase: int
	if time_of_day < 8.0:
		new_phase = ServicePhase.PREP
	elif time_of_day < 16.0:
		new_phase = ServicePhase.COOK
	elif time_of_day < 20.0:
		new_phase = ServicePhase.SERVE
	else:
		new_phase = ServicePhase.EVALUATE
	if new_phase != service_phase:
		service_phase = new_phase
		emit_signal("phase_changed", service_phase)

func set_service_phase(phase: int) -> void:
	service_phase = phase
	emit_signal("phase_changed", phase)

func get_time_of_day_string() -> String:
	var hours: int = int(floor(time_of_day))
	var minutes: int = int(floor((time_of_day - hours) * 60))
	var ampm: String = "AM"
	var display_hour: int = hours
	if hours >= 12:
		ampm = "PM"
		if hours > 12:
			display_hour = hours - 12
	if display_hour == 0:
		display_hour = 12
	return "%d:%02d %s" % [display_hour, minutes, ampm]

func get_day_phase() -> String:
	match service_phase:
		ServicePhase.PREP:
			return "Prep"
		ServicePhase.COOK:
			return "Cooking"
		ServicePhase.SERVE:
			return "Service"
		ServicePhase.EVALUATE:
			return "Evaluation"
		ServicePhase.DOWNTIME:
			return "Downtime"
		_:
			return "Unknown"

func pause() -> void:
	is_paused = true

func unpause() -> void:
	is_paused = false