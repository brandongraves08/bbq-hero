extends Control

## Smoker control panel UI

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

func setup(fire_system: FireSystem) -> void:
	_fire_system = fire_system
	if _fire_system == null:
		return
	target_temp_spin.min_value = _fire_system.get("_min_temp", 80)
	target_temp_spin.max_value = _fire_system.get("_max_temp", 175)
	target_temp_spin.value = _fire_system.target_temp
	intake_slider.value = _fire_system.air_intake_open * 100
	exhaust_slider.value = _fire_system.exhaust_open * 100

func update_display(temp: float, fuel: float, intake: float, smoke_q: float) -> void:
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
		if EconomyManager.spend(2.5, "fuel"):
			pass

func _on_add_wood() -> void:
	if _fire_system:
		_fire_system.add_wood_split()

func _on_add_water() -> void:
	if _fire_system:
		_fire_system.add_water(0.2)