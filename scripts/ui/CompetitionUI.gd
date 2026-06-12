extends Control

## Competition scoring and results display

@onready var results_container: VBoxContainer = $VBoxContainer/ResultsContainer
@onready var rank_label: Label = $VBoxContainer/RankLabel
@onready var score_label: Label = $VBoxContainer/ScoreLabel
@onready var turnin_label: Label = $VBoxContainer/TurninLabel
@onready var continue_btn: Button = $VBoxContainer/ContinueBtn

func _ready() -> void:
	continue_btn.pressed.connect(_on_continue)

func display_results(scores: Dictionary) -> void:
	var total: float = 0.0
	for child in results_container.get_children():
		child.queue_free()
	
	for category in scores:
		var score = scores[category]
		total += score
		var label = Label.new()
		label.text = "%s: %.1f" % [category.capitalize(), score]
		results_container.add_child(label)
	
	score_label.text = "Total Score: %.1f" % total

func show_ranking(rank: int, total_entries: int) -> void:
	rank_label.text = "Rank: %d / %d" % [rank, total_entries]

func show_turnin_screen(meat_category: String) -> void:
	turnin_label.text = "Turn in %s:" % meat_category.capitalize()

func _on_continue() -> void:
	visible = false