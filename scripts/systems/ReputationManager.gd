extends Node
class_name ReputationManager

## Manages reputation, fame levels, competition scores, and customer satisfaction

signal reputation_changed(new_value: float, delta: float)
signal fame_level_changed(level: int)

var reputation: float = 0.0
var competition_scores: Array = []
var customer_satisfaction: Array = []
var critic_reviews: Array = []

enum FameLevel { UNKNOWN, LOCAL, REGIONAL, FAMOUS, LEGENDARY }

const FAME_THRESHOLDS: Dictionary = {
	FameLevel.UNKNOWN: 0,
	FameLevel.LOCAL: 50,
	FameLevel.REGIONAL: 200,
	FameLevel.FAMOUS: 500,
	FameLevel.LEGENDARY: 800
}

func _ready() -> void:
	reputation = GameManager.reputation

func add_reputation(amount: float) -> void:
	var old_level = get_fame_level()
	reputation += amount
	GameManager.reputation = reputation
	emit_signal("reputation_changed", reputation, amount)
	var new_level = get_fame_level()
	if new_level != old_level:
		emit_signal("fame_level_changed", new_level)

func get_fame_level() -> int:
	if reputation >= FAME_THRESHOLDS[FameLevel.LEGENDARY]:
		return FameLevel.LEGENDARY
	elif reputation >= FAME_THRESHOLDS[FameLevel.FAMOUS]:
		return FameLevel.FAMOUS
	elif reputation >= FAME_THRESHOLDS[FameLevel.REGIONAL]:
		return FameLevel.REGIONAL
	elif reputation >= FAME_THRESHOLDS[FameLevel.LOCAL]:
		return FameLevel.LOCAL
	return FameLevel.UNKNOWN

func get_fame_level_name() -> String:
	match get_fame_level():
		FameLevel.UNKNOWN:
			return "Unknown"
		FameLevel.LOCAL:
			return "Local Legend"
		FameLevel.REGIONAL:
			return "Regional Star"
		FameLevel.FAMOUS:
			return "Famous Pitmaster"
		FameLevel.LEGENDARY:
			return "BBQ Legend"
	return "Unknown"

func add_competition_score(event_name: String, score_dict: Dictionary, rank: int) -> void:
	competition_scores.append({
		"date": GameManager.current_day,
		"event": event_name,
		"scores": score_dict,
		"rank": rank
	})

func get_average_score() -> float:
	if competition_scores.is_empty():
		return 0.0
	var total: float = 0.0
	var count: int = 0
	for entry in competition_scores:
		for key in entry["scores"]:
			total += entry["scores"][key]
			count += 1
	return total / max(count, 1)

func record_customer_satisfaction(score: float) -> void:
	customer_satisfaction.append({
		"day": GameManager.current_day,
		"score": score
	})

func get_reputation_for_phase(phase: int) -> float:
	match phase:
		2:
			return 200.0
		3:
			return 500.0
		_:
			return 99999.0

## ── Cook Result Processing ──────────────────────────────────────────────────
## Called after a cook completes to award reputation and track satisfaction.
## Returns a Dictionary with reputation details for the day summary UI.
func process_cook_result(cook_score: float, event_data: Dictionary) -> Dictionary:
	var result: Dictionary = {}

	# Base reputation: score / 10, so a perfect 100 = +10 rep
	var base_rep: float = cook_score / 10.0

	# Event difficulty multiplier
	var difficulty: int = event_data.get("difficulty", 1)
	var diff_mult: float = 0.8 + (difficulty - 1) * 0.15  # 0.8x to 1.4x
	var rep_gain: float = round(base_rep * diff_mult * 10.0) / 10.0

	# Customer count satisfaction bonus
	var customer_range: Array = event_data.get("customerCountRange", [10, 30])
	var avg_customers: float = (customer_range[0] + customer_range[1]) / 2.0
	var satisfaction: float = cook_score / 100.0
	record_customer_satisfaction(satisfaction)

	# Bonus for high scores (>70)
	var bonus_rep: float = 0.0
	if cook_score >= 70:
		bonus_rep += 2.0
	if cook_score >= 85:
		bonus_rep += 3.0
	if cook_score >= 95:
		bonus_rep += 5.0

	var total_rep_gain: float = rep_gain + bonus_rep
	add_reputation(total_rep_gain)

	result["base_rep"] = base_rep
	result["difficulty_multiplier"] = diff_mult
	result["rep_gain"] = rep_gain
	result["bonus_rep"] = bonus_rep
	result["total_rep_gained"] = total_rep_gain
	result["satisfaction"] = satisfaction
	result["customers_served"] = int(avg_customers)
	result["new_fame_level"] = get_fame_level()

	EventBus.emit("reputation_processed", result)
	return result