extends Control
class_name GigScoring

## ── Gig / Competition Scoring Screen ──────────────────────────────────────────
## Replaces the generic day summary with a gig-specific scoring screen.
## Shows KCBS-style scoring for competitions, customer satisfaction for gigs.

## ── Scoring Types ────────────────────────────────────────────────────────────
enum ScoringType { COMPETITION, GIG, CHALLENGE }

var scoring_type: int = ScoringType.GIG
var _cook_score: float = 0.0
var _meat_data: Dictionary = {}

## Node references (set by creator or on ready via scene binding)
@onready var title_label: Label = $MarginContainer/VBox/HeaderRow/TitleLabel
@onready var score_panel: Panel = $MarginContainer/VBox/ScorePanel
@onready var score_grade_label: Label = $MarginContainer/VBox/ScorePanel/MarginContainer/VBox/GradeLabel
@onready var score_value_label: Label = $MarginContainer/VBox/ScorePanel/MarginContainer/VBox/ScoreValueLabel
@onready var score_breakdown_grid: GridContainer = $MarginContainer/VBox/BreakdownGrid

@onready var customer_feedback_panel: Panel = $MarginContainer/VBox/CustomerFeedbackPanel
@onready var customer_feedback_label: Label = $MarginContainer/VBox/CustomerFeedbackPanel/MarginContainer/VBox/FeedbackListLabel

@onready var earnings_panel: Panel = $MarginContainer/VBox/EarningsPanel
@onready var payout_label: Label = $MarginContainer/VBox/EarningsPanel/MarginContainer/VBox/PayoutLabel
@onready var tips_label: Label = $MarginContainer/VBox/EarningsPanel/MarginContainer/VBox/TipsLabel
@onready var meat_cost_label: Label = $MarginContainer/VBox/EarningsPanel/MarginContainer/VBox/MeatCostLabel
@onready var fuel_cost_label: Label = $MarginContainer/VBox/EarningsPanel/MarginContainer/VBox/FuelCostLabel
@onready var net_profit_label: Label = $MarginContainer/VBox/EarningsPanel/MarginContainer/VBox/NetProfitLabel

@onready var rep_panel: Panel = $MarginContainer/VBox/RepPanel
@onready var rep_gained_label: Label = $MarginContainer/VBox/RepPanel/MarginContainer/VBox/RepGainedLabel
@onready var fame_label: Label = $MarginContainer/VBox/RepPanel/MarginContainer/VBox/FameLabel

@onready var continue_btn: Button = $MarginContainer/VBox/FooterRow/ContinueBtn

## Data used for scoring display
var _economy_data: Dictionary = {}
var _reputation_data: Dictionary = {}
var _event_data: Dictionary = {}
var _meat_name: String = ""
var _meat_weight: float = 0.0

## Positive and negative review snippets
const POSITIVE_REVIEWS: Array = [
	"🔥 \"Best BBQ I've ever had! The bark was incredible.\"",
	"⭐ \"Perfect smoke flavor. This pitmaster knows their craft.\"",
	"👨‍🍳 \"The tenderness was spot on. Melt-in-your-mouth good.\"",
	"🍖 \"That smoke ring is a work of art. Competition quality!\"",
	"😋 \"The flavor is amazing! I'm coming back for more.\"",
	"🌟 \"Absolutely phenomenal. The moisture was perfect.\"",
	"👍 \"Great BBQ! You can really taste the care that went into it.\"",
	"🔥 \"That bark was perfection. Crunchy and flavorful.\"",
	"🥩 \"Cooked to perfection. The temp was exactly right.\"",
	"💯 \"Hands down the best BBQ in town. Five stars!\""
]

const NEGATIVE_REVIEWS: Array = [
	"😕 \"It was okay, but the bark could be better. Needs more smoke.\"",
	"🤔 \"The texture was a bit tough. Could use more time.\"",
	"😐 \"Decent BBQ but nothing special. The smoke flavor was weak.\"",
	"👎 \"A bit dry for my taste. Needed more moisture.\"",
	"😬 \"The outside was good but the inside was uneven.\"",
	"🤷 \"Not bad, but I've had better. Work on your fire management.\"",
	"😓 \"The cook seemed rushed. Let it rest longer next time.\"",
	"🤨 \"The smoke ring was barely there. Needs more smoke early on.\"",
	"😤 \"Disappointing. Expected more bark development for the price.\"",
	"😭 \"Dry and tough. This needs a lot of work.\""
]

# ──────────────────────────────────────────────────────────────────────────────
# Lifecycle
# ──────────────────────────────────────────────────────────────────────────────

func _ready() -> void:
	continue_btn.pressed.connect(_on_continue)
	if GameManager.has_meta("last_cook_result"):
		_load_last_cook_result(GameManager.get_meta("last_cook_result"))


func _load_last_cook_result(result: Dictionary) -> void:
	setup(
		result.get("scoring_type", ScoringType.GIG),
		result.get("cook_score", 0.0),
		result.get("economy_result", {}),
		result.get("reputation_result", {}),
		result.get("event_data", {}),
		result.get("meat_name", "BBQ"),
		result.get("meat_weight", 0.0),
		result.get("bark", 0.0),
		result.get("ring", 0.0),
		result.get("moisture", 0.0),
		result.get("temp_accuracy", 0.0)
	)


## ── Public API ───────────────────────────────────────────────────────────────

## Set up the scoring screen with data from the completed cook
func setup(
	p_scoring_type: int,
	p_cook_score: float,
	p_economy_data: Dictionary,
	p_reputation_data: Dictionary,
	p_event_data: Dictionary,
	p_meat_name: String,
	p_meat_weight: float,
	p_bark: float,
	p_ring: float,
	p_moisture: float,
	p_temp_accuracy: float
) -> void:
	scoring_type = p_scoring_type
	_cook_score = p_cook_score
	_economy_data = p_economy_data
	_reputation_data = p_reputation_data
	_event_data = p_event_data
	_meat_name = p_meat_name
	_meat_weight = p_meat_weight

	_populate_scoring(p_bark, p_ring, p_moisture, p_temp_accuracy)


## ── Scoring Population ──────────────────────────────────────────────────────

func _populate_scoring(bark: float, ring: float, moisture: float, temp_accuracy: float) -> void:
	match scoring_type:
		ScoringType.COMPETITION:
			_populate_competition_scoring(bark, ring, moisture, temp_accuracy)
		ScoringType.CHALLENGE:
			_populate_competition_scoring(bark, ring, moisture, temp_accuracy)
		_:
			_populate_gig_scoring(bark, ring, moisture, temp_accuracy)

	_populate_earnings()
	_populate_reputation()
	_populate_customer_feedback()


## ── Competition Scoring (KCBS-style) ────────────────────────────────────────

func _populate_competition_scoring(bark: float, ring: float, moisture: float, temp_accuracy: float) -> void:
	var event_name: String = _event_data.get("name", "Competition")
	title_label.text = "🏆 COMPETITION SCORE: %s" % event_name

	# KCBS scoring weights
	var appearance_weight: float = 0.2
	var taste_weight: float = 0.4
	var tenderness_weight: float = 0.4

	# Calculate component scores (0-100 each)
	var appearance_score: float = bark * 100.0 * 0.7 + ring * 100.0 * 0.3
	var taste_score: float = (bark * 100.0 * 0.4 + moisture * 100.0 * 0.4 + _cook_score * 0.2)
	var tenderness_score: float = moisture * 100.0 * 0.5 + temp_accuracy * 0.5

	var weighted_score: float = (
		appearance_score * appearance_weight +
		taste_score * taste_weight +
		tenderness_score * tenderness_weight
	)

	_score_value_label.text = "🏆 KCBS Total: %.1f / 100" % weighted_score
	var grade_icon: String = _get_grade_icon(weighted_score)
	var grade_text: String = _get_grade_text(weighted_score)
	score_grade_label.text = "%s %s" % [grade_icon, grade_text]

	# Score breakdown
	score_breakdown_grid.columns = 3
	_score_breakdown_add("Appearance (20%%)", "%d/100" % appearance_score, _score_color(appearance_score))
	_score_breakdown_add("Taste (40%%)", "%d/100" % taste_score, _score_color(taste_score))
	_score_breakdown_add("Tenderness (40%%)", "%d/100" % tenderness_score, _score_color(tenderness_score))
	_score_breakdown_add("Bark Score", "%d%%" % (bark * 100), _score_color(bark * 100))
	_score_breakdown_add("Smoke Ring", "%d%%" % (ring * 100), _score_color(ring * 100))
	_score_breakdown_add("Moisture", "%d%%" % (moisture * 100), _score_color(moisture * 100))
	_score_breakdown_add("Doneness Accuracy", "%d%%" % int(temp_accuracy), _score_color(temp_accuracy))
	_score_breakdown_add("Rank Prediction", _get_rank_prediction(weighted_score), Color(1, 0.8, 0.3))


## ── Gig Scoring (Customer Satisfaction) ─────────────────────────────────────

func _populate_gig_scoring(bark: float, ring: float, moisture: float, temp_accuracy: float) -> void:
	var event_name: String = _event_data.get("name", "Gig")
	title_label.text = "🔥 GIG RESULTS: %s" % event_name

	# Customer satisfaction breakdown
	var food_quality_score: float = (bark * 40 + ring * 20 + moisture * 40) * _cook_score / 100.0
	var doneness_score: float = temp_accuracy
	var overall_score: float = (food_quality_score * 0.5 + doneness_score * 0.3 + (_cook_score / 100.0) * 100 * 0.2)

	score_value_label.text = "😊 Customer Satisfaction: %.1f / 100" % overall_score
	var grade_icon: String = _get_grade_icon(overall_score)
	var grade_text: String = _get_grade_text(overall_score)
	score_grade_label.text = "%s %s" % [grade_icon, grade_text]

	# Gig scoring grid
	score_breakdown_grid.columns = 2
	_score_breakdown_add("🔥 Food Quality", "%d/100" % int(food_quality_score), _score_color(food_quality_score))
	_score_breakdown_add("🍖 Bark Score", "%d%%" % (bark * 100), _score_color(bark * 100))
	_score_breakdown_add("🌊 Smoke Ring", "%d%%" % (ring * 100), _score_color(ring * 100))
	_score_breakdown_add("💧 Moisture / Juiciness", "%d%%" % (moisture * 100), _score_color(moisture * 100))
	_score_breakdown_add("🎯 Doneness / Temp Accuracy", "%d%%" % int(temp_accuracy), _score_color(temp_accuracy))
	_score_breakdown_add("⏱ Cook Time", _get_cook_time_text(), Color(0.7, 0.8, 1.0))

	# Expected range comparison
	var diff: float = _cook_score - _get_event_expected_score()
	var diff_text: String = ""
	var diff_color: Color
	if diff > 10:
		diff_text = "+%.0f above expected" % diff
		diff_color = Color(0.3, 1.0, 0.3)
	elif diff < -10:
		diff_text = "%.0f below expected" % diff
		diff_color = Color(1.0, 0.3, 0.3)
	else:
		diff_text = "In expected range"
		diff_color = Color(0.8, 0.8, 0.3)

	_score_breakdown_add("📊 vs. Expected Range", diff_text, diff_color)


## ── Earnings ────────────────────────────────────────────────────────────────

func _populate_earnings() -> void:
	var payout: float = _economy_data.get("final_payout", 0.0)
	var tips: float = _economy_data.get("tips", 0.0)
	var meat_cost: float = _economy_data.get("meat_cost", 0.0)
	var fuel_cost: float = _economy_data.get("fuel_cost", 0.0)
	var net: float = _economy_data.get("net_profit", 0.0)

	payout_label.text = "💰 Gig Payout: $%.0f" % payout
	tips_label.text = "💵 Tips: $%.0f" % tips
	meat_cost_label.text = "🥩 Meat Cost: -$%.0f" % meat_cost
	fuel_cost_label.text = "🔥 Fuel Cost: -$%.0f" % fuel_cost

	if net >= 0:
		net_profit_label.text = "📈 Net Profit: +$%.0f" % net
		net_profit_label.self_modulate = Color(0.3, 1.0, 0.3)
	else:
		net_profit_label.text = "📉 Net Loss: -$%.0f" % abs(net)
		net_profit_label.self_modulate = Color(1.0, 0.3, 0.3)


## ── Reputation ─────────────────────────────────────────────────────────────

func _populate_reputation() -> void:
	var rep_gain: float = _reputation_data.get("total_rep_gained", 0.0)
	var fame_name: String = _reputation_data.get("fame_name", "Unknown")
	var satisfaction: float = _reputation_data.get("satisfaction", 0.0) * 100.0

	rep_gained_label.text = "⭐ Reputation +%.1f" % rep_gain
	fame_label.text = "🏆 Fame Level: %s" % fame_name

	# Fame level change indicator
	var old_fame: int = _reputation_data.get("old_fame_level", 0)
	var new_fame: int = _reputation_data.get("new_fame_level", 0)
	if new_fame > old_fame:
		fame_label.text += "  ⬆ LEVEL UP!"


## ── Customer Feedback ──────────────────────────────────────────────────────

func _populate_customer_feedback() -> void:
	var score: float = _cook_score
	var lines: Array = []

	# Add score-based feedback
	if score >= 90:
		lines.append("🔥 OUTSTANDING! The judges/crowd was blown away!")
	elif score >= 75:
		lines.append("👍 Excellent cook! Almost perfect execution.")
	elif score >= 60:
		lines.append("😊 Good cook! Some room for improvement.")
	elif score >= 40:
		lines.append("😐 Decent effort. Focus on fire control and timing.")
	else:
		lines.append("📖 A rough cook, but you showed up. Every pro started here.")

	# Add 2-3 random customer quotes based on score
	var rng = RandomNumberGenerator.new()
	var positive_count: int = 0
	var negative_count: int = 0

	if score >= 70:
		positive_count = 2 + (1 if score >= 85 else 0)
		if score < 50:
			negative_count = 2
		elif score < 70:
			negative_count = 1
			positive_count = 1

	# Pick random reviews
	var used_pos: Array = []
	var used_neg: Array = []
	for i in range(positive_count):
		var idx: int = rng.randi_range(0, POSITIVE_REVIEWS.size() - 1)
		while idx in used_pos and used_pos.size() < POSITIVE_REVIEWS.size():
			idx = rng.randi_range(0, POSITIVE_REVIEWS.size() - 1)
		used_pos.append(idx)
		lines.append(POSITIVE_REVIEWS[idx])

	for i in range(negative_count):
		var idx: int = rng.randi_range(0, NEGATIVE_REVIEWS.size() - 1)
		while idx in used_neg and used_neg.size() < NEGATIVE_REVIEWS.size():
			idx = rng.randi_range(0, NEGATIVE_REVIEWS.size() - 1)
		used_neg.append(idx)
		lines.append(NEGATIVE_REVIEWS[idx])

	# Add tips
	if score < 90:
		if _reputation_data.get("satisfaction", 0.0) * 100.0 < 60:
			lines.append("💡 Tip: Focus on fire temperature consistency for better results.")
		if _economy_data.get("meat_cost", 0.0) > _economy_data.get("final_payout", 0.0):
			lines.append("💡 Tip: Your meat cost exceeded your payout. Consider cheaper cuts or better pricing.")

	customer_feedback_label.text = "\n\n".join(lines)


## ── Helpers ─────────────────────────────────────────────────────────────────

func _score_color(value: float) -> Color:
	if value >= 80:
		return Color(0.3, 1.0, 0.3)
	elif value >= 60:
		return Color(1.0, 0.8, 0.2)
	elif value >= 40:
		return Color(1.0, 0.6, 0.1)
	return Color(1.0, 0.3, 0.3)

func _get_grade_icon(score: float) -> String:
	if score >= 90: return "🥇"
	elif score >= 75: return "🥈"
	elif score >= 60: return "🥉"
	elif score >= 40: return "👍"
	else: return "👎"

func _get_grade_text(score: float) -> String:
	if score >= 90: return "Grand Champion"
	elif score >= 75: return "Excellent"
	elif score >= 60: return "Good"
	elif score >= 40: return "Passable"
	else: return "Needs Work"

func _get_rank_prediction(score: float) -> String:
	if score >= 90: return "🥇 1st Place"
	elif score >= 80: return "🥈 Top 3!"
	elif score >= 70: return "🥉 Top 10"
	elif score >= 60: return "🏅 Middle of Pack"
	elif score >= 40: return "📋 Bottom Half"
	return "📝 Last Place"

func _get_event_expected_score() -> float:
	var difficulty: int = _event_data.get("difficulty", 1)
	return 40.0 + (5 - float(difficulty)) * 8.0

func _get_cook_time_text() -> String:
	var event_name: String = _event_data.get("name", "Gig")
	if _event_data.get("type") == "competition":
		var time_limit: int = _event_data.get("timeLimitMin", 600)
		return "%d min allowed" % time_limit
	return "See cook results"

func _score_breakdown_add(label_text: String, value_text: String, color: Color = Color.WHITE) -> void:
	var label = Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color(0.85, 0.75, 0.55))
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	score_breakdown_grid.add_child(label)

	var value = Label.new()
	value.text = value_text
	value.add_theme_font_size_override("font_size", 14)
	value.add_theme_color_override("font_color", color)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	score_breakdown_grid.add_child(value)


## ── Continue / Transition ───────────────────────────────────────────────────

func _on_continue() -> void:
	# Advance day and return to hub
	GameManager.remove_meta("last_cook_result")
	GameManager.advance_day()
	get_tree().change_scene_to_file("res://scenes/hub.tscn")


## ── Animated Reveal (can be called after population) ────────────────────────

## Animate score counting up from 0 to final score
func animate_score_reveal(duration: float = 1.5) -> void:
	if not score_value_label or not is_instance_valid(score_value_label):
		return
	# Start from 0
	var start_score: float = 0.0
	var end_score: float = _cook_score
	var elapsed: float = 0.0

	while elapsed < duration:
		elapsed += get_process_delta_time()
		var t: float = clamp(elapsed / duration, 0.0, 1.0)
		var current: float = start_score + (end_score - start_score) * ease(t, 0.5)
		score_value_label.text = "Score: %.0f / 100" % current
		await get_tree().process_frame

	score_value_label.text = "Score: %.0f / 100" % end_score
