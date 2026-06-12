extends Node

## Central simulation tick manager.
## Drives all game simulations on one clock instead of scattered _process calls.
## Converts real delta-seconds into game-minutes for simulation systems.

const TICK_INTERVAL_SECONDS: float = 0.5
const MINUTES_PER_TICK: float = 0.5  # How many game-minutes pass per tick (tune for desired sim speed)

var tick_timer: float = 0.0
var sim_time_minutes: float = 0.0
var tick_count: int = 0
var is_paused: bool = false

# Registries for systems that want tick updates
var _tick_receivers: Array = []

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
	sim_time_minutes += MINUTES_PER_TICK
	
	# Emit signal so any node can hook in
	emit_signal("tick_processed", MINUTES_PER_TICK, tick_count)
	
	# Also publish via EventBus for systems that prefer that
	EventBus.emit("tick_processed", {
		"delta_minutes": MINUTES_PER_TICK,
		"tick_number": tick_count,
		"sim_time_minutes": sim_time_minutes
	})

func pause() -> void:
	is_paused = true
	EventBus.emit("simulation_paused")

func unpause() -> void:
	is_paused = false
	EventBus.emit("simulation_unpaused")

func set_time_scale(factor: float) -> void:
	# 1.0 = real-time, 2.0 = double speed, 0.5 = half speed
	# Adjust TICK_INTERVAL_SECONDS to control frequency vs responsiveness
	pass  # Future: adjust MINUTES_PER_TICK dynamically

func get_sim_time_hours() -> float:
	return sim_time_minutes / 60.0

func get_sim_time_string() -> String:
	var hours: int = int(floor(get_sim_time_hours())) % 24
	var minutes: int = int(sim_time_minutes) % 60
	return "%02d:%02d" % [hours, minutes]

func reset() -> void:
	tick_timer = 0.0
	sim_time_minutes = 0.0
	tick_count = 0
	is_paused = false
