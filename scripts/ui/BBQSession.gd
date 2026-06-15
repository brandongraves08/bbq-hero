extends Control

## Combined BBQ session scene controller.
## Manages both FireSystem (fire management) and MeatSystem (meat cooking)
## in a single playable interface. Inherits all fire controls from FirePrototype
## patterns and adds a full meat cooking panel.

## ── Systems ──────────────────────────────────────────────────────────────────
var _fire_system: FireSystem = null
var _meat_system: MeatSystem = null
var _cooker_data: Dictionary = {}
var _meats_data: Array = []
var _current_meat_id: String = ""
var _session_active: bool = false

## ── Fire UI Nodes ────────────────────────────────────────────────────────────
@onready var temp_bar: ProgressBar = $FirePanel/VBoxContainer/TempPanel/TempBar
@onready var temp_label: Label = $FirePanel/VBoxContainer/TempPanel/TempLabel
@onready var temp_trend_label: Label = $FirePanel/VBoxContainer/TempPanel/TrendLabel

@onready var fuel_bar: ProgressBar = $FirePanel/VBoxContainer/FuelPanel/FuelBar
@onready var fuel_label: Label = $FirePanel/VBoxContainer/FuelPanel/FuelLabel

@onready var smoke_quality_bar: ProgressBar = $FirePanel/VBoxContainer/SmokePanel/SmokeBar
@onready var smoke_label: Label = $FirePanel/VBoxContainer/SmokePanel/SmokeLabel

@onready var coal_bar: ProgressBar = $FirePanel/VBoxContainer/CoalPanel/CoalBar
@onready var water_bar: ProgressBar = $FirePanel/VBoxContainer/WaterPanel/WaterBar

@onready var fire_status_label: Label = $FirePanel/VBoxContainer/StatusLabel

@onready var intake_slider: HSlider = $FirePanel/VBoxContainer/Controls/IntakeRow/IntakeSlider
@onready var exhaust_slider: HSlider = $FirePanel/VBoxContainer/Controls/ExhaustRow/ExhaustSlider
@onready var target_temp_spin: SpinBox = $FirePanel/VBoxContainer/Controls/TargetRow/TargetSpin

@onready var add_fuel_btn: Button = $FirePanel/VBoxContainer/Controls/ButtonRow/AddFuelBtn
@onready var add_wood_btn: Button = $FirePanel/VBoxContainer/Controls/ButtonRow/AddWoodBtn
@onready var add_water_btn: Button = $FirePanel/VBoxContainer/Controls/ButtonRow/AddWaterBtn
@onready var light_btn: Button = $FirePanel/VBoxContainer/Controls/ButtonRow/LightFireBtn
@onready var extinguish_btn: Button = $FirePanel/VBoxContainer/Controls/ButtonRow/ExtinguishBtn

@onready var speed_label: Label = $FirePanel/VBoxContainer/Controls/SpeedRow/SpeedLabel
@onready var speed_1x_btn: Button = $FirePanel/VBoxContainer/Controls/SpeedRow/Speed1xBtn
@onready var speed_2x_btn: Button = $FirePanel/VBoxContainer/Controls/SpeedRow/Speed2xBtn
@onready var speed_5x_btn: Button = $FirePanel/VBoxContainer/Controls/SpeedRow/Speed5xBtn
@onready var speed_10x_btn: Button = $FirePanel/VBoxContainer/Controls/SpeedRow/Speed10xBtn

## ── Meat UI Nodes ────────────────────────────────────────────────────────────
@onready var meat_panel: Panel = $MeatPanel
@onready var meat_header: Label = $MeatPanel/VBoxContainer/HeaderLabel
@onready var meat_status_label: Label = $MeatPanel/VBoxContainer/MeatStatusLabel
@onready var meat_selector: OptionButton = $MeatPanel/VBoxContainer/MeatSelectorRow/MeatSelector
@onready var weight_spin: SpinBox = $MeatPanel/VBoxContainer/MeatSelectorRow/WeightSpin
@onready var load_meat_btn: Button = $MeatPanel/VBoxContainer/MeatSelectorRow/LoadMeatBtn

@onready var internal_temp_bar: ProgressBar = $MeatPanel/VBoxContainer/InternalTempPanel/InternalTempBar
@onready var internal_temp_label: Label = $MeatPanel/VBoxContainer/InternalTempPanel/InternalTempLabel
@onready var target_temp_label: Label = $MeatPanel/VBoxContainer/InternalTempPanel/TargetTempLabel

@onready var stall_bar: ProgressBar = $MeatPanel/VBoxContainer/StallPanel/StallBar
@onready var stall_label: Label = $MeatPanel/VBoxContainer/StallPanel/StallLabel

@onready var bark_bar: ProgressBar = $MeatPanel/VBoxContainer/BarkPanel/BarkBar
@onready var bark_label: Label = $MeatPanel/VBoxContainer/BarkPanel/BarkLabel

@onready var smoke_ring_bar: ProgressBar = $MeatPanel/VBoxContainer/SmokeRingPanel/SmokeRingBar
@onready var smoke_ring_label: Label = $MeatPanel/VBoxContainer/SmokeRingPanel/SmokeRingLabel

@onready var moisture_bar: ProgressBar = $MeatPanel/VBoxContainer/MoisturePanel/MoistureBar
@onready var moisture_label: Label = $MeatPanel/VBoxContainer/MoisturePanel/MoistureLabel

@onready var cook_time_label: Label = $MeatPanel/VBoxContainer/CookTimeLabel

@onready var wrap_btn: Button = $MeatPanel/VBoxContainer/ActionRow/WrapBtn
@onready var unwrap_btn: Button = $MeatPanel/VBoxContainer/ActionRow/UnwrapBtn
@onready var rest_btn: Button = $MeatPanel/VBoxContainer/ActionRow/RestBtn

@onready var quality_panel: Panel = $MeatPanel/VBoxContainer/QualityPanel
@onready var quality_score_label: Label = $MeatPanel/VBoxContainer/QualityPanel/QualityScoreLabel
@onready var quality_detail_label: Label = $MeatPanel/VBoxContainer/QualityPanel/QualityDetailLabel
@onready var new_cook_btn: Button = $MeatPanel/VBoxContainer/QualityPanel/NewCookBtn


func _ready() -> void:
	_setup_fire_system()
	_setup_meat_system()
	_load_meats_list()
	_connect_fire_controls()
	_connect_meat_controls()
	_connect_events()
	_connect_tick()
	_update_meat_ui_visibility(false)


## ── Setup ────────────────────────────────────────────────────────────────────

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


func _setup_meat_system() -> void:
	_meat_system = MeatSystem.new()
	add_child(_meat_system)
	# Wire fire_system reference so MeatSystem reads ambient temp and smoke quality
	_meat_system.fire_system = _fire_system


func _load_meats_list() -> void:
	var file = FileAccess.open("res://data/meats.json", FileAccess.READ)
	if file == null:
		push_error("BBQSession: Failed to load meats.json")
		return
	var content = file.get_as_text()
	file.close()
	var json = JSON.new()
	var parse_result = json.parse(content)
	if parse_result != OK:
		push_error("BBQSession: Failed to parse meats.json")
		return
	_meats_data = json.data

	meat_selector.clear()
	for meat in _meats_data:
		meat_selector.add_item(meat["name"], meat_selector.item_count)
		meat_selector.set_item_metadata(meat_selector.item_count - 1, meat["id"])

	if _meats_data.size() > 0:
		meat_selector.select(0)
		_on_meat_selected(0)


## ── Fire Controls ────────────────────────────────────────────────────────────

func _connect_fire_controls() -> void:
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


func _connect_meat_controls() -> void:
	meat_selector.item_selected.connect(_on_meat_selected)
	load_meat_btn.pressed.connect(_on_load_meat)
	wrap_btn.pressed.connect(_on_wrap)
	unwrap_btn.pressed.connect(_on_unwrap)
	rest_btn.pressed.connect(_on_rest)
	new_cook_btn.pressed.connect(_on_new_cook)


func _connect_events() -> void:
	EventBus.on("fire_state_updated", _on_fire_state)
	EventBus.on("fire_lit", _on_fire_lit)
	EventBus.on("fire_out", _on_fire_out)
	EventBus.on("fire_fuel_low", _on_fuel_low)
	EventBus.on("fire_smoke_quality_changed", _on_smoke_changed)

	EventBus.on("meat_state_updated", _on_meat_state)
	EventBus.on("meat_stall_started", _on_meat_stall_started)
	EventBus.on("meat_stall_ended", _on_meat_stall_ended)
	EventBus.on("meat_target_temp_reached", _on_meat_done)
	EventBus.on("meat_wrapped", _on_meat_wrapped)
	EventBus.on("meat_resting", _on_meat_resting)
	EventBus.on("meat_loaded", _on_meat_loaded)


func _connect_tick() -> void:
	TickManager.tick_processed.connect(_on_tick)
	TickManager.unpause()


## ── Tick ─────────────────────────────────────────────────────────────────────

func _on_tick(_delta: float, _tick: int) -> void:
	_update_speed_display()


## ── Fire Handlers ────────────────────────────────────────────────────────────

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
	fire_status_label.text = status


func _on_fire_lit(_data) -> void:
	fire_status_label.text = "🔥 FIRE LIT!"

func _on_fire_out(_data) -> void:
	fire_status_label.text = "❄️ FIRE OUT — Add fuel and relight"

func _on_fuel_low(_data) -> void:
	fire_status_label.text = "⚠️ FUEL LOW — Add more!"

func _on_smoke_changed(data: Dictionary) -> void:
	smoke_quality_bar.value = data.get("quality", 0.5)


func _smoke_quality_to_color(quality: float) -> Color:
	if quality > 0.8:
		return Color(0.85, 0.85, 0.95, 1)
	elif quality > 0.5:
		return Color(0.6, 0.55, 0.5, 1)
	elif quality > 0.2:
		return Color(0.4, 0.3, 0.2, 1)
	return Color(0.2, 0.15, 0.1, 1)


func _update_speed_display() -> void:
	speed_label.text = "Speed: %.1fx" % TickManager.get_speed()


## ── Meat Handlers ────────────────────────────────────────────────────────────

func _on_meat_selected(index: int) -> void:
	if index < 0 or index >= _meats_data.size():
		return
	var meat = _meats_data[index]
	var weight_range = meat.get("weightRangeKg", [1.0, 3.0])
	weight_spin.min_value = weight_range[0]
	weight_spin.max_value = weight_range[1]
	weight_spin.value = (weight_range[0] + weight_range[1]) / 2.0


func _on_load_meat() -> void:
	var idx = meat_selector.selected
	if idx < 0 or idx >= _meats_data.size():
		return
	var meat = _meats_data[idx]
	var meat_id = meat["id"]
	var weight = weight_spin.value

	_meat_system.load_meat(meat_id, weight)
	_current_meat_id = meat_id
	_session_active = true
	_update_meat_ui_visibility(true)
	quality_panel.visible = false

	# Set cooker target temp to match meat's ideal cook temp
	var ideal_cook_temp = meat.get("idealCookTempC", 107)
	_fire_system.set_target_temp(ideal_cook_temp)
	target_temp_spin.value = ideal_cook_temp

	meat_header.text = "🥩 " + meat["name"]
	meat_status_label.text = "Loaded — Light the fire to begin cooking!"


func _on_meat_loaded(data: Dictionary) -> void:
	var meat_name = ""
	for m in _meats_data:
		if m["id"] == data.get("meat_id", ""):
			meat_name = m["name"]
			break
	meat_status_label.text = "✅ %s loaded (%.1f kg)" % [meat_name, data.get("weight", 0)]


func _on_meat_state(data: Dictionary) -> void:
	if not _session_active:
		return

	var internal = data.get("internal_temp", 4.0)
	var target = data.get("target_temp", 95.0)
	var bark = data.get("bark", 0.0)
	var ring = data.get("smoke_ring", 0.0)
	var moisture = data.get("moisture", 1.0)
	var stalling = data.get("is_stalling", false)
	var wrapped = data.get("is_wrapped", false)
	var cook_time = data.get("cook_time", 0.0)

	# Internal temp gauge
	internal_temp_bar.max_value = target * 1.3
	internal_temp_bar.value = internal
	internal_temp_label.text = "%.1f°C" % internal
	target_temp_label.text = "Target: %.0f°C" % target

	# Color the temp bar based on progress
	var temp_pct = internal / target
	if temp_pct >= 1.0:
		internal_temp_bar.self_modulate = Color(0.2, 1.0, 0.2)
	elif temp_pct >= 0.7:
		internal_temp_bar.self_modulate = Color(1.0, 0.8, 0.2)
	elif temp_pct >= 0.3:
		internal_temp_bar.self_modulate = Color(1.0, 0.5, 0.1)
	else:
		internal_temp_bar.self_modulate = Color(0.4, 0.6, 1.0)

	# Stall indicator
	stall_bar.value = 1.0 if stalling else 0.0
	stall_label.text = "⚠️ STALLING!" if stalling else "No stall"

	# Bark bar
	bark_bar.value = bark
	bark_label.text = "Bark: %d%%" % (bark * 100)

	# Smoke ring bar
	smoke_ring_bar.value = ring
	smoke_ring_label.text = "Ring: %d%%" % (ring * 100)

	# Moisture bar
	moisture_bar.value = moisture
	moisture_label.text = "Moisture: %d%%" % (moisture * 100)

	# Cook time
	var hours = int(cook_time) / 60
	var mins = int(cook_time) % 60
	cook_time_label.text = "⏱ Cook time: %dh %02dm" % [hours, mins]

	# Status
	var status = _meat_system.get_cook_status()
	match status:
		"Resting": meat_status_label.text = "🛌 Resting..."
		"Stalling": meat_status_label.text = "⚠️ In the stall — be patient or wrap!"
		"Done": meat_status_label.text = "✅ Done! Check quality score."
		"Cold": meat_status_label.text = "❄️ Meat is cold — waiting for heat..."
		"Low": meat_status_label.text = "🔥 Cooking — temp rising"
		_: meat_status_label.text = "🔥 Cooking..."

	# Update action buttons
	wrap_btn.disabled = wrapped or _meat_system.cook_complete or _meat_system.is_resting
	unwrap_btn.disabled = not wrapped or _meat_system.cook_complete or _meat_system.is_resting
	rest_btn.disabled = not _meat_system.cook_complete or _meat_system.is_resting


func _on_meat_stall_started(_data) -> void:
	meat_status_label.text = "⚠️ STALL HIT! Temp plateaued. Wrap or wait it out."


func _on_meat_stall_ended(_data) -> void:
	meat_status_label.text = "✅ Stall broken! Temp rising again."


func _on_meat_done(data: Dictionary) -> void:
	meat_status_label.text = "✅ Target temp reached! Let it rest or check quality."
	wrap_btn.disabled = true
	unwrap_btn.disabled = true
	rest_btn.disabled = false


func _on_meat_wrapped(data: Dictionary) -> void:
	var wrap_type = data.get("type", "paper")
	meat_status_label.text = "📦 Wrapped in %s!" % wrap_type
	wrap_btn.disabled = true
	unwrap_btn.disabled = false


func _on_meat_resting(data: Dictionary) -> void:
	var rest_time = data.get("rest_time", 30)
	meat_status_label.text = "🛌 Resting for %d min — carryover temp rising..." % rest_time
	wrap_btn.disabled = true
	unwrap_btn.disabled = true
	rest_btn.disabled = true


func _on_wrap() -> void:
	_meat_system.wrap("paper")


func _on_unwrap() -> void:
	_meat_system.unwrap()
	meat_status_label.text = "Unwrapped — finish cooking uncovered."


func _on_rest() -> void:
	_meat_system.start_rest()
	# After rest completes, show quality
	await get_tree().create_timer(2.0).timeout
	_show_quality()


func _show_quality() -> void:
	var score = _meat_system.get_quality_score()
	var grade = _get_grade(score)
	quality_panel.visible = true
	quality_score_label.text = "🏆 Quality Score: %.1f / 100" % score
	quality_detail_label.text = "Grade: %s\n" % grade
	quality_detail_label.text += "Bark: %d%% | Smoke Ring: %d%% | Moisture: %d%%" % [
		_meat_system.bark_formation * 100,
		_meat_system.smoke_ring_depth * 100,
		_meat_system.moisture_content * 100
	]


func _get_grade(score: float) -> String:
	if score >= 90: return "🥇 Competition Grade"
	elif score >= 75: return "🥈 Excellent"
	elif score >= 60: return "🥉 Good"
	elif score >= 40: return "👍 Passable"
	else: return "👎 Needs Work"


func _on_new_cook() -> void:
	_session_active = false
	_current_meat_id = ""
	quality_panel.visible = false
	_update_meat_ui_visibility(false)
	meat_header.text = "🥩 Meat Selection"
	meat_status_label.text = "Select a meat and load it to begin."
	# Reset fire
	_fire_system.fuel_remaining = 0
	_fire_system._is_lit = false
	_fire_system.current_temp = 25.0
	_fire_system.smoke_quality = 0.7
	_fire_system.coal_bed_health = 0.5
	_fire_system.water_level = 0.5
	# Remove and recreate meat system for clean state
	_meat_system.queue_free()
	_meat_system = MeatSystem.new()
	add_child(_meat_system)
	_meat_system.fire_system = _fire_system


func _update_meat_ui_visibility(visible_state: bool) -> void:
	internal_temp_bar.visible = visible_state
	internal_temp_label.visible = visible_state
	target_temp_label.visible = visible_state
	stall_bar.visible = visible_state
	stall_label.visible = visible_state
	bark_bar.visible = visible_state
	bark_label.visible = visible_state
	smoke_ring_bar.visible = visible_state
	smoke_ring_label.visible = visible_state
	moisture_bar.visible = visible_state
	moisture_label.visible = visible_state
	cook_time_label.visible = visible_state
	wrap_btn.visible = visible_state
	unwrap_btn.visible = visible_state
	rest_btn.visible = visible_state