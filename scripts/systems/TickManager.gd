extends Node

## Central simulation tick manager.
## Drives all game simulations on one clock instead of scattered _process calls.
## Speed multiplier allows fast-forward through long cooks.

const TICK_INTERVAL_SECONDS: float = 0.5
var minutes_per_tick: float = 0.5

var tick_timer: float = 0.0
var sim_time_minutes: float = 0.0
var tick_count: int = 0
var is_paused: bool = true
var _speed_multiplier: float = 1.0

signal tick_processed(delta_minutes: float, tick_number: int)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	if is_paused:
		return
	tick_timer += delta
	while tick_timer >= TICK_INTERVAL_SECONDS:
		tick_timer -= TICK_INTERVAL_SECONDS
		_process_tick()

func _process_tick() -> void:
	tick_count += 1
	sim_time_minutes += minutes_per_tick
	emit_signal("tick_processed", minutes_per_tick, tick_count)
	EventBus.emit("tick_processed", {
		"delta_minutes": minutes_per_tick,
		"tick_number": tick_count,
		"sim_time_minutes": sim_time_minutes
	})

func pause() -> void:
	is_paused = true
	EventBus.emit("simulation_paused")

func unpause() -> void:
	is_paused = false
	EventBus.emit("simulation_unpaused")

func set_speed(multiplier: float) -> void:
	var effective = clamp(multiplier, 0.25, 20.0)
	minutes_per_tick = 0.5 * effective
	_speed_multiplier = effective
	EventBus.emit("simulation_speed_changed", {"speed": effective})

func get_speed() -> float:
	return _speed_multiplier

func get_sim_time_hours() -> float:
	return sim_time_minutes / 60.0

func get_sim_time_string() -> String:
	var hours: int = int(floor(get_sim_time_hours())) % 24
	var mins: int = int(sim_time_minutes) % 60
	return "%02d:%02d" % [hours, mins]

func reset() -> void:
	tick_timer = 0.0
	sim_time_minutes = 0.0
	tick_count = 0
	is_paused = true
	_speed_multiplier = 1.0
	minutes_per_tick = 0.5
