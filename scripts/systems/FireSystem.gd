extends Node
class_name FireSystem

## Simulation of a single smoker's fire thermodynamics
## Manages temperature curve, fuel burn, airflow, and smoke quality

var current_temp: float = 25.0   # Starting at ambient
var target_temp: float = 107.0   # Default brisket temp
var fuel_remaining: float = 0.0  # kg of fuel
var wood_split_timer: float = 0.0  # minutes since last wood split
var air_intake_open: float = 0.5   # 0.0 (closed) to 1.0 (fully open)
var exhaust_open: float = 0.7      # 0.0 (closed) to 1.0 (fully open)
var smoke_quality: float = 0.7     # 0.0 (dirty) to 1.0 (clean)
var coal_bed_health: float = 0.5   # 0.0 (dead) to 1.0 (excellent)
var water_level: float = 0.5       # 0.0 (empty) to 1.0 (full)
var ambient_temp: float = 25.0

var _cooker_data: Dictionary = {}
var _burn_rate_mult: float = 1.0
var _max_temp: float = 160.0
var _min_temp: float = 90.0
var _is_lit: bool = false

signal temp_warning(temp: float)
signal fire_out()
signal fuel_low()
signal smoke_quality_changed(quality: float)

func _ready() -> void:
	pass

func configure(cooker_data: Dictionary) -> void:
	_cooker_data = cooker_data
	_max_temp = cooker_data.get("tempRangeC", {}).get("max", 160)
	_min_temp = cooker_data.get("tempRangeC", {}).get("min", 90)
	_burn_rate_mult = cooker_data.get("fuelBurnRate", 1.0)
	target_temp = (_min_temp + _max_temp) / 2.0
	fuel_remaining = 0.0

func light_fire() -> void:
	_is_lit = true
	current_temp = max(current_temp, 30.0)
	coal_bed_health = 0.3

func _process(delta: float) -> void:
	if not _is_lit or fuel_remaining <= 0:
		return
	
	var delta_min = delta * 60.0
	
	# Fuel consumption
	var fuel_burn = _burn_rate_mult * (0.5 + air_intake_open * 0.5) * delta_min / 60.0
	fuel_remaining -= fuel_burn
	if fuel_remaining <= 0:
		fuel_remaining = 0
		emit_signal("fuel_low")
		if current_temp < 60:
			emit_signal("fire_out")
			_is_lit = false
			return
	
	# Temperature simulation
	var target_delta = target_temp - current_temp
	# Heat inertia: airflow pulls temp toward target
	var airflow_factor = (air_intake_open + exhaust_open) / 2.0
	var temp_change = target_delta * 0.02 * airflow_factor * delta_min
	
	# Coal bed effect: healthier coal responds better
	temp_change *= (0.5 + coal_bed_health * 0.5)
	
	# Fuel burn adds heat when burning
	var burn_heat = fuel_burn * 20.0 * delta_min
	temp_change += burn_heat * 0.01
	
	# Water pan moderation
	var water_factor = 1.0 - (water_level * 0.3)
	temp_change *= water_factor
	
	# Ambient temperature offset
	var ambient_offset = (ambient_temp - 25.0) * 0.01 * delta_min
	temp_change += ambient_offset
	
	current_temp += temp_change
	current_temp = clamp(current_temp, ambient_temp, _max_temp + 20)
	
	# Smoke quality calculation
	var smoke_target = (0.3 + air_intake_open * 0.4) - (1.0 - exhaust_open) * 0.3
	# Dirty smoke from too many splits too fast
	if wood_split_timer < 15:
		smoke_target -= 0.2
	smoke_quality = move_toward(smoke_quality, clamp(smoke_target, 0.1, 0.95), 0.02 * delta_min)
	
	# Wood split timer decay
	if wood_split_timer > 0:
		wood_split_timer = max(0, wood_split_timer - delta_min)
	
	# Coal bed health decays over time, improves with fuel
	coal_bed_health = max(0, coal_bed_health - 0.001 * delta_min)
	
	# Water level slowly evaporates
	water_level = max(0, water_level - 0.002 * delta_min)

func set_target_temp(temp: float) -> void:
	target_temp = clamp(temp, _min_temp, _max_temp)

func set_intake(amount: float) -> void:
	air_intake_open = clamp(amount, 0.0, 1.0)

func set_exhaust(amount: float) -> void:
	exhaust_open = clamp(amount, 0.0, 1.0)

func add_fuel(type: String, amount: float) -> void:
	fuel_remaining += amount
	coal_bed_health = min(1.0, coal_bed_health + 0.1)
	_is_lit = true

func add_wood_split() -> void:
	wood_split_timer = 30.0
	# Wood split burst: temp surge
	current_temp = min(current_temp + 15, _max_temp + 20)
	coal_bed_health = min(1.0, coal_bed_health + 0.05)

func add_water(amount: float) -> void:
	water_level = clamp(water_level + amount, 0.0, 1.0)

func get_smoke_quality() -> float:
	return smoke_quality

func get_burn_rate() -> float:
	return _burn_rate_mult * (0.5 + air_intake_open * 0.5)

func get_temp_trend() -> String:
	var rate = target_temp - current_temp
	if abs(rate) < 3:
		return "stable"
	elif rate > 0:
		return "rising"
	return "falling"