extends Control
class_name GigSelectUI

## ── Gig Selection Screen ────────────────────────────────────────────────────
## Shows available gigs/events filtered by current phase and reputation.
## Player picks a gig → goes to cook scene with that gig's parameters.
##
## Flow: hub → gig_select → first_playable (cook)

@onready var title_label: Label = $MarginContainer/VBox/HeaderRow/TitleLabel
@onready var rep_label: Label = $MarginContainer/VBox/HeaderRow/RepLabel
@onready var money_label: Label = $MarginContainer/VBox/HeaderRow/MoneyLabel
@onready var gig_container: VBoxContainer = $MarginContainer/VBox/ScrollContainer/VBox/GigList
@onready var back_btn: Button = $MarginContainer/VBox/FooterRow/BackBtn
@onready var no_gigs_label: Label = $MarginContainer/VBox/ScrollContainer/VBox/NoGigsLabel

var _available_gigs: Array = []
var _selected_gig_id: String = ""

func _ready() -> void:
	back_btn.pressed.connect(_on_back)
	_refresh_display()
	_populate_gig_list()

	# Listen for rep changes (gig availability may change)
	ReputationManager.reputation_changed.connect(_on_rep_changed)

func _refresh_display() -> void:
	rep_label.text = "Rep: %d" % GameManager.reputation
	money_label.text = "$%.0f" % EconomyManager.money

	# Phase label
	match GameManager.current_phase:
		GameManager.Phase.ONE:
			title_label.text = "🔥 Gig Board — Backyard Cookouts"
		GameManager.Phase.TWO:
			title_label.text = "🚚 Gig Board — Food Truck Events"
		GameManager.Phase.THREE:
			title_label.text = "🍽️ Gig Board — Restaurant Service"

func _on_rep_changed(_new: float, _delta: float) -> void:
	_refresh_display()
	_populate_gig_list()

## Populate the gig list from EventManager filtered by current phase and reputation
func _populate_gig_list() -> void:
	# Clear existing gig cards (keep NoGigsLabel)
	for child in gig_container.get_children():
		if child != no_gigs_label:
			child.queue_free()

	_available_gigs = EventManager.get_gigs_for_phase(GameManager.current_phase)

	if _available_gigs.is_empty():
		no_gigs_label.visible = true
		no_gigs_label.text = "No gigs available yet. Build your reputation to unlock more!"
		return

	no_gigs_label.visible = false

	# Sort: competitions first, then by difficulty
	_available_gigs.sort_custom(func(a: Dictionary, b: Dictionary) -> int:
		var type_a = a.get("type", "gig")
		var type_b = b.get("type", "gig")
		if type_a == "competition" and type_b != "competition":
			return -1
		elif type_a != "competition" and type_b == "competition":
			return 1
		return a.get("difficulty", 1) - b.get("difficulty", 1)
	)

	for gig in _available_gigs:
		var card = _create_gig_card(gig)
		gig_container.add_child(card)

## Creates a visual gig card panel with gig info
func _create_gig_card(gig: Dictionary) -> Panel:
	var card = Panel.new()
	card.custom_minimum_size = Vector2(0, 120)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var margin = MarginContainer.new()
	margin.theme_override_constants["margin_left"] = 12
	margin.theme_override_constants["margin_right"] = 12
	margin.theme_override_constants["margin_top"] = 8
	margin.theme_override_constants["margin_bottom"] = 8
	card.add_child(margin)

	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(hbox)

	# ── Left: Gig Info ─────────────────────────────────────────────────────
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)

	# Name row
	var name_hbox = HBoxContainer.new()
	info_vbox.add_child(name_hbox)

	var type_icon = ""
	match gig.get("type", "gig"):
		"competition": type_icon = "🏆 "
		"challenge": type_icon = "⚡ "
		_: type_icon = "🔥 "

	var name_label = Label.new()
	name_label.text = type_icon + gig.get("name", "Unknown Gig")
	name_label.theme_override_font_sizes = {"font_size": 18}
	name_label.theme_override_colors = {"font_color": Color(1, 0.75, 0.35)}
	name_hbox.add_child(name_label)

	# Difficulty badges
	var diff = gig.get("difficulty", 1)
	var diff_label = Label.new()
	var diff_stars = ""
	for i in range(diff): diff_stars += "🔥"
	diff_label.text = "  " + diff_stars
	diff_label.theme_override_font_sizes = {"font_size": 14}
	diff_label.theme_override_colors = {"font_color": Color(1, 0.5, 0.1)}
	name_hbox.add_child(diff_label)

	# Description
	var desc_label = Label.new()
	desc_label.text = gig.get("description", "")
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_label.theme_override_font_sizes = {"font_size": 12}
	desc_label.theme_override_colors = {"font_color": Color(0.7, 0.65, 0.5)}
	desc_label.custom_minimum_size = Vector2(0, 32)
	desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_child(desc_label)

	# Metadata row
	var meta_hbox = HBoxContainer.new()
	meta_hbox.theme_override_constants["separation"] = 20
	info_vbox.add_child(meta_hbox)

	var payout_range = gig.get("payoutRange", [0, 0])
	var payout_label = Label.new()
	payout_label.text = "💰 $%d-$%d" % [payout_range[0], payout_range[1]]
	payout_label.theme_override_font_sizes = {"font_size": 12}
	payout_label.theme_override_colors = {"font_color": Color(0.6, 1, 0.3)}
	meta_hbox.add_child(payout_label)

	var customer_range = gig.get("customerCountRange", [0, 0])
	var cust_label = Label.new()
	cust_label.text = "👥 %d-%d guests" % [customer_range[0], customer_range[1]]
	cust_label.theme_override_font_sizes = {"font_size": 12}
	cust_label.theme_override_colors = {"font_color": Color(0.8, 0.7, 0.5)}
	meta_hbox.add_child(cust_label)

	var time_limit = gig.get("timeLimitMin", 0)
	var time_label = Label.new()
	var hours = time_limit / 60
	var mins = time_limit % 60
	time_label.text = "⏱ %dh %02dm" % [hours, mins]
	time_label.theme_override_font_sizes = {"font_size": 12}
	time_label.theme_override_colors = {"font_color": Color(0.7, 0.8, 1)}
	meta_hbox.add_child(time_label)

	# Meat requirements
	var meats = gig.get("meatRequirements", [])
	if not meats.is_empty():
		var meat_str = ""
		for m in meats:
			if not meat_str.is_empty(): meat_str += ", "
			meat_str += "%s (%.0fkg)" % [m.get("meatType", "?"), m.get("quantityKg", 0)]
		var meat_label = Label.new()
		meat_label.text = "🥩 " + meat_str
		meat_label.theme_override_font_sizes = {"font_size": 11}
		meat_label.theme_override_colors = {"font_color": Color(0.65, 0.55, 0.4)}
		meta_hbox.add_child(meat_label)

	# ── Right: Select Button ──────────────────────────────────────────────
	var btn_vbox = VBoxContainer.new()
	btn_vbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_vbox.alignment = BoxContainer.ALIGN_CENTER
	hbox.add_child(btn_vbox)

	var select_btn = Button.new()
	select_btn.text = "🔥 Cook"
	select_btn.custom_minimum_size = Vector2(140, 48)
	select_btn.theme_override_font_sizes = {"font_size": 16}

	var gig_id = gig.get("id", "")
	var is_competition = gig.get("type") == "competition"
	var btn_text = "🔥 Compete!" if is_competition else "🔥 Cook"
	select_btn.text = btn_text

	select_btn.pressed.connect(func():
		if is_competition:
			# For competitions, show more intense language
			pass
		_selected_gig_id = gig_id
		_start_gig(gig_id)
	)
	btn_vbox.add_child(select_btn)

	return card

## Start the selected gig and transition to the cook scene
func _start_gig(event_id: String) -> void:
	# Select the event in EventManager
	var success = EventManager.select_gig(event_id)
	if not success:
		push_error("GigSelectUI: Failed to start gig '%s'" % event_id)
		return

	# Set active gig in GameManager
	GameManager.start_gig(event_id)

	# Transition to the cook scene
	get_tree().change_scene_to_file("res://scenes/first_playable.tscn")

func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/hub.tscn")