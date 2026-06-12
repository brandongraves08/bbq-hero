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