extends Node
class_name MeatSystem

## Meat cooking simulation — driven by TickManager.
## Handles internal temp, stall, bark formation, smoke ring, and carryover.

## A reference to the FireSystem this meat is cooking on
var fire_system: FireSystem = null
var meat_data: Dictionary = {}
var current_weight: float = 0.0
var internal_temp: float = 4.0
var target_internal_temp: float = 95.0
var cook_time: float = 0.0
var bark_formation: float = 0.0
var smoke_ring_depth: float = 0.0
var moisture_content: float = 1.0
var is_wrapped: bool = false
var wrap_type: String = "none"
var is_resting: bool = false
var rest_time_left: float = 0.0
var is_stalling: bool = false
var stall_progress: float = 0.0
var cook_complete: bool = false
var smoke_absorbed: float = 0.0
var meat_id: String = ""

func _ready() -> void:
	TickManager.tick_processed.connect(_on_tick)
	EventBus.on("fire_state_updated", _on_fire_state_updated)

func _on_fire_state_updated(state: Dictionary) -> void:
	pass  # Store ambient temp for logging if needed

func load_meat(meat_id_in: String, weight: float) -> void:
	meat_id = meat_id_in
	meat_data = _load_meat_data(meat_id_in)
	if meat_data.is_empty():
		meat_data = {
			"name": "Generic Meat",
			"idealInternalTempC": 85,
			"stallTempC": 68,
			"stallDurationMin": 60,
			"barkPotential": 0.5,
			"moistureSensitivity": 0.5,
			"smokeAbsorption": 0.5,
			"restingMin": 30,
			"yieldPercent": 0.7,
			"grades": [{"name": "Standard", "priceMultiplier": 1.0, "minMarbling": 0.3}]
		}
	current_weight = weight
	target_internal_temp = meat_data.get("idealInternalTempC", 95)
	internal_temp = 4.0
	cook_time = 0.0
	bark_formation = 0.0
	smoke_ring_depth = 0.0
	moisture_content = 1.0
	is_wrapped = false
	wrap_type = "none"
	is_resting = false
	is_stalling = false
	stall_progress = 0.0
	cook_complete = false
	smoke_absorbed = 0.0
	EventBus.emit("meat_loaded", {"meat_id": meat_id_in, "weight": weight})

func _load_meat_data(meat_id_param: String) -> Dictionary:
	var file = FileAccess.open("res://data/meats.json", FileAccess.READ)
	if file == null:
		return {}
	var content = file.get_as_text()
	file.close()
	var json = JSON.new()
	var parse_result = json.parse(content)
	if parse_result != OK:
		return {}
	var meats: Array = json.data
	for meat in meats:
		if meat["id"] == meat_id_param:
			return meat
	return {}

func _on_tick(delta_minutes: float, _tick_number: int) -> void:
	if cook_complete or is_resting:
		return

	# Get ambient from FireSystem
	var ambient_temp = fire_system.current_temp if fire_system else 25.0
	var smoke_q = fire_system.smoke_quality if fire_system else 0.5

	cook_time += delta_minutes

	# Temperature rise rate
	var temp_diff = ambient_temp - internal_temp
	var rise_rate = temp_diff * 0.005 * delta_minutes
	if is_wrapped:
		rise_rate *= 0.6
	var mass_factor = 1.0 / (1.0 + current_weight * 0.05)
	rise_rate *= mass_factor
	internal_temp += rise_rate

	# Stall mechanic
	var stall_start = meat_data.get("stallTempC", 68) - 2.0
	var stall_end = meat_data.get("stallTempC", 68) + 3.0
	var stall_duration = meat_data.get("stallDurationMin", 60)

	if internal_temp >= stall_start and internal_temp <= stall_end and not is_wrapped:
		if not is_stalling:
			is_stalling = true
			EventBus.emit("meat_stall_started", {"meat_id": meat_id})
		stall_progress += delta_minutes / stall_duration
		if stall_progress >= 1.0:
			is_stalling = false
			EventBus.emit("meat_stall_ended", {"meat_id": meat_id})
			internal_temp = stall_end + 0.1
	else:
		if is_stalling:
			is_stalling = false
			EventBus.emit("meat_stall_ended", {"meat_id": meat_id})
		stall_progress = 0.0

	# Bark formation
	if not is_wrapped and internal_temp > 50:
		var bark_rate = meat_data.get("barkPotential", 0.5) * 0.001 * delta_minutes
		bark_formation = min(1.0, bark_formation + bark_rate * smoke_q)

	# Smoke ring
	if cook_time < 180 and not is_wrapped:
		var ring_rate = meat_data.get("smokeAbsorption", 0.5) * 0.002 * delta_minutes
		smoke_ring_depth = min(1.0, smoke_ring_depth + ring_rate * smoke_q)
		smoke_absorbed += ring_rate * smoke_q

	# Moisture content
	var moisture_loss = meat_data.get("moistureSensitivity", 0.5) * 0.001 * delta_minutes
	moisture_content = max(0.2, moisture_content - moisture_loss)
	if is_wrapped:
		moisture_content = min(1.0, moisture_content + 0.002 * delta_minutes)

	# Check completion
	if internal_temp >= target_internal_temp:
		cook_complete = true
		EventBus.emit("meat_target_temp_reached", {
			"meat_id": meat_id,
			"temp": internal_temp,
			"bark": bark_formation,
			"smoke_ring": smoke_ring_depth,
			"moisture": moisture_content
		})

	# Publish state
	EventBus.emit("meat_state_updated", {
		"meat_id": meat_id,
		"internal_temp": internal_temp,
		"target_temp": target_internal_temp,
		"bark": bark_formation,
		"smoke_ring": smoke_ring_depth,
		"moisture": moisture_content,
		"is_stalling": is_stalling,
		"is_wrapped": is_wrapped,
		"cook_time": cook_time
	})

func get_done_percentage() -> float:
	if target_internal_temp <= 0:
		return 0.0
	return clamp(internal_temp / target_internal_temp, 0.0, 1.0)

func get_bark_score() -> float:
	return bark_formation * meat_data.get("barkPotential", 0.5)

func wrap(type: String) -> void:
	if type in ["paper", "foil"]:
		is_wrapped = true
		wrap_type = type
		bark_formation *= 0.95 if type == "paper" else 0.9
		EventBus.emit("meat_wrapped", {"meat_id": meat_id, "type": type})

func unwrap() -> void:
	is_wrapped = false
	wrap_type = "none"

func start_rest() -> void:
	is_resting = true
	rest_time_left = meat_data.get("restingMin", 30)
	internal_temp += 4.0
	EventBus.emit("meat_resting", {"meat_id": meat_id, "rest_time": rest_time_left})

func get_cook_status() -> String:
	if is_resting:
		return "Resting"
	if is_stalling:
		return "Stalling"
	if cook_complete:
		return "Done"
	if internal_temp < 30:
		return "Cold"
	if internal_temp < target_internal_temp * 0.7:
		return "Low"
	return "Cooking"

func get_stall_progress() -> float:
	return stall_progress

func get_quality_score() -> float:
	var temp_score = 1.0 if internal_temp >= target_internal_temp else internal_temp / target_internal_temp
	var bark_score = get_bark_score()
	var moisture_score = moisture_content
	var ring_score = smoke_ring_depth
	var yield_score = 1.0
	var quality = (temp_score * 0.3 + bark_score * 0.25 + moisture_score * 0.25 + ring_score * 0.1 + yield_score * 0.1)
	return clamp(quality * 100.0, 0.0, 100.0)

func get_state() -> Dictionary:
	return {
		"meat_id": meat_id,
		"weight": current_weight,
		"internal_temp": internal_temp,
		"cook_time": cook_time,
		"bark": bark_formation,
		"smoke_ring": smoke_ring_depth,
		"moisture": moisture_content,
		"is_wrapped": is_wrapped,
		"wrap_type": wrap_type,
		"is_resting": is_resting,
		"cook_complete": cook_complete,
		"is_stalling": is_stalling
	}

func load_state(state: Dictionary) -> void:
	var mid = state.get("meat_id", "")
	if not mid.is_empty():
		load_meat(mid, state.get("weight", 2.0))
	internal_temp = state.get("internal_temp", 4.0)
	cook_time = state.get("cook_time", 0.0)
	bark_formation = state.get("bark", 0.0)
	smoke_ring_depth = state.get("smoke_ring", 0.0)
	moisture_content = state.get("moisture", 1.0)
	is_wrapped = state.get("is_wrapped", false)
	wrap_type = state.get("wrap_type", "none")
	is_resting = state.get("is_resting", false)
	cook_complete = state.get("cook_complete", false)
	is_stalling = state.get("is_stalling", false)