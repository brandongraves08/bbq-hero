extends Control
class_name FirstPlayable

## ── First Playable: End-to-End Brisket Cook ───────────────────────────────────
## A polished walkthrough of the full BBQ cook loop:
##   Setup → Light Fire → Load Meat → Manage → Rest → Score
## Uses Kenney Adventure UI PNG assets for themed panels/buttons/progress bars.
## Wraps FireSystem, MeatSystem, TickManager, EventBus into guided phases.

enum GamePhase { SETUP, COOKING, RESTING, RESULTS }

var _phase: int = GamePhase.SETUP

## Systems
var _fire_system: FireSystem = null
var _meat_system: MeatSystem = null

## Data
var _meats_data: Array = []
var _smokers_data: Array = []
var _selected_smoker_id: String = "rusty_offset"
var _selected_meat_id: String = "packer_brisket"
var _selected_weight: float = 7.0

## UI Node Paths (set at runtime for dynamic scene support)
@onready var setup_panel: Panel = $SetupPanel
@onready var cooking_panel: Control = $CookingPanel
@onready var resting_panel: Control = $RestingPanel
@onready var results_panel: Control = $ResultsPanel

## ── Setup Phase Nodes ─────────────────────────────────────────────────────────
@onready var setup_smoker_buttons: VBoxContainer = $SetupPanel/MarginContainer/VBoxContainer/SmokerSelect/VBoxContainer
@onready var setup_meat_buttons: VBoxContainer = $SetupPanel/MarginContainer/VBoxContainer/MeatSelect/VBoxContainer
@onready var setup_weight_slider: HSlider = $SetupPanel/MarginContainer/VBoxContainer/WeightRow/HSlider
@onready var setup_weight_label: Label = $SetupPanel/MarginContainer/VBoxContainer/WeightRow/WeightLabel
@onready var setup_begin_btn: Button = $SetupPanel/MarginContainer/VBoxContainer/BeginBtn
@onready var setup_title_label: Label = $SetupPanel/MarginContainer/VBoxContainer/TitleLabel
@onready var setup_smoker_desc: Label = $SetupPanel/MarginContainer/VBoxContainer/SmokerSelect/SmokerDesc
@onready var setup_meat_desc: Label = $SetupPanel/MarginContainer/VBoxContainer/MeatSelect/MeatDesc

## ── Cooking Phase Nodes ───────────────────────────────────────────────────────
## Fire panel
@onready var fire_panel: Panel = $CookingPanel/MarginContainer/HBoxContainer/FirePanel
@onready var fire_status_label: Label = $CookingPanel/MarginContainer/HBoxContainer/FirePanel/VBox/StatusLabel
@onready var fire_temp_bar: ProgressBar = $CookingPanel/MarginContainer/HBoxContainer/FirePanel/VBox/TempRow/TempBar
@onready var fire_temp_label: Label = $CookingPanel/MarginContainer/HBoxContainer/FirePanel/VBox/TempRow/TempLabel
@onready var fire_trend_label: Label = $CookingPanel/MarginContainer/HBoxContainer/FirePanel/VBox/TempRow/TrendLabel
@onready var fire_fuel_bar: ProgressBar = $CookingPanel/MarginContainer/HBoxContainer/FirePanel/VBox/FuelRow/FuelBar
@onready var fire_fuel_label: Label = $CookingPanel/MarginContainer/HBoxContainer/FirePanel/VBox/FuelRow/FuelLabel
@onready var fire_smoke_bar: ProgressBar = $CookingPanel/MarginContainer/HBoxContainer/FirePanel/VBox/SmokeRow/SmokeBar
@onready var fire_smoke_label: Label = $CookingPanel/MarginContainer/HBoxContainer/FirePanel/VBox/SmokeRow/SmokeLabel
@onready var fire_coal_bar: ProgressBar = $CookingPanel/MarginContainer/HBoxContainer/FirePanel/VBox/CoalRow/CoalBar
@onready var fire_water_bar: ProgressBar = $CookingPanel/MarginContainer/HBoxContainer/FirePanel/VBox/WaterRow/WaterBar

@onready var fire_intake_slider: HSlider = $CookingPanel/MarginContainer/HBoxContainer/FirePanel/VBox/ControlsRow/IntakeSlider
@onready var fire_exhaust_slider: HSlider = $CookingPanel/MarginContainer/HBoxContainer/FirePanel/VBox/ControlsRow/ExhaustSlider
@onready var fire_target_spin: SpinBox = $CookingPanel/MarginContainer/HBoxContainer/FirePanel/VBox/ControlsRow/TargetSpin

@onready var fire_light_btn: Button = $CookingPanel/MarginContainer/HBoxContainer/FirePanel/VBox/ActionRow/LightBtn
@onready var fire_fuel_btn: Button = $CookingPanel/MarginContainer/HBoxContainer/FirePanel/VBox/ActionRow/FuelBtn
@onready var fire_wood_btn: Button = $CookingPanel/MarginContainer/HBoxContainer/FirePanel/VBox/ActionRow/WoodBtn
@onready var fire_water_btn: Button = $CookingPanel/MarginContainer/HBoxContainer/FirePanel/VBox/ActionRow/WaterBtn

## Speed controls
@onready var speed_label: Label = $CookingPanel/MarginContainer/HBoxContainer/FirePanel/VBox/SpeedRow/SpeedLabel
@onready var speed_1x_btn: Button = $CookingPanel/MarginContainer/HBoxContainer/FirePanel/VBox/SpeedRow/Speed1x
@onready var speed_2x_btn: Button = $CookingPanel/MarginContainer/HBoxContainer/FirePanel/VBox/SpeedRow/Speed2x
@onready var speed_5x_btn: Button = $CookingPanel/MarginContainer/HBoxContainer/FirePanel/VBox/SpeedRow/Speed5x
@onready var speed_10x_btn: Button = $CookingPanel/MarginContainer/HBoxContainer/FirePanel/VBox/SpeedRow/Speed10x

## Meat panel
@onready var meat_panel: Panel = $CookingPanel/MarginContainer/HBoxContainer/MeatPanel
@onready var meat_header_label: Label = $CookingPanel/MarginContainer/HBoxContainer/MeatPanel/VBox/HeaderLabel
@onready var meat_status_label: Label = $CookingPanel/MarginContainer/HBoxContainer/MeatPanel/VBox/StatusLabel
@onready var meat_cook_time: Label = $CookingPanel/MarginContainer/HBoxContainer/MeatPanel/VBox/CookTimeLabel

@onready var meat_temp_bar: ProgressBar = $CookingPanel/MarginContainer/HBoxContainer/MeatPanel/VBox/TempRow/TempBar
@onready var meat_temp_label: Label = $CookingPanel/MarginContainer/HBoxContainer/MeatPanel/VBox/TempRow/TempHeader/TempLabel
@onready var meat_target_label: Label = $CookingPanel/MarginContainer/HBoxContainer/MeatPanel/VBox/TempRow/TempHeader/TargetLabel

@onready var meat_stall_label: Label = $CookingPanel/MarginContainer/HBoxContainer/MeatPanel/VBox/StallIndicator/StallLabel
@onready var meat_stall_bar: ProgressBar = $CookingPanel/MarginContainer/HBoxContainer/MeatPanel/VBox/StallIndicator/StallBar

@onready var meat_bark_bar: ProgressBar = $CookingPanel/MarginContainer/HBoxContainer/MeatPanel/VBox/QualityRow/BarkBar
@onready var meat_bark_label: Label = $CookingPanel/MarginContainer/HBoxContainer/MeatPanel/VBox/QualityRow/BarkLabel
@onready var meat_ring_bar: ProgressBar = $CookingPanel/MarginContainer/HBoxContainer/MeatPanel/VBox/QualityRow/RingBar
@onready var meat_ring_label: Label = $CookingPanel/MarginContainer/HBoxContainer/MeatPanel/VBox/QualityRow/RingLabel
@onready var meat_moisture_bar: ProgressBar = $CookingPanel/MarginContainer/HBoxContainer/MeatPanel/VBox/QualityRow/MoistureBar
@onready var meat_moisture_label: Label = $CookingPanel/MarginContainer/HBoxContainer/MeatPanel/VBox/QualityRow/MoistureLabel

@onready var meat_wrap_btn: Button = $CookingPanel/MarginContainer/HBoxContainer/MeatPanel/VBox/ActionRow/WrapBtn
@onready var meat_unwrap_btn: Button = $CookingPanel/MarginContainer/HBoxContainer/MeatPanel/VBox/ActionRow/UnwrapBtn
@onready var meat_load_btn: Button = $CookingPanel/MarginContainer/HBoxContainer/MeatPanel/VBox/ActionRow/LoadMeatBtn

## ── Resting Phase Nodes ───────────────────────────────────────────────────────
@onready var resting_timer_label: Label = $RestingPanel/MarginContainer/VBox/TimerLabel
@onready var resting_temp_label: Label = $RestingPanel/MarginContainer/VBox/TempLabel
@onready var resting_bar: ProgressBar = $RestingPanel/MarginContainer/VBox/RestBar

## ── Results Phase Nodes ───────────────────────────────────────────────────────
@onready var results_grade_label: Label = $ResultsPanel/MarginContainer/VBox/GradeLabel
@onready var results_score_label: Label = $ResultsPanel/MarginContainer/VBox/ScoreLabel
@onready var results_bark_label: Label = $ResultsPanel/MarginContainer/VBox/Breakdown/BarkValue
@onready var results_ring_label: Label = $ResultsPanel/MarginContainer/VBox/Breakdown/RingValue
@onready var results_moisture_label: Label = $ResultsPanel/MarginContainer/VBox/Breakdown/MoistureValue
@onready var results_temp_label: Label = $ResultsPanel/MarginContainer/VBox/Breakdown/TempValue
@onready var results_time_label: Label = $ResultsPanel/MarginContainer/VBox/Breakdown/TimeValue
@onready var results_feedback_label: Label = $ResultsPanel/MarginContainer/VBox/FeedbackLabel
@onready var results_restart_btn: Button = $ResultsPanel/MarginContainer/VBox/ActionRow/RestartBtn
@onready var results_quit_btn: Button = $ResultsPanel/MarginContainer/VBox/ActionRow/QuitBtn

## ── Event tracking ────────────────────────────────────────────────────────────
var _cook_start_time: float = 0.0
@warning_ignore("unused_private_variable")
var _rest_start_time: float = 0.0
@warning_ignore("unused_private_variable")
var _rest_duration: float = 0.0
var _meat_loaded: bool = false
var _fire_lit: bool = false
var _done_pulled: bool = false

## ── Kenney texture caches ─────────────────────────────────────────────────────
var _tex_panel_brown: Texture2D = preload("res://assets/ui/kenney-adventure/PNG/Default/panel_brown.png")
var _tex_panel_brown_dark: Texture2D = preload("res://assets/ui/kenney-adventure/PNG/Default/panel_brown_dark.png")
var _tex_panel_brown_corners: Texture2D = preload("res://assets/ui/kenney-adventure/PNG/Default/panel_brown_corners_a.png")
## Unused — kept for future panel decor
@warning_ignore("unused_private_variable")
var _tex_progress_blue: Texture2D = preload("res://assets/ui/kenney-adventure/PNG/Default/progress_blue.png")
var _tex_progress_green: Texture2D = preload("res://assets/ui/kenney-adventure/PNG/Default/progress_green.png")
var _tex_progress_red: Texture2D = preload("res://assets/ui/kenney-adventure/PNG/Default/progress_red.png")
var _tex_progress_white: Texture2D = preload("res://assets/ui/kenney-adventure/PNG/Default/progress_white.png")
var _tex_button_brown: Texture2D = preload("res://assets/ui/kenney-adventure/PNG/Default/button_brown.png")
var _tex_button_brown_close: Texture2D = preload("res://assets/ui/kenney-adventure/PNG/Default/button_brown_close.png")
var _tex_banner_hanging: Texture2D = preload("res://assets/ui/kenney-adventure/PNG/Default/banner_hanging.png")
@warning_ignore("unused_private_variable")

# GDScript warnings suppressed for unused texture vars kept for future visual polish

# ──────────────────────────────────────────────────────────────────────────────
# Lifecycle
# ──────────────────────────────────────────────────────────────────────────────

func _ready() -> void:
	_load_data()
	_apply_kenney_theme()
	_show_phase(GamePhase.SETUP)
	_connect_setup_signals()
	_connect_tick()


func _exit_tree() -> void:
	_cleanup_systems()


func _cleanup_systems() -> void:
	if TickManager and not TickManager.is_paused:
		TickManager.pause()
	if _fire_system and is_instance_valid(_fire_system):
		_fire_system.queue_free()
	if _meat_system and is_instance_valid(_meat_system):
		_meat_system.queue_free()


# ──────────────────────────────────────────────────────────────────────────────
# Data Loading
# ──────────────────────────────────────────────────────────────────────────────

func _load_data() -> void:
	# Load meats
	var file = FileAccess.open("res://data/meats.json", FileAccess.READ)
	if file:
		var json = JSON.new()
		if json.parse(file.get_as_text()) == OK:
			_meats_data = json.data
		file.close()

	# Load smokers
	file = FileAccess.open("res://data/smokers.json", FileAccess.READ)
	if file:
		var json = JSON.new()
		if json.parse(file.get_as_text()) == OK:
			_smokers_data = json.data
		file.close()

	if _meats_data.is_empty() or _smokers_data.is_empty():
		push_error("FirstPlayable: Failed to load game data")
		_use_default_data()


func _use_default_data() -> void:
	# Fallback default data if JSONs fail to load
	_meats_data = [{
		"id": "packer_brisket",
		"name": "Packer Brisket (Whole)",
		"weightRangeKg": [5.0, 9.0],
		"idealCookTempC": 107,
		"idealInternalTempC": 95,
		"stallTempC": 68,
		"stallDurationMin": 120,
		"barkPotential": 0.9,
		"moistureSensitivity": 0.6,
		"smokeAbsorption": 0.8,
		"restingMin": 60,
		"yieldPercent": 0.60,
		"difficulty": 5
	}]
	_smokers_data = [{
		"id": "rusty_offset",
		"name": "Rusty Offset Smoker",
		"description": "A beat-up secondhand offset smoker.",
		"tempRangeC": {"min": 90, "max": 160},
		"fuelBurnRate": 1.2,
		"heatStability": 1,
		"smokeIntensity": 4,
		"barkPotential": 4
	}]


# ──────────────────────────────────────────────────────────────────────────────
# Kenney Theme Application
# ──────────────────────────────────────────────────────────────────────────────

func _apply_kenney_theme() -> void:
	# Build a theme using Kenney Adventure PNG textures
	var theme = Theme.new()

	# ── Panel styles ───────────────────────────────────────────────────────────
	var panel_style = StyleBoxTexture.new()
	panel_style.texture = _tex_panel_brown
	panel_style.set_patch_margin(SIDE_LEFT, 12)
	panel_style.set_patch_margin(SIDE_RIGHT, 12)
	panel_style.set_patch_margin(SIDE_TOP, 12)
	panel_style.set_patch_margin(SIDE_BOTTOM, 12)
	panel_style.patch_scale = 2.0
	theme.set_stylebox("panel", "Panel", panel_style)

	var dark_panel_style = StyleBoxTexture.new()
	dark_panel_style.texture = _tex_panel_brown_dark
	dark_panel_style.set_patch_margin(SIDE_LEFT, 12)
	dark_panel_style.set_patch_margin(SIDE_RIGHT, 12)
	dark_panel_style.set_patch_margin(SIDE_TOP, 12)
	dark_panel_style.set_patch_margin(SIDE_BOTTOM, 12)
	theme.set_stylebox("panel", "Panel_dark", dark_panel_style)
	# Also set as default for any Panel
	theme.set_stylebox("panel", "", panel_style)

	# ── Button styles ──────────────────────────────────────────────────────────
	var btn_style = StyleBoxTexture.new()
	btn_style.texture = _tex_button_brown
	btn_style.set_patch_margin(SIDE_LEFT, 8)
	btn_style.set_patch_margin(SIDE_RIGHT, 8)
	btn_style.set_patch_margin(SIDE_TOP, 8)
	btn_style.set_patch_margin(SIDE_BOTTOM, 8)
	theme.set_stylebox("normal", "Button", btn_style)
	theme.set_stylebox("hover", "Button", btn_style)

	var btn_pressed_style = StyleBoxTexture.new()
	btn_pressed_style.texture = _tex_button_brown_close
	btn_pressed_style.set_patch_margin(SIDE_LEFT, 8)
	btn_pressed_style.set_patch_margin(SIDE_RIGHT, 8)
	btn_pressed_style.set_patch_margin(SIDE_TOP, 8)
	btn_pressed_style.set_patch_margin(SIDE_BOTTOM, 8)
	theme.set_stylebox("pressed", "Button", btn_pressed_style)

	theme.default_font = ThemeDB.fallback_font
	theme.default_font_size = 14

	# ── Progress Bar styles ────────────────────────────────────────────────────
	var bg_style = StyleBoxEmpty.new()
	theme.set_stylebox("background", "ProgressBar", bg_style)

	var fill_blue = StyleBoxTexture.new()
	fill_blue.texture = _tex_progress_blue
	fill_blue.set_patch_margin(SIDE_LEFT, 4)
	fill_blue.set_patch_margin(SIDE_RIGHT, 4)
	fill_blue.set_patch_margin(SIDE_TOP, 4)
	fill_blue.set_patch_margin(SIDE_BOTTOM, 4)
	theme.set_stylebox("fill", "ProgressBar", fill_blue)

	# ── HSlider ────────────────────────────────────────────────────────────────
	var slider_bg = StyleBoxTexture.new()
	slider_bg.texture = _tex_progress_white
	slider_bg.set_patch_margin(SIDE_LEFT, 4)
	slider_bg.set_patch_margin(SIDE_RIGHT, 4)
	slider_bg.set_patch_margin(SIDE_TOP, 4)
	slider_bg.set_patch_margin(SIDE_BOTTOM, 4)
	theme.set_stylebox("slider", "HSlider", slider_bg)

	var grabber_style = StyleBoxTexture.new()
	grabber_style.texture = _tex_button_brown
	grabber_style.set_patch_margin(SIDE_LEFT, 4)
	grabber_style.set_patch_margin(SIDE_RIGHT, 4)
	grabber_style.set_patch_margin(SIDE_TOP, 4)
	grabber_style.set_patch_margin(SIDE_BOTTOM, 4)
	theme.set_stylebox("grabber", "HSlider", grabber_style)

	theme.theme_type_variation("Panel_dark", "Panel")
	theme.theme_type_variation("Panel_gold", "Panel")

	theme.set_color("font_color", "Label", Color(0.95, 0.87, 0.7))
	theme.set_color("font_color", "Button", Color(1, 1, 1))
	theme.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.5))
	theme.set_constant("shadow_offset", "Label", 1)

	# Apply theme to self and all children
	self.theme = theme


# ──────────────────────────────────────────────────────────────────────────────
# Phase Management
# ──────────────────────────────────────────────────────────────────────────────

func _show_phase(phase: int) -> void:
	_phase = phase
	setup_panel.visible = phase == GamePhase.SETUP
	cooking_panel.visible = phase == GamePhase.COOKING
	resting_panel.visible = phase == GamePhase.RESTING
	results_panel.visible = phase == GamePhase.RESULTS

	match phase:
		GamePhase.SETUP:
			_populate_setup()
		GamePhase.COOKING:
			_init_cooking()
		GamePhase.RESTING:
			_init_resting()
		GamePhase.RESULTS:
			_show_results()


# ──────────────────────────────────────────────────────────────────────────────
# SETUP PHASE
# ──────────────────────────────────────────────────────────────────────────────

func _populate_setup() -> void:
	setup_title_label.text = "🔥 FIRST PLAYABLE: BRISKET COOK\n🏆 Smoke & Fire: BBQ Hero"
	_populate_smoker_buttons()
	_populate_meat_buttons()

	# Weight slider — disconnect first to avoid duplicates on restart
	if setup_weight_slider.value_changed.is_connected(_on_setup_weight_changed):
		setup_weight_slider.value_changed.disconnect(_on_setup_weight_changed)
	if setup_begin_btn.pressed.is_connected(_on_setup_begin):
		setup_begin_btn.pressed.disconnect(_on_setup_begin)
	_update_weight_display()
	setup_weight_slider.value_changed.connect(_on_setup_weight_changed)
	setup_begin_btn.pressed.connect(_on_setup_begin)


func _populate_smoker_buttons() -> void:
	# Clear existing
	for child in setup_smoker_buttons.get_children():
		child.queue_free()

	for smoker in _smokers_data:
		var smoker_id = smoker.get("id", "")
		var smoker_name = smoker.get("name", "Unknown Smoker")
		var smoker_desc = smoker.get("description", "")
		var tier = smoker.get("tier", 1)

		var btn = Button.new()
		btn.text = "%s  (Tier %d)" % [smoker_name, tier]
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		btn.custom_minimum_size = Vector2(300, 36)
		var tid = smoker_id
		var desc = smoker_desc
		btn.pressed.connect(func():
			_selected_smoker_id = tid
			setup_smoker_desc.text = desc
			_highlight_selected_button(setup_smoker_buttons, btn)
		)
		setup_smoker_buttons.add_child(btn)

	# Select first by default
	var first_btn = setup_smoker_buttons.get_child(0)
	if first_btn:
		_selected_smoker_id = _smokers_data[0].get("id", "rusty_offset")
		setup_smoker_desc.text = _smokers_data[0].get("description", "")
		_highlight_selected_button(setup_smoker_buttons, first_btn)


func _populate_meat_buttons() -> void:
	for child in setup_meat_buttons.get_children():
		child.queue_free()

	# Filter to beef/brisket options primarily
	for meat in _meats_data:
		var meat_id = meat.get("id", "")
		var meat_name = meat.get("name", "Unknown Meat")
		var diff = meat.get("difficulty", 1)
		var stall = meat.get("stallDurationMin", 60)

		# Show brisket first, then other meats
		var btn = Button.new()
		var label = "%s  (Difficulty: %d)" % [meat_name, diff]
		if meat.get("category", "") == "brisket":
			label = "★ " + label
		btn.text = label
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		btn.custom_minimum_size = Vector2(340, 36)

		var mid = meat_id
		var desc = "Category: %s | Stall: %d min | Weight: %.0f-%.0f kg" % [
			meat.get("category", "?"),
			stall,
			meat.get("weightRangeKg", [1, 5])[0],
			meat.get("weightRangeKg", [1, 5])[1]
		]
		var weight_range = meat.get("weightRangeKg", [1.0, 9.0])
		btn.pressed.connect(func():
			_selected_meat_id = mid
			setup_meat_desc.text = desc
			setup_weight_slider.min_value = weight_range[0]
			setup_weight_slider.max_value = weight_range[1]
			setup_weight_slider.value = (weight_range[0] + weight_range[1]) / 2.0
			_selected_weight = setup_weight_slider.value
			_update_weight_display()
			_highlight_selected_button(setup_meat_buttons, btn)
		)
		setup_meat_buttons.add_child(btn)

	# Select first by default
	var first_btn = setup_meat_buttons.get_child(0)
	if first_btn and _meats_data.size() > 0:
		_selected_meat_id = _meats_data[0].get("id", "packer_brisket")
		var w = _meats_data[0].get("weightRangeKg", [5.0, 9.0])
		setup_weight_slider.min_value = w[0]
		setup_weight_slider.max_value = w[1]
		setup_weight_slider.value = (w[0] + w[1]) / 2.0
		_selected_weight = setup_weight_slider.value
		_update_weight_display()
		setup_meat_desc.text = "Category: %s | Stall: %d min | Weight: %.0f-%.0f kg" % [
			_meats_data[0].get("category", "?"),
			_meats_data[0].get("stallDurationMin", 60),
			w[0], w[1]
		]
		_highlight_selected_button(setup_meat_buttons, first_btn)


func _highlight_selected_button(container: VBoxContainer, selected: Button) -> void:
	for child in container.get_children():
		if child is Button:
			child.self_modulate = Color(1, 1, 0.7) if child == selected else Color(0.7, 0.7, 0.7)
			child.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

func _on_setup_weight_changed(value: float) -> void:
	_selected_weight = round(value * 10.0) / 10.0
	_update_weight_display()

func _update_weight_display() -> void:
	setup_weight_label.text = "Weight: %.1f kg" % _selected_weight


func _get_selected_meat_data() -> Dictionary:
	for m in _meats_data:
		if m.get("id", "") == _selected_meat_id:
			return m
	return _meats_data[0] if _meats_data.size() > 0 else {}

func _get_selected_smoker_data() -> Dictionary:
	for s in _smokers_data:
		if s.get("id", "") == _selected_smoker_id:
			return s
	return _smokers_data[0] if _smokers_data.size() > 0 else {}


# ──────────────────────────────────────────────────────────────────────────────
# BEGIN COOK — Transition Setup → Cooking
# ──────────────────────────────────────────────────────────────────────────────

func _on_setup_begin() -> void:
	_meat_loaded = false
	_fire_lit = false
	_done_pulled = false

	# Create fire system
	_fire_system = FireSystem.new()
	var cooker_data = _get_selected_smoker_data()
	_fire_system.configure(cooker_data)
	add_child(_fire_system)

	# Create meat system
	_meat_system = MeatSystem.new()
	_meat_system.fire_system = _fire_system
	add_child(_meat_system)

	# Connect EventBus
	_connect_cooking_events()

	# Setup cooking panel UI
	_configure_cooking_ui()

	# Show cooking phase
	_show_phase(GamePhase.COOKING)
	setup_panel.visible = false

	# Start the simulation unpaused
	TickManager.unpause()


# ──────────────────────────────────────────────────────────────────────────────
# COOKING PHASE — Connect Events
# ──────────────────────────────────────────────────────────────────────────────

func _connect_cooking_events() -> void:
	EventBus.on("fire_state_updated", _on_fire_state_updated)
	EventBus.on("meat_state_updated", _on_meat_state_updated)
	EventBus.on("meat_stall_started", _on_stall_started)
	EventBus.on("meat_stall_ended", _on_stall_ended)
	EventBus.on("meat_target_temp_reached", _on_meat_done)
	EventBus.on("fire_lit", _on_fire_lit)
	EventBus.on("fire_out", _on_fire_out)


func _configure_cooking_ui() -> void:
	# Fire controls
	fire_intake_slider.value_changed.connect(_on_intake_changed)
	fire_exhaust_slider.value_changed.connect(_on_exhaust_changed)
	fire_target_spin.value_changed.connect(_on_target_changed)
	fire_light_btn.pressed.connect(_on_light_fire)
	fire_fuel_btn.pressed.connect(_on_add_fuel)
	fire_wood_btn.pressed.connect(_on_add_wood)
	fire_water_btn.pressed.connect(_on_add_water)

	# Meat controls
	meat_load_btn.pressed.connect(_on_load_meat)
	meat_wrap_btn.pressed.connect(_on_wrap_meat)
	meat_unwrap_btn.pressed.connect(_on_unwrap_meat)

	# Speed controls
	speed_1x_btn.pressed.connect(func(): TickManager.set_speed(1.0))
	speed_2x_btn.pressed.connect(func(): TickManager.set_speed(2.0))
	speed_5x_btn.pressed.connect(func(): TickManager.set_speed(5.0))
	speed_10x_btn.pressed.connect(func(): TickManager.set_speed(10.0))

	# Configure fire UI
	var cooker = _get_selected_smoker_data()
	var tr = cooker.get("tempRangeC", {"min": 90, "max": 160})
	fire_target_spin.min_value = tr.get("min", 90)
	fire_target_spin.max_value = tr.get("max", 160)
	fire_target_spin.value = (tr.get("min", 90) + tr.get("max", 160)) / 2.0
	fire_light_btn.disabled = false

	# Configure meat panel
	var meat_data = _get_selected_meat_data()
	meat_header_label.text = "🥩 %s  (%.1f kg)" % [meat_data.get("name", "Brisket"), _selected_weight]
	meat_status_label.text = "🔥 Light the fire first, then load the meat!"
	meat_target_label.text = "Target: %.0f°C" % meat_data.get("idealInternalTempC", 95)

	# Buttons start disabled
	meat_load_btn.disabled = true
	meat_wrap_btn.disabled = true
	meat_unwrap_btn.disabled = true
	_meat_loaded = false

	# Hide meat quality bars until loaded
	meat_bark_bar.visible = false
	meat_bark_label.visible = false
	meat_ring_bar.visible = false
	meat_ring_label.visible = false
	meat_moisture_bar.visible = false
	meat_moisture_label.visible = false
	meat_stall_label.visible = false
	meat_stall_bar.visible = false

	# Initial state
	fire_status_label.text = "❄️ COLD — Light the fire!"
	fire_intake_slider.value = 50
	fire_exhaust_slider.value = 70


func _connect_setup_signals() -> void:
	pass


# ──────────────────────────────────────────────────────────────────────────────
# COOKING — FIRE HANDLERS
# ──────────────────────────────────────────────────────────────────────────────

func _on_light_fire() -> void:
	if _fire_system:
		_fire_system.light_fire()
		_fire_system.add_fuel("lump_oak", 3.0)
		fire_light_btn.disabled = true
		meat_load_btn.disabled = false
		fire_status_label.text = "🔥 Fire lit! Add fuel to maintain temp."


func _on_fire_lit(_data: Dictionary) -> void:
	_fire_lit = true
	if not fire_light_btn.disabled:
		fire_light_btn.disabled = true
		meat_load_btn.disabled = false


func _on_fire_out(_data: Dictionary) -> void:
	fire_status_label.text = "❄️ FIRE OUT — Add fuel to relight!"
	fire_light_btn.disabled = false
	meat_load_btn.disabled = true
	_fire_lit = false


func _on_add_fuel() -> void:
	if _fire_system:
		_fire_system.add_fuel("lump_oak", 2.0)
		fire_status_label.text = "⛽ Fuel added! (%.1f kg)" % _fire_system.fuel_remaining

func _on_add_wood() -> void:
	if _fire_system:
		_fire_system.add_wood_split()
		fire_status_label.text = "🪵 Wood split added! Temp boost +15°C"

func _on_add_water() -> void:
	if _fire_system:
		_fire_system.add_water(0.3)
		fire_status_label.text = "💧 Water pan refilled"

func _on_intake_changed(val: float) -> void:
	if _fire_system:
		_fire_system.set_intake(val / 100.0)

func _on_exhaust_changed(val: float) -> void:
	if _fire_system:
		_fire_system.set_exhaust(val / 100.0)

func _on_target_changed(val: float) -> void:
	if _fire_system:
		_fire_system.set_target_temp(val)


func _on_fire_state_updated(data: Dictionary) -> void:
	var temp = data.get("temp", 25.0)
	var fuel = data.get("fuel_remaining", 0.0)
	var smoke = data.get("smoke_quality", 0.5)
	var coal = data.get("coal_bed", 0.5)
	var water = data.get("water_level", 0.5)

	fire_temp_bar.max_value = 180
	fire_temp_bar.value = temp
	fire_temp_label.text = "%d°C" % temp

	var trend = _fire_system.get_temp_trend() if _fire_system else "stable"
	fire_trend_label.text = trend.capitalize()
	match trend:
		"rising": fire_trend_label.self_modulate = Color(0.3, 1.0, 0.3)
		"falling": fire_trend_label.self_modulate = Color(1.0, 0.3, 0.3)
		_: fire_trend_label.self_modulate = Color(0.95, 0.87, 0.5)

	fire_fuel_bar.max_value = 10.0
	fire_fuel_bar.value = fuel
	fire_fuel_label.text = "Fuel: %.1f kg" % fuel

	var smoke_pct = smoke * 100
	fire_smoke_bar.value = smoke
	fire_smoke_label.text = "Smoke: %d%%" % smoke_pct

	var smoke_color = Color(0.8, 0.8, 0.9)
	if smoke < 0.5:
		smoke_color = Color(0.4, 0.3, 0.2)
	elif smoke < 0.2:
		smoke_color = Color(0.2, 0.15, 0.1)
	fire_smoke_bar.self_modulate = smoke_color

	fire_coal_bar.value = coal
	fire_water_bar.value = water

	# Fire danger zone warning
	if _fire_lit and fuel <= 0.5 and _fire_system:
		fire_status_label.text = "⚠️ FUEL CRITICAL — Add more or fire will die!"


# ──────────────────────────────────────────────────────────────────────────────
# COOKING — MEAT HANDLERS
# ──────────────────────────────────────────────────────────────────────────────

func _on_load_meat() -> void:
	if not _fire_system or not _meat_system:
		return
	_meat_system.load_meat(_selected_meat_id, _selected_weight)
	_meat_loaded = true
	meat_load_btn.disabled = true
	meat_status_label.text = "✅ Meat loaded! Managing the cook..."
	_cook_start_time = _meat_system.cook_time

	# Show quality meters
	meat_bark_bar.visible = true
	meat_bark_label.visible = true
	meat_ring_bar.visible = true
	meat_ring_label.visible = true
	meat_moisture_bar.visible = true
	meat_moisture_label.visible = true
	meat_stall_label.visible = true
	meat_stall_bar.visible = true

	# Set cooker target temp to match meat's ideal
	var meat_data = _get_selected_meat_data()
	var ideal = meat_data.get("idealCookTempC", 107)
	if _fire_system:
		_fire_system.set_target_temp(ideal)
	fire_target_spin.value = ideal


func _on_meat_state_updated(data: Dictionary) -> void:
	if not _meat_loaded and not data.get("is_resting", false):
		return

	var internal = data.get("internal_temp", 4.0)
	var target = data.get("target_temp", 95.0)
	var bark = data.get("bark", 0.0)
	var ring = data.get("smoke_ring", 0.0)
	var moisture = data.get("moisture", 1.0)
	var stalling = data.get("is_stalling", false)
	var wrapped = data.get("is_wrapped", false)
	var cook_time_min = data.get("cook_time", 0.0)

	# Temp display
	meat_temp_bar.max_value = target * 1.3
	meat_temp_bar.value = internal

	var temp_pct = internal / target if target > 0 else 0.0
	if temp_pct >= 1.0:
		meat_temp_bar.self_modulate = Color(0.2, 1.0, 0.2)
	elif temp_pct >= 0.7:
		meat_temp_bar.self_modulate = Color(1.0, 0.8, 0.2)
	elif temp_pct >= 0.3:
		meat_temp_bar.self_modulate = Color(1.0, 0.5, 0.1)
	else:
		meat_temp_bar.self_modulate = Color(0.4, 0.6, 1.0)

	meat_temp_label.text = "%.1f°C" % internal
	meat_target_label.text = "Target: %.0f°C" % target

	# Stall
	if stalling:
		meat_stall_label.text = "⚠️ STALL ACTIVE — Temp plateaued! Wrap or wait."
		meat_stall_bar.value = _meat_system.get_stall_progress() if _meat_system else 0.0
	else:
		meat_stall_label.text = "Temp rising normally"
		meat_stall_bar.value = 0.0

	# Bark
	meat_bark_bar.value = bark
	meat_bark_label.text = "Bark: %d%%" % (bark * 100)

	# Smoke ring
	meat_ring_bar.value = ring
	meat_ring_label.text = "Ring: %d%%" % (ring * 100)

	# Moisture
	meat_moisture_bar.value = moisture
	meat_moisture_label.text = "Moisture: %d%%" % (moisture * 100)

	# Cook time
	var h = int(cook_time_min) / 60
	var m = int(cook_time_min) % 60
	meat_cook_time.text = "⏱ %dh %02dm" % [h, m]

	# Status
	var status = _meat_system.get_cook_status() if _meat_system else "Cooking"
	var status_text = ""
	match status:
		"Cooking": status_text = "🔥 Cooking — temp rising"
		"Stalling": status_text = "⚠️ In the stall — wrap or wait"
		"Done": status_text = "✅ Hit target! Let rest or check quality"
		"Resting": status_text = "🛌 Resting..."
		"Low": status_text = "🔥 Temp climbing"
		"Cold": status_text = "❄️ Meat still cold"
		_: status_text = "🔥 Cooking..."
	meat_status_label.text = status_text

	# Action buttons
	if _meat_system:
		meat_wrap_btn.disabled = wrapped or _meat_system.cook_complete or _meat_system.is_resting
		meat_unwrap_btn.disabled = not wrapped or _meat_system.cook_complete or _meat_system.is_resting

	# Show rest button when done
	if _meat_system and _meat_system.cook_complete and not _meat_system.is_resting:
		meat_status_label.text = "✅ Done! Hit the wrap button to rest the meat."


func _on_stall_started(_data: Dictionary) -> void:
	meat_status_label.text = "⚠️ STALL HIT! Temp stuck around 68°C. Wrap in paper or wait it out."


func _on_stall_ended(_data: Dictionary) -> void:
	meat_status_label.text = "✅ Stall broken! Temp climbing again. Almost there!"


func _on_meat_done(_data: Dictionary) -> void:
	_done_pulled = true
	meat_status_label.text = "🎯 Target internal temp reached! Let the meat rest."
	meat_wrap_btn.disabled = true
	meat_unwrap_btn.disabled = true
	# Show "rest" option
	EventBus.emit("meat_ready_to_rest", {})


func _on_wrap_meat() -> void:
	if _meat_system:
		_meat_system.wrap("paper")
		meat_status_label.text = "📦 Wrapped in pink butcher paper! Temp will accelerate."
		meat_wrap_btn.disabled = true
		meat_unwrap_btn.disabled = false


func _on_unwrap_meat() -> void:
	if _meat_system:
		_meat_system.unwrap()
		meat_status_label.text = "📄 Unwrapped — finish cooking exposed for bark."
		meat_wrap_btn.disabled = false
		meat_unwrap_btn.disabled = true


# ──────────────────────────────────────────────────────────────────────────────
# COOKING → REST TRANSITION (manual via special button when done)
# ──────────────────────────────────────────────────────────────────────────────

func _check_rest_transition() -> void:
	if _done_pulled and _meat_system and not _meat_system.is_resting:
		# Auto-transition to rest after a brief delay when meat is done
		# (User clicked "rest" trigger)
		_start_rest()


func _on_rest_meat() -> void:
	_start_rest()


func _start_rest() -> void:
	if not _meat_system or _meat_system.is_resting:
		return
	_meat_system.start_rest()
	var rest_min = _meat_system.meat_data.get("restingMin", 60)
	_rest_duration = rest_min
	_rest_start_time = TickManager.sim_time_minutes

	# Use the meat_panel wrap/unwrap buttons — convert wrap to "Rest" and unwrap to "Done"
	meat_wrap_btn.text = "🛌 Resting..."
	meat_wrap_btn.disabled = true
	meat_unwrap_btn.text = "Quick Rest (30m)"
	meat_unwrap_btn.disabled = false
	meat_unwrap_btn.pressed.disconnect(_on_unwrap_meat)
	meat_unwrap_btn.pressed.connect(_on_quick_rest)

	meat_status_label.text = "🛌 Meat resting! Carryover heat will raise temp ~4°C."


func _on_quick_rest() -> void:
	# Skip full rest - go straight to results after a minimal rest
	await get_tree().create_timer(2.0).timeout
	_show_phase(GamePhase.RESTING)


# ──────────────────────────────────────────────────────────────────────────────
# TICK CALLBACK — Check rest completion
# ──────────────────────────────────────────────────────────────────────────────

func _connect_tick() -> void:
	TickManager.tick_processed.connect(_on_global_tick)


func _on_global_tick(delta_minutes: float, _tick: int) -> void:
	match _phase:
		GamePhase.COOKING:
			_update_speed_display()
		GamePhase.RESTING:
			# Deduct rest time using sim minutes, not wall clock
			if _meat_system and _meat_system.is_resting:
				_meat_system.rest_time_left -= delta_minutes
				_update_resting()
				if _meat_system.rest_time_left <= 0:
					_meat_system.rest_time_left = 0
					_show_phase(GamePhase.RESULTS)


func _update_speed_display() -> void:
	speed_label.text = "Speed: %.1fx" % TickManager.get_speed()


# ──────────────────────────────────────────────────────────────────────────────
# RESTING PHASE
# ──────────────────────────────────────────────────────────────────────────────

func _init_resting() -> void:
	resting_panel.visible = true
	cooking_panel.visible = false
	TickManager.set_speed(5.0)

	var meat_data = _get_selected_meat_data()
	var rest_min = meat_data.get("restingMin", 60) if _meat_system else 60
	_rest_duration = rest_min

	resting_bar.max_value = rest_min
	resting_bar.value = rest_min

	var temp_after_carryover = _meat_system.internal_temp if _meat_system else 0.0
	resting_temp_label.text = "Internal Temp: %.1f°C  (+3-4°C carryover)" % temp_after_carryover
	resting_timer_label.text = "Resting: %d min remaining" % rest_min


func _update_resting() -> void:
	if not _meat_system:
		return
	var remaining = _meat_system.rest_time_left
	resting_bar.value = remaining
	resting_timer_label.text = "Resting: %d min remaining" % int(ceil(remaining))
	resting_temp_label.text = "Internal Temp: %.1f°C" % _meat_system.internal_temp


# ──────────────────────────────────────────────────────────────────────────────
# RESULTS PHASE
# ──────────────────────────────────────────────────────────────────────────────

func _show_results() -> void:
	_show_phase(GamePhase.RESULTS)

	if not _meat_system:
		results_score_label.text = "Error: No meat data"
		return

	var raw_score = _meat_system.get_quality_score()
	var bark = _meat_system.bark_formation * 100.0
	var ring = _meat_system.smoke_ring_depth * 100.0
	var moisture = _meat_system.moisture_content * 100.0
	var temp_achieved = _meat_system.internal_temp
	var target_temp = _meat_system.target_internal_temp
	var temp_accuracy = clamp(100.0 - abs(temp_achieved - target_temp) * 2.0, 0.0, 100.0)
	var cook_time = _meat_system.cook_time

	# Compute weighted score for display
	var final_score = clamp(raw_score, 0.0, 100.0)

	var grade = _get_grade_text(final_score)
	var grade_icon = _get_grade_icon(final_score)

	results_grade_label.text = "%s  %s" % [grade_icon, grade]
	results_score_label.text = "🏆 TOTAL SCORE: %.1f / 100" % final_score

	results_bark_label.text = "%d%%" % bark
	results_ring_label.text = "%d%%" % ring
	results_moisture_label.text = "%d%%" % moisture
	results_temp_label.text = "%.1f°C / %.0f°C  (Accuracy: %.0f%%)" % [temp_achieved, target_temp, temp_accuracy]
	var el_h = int(cook_time) / 60
	var el_m = int(cook_time) % 60
	results_time_label.text = "%dh %02dm" % [el_h, el_m]

	# Feedback text
	var feedback = _get_feedback(final_score, bark, ring, moisture, temp_accuracy)
	results_feedback_label.text = feedback

	# Buttons
	results_restart_btn.pressed.connect(_on_restart)
	results_quit_btn.pressed.connect(_on_quit)


func _get_grade_text(score: float) -> String:
	if score >= 90: return "Competition Grade"
	elif score >= 75: return "Excellent"
	elif score >= 60: return "Good"
	elif score >= 40: return "Passable"
	else: return "Needs Work"

func _get_grade_icon(score: float) -> String:
	if score >= 90: return "🥇"
	elif score >= 75: return "🥈"
	elif score >= 60: return "🥉"
	elif score >= 40: return "👍"
	else: return "👎"

func _get_feedback(score: float, bark: float, ring: float, moisture: float, temp_acc: float) -> String:
	var lines = []
	if score >= 80:
		lines.append("🔥 OUTSTANDING COOK! You've got the touch of a true pitmaster!")
	elif score >= 60:
		lines.append("👍 Solid cook! A few tweaks and you'll be competition-ready.")
	else:
		lines.append("📖 Every cook is a lesson. Try again and focus on fire management.")

	if bark < 40:
		lines.append("💡 Tip: Better bark comes from consistent smoke and letting the rub set.")
	if moisture < 40:
		lines.append("💡 Tip: Spritz or wrap sooner to lock in moisture.")
	if ring < 30:
		lines.append("💡 Tip: More smoke early in the cook builds a better smoke ring.")
	if temp_acc < 70:
		lines.append("💡 Tip: Pulling at the right temp is critical. Watch your thermometer!")

	return "\n".join(lines)


func _on_restart() -> void:
	# Full reset
	TickManager.pause()
	_cleanup_systems()
	_phase = -1

	# Reset meat system
	_meat_system = null
	_fire_system = null
	_meat_loaded = false
	_fire_lit = false
	_done_pulled = false

	# Reset cooking panel buttons text
	meat_wrap_btn.text = "📦 Wrap (Paper)"
	meat_unwrap_btn.text = "📄 Unwrap"
	meat_load_btn.text = "Load Meat"

	# Disconnect all cooking panel signals to avoid duplicates
	for conn in meat_unwrap_btn.pressed.get_connections():
		meat_unwrap_btn.pressed.disconnect(conn.callable)
	for conn in meat_load_btn.pressed.get_connections():
		meat_load_btn.pressed.disconnect(conn.callable)
	for conn in meat_wrap_btn.pressed.get_connections():
		meat_wrap_btn.pressed.disconnect(conn.callable)
	for conn in fire_light_btn.pressed.get_connections():
		fire_light_btn.pressed.disconnect(conn.callable)
	for conn in fire_fuel_btn.pressed.get_connections():
		fire_fuel_btn.pressed.disconnect(conn.callable)
	for conn in fire_wood_btn.pressed.get_connections():
		fire_wood_btn.pressed.disconnect(conn.callable)
	for conn in fire_water_btn.pressed.get_connections():
		fire_water_btn.pressed.disconnect(conn.callable)
	for conn in fire_intake_slider.value_changed.get_connections():
		fire_intake_slider.value_changed.disconnect(conn.callable)
	for conn in fire_exhaust_slider.value_changed.get_connections():
		fire_exhaust_slider.value_changed.disconnect(conn.callable)
	for conn in fire_target_spin.value_changed.get_connections():
		fire_target_spin.value_changed.disconnect(conn.callable)
	for conn in speed_1x_btn.pressed.get_connections():
		speed_1x_btn.pressed.disconnect(conn.callable)
	for conn in speed_2x_btn.pressed.get_connections():
		speed_2x_btn.pressed.disconnect(conn.callable)
	for conn in speed_5x_btn.pressed.get_connections():
		speed_5x_btn.pressed.disconnect(conn.callable)
	for conn in speed_10x_btn.pressed.get_connections():
		speed_10x_btn.pressed.disconnect(conn.callable)
	# Also disconnect results buttons
	for conn in results_restart_btn.pressed.get_connections():
		results_restart_btn.pressed.disconnect(conn.callable)
	for conn in results_quit_btn.pressed.get_connections():
		results_quit_btn.pressed.disconnect(conn.callable)
	# Disconnect EventBus listeners
	EventBus.off("fire_state_updated", _on_fire_state_updated)
	EventBus.off("meat_state_updated", _on_meat_state_updated)
	EventBus.off("meat_stall_started", _on_stall_started)
	EventBus.off("meat_stall_ended", _on_stall_ended)
	EventBus.off("meat_target_temp_reached", _on_meat_done)
	EventBus.off("fire_lit", _on_fire_lit)
	EventBus.off("fire_out", _on_fire_out)

	# Reset fire
	fire_light_btn.disabled = false
	meat_load_btn.disabled = true
	meat_wrap_btn.disabled = true
	meat_unwrap_btn.disabled = true
	meat_temp_bar.value = 0
	meat_temp_label.text = "—°C"
	meat_cook_time.text = "⏱ 0h 00m"

	# Show setup again
	_show_phase(GamePhase.SETUP)


func _on_quit() -> void:
	get_tree().quit()