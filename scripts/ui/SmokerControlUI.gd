extends Control

## Smoker control panel UI — event-bus driven.
## Subscribes to fire_state_updated for display, sends commands via FireSystem reference.

@onready var temp_display: Label = $VBoxContainer/TempDisplay
@onready var fuel_display: Label = $VBoxContainer/FuelDisplay
@onready var smoke_display: Label = $VBoxContainer/SmokeDisplay
@onready var intake_slider: HSlider = $VBoxContainer/IntakeSlider
@onready var exhaust_slider: HSlider = $VBoxContainer/ExhaustSlider
@onready var target_temp_spin: SpinBox = $VBoxContainer/TargetTempSpin
@onready var add_fuel_btn: Button = $VBoxContainer/AddFuelBtn
@onready var add_wood_btn: Button = $VBoxContainer/AddWoodBtn
@onready var add_water_btn: Button = $VBoxContainer/AddWaterBtn

var _fire_system: FireSystem = null

func _ready() -> void:
	intake_slider.value_changed.connect(_on_intake_changed)
	exhaust_slider.value_changed.connect(_on_exhaust_changed)
	target_temp_spin.value_changed.connect(_on_target_temp_changed)
	add_fuel_btn.pressed.connect(_on_add_fuel)
	add_wood_btn.pressed.connect(_on_add_wood)
	add_water_btn.pressed.connect(_on_add_water)
	EventBus.on("fire_state_updated", _on_fire_state_update)
	EventBus.on("fire_lit", _on_fire_lit)
	EventBus.on("fire_out", _on_fire_out)
	EventBus.on("fire_fuel_low", _on_fuel_low)

func setup(fire: FireSystem) -> void:
	_fire_system = fire
	if _fire_system == null:
		return
	target_temp_spin.min_value = _fire_system.get("_min_temp", 80)
	target_temp_spin.max_value = _fire_system.get("_max_temp", 175)
	target_temp_spin.value = _fire_system.target_temp
	intake_slider.value = _fire_system.air_intake_open * 100
	exhaust_slider.value = _fire_system.exhaust_open * 100

func _on_fire_state_update(data: Dictionary) -> void:
	update_display(
		data.get("temp", 0),
		data.get("fuel_remaining", 0),
		data.get("air_intake", 0.5),
		data.get("smoke_quality", 0.7)
	)

func _on_fire_lit(_data) -> void:
	print("UI: Fire lit!")

func _on_fire_out(_data) -> void:
	print("UI: Fire went out!")

func _on_fuel_low(_data) -> void:
	print("UI: Fuel low!")

func update_display(temp: float, fuel: float, _intake: float, smoke_q: float) -> void:
	temp_display.text = "Temp: %.0f°C" % temp
	fuel_display.text = "Fuel: %.1f kg" % fuel
	smoke_display.text = "Smoke: %d%%" % (smoke_q * 100)

func _on_intake_changed(value: float) -> void:
	if _fire_system:
		_fire_system.set_intake(value / 100.0)

func _on_exhaust_changed(value: float) -> void:
	if _fire_system:
		_fire_system.set_exhaust(value / 100.0)

func _on_target_temp_changed(value: float) -> void:
	if _fire_system:
		_fire_system.set_target_temp(value)

func _on_add_fuel() -> void:
	if _fire_system:
		_fire_system.add_fuel("lump_oak", 1.0)
		EconomyManager.spend(2.5, "fuel")

func _on_add_wood() -> void:
	if _fire_system:
		_fire_system.add_wood_split()

func _on_add_water() -> void:
	if _fire_system:
		_fire_system.add_water(0.2)