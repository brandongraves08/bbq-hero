extends Control

## End-of-day summary screen

@onready var day_label: Label = $VBoxContainer/DayLabel
@onready var income_label: Label = $VBoxContainer/IncomeLabel
@onready var expenses_label: Label = $VBoxContainer/ExpensesLabel
@onready var profit_label: Label = $VBoxContainer/ProfitLabel
@onready var rep_delta_label: Label = $VBoxContainer/RepDeltaLabel
@onready var events_label: Label = $VBoxContainer/EventsLabel
@onready var continue_btn: Button = $VBoxContainer/ContinueBtn

func _ready() -> void:
	continue_btn.pressed.connect(_on_continue)

func show(day_data: Dictionary) -> void:
	day_label.text = "Day %d Summary" % day_data.get("day", GameManager.current_day)
	income_label.text = "Income: $%.0f" % day_data.get("income", 0.0)
	expenses_label.text = "Expenses: $%.0f" % day_data.get("expenses", 0.0)
	
	var profit = day_data.get("income", 0.0) - day_data.get("expenses", 0.0)
	var profit_text = "Profit: $%.0f" % profit
	if profit >= 0:
		profit_text = "+ " + profit_text
	profit_label.text = profit_text
	
	rep_delta_label.text = "Reputation Change: +%.0f" % day_data.get("reputation_delta", 0.0)
	
	var events_text = "Events: "
	var events = day_data.get("events", [])
	if events.is_empty():
		events_text += "None"
	else:
		events_text += ", ".join(events)
	events_label.text = events_text
	
	visible = true

func _on_continue() -> void:
	visible = false
	TimeManager.advance_time(8.0)