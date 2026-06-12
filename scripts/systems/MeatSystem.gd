extends Node
class_name MeatSystem

## Simulates cooking a single cut of meat
## Handles internal temp, stall, bark formation, smoke ring, and carryover

var meat_data: Dictionary = {}
var current_weight: float = 0.0
var internal_temp: float = 4.0  # Starting from fridge temp
var target_internal_temp: float = 95.0
var cook_time: float = 0.0  # Total minutes cooked
var bark_formation: float = 0.0  # 0.0 to 1.0
var smoke_ring_depth: float = 0.0  # 0.0 to 1.0
var moisture_content: float = 1.0  # 0.0 to 1.0
var is_wrapped: bool = false
var wrap_type: String = "none"  # "paper", "foil", "none"
var is_resting: bool = false
var rest_time_left: float = 0.0
var is_stalling: bool = false
var stall_progress: float = 0.0
var cook_complete: bool = false
var smoke_absorbed: float = 0.0

signal stall_started()
signal stall_ended()
signal target_temp_reached()
signal meat_resting()
signal cook_complete(quality_score: float)

func _ready() -> void:
	pass

func load_meat(meat_id: String, weight: float) -> void:
	meat_data = _load_meat_data(meat_id)
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

func _load_meat_data(meat_id: String) -> Dictionary:
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
		if meat["id"] == meat_id:
			return meat
	return {}

func update_cook(ambient_temp: float, smoke_q: float, delta_minutes: float) -> void:
	if cook_complete or is_resting:
		return
	
	cook_time += delta_minutes
	
	# Temperature rise rate based on delta-T
	var temp_diff = ambient_temp - internal_temp
	var rise_rate = temp_diff * 0.005 * delta_minutes
	
	# Slower rise when wrapped
	if is_wrapped:
		rise_rate *= 0.6
	
	# Meat mass slows temp rise
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
			emit_signal("stall_started")
		# Stall holds temp nearly static
		stall_progress += delta_minutes / stall_duration
		if stall_progress >= 1.0:
			is_stalling = false
			emit_signal("stall_ended")
			internal_temp = stall_end + 0.1
	else:
		if is_stalling:
			is_stalling = false
			emit_signal("stall_ended")
		stall_progress = 0.0
	
	# Bark formation
	if not is_wrapped and internal_temp > 50:
		var bark_rate = meat_data.get("barkPotential", 0.5) * 0.001 * delta_minutes
		bark_formation = min(1.0, bark_formation + bark_rate * smoke_q)
	
	# Smoke ring (NO2 reaction, time-limited to first 3 hours)
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
		emit_signal("target_temp_reached")

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
		# Wrapping halts bark and smoke ring development
		bark_formation *= 0.95 if type == "paper" else 0.9

func unwrap() -> void:
	is_wrapped = false
	wrap_type = "none"

func start_rest() -> void:
	is_resting = true
	rest_time_left = meat_data.get("restingMin", 30)
	# Carryover cooking: temp rises 3-5C during rest
	internal_temp += 4.0
	emit_signal("meat_resting")

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
	# Composite quality score for competition evaluation
	var temp_score = 1.0 if internal_temp >= target_internal_temp else internal_temp / target_internal_temp
	var bark_score = get_bark_score()
	var moisture_score = moisture_content
	var ring_score = smoke_ring_depth
	var yield_score = 1.0
	
	var quality = (temp_score * 0.3 + bark_score * 0.25 + moisture_score * 0.25 + ring_score * 0.1 + yield_score * 0.1)
	return clamp(quality * 100.0, 0.0, 100.0)