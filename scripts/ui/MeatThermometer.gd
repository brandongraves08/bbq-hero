extends Control
class_name MeatThermometer

## ── Reusable Meat Thermometer Widget ─────────────────────────────────────────
## Displays internal temperature as a vertical thermometer with color zones.
## Shows current temp, target temp marker, and color-coded mercury column.

## Current internal temperature in °C
var current_temp: float = 4.0
## Target internal temperature in °C
var target_temp: float = 95.0
## Maximum display temperature
var max_temp: float = 120.0

## Color for cold zone (below 30% of target)
var cold_color: Color = Color(0.3, 0.5, 1.0)
## Color for warming zone (30-70% of target)
var warm_color: Color = Color(1.0, 0.6, 0.2)
## Color for near-target zone (70-100% of target)
var hot_color: Color = Color(1.0, 0.3, 0.1)
## Color for done zone (at or above target)
var done_color: Color = Color(0.2, 1.0, 0.3)

## Width of the thermometer tube
var tube_width: float = 24.0

func _draw() -> void:
	var draw_size = get_size()
	var tube_x: float = (draw_size.x - tube_width) / 2.0
	var tube_top: float = 10.0
	var tube_bottom: float = draw_size.y - 20.0
	var tube_height: float = tube_bottom - tube_top
	var bulb_radius: float = tube_width / 2.0
	var bulb_center: Vector2 = Vector2(tube_x + tube_width / 2.0, tube_bottom + bulb_radius)

	# ── Draw background tube (outer casing) ──────────────────────────────
	var tube_rect = Rect2(tube_x - 2, tube_top - 2, tube_width + 4, tube_height + 4)
	var casing_color = Color(0.8, 0.8, 0.8, 0.3)
	draw_rect(tube_rect, casing_color, true)

	# ── Draw background tube (inner) ────────────────────────────────────
	var inner_rect = Rect2(tube_x, tube_top, tube_width, tube_height)
	var bg_color = Color(0.15, 0.15, 0.15, 0.5)
	draw_rect(inner_rect, bg_color, true)

	# ── Draw temperature bulb at bottom ─────────────────────────────────
	draw_circle(bulb_center, bulb_radius, bg_color)

	# ── Calculate mercury fill ──────────────────────────────────────────
	var fill_pct: float = clamp(current_temp / max(1.0, max_temp), 0.0, 1.0)
	var mercury_height: float = tube_height * fill_pct
	var mercury_top: float = tube_bottom - mercury_height

	# Determine mercury color based on temp relative to target
	var temp_ratio: float = current_temp / max(1.0, target_temp)
	var mercury_color: Color
	if current_temp >= target_temp:
		mercury_color = done_color
	elif temp_ratio >= 0.7:
		mercury_color = hot_color
	elif temp_ratio >= 0.3:
		mercury_color = warm_color
	else:
		mercury_color = cold_color

	# ── Draw mercury column ─────────────────────────────────────────────
	var mercury_rect = Rect2(tube_x + 2, mercury_top + 2, tube_width - 4, mercury_height - 2)
	draw_rect(mercury_rect, mercury_color, true)

	# ── Draw bulb fill ──────────────────────────────────────────────────
	draw_circle(bulb_center, bulb_radius - 2, mercury_color)

	# ── Draw target marker ──────────────────────────────────────────────
	var target_pct: float = clamp(target_temp / max(1.0, max_temp), 0.0, 1.0)
	var target_y: float = tube_bottom - tube_height * target_pct
	var marker_color = Color(1.0, 1.0, 1.0, 0.8)

	# Draw target marker lines
	draw_line(Vector2(tube_x - 6, target_y), Vector2(tube_x - 2, target_y), marker_color, 2.0)
	draw_line(Vector2(tube_x + tube_width + 2, target_y), Vector2(tube_x + tube_width + 6, target_y), marker_color, 2.0)
	draw_line(Vector2(tube_x - 4, target_y - 4), Vector2(tube_x - 4, target_y + 4), marker_color, 1.5)
	draw_line(Vector2(tube_x + tube_width + 4, target_y - 4), Vector2(tube_x + tube_width + 4, target_y + 4), marker_color, 1.5)

	# ── Draw temperature labels ─────────────────────────────────────────
	var font: Font = ThemeDB.fallback_font
	var font_size: int = 10

	# Current temp at the bottom
	var temp_text: String = "%.0f°C" % current_temp
	var temp_text_size: Vector2 = font.get_string_size(temp_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var text_x: float = (draw_size.x - temp_text_size.x) / 2.0
	var text_y: float = tube_bottom + bulb_radius * 2 + 6
	draw_string(font, Vector2(text_x, text_y), temp_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(1, 1, 1, 0.9))

	# Target temp near the marker
	var target_text: String = "%.0f°" % target_temp
	var target_text_size: Vector2 = font.get_string_size(target_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8)
	var target_text_x: float = tube_x + tube_width + 8
	var target_text_y: float = target_y + target_text_size.y / 2.0 - 2
	draw_string(font, Vector2(target_text_x, target_text_y), target_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, marker_color)

func set_temperatures(current: float, target: float) -> void:
	current_temp = current
	target_temp = target
	max_temp = max(target * 1.3, 100.0)
	queue_redraw()

func _get_minimum_size() -> Vector2:
	return Vector2(50, 180)
