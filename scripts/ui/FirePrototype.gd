extends Control

## Standalone fire management prototype scene.
## Plugs FireSystem into visual controls via TickManager + EventBus.
## No economy, no meat — just feel the fire.

var _fire_system: FireSystem = null
var _cooker_data: Dictionary = {}
var _smoke_particles: CPUParticles2D = null
var _temp_history: Array = []  # Last 60 readings for trend line

@onready var temp_bar: ProgressBar = $VBoxContainer/TempPanel/TempBar
@onready var temp_label: Label = $VBoxContainer/TempPanel/TempLabel
@onready var temp_trend_label: Label = $VBoxContainer/TempPanel/TrendLabel

@onready var fuel_bar: ProgressBar = $VBoxContainer/FuelPanel/FuelBar
@onready var fuel_label: Label = $VBoxContainer/FuelPanel/FuelLabel

@onready var smoke_quality_bar: ProgressBar = $VBoxContainer/SmokePanel/SmokeBar
@onready var smoke_label: Label = $VBoxContainer/SmokePanel/SmokeLabel

@onready var coal_bar: ProgressBar = $VBoxContainer/CoalPanel/CoalBar
@onready var water_bar: ProgressBar = $VBoxContainer/WaterPanel/WaterBar

@onready var status_label: Label = $VBoxContainer/StatusLabel

@onready var intake_slider: HSlider = $VBoxContainer/Controls/IntakeRow/IntakeSlider
@onready var exhaust_slider: HSlider = $VBoxContainer/Controls/ExhaustRow/ExhaustSlider
@onready var target_temp_spin: SpinBox = $VBoxContainer/Controls/TargetRow/TargetSpin

@onready var add_fuel_btn: Button = $VBoxContainer/Controls/ButtonRow/AddFuelBtn
@onready var add_wood_btn: Button = $VBoxContainer/Controls/ButtonRow/AddWoodBtn
@onready var add_water_btn: Button = $VBoxContainer/Controls/ButtonRow/AddWaterBtn
@onready var light_btn: Button = $VBoxContainer/Controls/ButtonRow/LightFireBtn
@onready var extinguish_btn: Button = $VBoxContainer/Controls/ButtonRow/ExtinguishBtn

@onready var speed_label: Label = $VBoxContainer/Controls/SpeedRow/SpeedLabel
@onready var speed_1x_btn: Button = $VBoxContainer/Controls/SpeedRow/Speed1xBtn
@onready var speed_2x_btn: Button = $VBoxContainer/Controls/SpeedRow/Speed2xBtn
@onready var speed_5x_btn: Button = $VBoxContainer/Controls/SpeedRow/Speed5xBtn
@onready var speed_10x_btn: Button = $VBoxContainer/Controls/SpeedRow/Speed10xBtn


func _ready() -> void:
	_setup_fire_system()
	_connect_controls()
	_connect_events()
	_connect_tick()


func _setup_fire_system() -> void:
	_cooker_data = CookerManager.get_cooker("rusty_offset")
	_fire_system = CookerManager.make_cooker_instance("rusty_offset")
	if _fire_system == null:
		_fire_system = FireSystem.new()
		_fire_system.configure({"tempRangeC": {"min": 90, "max": 160}, "fuelBurnRate": 1.2})
	add_child(_fire_system)
	
	target_temp_spin.min_value = 90
	target_temp_spin.max_value = 160
	target_temp_spin.value = 107


func _connect_controls() -> void:
	intake_slider.value_changed.connect(_on_intake)
	exhaust_slider.value_changed.connect(_on_exhaust)
	target_temp_spin.value_changed.connect(_on_target)
	add_fuel_btn.pressed.connect(_on_add_fuel)
	add_wood_btn.pressed.connect(_on_add_wood)
	add_water_btn.pressed.connect(_on_add_water)
	light_btn.pressed.connect(_on_light)
	extinguish_btn.pressed.connect(_on_extinguish)
	speed_1x_btn.pressed.connect(func(): TickManager.set_speed(1.0))
	speed_2x_btn.pressed.connect(func(): TickManager.set_speed(2.0))
	speed_5x_btn.pressed.connect(func(): TickManager.set_speed(5.0))
	speed_10x_btn.pressed.connect(func(): TickManager.set_speed(10.0))


func _connect_events() -> void:
	EventBus.on("fire_state_updated", _on_fire_state)
	EventBus.on("fire_lit", _on_fire_lit)
	EventBus.on("fire_out", _on_fire_out)
	EventBus.on("fire_fuel_low", _on_fuel_low)
	EventBus.on("fire_smoke_quality_changed", _on_smoke_changed)


func _connect_tick() -> void:
	TickManager.tick_processed.connect(_on_tick)
	TickManager.unpause()


func _on_tick(_delta: float, _tick: int) -> void:
	_update_speed_display()


func _on_intake(val: float) -> void:
	_fire_system.set_intake(val / 100.0)

func _on_exhaust(val: float) -> void:
	_fire_system.set_exhaust(val / 100.0)

func _on_target(val: float) -> void:
	_fire_system.set_target_temp(val)

func _on_add_fuel() -> void:
	_fire_system.add_fuel("lump_oak", 2.0)

func _on_add_wood() -> void:
	_fire_system.add_wood_split()

func _on_add_water() -> void:
	_fire_system.add_water(0.3)

func _on_light() -> void:
	_fire_system.light_fire()
	_fire_system.add_fuel("lump_oak", 3.0)

func _on_extinguish() -> void:
	_fire_system.fuel_remaining = 0
	_fire_system._is_lit = false
	EventBus.emit("fire_out", {})


func _on_fire_state(data: Dictionary) -> void:
	var temp = data.get("temp", 25)
	var fuel = data.get("fuel_remaining", 0)
	var smoke = data.get("smoke_quality", 0.5)
	var coal = data.get("coal_bed", 0.5)
	var water = data.get("water_level", 0.5)
	
	var tmin = _fire_system.get("_min_temp", 90)
	var tmax = _fire_system.get("_max_temp", 160)
	
	temp_bar.max_value = tmax + 20
	temp_bar.value = temp
	temp_label.text = "%d°C" % temp
	
	var trend = _fire_system.get_temp_trend()
	temp_trend_label.text = trend
	match trend:
		"rising": temp_trend_label.self_modulate = Color(0.3, 1.0, 0.3)
		"falling": temp_trend_label.self_modulate = Color(1.0, 0.3, 0.3)
		_: temp_trend_label.self_modulate = Color(0.8, 0.8, 0.3)
	
	fuel_bar.max_value = 10
	fuel_bar.value = fuel
	fuel_label.text = "%.1f kg" % fuel
	
	smoke_quality_bar.value = smoke
	var smoke_color = _smoke_quality_to_color(smoke)
	smoke_quality_bar.self_modulate = smoke_color
	smoke_label.text = "%d%%" % (smoke * 100)
	
	coal_bar.value = coal
	water_bar.value = water
	
	var status = "🔥 LIT — " + trend.capitalize()
	if not _fire_system.get("_is_lit", false):
		status = "❄️ COLD — Light the fire"
	status_label.text = status


func _on_fire_lit(_data) -> void:
	status_label.text = "🔥 FIRE LIT!"

func _on_fire_out(_data) -> void:
	status_label.text = "❄️ FIRE OUT — Add fuel and relight"

func _on_fuel_low(_data) -> void:
	status_label.text = "⚠️ FUEL LOW — Add more!"

func _on_smoke_changed(data: Dictionary) -> void:
	smoke_quality_bar.value = data.get("quality", 0.5)


func _smoke_quality_to_color(quality: float) -> Color:
	if quality > 0.8:
		return Color(0.85, 0.85, 0.95, 1)  # Clean: thin blue
	elif quality > 0.5:
		return Color(0.6, 0.55, 0.5, 1)     # OK: light gray
	elif quality > 0.2:
		return Color(0.4, 0.3, 0.2, 1)       # Dirty: brown-gray
	return Color(0.2, 0.15, 0.1, 1)          # Bad: thick dark


func _update_speed_display() -> void:
	speed_label.text = "Speed: %.1fx" % TickManager.get_speed()
