extends Node

## Global game state manager
## Controls phase progression, save/load, and day cycle

enum GameState { MENU, BACKYARD, FOOD_TRUCK, RESTAURANT }
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

signal day_changed(day_number: int)
signal phase_changed(phase: int)
signal game_saved()
signal game_loaded()

func _ready() -> void:
	pass

func start_new_game() -> void:
	current_state = GameState.BACKYARD
	current_phase = Phase.ONE
	current_day = 1
	reputation = 0.0
	money = 100.0
	skill_points = 2
	skill_levels = {}
	GameManager.emit_signal("day_changed", current_day)
	GameManager.emit_signal("phase_changed", current_phase)

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

func save_game() -> void:
	var save_data = {
		"current_state": current_state,
		"current_phase": current_phase,
		"current_day": current_day,
		"player_name": player_name,
		"reputation": reputation,
		"money": money,
		"skill_points": skill_points,
		"skill_levels": skill_levels
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
	current_state = data.get("current_state", GameState.BACKYARD)
	current_phase = data.get("current_phase", Phase.ONE)
	current_day = data.get("current_day", 1)
	player_name = data.get("player_name", "Pitmaster")
	reputation = data.get("reputation", 0.0)
	money = data.get("money", 100.0)
	skill_points = data.get("skill_points", 0)
	skill_levels = data.get("skill_levels", {})
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