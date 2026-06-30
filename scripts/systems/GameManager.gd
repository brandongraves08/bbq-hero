extends Node

## Global game state manager
## Controls phase progression, save/load, and day cycle
## Also manages scene flow: MENU → HUB → GIG_SELECT → COOK → DAY_SUMMARY → HUB

enum GameState { MENU, HUB, GIG_SELECT, BACKYARD, FOOD_TRUCK, RESTAURANT, DAY_SUMMARY }
enum Phase { ONE, TWO, THREE }
enum FameLevel { UNKNOWN, LOCAL, REGIONAL, FAMOUS, LEGENDARY }

var current_state: int = GameState.MENU
var current_phase: int = Phase.ONE
var current_day: int = 0
var player_name: String = "Pitmaster"
var reputation: float = 0.0
var money: float = 100.0
var skill_points: int = 0
var skill_levels: Dictionary = {}

## Tracks the currently selected gig/event for the current cook cycle
var active_gig: Dictionary = {}
var active_gig_id: String = ""

signal day_changed(day_number: int)
signal phase_changed(phase: int)
signal game_saved()
signal game_loaded()
signal state_changed(new_state: int, old_state: int)

func _ready() -> void:
	pass

func start_new_game() -> void:
	current_state = GameState.HUB
	current_phase = Phase.ONE
	current_day = 1
	reputation = 0.0
	money = 100.0
	skill_points = 2
	skill_levels = {}
	active_gig = {}
	active_gig_id = ""
	emit_signal("day_changed", current_day)
	emit_signal("phase_changed", current_phase)

func advance_day() -> void:
	current_day += 1
	emit_signal("day_changed", current_day)
	_check_phase_transition()

func _check_phase_transition() -> void:
	match current_phase:
		Phase.ONE:
			if reputation >= get_reputation_threshold(Phase.TWO):
				current_phase = Phase.TWO
				current_state = GameState.FOOD_TRUCK
				emit_signal("phase_changed", current_phase)
		Phase.TWO:
			if reputation >= get_reputation_threshold(Phase.THREE):
				current_phase = Phase.THREE
				current_state = GameState.RESTAURANT
				emit_signal("phase_changed", current_phase)

func get_reputation_threshold(phase: int) -> float:
	match phase:
		Phase.TWO:
			return 200.0
		Phase.THREE:
			return 500.0
		_:
			return 99999.0

## ── Scene Flow Transitions ────────────────────────────────────────────────

## Go from menu → hub
func go_to_hub() -> void:
	var old = current_state
	current_state = GameState.HUB
	emit_signal("state_changed", current_state, old)

## Go from hub → gig selection screen
func go_to_gig_select() -> void:
	var old = current_state
	current_state = GameState.GIG_SELECT
	emit_signal("state_changed", current_state, old)

## Set the active gig and transition to the cook scene
func start_gig(event_id: String) -> bool:
	active_gig_id = event_id
	active_gig = EventManager.get_event_by_id(event_id)
	if active_gig.is_empty():
		push_error("GameManager: Gig '%s' not found!" % event_id)
		return false
	return true

## Go from gig_select → first_playable cook scene
func go_to_cook() -> void:
	var old = current_state
	current_state = GameState.BACKYARD
	emit_signal("state_changed", current_state, old)

## Go from cook results → day summary scene (day advances on player confirm)
func go_to_day_summary() -> void:
	var old = current_state
	current_state = GameState.DAY_SUMMARY
	emit_signal("state_changed", current_state, old)

## ── Save / Load ───────────────────────────────────────────────────────────

func save_game() -> void:
	var save_data = {
		"current_state": current_state,
		"current_phase": current_phase,
		"current_day": current_day,
		"player_name": player_name,
		"reputation": reputation,
		"money": money,
		"skill_points": skill_points,
		"skill_levels": skill_levels,
		"active_gig_id": active_gig_id
	}
	var file = FileAccess.open("user://savegame.json", FileAccess.WRITE)
	file.store_line(JSON.stringify(save_data))
	file.close()
	emit_signal("game_saved")

func load_game() -> bool:
	if not FileAccess.file_exists("user://savegame.json"):
		return false
	var file = FileAccess.open("user://savegame.json", FileAccess.READ)
	var content = file.get_as_text()
	file.close()
	var json = JSON.new()
	var parse_result = json.parse(content)
	if parse_result != OK:
		return false
	var data = json.data
	current_state = data.get("current_state", GameState.HUB)
	current_phase = data.get("current_phase", Phase.ONE)
	current_day = data.get("current_day", 1)
	player_name = data.get("player_name", "Pitmaster")
	reputation = data.get("reputation", 0.0)
	money = data.get("money", 100.0)
	skill_points = data.get("skill_points", 0)
	skill_levels = data.get("skill_levels", {})
	active_gig_id = data.get("active_gig_id", "")
	if not active_gig_id.is_empty():
		active_gig = EventManager.get_event_by_id(active_gig_id)
	emit_signal("game_loaded")
	return true

func end_game() -> void:
	get_tree().quit()

func get_all_manager_status() -> Dictionary:
	return {
		"state": current_state,
		"phase": current_phase,
		"day": current_day,
		"money": money,
		"reputation": reputation,
		"skill_points": skill_points,
		"fame_level": get_fame_level()
	}

func get_fame_level() -> int:
	if reputation >= 800:
		return FameLevel.LEGENDARY
	elif reputation >= 500:
		return FameLevel.FAMOUS
	elif reputation >= 200:
		return FameLevel.REGIONAL
	elif reputation >= 50:
		return FameLevel.LOCAL
	return FameLevel.UNKNOWN

func get_fame_level_name() -> String:
	match get_fame_level():
		FameLevel.UNKNOWN:
			return "Unknown"
		FameLevel.LOCAL:
			return "Local Legend"
		FameLevel.REGIONAL:
			return "Regional Star"
		FameLevel.FAMOUS:
			return "Famous Pitmaster"
		FameLevel.LEGENDARY:
			return "BBQ Legend"
	return "Unknown"
