extends Control
class_name CookVisuals

## ── Visual Cook Feedback ──────────────────────────────────────────────────────
## Adds real visual feedback during the cook: temperature gauge, smoke quality
## indicator, meat visual progression, fire visualization, and fuel level bar.
##
## Attach this as a child of the cooking panel to overlay visual elements.

## Reference to the meat sprite/icon for color modulation
var meat_sprite: TextureRect = null
## Reference to the thermometer widget
var thermometer: MeatThermometer = null

## ── Node References (set by parent) ──────────────────────────────────────────
## Smoke quality indicator bar
var smoke_bar: ProgressBar = null
## Temp gauge arc/progress bar (fire temp)
var fire_temp_gauge: ProgressBar = null
## Meat temp gauge
var meat_temp_gauge: ProgressBar = null
## Fuel level bar
var fuel_bar: ProgressBar = null
## Moisture bar
var moisture_bar: ProgressBar = null

## ── Labels ───────────────────────────────────────────────────────────────────
var cook_stage_label: Label = null
var meat_progress_label: Label = null
var bark_progress_label: Label = null
var ring_progress_label: Label = null

## ── Meat progression data ────────────────────────────────────────────────────
## Stages: raw → seasoned → cooking → bark_forming → done → resting
enum MeatStage { RAW, SEASONED, COOKING, BARK_FORMING, DONE, RESTING }
var current_stage: int = MeatStage.RAW
var cook_pct: float = 0.0
var _meat_data: Dictionary = {}

## Stage colors for color modulation
const STAGE_COLORS: Dictionary = {
	MeatStage.RAW: Color(0.85, 0.4, 0.3),
	MeatStage.SEASONED: Color(0.7, 0.35, 0.25),
	MeatStage.COOKING: Color(0.55, 0.3, 0.2),
	MeatStage.BARK_FORMING: Color(0.3, 0.18, 0.1),
	MeatStage.DONE: Color(0.2, 0.12, 0.08),
	MeatStage.RESTING: Color(0.25, 0.15, 0.1)
}

## Stage labels for display
const STAGE_LABELS: Dictionary = {
	MeatStage.RAW: "🥩 Raw",
	MeatStage.SEASONED: "🧂 Seasoned",
	MeatStage.COOKING: "🔥 Cooking",
	MeatStage.BARK_FORMING: "🌋 Bark Forming",
	MeatStage.DONE: "✅ Done",
	MeatStage.RESTING: "🛌 Resting"
}

## ── Fire visualization ───────────────────────────────────────────────────────
var fire_flame_nodes: Array = []
var fire_intensity: float = 0.0

## Smoke quality display data
var smoke_quality: float = 0.5
var smoke_color: Color = Color(0.7, 0.7, 0.8)
var is_clean_smoke: bool = true

## ── Initialization ───────────────────────────────────────────────────────────

func _ready() -> void:
	_setup_fire_flames()


func _setup_fire_flames() -> void:
	# Create placeholder flame sprite nodes with color rects
	for i in range(3):
		var flame = ColorRect.new()
		flame.size = Vector2(12, 16 + i * 8)
		flame.color = Color(1.0, 0.3 + i * 0.2, 0.0, 0.0)
		flame.position = Vector2(8 + i * 14, 20 - i * 6)
		flame.visible = false
		flame.name = "Flame%d" % i
		fire_flame_nodes.append(flame)
		add_child(flame)


## ── Public API ───────────────────────────────────────────────────────────────

## Called every tick / state update to refresh all visual elements
func update_visuals(fire_state: Dictionary, meat_state: Dictionary, meat_data: Dictionary) -> void:
	_meat_data = meat_data
	_update_fire_visuals(fire_state)
	_update_smoke_quality(fire_state)
	_update_meat_progression(meat_state)
	_update_thermometer(meat_state)
	_update_quality_bars(meat_state)
	_update_labels(meat_state)


## ── Fire Visualization ───────────────────────────────────────────────────────

func _update_fire_visuals(state: Dictionary) -> void:
	var temp: float = state.get("temp", 25.0)
	var fuel: float = state.get("fuel_remaining", 0.0)
	var is_lit: bool = state.get("is_lit", false) or temp > 60.0
	var target: float = state.get("target_temp", 107.0)

	# Fire intensity based on temp relative to target
	fire_intensity = clamp(temp / max(target, 1.0), 0.0, 1.5)

	# Update flame nodes
	var flame_alpha: float = 0.0
	if is_lit and temp > 60.0:
		flame_alpha = min(fire_intensity * 0.7, 0.9)
		flame_alpha = max(flame_alpha, 0.1)

	for i in range(fire_flame_nodes.size()):
		var flame = fire_flame_nodes[i]
		flame.visible = flame_alpha > 0.05
		if flame.visible:
			var alpha = flame_alpha * (1.0 - i * 0.15)
			var r = 1.0
			var g = max(0.1, 0.5 - i * 0.15) * fire_intensity
			flame.color = Color(r, g, 0.0, alpha)
			# Animate height with sine wave
			var wave = sin(Time.get_ticks_msec() * 0.005 + i * 2.0) * 0.2 + 1.0
			var base_height = 16.0 + i * 8.0
			flame.size = Vector2(12, base_height * wave * (0.5 + fire_intensity * 0.5))

	# Update fire temp gauge color
	if fire_temp_gauge and is_instance_valid(fire_temp_gauge):
		var temp_ratio = temp / max(target, 1.0)
		if temp_ratio >= 1.1:
			fire_temp_gauge.self_modulate = Color(1.0, 0.2, 0.2)  # Too hot
		elif temp_ratio >= 0.9:
			fire_temp_gauge.self_modulate = Color(0.3, 1.0, 0.3)  # In range
		elif temp_ratio >= 0.5:
			fire_temp_gauge.self_modulate = Color(1.0, 0.7, 0.2)  # Warming
		else:
			fire_temp_gauge.self_modulate = Color(0.4, 0.6, 1.0)  # Too cold

	# Update fuel level bar
	if fuel_bar and is_instance_valid(fuel_bar):
		var fuel_pct = clamp(fuel / 10.0, 0.0, 1.0)
		fuel_bar.value = fuel_pct
		if fuel_pct < 0.1:
			fuel_bar.self_modulate = Color(1.0, 0.2, 0.2)
		elif fuel_pct < 0.3:
			fuel_bar.self_modulate = Color(1.0, 0.7, 0.1)
		else:
			fuel_bar.self_modulate = Color(0.6, 1.0, 0.3)


## ── Smoke Quality Indicator ──────────────────────────────────────────────────

func _update_smoke_quality(state: Dictionary) -> void:
	var quality: float = state.get("smoke_quality", 0.5)
	smoke_quality = quality

	# Classify smoke
	if quality >= 0.7 and quality <= 0.85:
		# Clean blue smoke
		is_clean_smoke = true
		smoke_color = Color(0.5, 0.7, 0.9, 0.6)
	elif quality < 0.3:
		# Dirty white/grey smoke (too little airflow)
		is_clean_smoke = false
		smoke_color = Color(0.6, 0.6, 0.6, 0.8)
	elif quality < 0.7:
		# Mixed smoke
		is_clean_smoke = false
		smoke_color = Color(0.7, 0.7, 0.8, 0.6)
	else:
		# Too much smoke
		is_clean_smoke = false
		smoke_color = Color(0.9, 0.9, 0.9, 0.7)

	# Update smoke bar
	if smoke_bar and is_instance_valid(smoke_bar):
		smoke_bar.value = quality
		smoke_bar.self_modulate = smoke_color

	# Determine smoke quality label text
	var smoke_text: String = "💨 Smoke: %d%%" % (quality * 100.0)
	if quality >= 0.7 and quality <= 0.85:
		smoke_text = "🌫️ Thin Blue Smoke! (%d%%)" % (quality * 100.0)
	elif quality < 0.3:
		smoke_text = "💨 Dirty Smoke (%d%%) - Open exhaust!" % (quality * 100.0)
	elif quality < 0.7:
		smoke_text = "🌫️ Mixed Smoke (%d%%)" % (quality * 100.0)
	else:
		smoke_text = "💨 Too Much Smoke (%d%%)" % (quality * 100.0)

	if cook_stage_label and is_instance_valid(cook_stage_label):
		pass  # Smoke label updates go to a separate label if available


## ── Meat Visual Progression ─────────────────────────────────────────────────

func _update_meat_progression(state: Dictionary) -> void:
	var internal_temp: float = state.get("internal_temp", 4.0)
	var target_temp: float = state.get("target_temp", 95.0)
	var bark: float = state.get("bark", 0.0)
	var is_resting: bool = state.get("is_resting", false)
	var cook_complete: bool = state.get("cook_complete", false)
	var cook_time: float = state.get("cook_time", 0.0)

	# Calculate overall cook progress
	cook_pct = clamp(internal_temp / max(target_temp, 1.0), 0.0, 1.0)

	# Determine stage
	var new_stage: int = current_stage

	if is_resting:
		new_stage = MeatStage.RESTING
	elif cook_complete:
		new_stage = MeatStage.DONE
	elif cook_pct >= 0.9:
		new_stage = MeatStage.DONE
	elif cook_pct >= 0.6 or bark > 0.5:
		new_stage = MeatStage.BARK_FORMING
	elif cook_pct >= 0.2:
		new_stage = MeatStage.COOKING
	elif cook_time > 5:
		new_stage = MeatStage.SEASONED
	else:
		new_stage = MeatStage.RAW

	if new_stage != current_stage:
		current_stage = new_stage
		EventBus.emit("meat_stage_changed", {
			"stage": current_stage,
			"stage_name": STAGE_LABELS.get(current_stage, "Raw")
		})

	# Update meat sprite color modulation
	if meat_sprite and is_instance_valid(meat_sprite):
		meat_sprite.self_modulate = STAGE_COLORS.get(current_stage, Color.WHITE)

	# Update meat progress label
	if meat_progress_label and is_instance_valid(meat_progress_label):
		var stage_name: String = STAGE_LABELS.get(current_stage, "Raw")
		var pct: int = int(cook_pct * 100.0)
		meat_progress_label.text = "%s (%d%%)" % [stage_name, pct]
		meat_progress_label.self_modulate = STAGE_COLORS.get(current_stage, Color.WHITE).lightened(0.5)


## ── Thermometer Update ──────────────────────────────────────────────────────

func _update_thermometer(state: Dictionary) -> void:
	var internal_temp: float = state.get("internal_temp", 4.0)
	var target_temp: float = state.get("target_temp", 95.0)

	if thermometer and is_instance_valid(thermometer):
		thermometer.set_temperatures(internal_temp, target_temp)


## ── Quality Bars Update ─────────────────────────────────────────────────────

func _update_quality_bars(state: Dictionary) -> void:
	var bark: float = state.get("bark", 0.0)
	var ring: float = state.get("smoke_ring", 0.0)
	var moisture: float = state.get("moisture", 1.0)

	if bark_progress_label and is_instance_valid(bark_progress_label):
		bark_progress_label.text = "Bark: %d%%" % (bark * 100.0)

	if ring_progress_label and is_instance_valid(ring_progress_label):
		ring_progress_label.text = "Ring: %d%%" % (ring * 100.0)

	# Update moisture bar color
	if moisture_bar and is_instance_valid(moisture_bar):
		moisture_bar.value = moisture
		if moisture < 0.3:
			moisture_bar.self_modulate = Color(1.0, 0.3, 0.3)
		elif moisture < 0.6:
			moisture_bar.self_modulate = Color(1.0, 0.7, 0.2)
		else:
			moisture_bar.self_modulate = Color(0.3, 1.0, 0.3)

	# Update meat temp gauge color
	if meat_temp_gauge and is_instance_valid(meat_temp_gauge):
		var temp_ratio: float = state.get("internal_temp", 0.0) / max(state.get("target_temp", 95.0), 1.0)
		if temp_ratio >= 1.0:
			meat_temp_gauge.self_modulate = Color(0.2, 1.0, 0.2)
		elif temp_ratio >= 0.7:
			meat_temp_gauge.self_modulate = Color(1.0, 0.8, 0.2)
		elif temp_ratio >= 0.3:
			meat_temp_gauge.self_modulate = Color(1.0, 0.5, 0.1)
		else:
			meat_temp_gauge.self_modulate = Color(0.4, 0.6, 1.0)


## ── Labels Update ───────────────────────────────────────────────────────────

func _update_labels(state: Dictionary) -> void:
	# Nothing else needed per-tick beyond what's handled above
	pass


## ── Meat Stage Helpers ──────────────────────────────────────────────────────

func get_stage_name(stage: int = -1) -> String:
	if stage < 0:
		stage = current_stage
	return STAGE_LABELS.get(stage, "Raw")

func get_stage_color(stage: int = -1) -> Color:
	if stage < 0:
		stage = current_stage
	return STAGE_COLORS.get(stage, Color.WHITE)


## ── Config ──────────────────────────────────────────────────────────────────

## Hook up external node references
func setup_nodes(
	p_meat_sprite: TextureRect = null,
	p_thermometer: MeatThermometer = null,
	p_smoke_bar: ProgressBar = null,
	p_fire_temp_gauge: ProgressBar = null,
	p_meat_temp_gauge: ProgressBar = null,
	p_fuel_bar: ProgressBar = null,
	p_moisture_bar: ProgressBar = null,
	p_cook_stage_label: Label = null,
	p_meat_progress_label: Label = null,
	p_bark_progress_label: Label = null,
	p_ring_progress_label: Label = null
) -> void:
	meat_sprite = p_meat_sprite
	thermometer = p_thermometer
	smoke_bar = p_smoke_bar
	fire_temp_gauge = p_fire_temp_gauge
	meat_temp_gauge = p_meat_temp_gauge
	fuel_bar = p_fuel_bar
	moisture_bar = p_moisture_bar
	cook_stage_label = p_cook_stage_label
	meat_progress_label = p_meat_progress_label
	bark_progress_label = p_bark_progress_label
	ring_progress_label = p_ring_progress_label