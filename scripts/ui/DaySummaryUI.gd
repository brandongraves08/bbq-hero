extends Control
class_name DaySummaryUI

## ── Day Summary Screen ──────────────────────────────────────────────────────
## Shows cook results breakdown: score, money earned, reputation gained, expenses.
## Player confirms → advances to next day → returns to hub.
##
## Flow: first_playable (cook ends) → day_summary → hub

@onready var day_label: Label = $MarginContainer/VBox/HeaderRow/DayLabel
@onready var score_label: Label = $MarginContainer/VBox/ScorePanel/MarginContainer/VBox/ScoreLabel
@onready var grade_label: Label = $MarginContainer/VBox/ScorePanel/MarginContainer/VBox/GradeLabel

@onready var earnings_panel: Panel = $MarginContainer/VBox/EarningsPanel
@onready var payout_label: Label = $MarginContainer/VBox/EarningsPanel/MarginContainer/VBox/PayoutLabel
@onready var tips_label: Label = $MarginContainer/VBox/EarningsPanel/MarginContainer/VBox/TipsLabel
@onready var total_earned_label: Label = $MarginContainer/VBox/EarningsPanel/MarginContainer/VBox/TotalEarnedLabel

@onready var expenses_panel: Panel = $MarginContainer/VBox/ExpensesPanel
@onready var fuel_cost_label: Label = $MarginContainer/VBox/ExpensesPanel/MarginContainer/VBox/FuelCostLabel
@onready var meat_cost_label: Label = $MarginContainer/VBox/ExpensesPanel/MarginContainer/VBox/MeatCostLabel
@onready var total_expenses_label: Label = $MarginContainer/VBox/ExpensesPanel/MarginContainer/VBox/TotalExpensesLabel

@onready var rep_panel: Panel = $MarginContainer/VBox/RepPanel
@onready var rep_gain_label: Label = $MarginContainer/VBox/RepPanel/MarginContainer/VBox/RepGainLabel
@onready var fame_label: Label = $MarginContainer/VBox/RepPanel/MarginContainer/VBox/FameLabel
@onready var satisfaction_label: Label = $MarginContainer/VBox/RepPanel/MarginContainer/VBox/SatisfactionLabel

@onready var profit_label: Label = $MarginContainer/VBox/ProfitRow/ProfitLabel
@onready var profit_icon_label: Label = $MarginContainer/VBox/ProfitRow/ProfitIconLabel

@onready var feedback_label: Label = $MarginContainer/VBox/FeedbackPanel/MarginContainer/FeedbackLabel
@onready var continue_btn: Button = $MarginContainer/VBox/FooterRow/ContinueBtn

## Data from the completed cook cycle
var _economy_result: Dictionary = {}
var _reputation_result: Dictionary = {}
var _cook_score: float = 0.0

func _ready() -> void:
	continue_btn.pressed.connect(_on_continue)

	# If we have cook data stored from the cook scene, show the summary
	# The data is passed via a temporary autoload/singleton approach:
	# FirstPlayable stores cook result data in GameManager meta before transitioning
	_retrieve_cook_data()

## Retrieve cook result data set by FirstPlayable before the scene transition
func _retrieve_cook_data() -> void:
	# Check if cook result data was stored via EventBus recent events
	# or through GameManager meta
	var stored = GameManager.get_meta("last_cook_result", {})
	if stored.is_empty():
		# Fallback: show empty summary
		_show_empty_summary()
		return

	_cook_score = stored.get("cook_score", 0.0)
	_economy_result = stored.get("economy_result", {})
	_reputation_result = stored.get("reputation_result", {})
	_populate_summary()

## Show the day summary with all data populated
func _populate_summary() -> void:
	day_label.text = "Day %d Complete!" % GameManager.current_day

	# Score
	var score = _cook_score
	score_label.text = "Cook Score: %.0f / 100" % score
	grade_label.text = "%s  %s" % [_get_grade_icon(score), _get_grade_text(score)]

	# ── Earnings ──────────────────────────────────────────────────────────
	var payout = _economy_result.get("final_payout", 0.0)
	var tips = _economy_result.get("tips", 0.0)
	var total_earned = _economy_result.get("total_earned", 0.0)
	payout_label.text = "💰 Gig Payout: $%.0f" % payout
	tips_label.text = "💵 Tips: $%.0f" % tips
	total_earned_label.text = "↗ Total Earned: $%.0f" % total_earned

	# ── Expenses ──────────────────────────────────────────────────────────
	var fuel_cost = _economy_result.get("fuel_cost", 0.0)
	var meat_cost = _economy_result.get("meat_cost", 0.0)
	var total_expenses = _economy_result.get("total_expenses", 0.0)
	fuel_cost_label.text = "🔥 Fuel Used: $%.0f" % fuel_cost
	meat_cost_label.text = "🥩 Meat Cost: $%.0f" % meat_cost
	total_expenses_label.text = "↘ Total Expenses: $%.0f" % total_expenses

	# ── Profit ────────────────────────────────────────────────────────────
	var net = _economy_result.get("net_profit", 0.0)
	if net >= 0:
		profit_label.text = "+$%.0f" % net
		profit_label.self_modulate = Color(0.3, 1.0, 0.3)
		profit_icon_label.text = "📈 Net Profit"
	else:
		profit_label.text = "-$%.0f" % abs(net)
		profit_label.self_modulate = Color(1.0, 0.3, 0.3)
		profit_icon_label.text = "📉 Net Loss"

	# ── Reputation ────────────────────────────────────────────────────────
	var rep_gain = _reputation_result.get("total_rep_gained", 0.0)
	var fame = _reputation_result.get("new_fame_level", 0)
	var satisfaction = _reputation_result.get("satisfaction", 0.0) * 100.0

	rep_gain_label.text = "Reputation +%.0f" % rep_gain
	fame_label.text = "🏆 %s" % ReputationManager.get_fame_level_name()

	# Satisfaction
	var sat_text = ""
	if satisfaction >= 90:
		sat_text = "😍 Customers thrilled! (%.0f%%)" % satisfaction
	elif satisfaction >= 70:
		sat_text = "😊 Customers happy (%.0f%%)" % satisfaction
	elif satisfaction >= 50:
		sat_text = "😐 Customers satisfied (%.0f%%)" % satisfaction
	else:
		sat_text = "😕 Customers disappointed (%.0f%%)" % satisfaction
	satisfaction_label.text = sat_text

	# ── Feedback ──────────────────────────────────────────────────────────
	feedback_label.text = _get_feedback(score,
		_economy_result.get("meat_cost", 0.0),
		_reputation_result.get("customers_served", 0))

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

func _get_feedback(score: float, expenses: float, customers: int) -> String:
	var lines = []
	if score >= 80:
		lines.append("🔥 OUTSTANDING! The crowd loved it. You're building a real name out there.")
	elif score >= 60:
		lines.append("👍 Solid cook. Keep practicing and dial in your fire management.")
	elif score >= 40:
		lines.append("📖 A learning experience. Every great pitmaster started somewhere.")
	else:
		lines.append("💪 Rough cook, but you showed up. The next one will be better.")

	# Additional tips
	if score < 40:
		lines.append("💡 Focus on maintaining a consistent fire temperature next time.")

	if customers > 0:
		# Gig had customers
		lines.append("👥 Served %d customers today." % customers)

	if not lines.is_empty():
		return "\n".join(lines)
	return "Keep at it, pitmaster!"

func _show_empty_summary() -> void:
	day_label.text = "Day %d Complete!" % GameManager.current_day
	score_label.text = "Cook Score: -- / 100"
	grade_label.text = "No cook data"
	payout_label.text = "💰 Gig Payout: $0"
	tips_label.text = "💵 Tips: $0"
	total_earned_label.text = "↗ Total Earned: $0"
	fuel_cost_label.text = "🔥 Fuel Used: $0"
	meat_cost_label.text = "🥩 Meat Cost: $0"
	total_expenses_label.text = "↘ Total Expenses: $0"
	profit_label.text = "$0"
	profit_icon_label.text = "📊 Net"
	rep_gain_label.text = "Reputation +0"
	fame_label.text = "🏆 Unknown"
	satisfaction_label.text = "No customers"
	feedback_label.text = "No cook data available."

## Player confirms → advance day, clear meta, and transition to hub
func _on_continue() -> void:
	GameManager.remove_meta("last_cook_result")
	GameManager.advance_day()
	get_tree().change_scene_to_file("res://scenes/hub.tscn")
