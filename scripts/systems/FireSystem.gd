extends Node
class_name FireSystem

## Smoker fire thermodynamics simulation.
## Driven by TickManager — no standalone _process.

var current_temp: float = 25.0
var target_temp: float = 107.0
var fuel_remaining: float = 0.0
var wood_split_timer: float = 0.0
var air_intake_open: float = 0.5
var exhaust_open: float = 0.7
var smoke_quality: float = 0.7
var coal_bed_health: float = 0.5
var water_level: float = 0.5
var ambient_temp: float = 25.0

var _cooker_data: Dictionary = {}
var _burn_rate_mult: float = 1.0
var _max_temp: float = 160.0
var _min_temp: float = 90.0
var _is_lit: bool = false

func _ready() -> void:
	TickManager.tick_processed.connect(_on_tick)

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
	EventBus.emit("fire_lit", {"smoker": _cooker_data.get("id", "unknown")})

func _on_tick(delta_minutes: float, _tick_number: int) -> void:
	if not _is_lit or fuel_remaining <= 0:
		return

	# Fuel consumption
	var fuel_burn = _burn_rate_mult * (0.5 + air_intake_open * 0.5) * delta_minutes / 60.0
	fuel_remaining -= fuel_burn
	if fuel_remaining <= 0:
		fuel_remaining = 0
		EventBus.emit("fire_fuel_low", {"remaining": 0.0})
		if current_temp < 60:
			_is_lit = false
			EventBus.emit("fire_out", {})
			return

	# Temperature simulation
	var target_delta = target_temp - current_temp
	var airflow_factor = (air_intake_open + exhaust_open) / 2.0
	var temp_change = target_delta * 0.02 * airflow_factor * delta_minutes
	temp_change *= (0.5 + coal_bed_health * 0.5)

	var burn_heat = fuel_burn * 20.0 * delta_minutes
	temp_change += burn_heat * 0.01

	var water_factor = 1.0 - (water_level * 0.3)
	temp_change *= water_factor

	var ambient_offset = (ambient_temp - 25.0) * 0.01 * delta_minutes
	temp_change += ambient_offset

	current_temp += temp_change
	current_temp = clamp(current_temp, ambient_temp, _max_temp + 20)

	# Smoke quality
	var smoke_target = (0.3 + air_intake_open * 0.4) - (1.0 - exhaust_open) * 0.3
	if wood_split_timer < 15:
		smoke_target -= 0.2
	var old_quality = smoke_quality
	smoke_quality = move_toward(smoke_quality, clamp(smoke_target, 0.1, 0.95), 0.02 * delta_minutes)
	if abs(smoke_quality - old_quality) > 0.05:
		EventBus.emit("fire_smoke_quality_changed", {"quality": smoke_quality})

	# Wood split timer decay
	if wood_split_timer > 0:
		wood_split_timer = max(0, wood_split_timer - delta_minutes)

	# Coal bed health
	coal_bed_health = max(0, coal_bed_health - 0.001 * delta_minutes)

	# Water level evaporation
	water_level = max(0, water_level - 0.002 * delta_minutes)

	# Publish current state for UI
	EventBus.emit("fire_state_updated", {
		"temp": current_temp,
		"target_temp": target_temp,
		"fuel_remaining": fuel_remaining,
		"smoke_quality": smoke_quality,
		"air_intake": air_intake_open,
		"exhaust": exhaust_open,
		"coal_bed": coal_bed_health,
		"water_level": water_level
	})

func set_target_temp(temp: float) -> void:
	target_temp = clamp(temp, _min_temp, _max_temp)
	EventBus.emit("fire_target_temp_set", {"temp": target_temp})

func set_intake(amount: float) -> void:
	air_intake_open = clamp(amount, 0.0, 1.0)

func set_exhaust(amount: float) -> void:
	exhaust_open = clamp(amount, 0.0, 1.0)

func add_fuel(type: String, amount: float) -> void:
	fuel_remaining += amount
	coal_bed_health = min(1.0, coal_bed_health + 0.1)
	_is_lit = true
	EventBus.emit("fire_fuel_added", {"type": type, "amount": amount})

func add_wood_split() -> void:
	wood_split_timer = 30.0
	current_temp = min(current_temp + 15, _max_temp + 20)
	coal_bed_health = min(1.0, coal_bed_health + 0.05)
	EventBus.emit("fire_wood_split_added", {})

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

func get_state() -> Dictionary:
	return {
		"current_temp": current_temp,
		"target_temp": target_temp,
		"fuel_remaining": fuel_remaining,
		"air_intake": air_intake_open,
		"exhaust": exhaust_open,
		"smoke_quality": smoke_quality,
		"coal_bed": coal_bed_health,
		"water": water_level,
		"is_lit": _is_lit
	}

func load_state(state: Dictionary) -> void:
	current_temp = state.get("current_temp", 25.0)
	target_temp = state.get("target_temp", 107.0)
	fuel_remaining = state.get("fuel_remaining", 0.0)
	air_intake_open = state.get("air_intake", 0.5)
	exhaust_open = state.get("exhaust", 0.7)
	smoke_quality = state.get("smoke_quality", 0.7)
	coal_bed_health = state.get("coal_bed", 0.5)
	water_level = state.get("water", 0.5)
	_is_lit = state.get("is_lit", false)