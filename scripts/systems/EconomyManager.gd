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