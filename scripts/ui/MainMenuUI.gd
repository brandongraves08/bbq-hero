extends Control

## Main menu UI controller

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var new_game_button: Button = $VBoxContainer/NewGameButton
@onready var load_game_button: Button = $VBoxContainer/LoadGameButton
@onready var quit_button: Button = $VBoxContainer/QuitButton

func _ready() -> void:
	new_game_button.pressed.connect(_on_new_game)
	load_game_button.pressed.connect(_on_load_game)
	quit_button.pressed.connect(_on_quit)
	
	# Disable load if no save exists
	if not FileAccess.file_exists("user://savegame.json"):
		load_game_button.disabled = true

func _on_new_game() -> void:
	GameManager.start_new_game()
	# Initialize EconomyManager and ReputationManager money/rep
	EconomyManager.money = GameManager.money
	ReputationManager.reputation = GameManager.reputation
	get_tree().change_scene_to_file("res://scenes/hub.tscn")

func _on_load_game() -> void:
	if GameManager.load_game():
		EconomyManager.money = GameManager.money
		ReputationManager.reputation = GameManager.reputation
		get_tree().change_scene_to_file("res://scenes/hub.tscn")

func _on_quit() -> void:
	GameManager.end_game()