extends Node
class_name EventManager

## Manages available events, active events, and event history

var available_events: Array = []
var current_event: Dictionary = {}
var event_history: Array = []
var _all_events: Array = []

signal event_started(event_id: String, event_data: Dictionary)
signal event_completed(event_id: String, result: Dictionary)

func _ready() -> void:
	_load_all_events()
	_refresh_available_events()

func _load_all_events() -> void:
	var file = FileAccess.open("res://data/events.json", FileAccess.READ)
	if file == null:
		return
	var content = file.get_as_text()
	file.close()
	var json = JSON.new()
	var parse_result = json.parse(content)
	if parse_result != OK:
		return
	_all_events = json.data

func _refresh_available_events() -> void:
	available_events.clear()
	var phase = GameManager.current_phase
	var rep = GameManager.reputation
	
	for event in _all_events:
		var event_phase = event.get("phase", 1)
		var req_rep = event.get("reputationRequired", 0)
		
		if phase == event_phase and rep >= req_rep:
			# Check if milestone events should auto-trigger
			if event.get("type") == "milestone":
				# Only show if relevant milestone hasn't happened
				available_events.append(event)
			else:
				available_events.append(event)

func get_available_events() -> Array:
	_refresh_available_events()
	return available_events

func start_event(event_id: String) -> bool:
	for event in _all_events:
		if event["id"] == event_id:
			current_event = event
			emit_signal("event_started", event_id, event)
			return true
	return false

func complete_event(result_data: Dictionary) -> void:
	var event_record = {
		"event": current_event.get("id", "unknown"),
		"event_name": current_event.get("name", "Unknown Event"),
		"day": GameManager.current_day,
		"result": result_data
	}
	event_history.append(event_record)
	emit_signal("event_completed", current_event.get("id", ""), result_data)
	current_event = {}

func get_event_history() -> Array:
	return event_history

func generate_event_for_phase(phase: int) -> Array:
	var phase_events: Array = []
	for event in _all_events:
		if event.get("phase", 1) == phase and not event.get("type") == "milestone":
			phase_events.append(event)
	return phase_events

func is_competition(event_id: String) -> bool:
	for event in _all_events:
		if event["id"] == event_id:
			return event.get("type") == "competition"
	return false

func get_event_by_id(event_id: String) -> Dictionary:
	for event in _all_events:
		if event["id"] == event_id:
			return event
	return {}

func is_event_active() -> bool:
	return not current_event.is_empty()