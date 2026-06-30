extends Node
class_name EconomyManager

## Manages all money, income, expenses, and daily P&L tracking

var money: float = 100.0
var daily_income: Dictionary = {}
var daily_expenses: Dictionary = {}
var daily_records: Array = []

signal money_changed(new_balance: float, delta: float)

func _ready() -> void:
	money = GameManager.money

func earn(amount: float, source: String) -> void:
	if amount <= 0:
		return
	money += amount
	GameManager.money = money
	if daily_income.has(source):
		daily_income[source] += amount
	else:
		daily_income[source] = amount
	emit_signal("money_changed", money, amount)

func spend(amount: float, category: String) -> bool:
	if amount <= 0:
		return false
	if money < amount:
		return false
	money -= amount
	GameManager.money = money
	if daily_expenses.has(category):
		daily_expenses[category] += amount
	else:
		daily_expenses[category] = amount
	emit_signal("money_changed", money, -amount)
	return true

func can_afford(amount: float) -> bool:
	return money >= amount

func get_daily_profit(day: int) -> float:
	if day < 0 or day >= daily_records.size():
		return 0.0
	var record = daily_records[day]
	return record.get("income", 0.0) - record.get("expenses", 0.0)

func get_total_profit() -> float:
	var total: float = 0.0
	for record in daily_records:
		total += record.get("income", 0.0) - record.get("expenses", 0.0)
	return total

func get_income_breakdown() -> Dictionary:
	return daily_income.duplicate()

func get_expense_breakdown() -> Dictionary:
	return daily_expenses.duplicate()

func reset_daily() -> void:
	var record = {
		"day": GameManager.current_day,
		"income": 0.0,
		"expenses": 0.0,
		"income_detail": daily_income.duplicate(),
		"expense_detail": daily_expenses.duplicate()
	}
	for source in daily_income:
		record["income"] += daily_income[source]
	for category in daily_expenses:
		record["expenses"] += daily_expenses[category]
	daily_records.append(record)
	daily_income.clear()
	daily_expenses.clear()

## ── Cook Result Processing ──────────────────────────────────────────────────
## Called after a cook completes to calculate earnings, tips, expenses.
## Returns a Dictionary with full breakdown for the day summary UI.
func process_cook_result(meat_data: Dictionary, cook_score: float, event_data: Dictionary, fuel_cost: float = 0.0) -> Dictionary:
	var result: Dictionary = {}
	result["cook_score"] = cook_score
	result["fuel_cost"] = fuel_cost

	# Track fuel expense
	if fuel_cost > 0.0:
		spend(fuel_cost, "fuel")

	# Track meat cost (approximate: weight × price_per_kg)
	var meat_weight: float = meat_data.get("weight", 5.0)
	var meat_cost_per_kg: float = 12.0  # Base cost per kg of meat
	var meat_cost: float = meat_weight * meat_cost_per_kg
	spend(meat_cost, "meat")
	result["meat_cost"] = meat_cost

	# Calculate base payout from event data
	var payout_range: Array = event_data.get("payoutRange", [50, 150])
	var base_payout: float = payout_range[0] + (payout_range[1] - payout_range[0]) * (cook_score / 100.0)
	base_payout = round(base_payout * 100.0) / 100.0

	# Score multiplier: score 0-100 maps to 0.3x - 1.5x
	var score_mult: float = 0.3 + (cook_score / 100.0) * 1.2
	var final_payout: float = round(base_payout * score_mult * 100.0) / 100.0

	# Tips: based on score with some randomness
	var rng = RandomNumberGenerator.new()
	var tip_mult: float = 0.1 + (cook_score / 100.0) * 0.4  # 0.1x-0.5x of payout
	tip_mult *= 1.0 + (rng.randf() - 0.5) * 0.4  # ±20% randomness
	var tips: float = round(final_payout * tip_mult * 100.0) / 100.0

	# Earn payout
	earn(final_payout, "gig_payout")
	earn(tips, "tips")

	result["base_payout"] = base_payout
	result["score_multiplier"] = score_mult
	result["final_payout"] = final_payout
	result["tips"] = tips
	result["total_earned"] = final_payout + tips
	result["total_expenses"] = fuel_cost + meat_cost
	result["net_profit"] = result["total_earned"] - result["total_expenses"]

	EventBus.emit("economy_processed", result)
	return result
