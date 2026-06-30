extends Control
class_name UpgradeShopUI

## ── Upgrade Shop Screen ─────────────────────────────────────────────────────
## Shows available upgrades and skill points for the player to spend.
## Player can purchase upgrades and level up skills between gigs.

@onready var money_label: Label = $MarginContainer/VBox/HeaderRow/MoneyLabel
@onready var sp_label: Label = $MarginContainer/VBox/HeaderRow/SPLabel
@onready var upgrade_container: VBoxContainer = $MarginContainer/VBox/ScrollContainer/VBox/UpgradeList
@onready var no_upgrades_label: Label = $MarginContainer/VBox/ScrollContainer/VBox/NoUpgradesLabel
@onready var back_btn: Button = $MarginContainer/VBox/FooterRow/BackBtn
@onready var success_label: Label = $MarginContainer/VBox/FooterRow/SuccessLabel

func _ready() -> void:
	back_btn.pressed.connect(_on_back)
	_refresh_display()
	_populate_upgrades()

func _refresh_display() -> void:
	money_label.text = "$%.0f" % EconomyManager.money
	sp_label.text = "Skill Pts: %d" % GameManager.skill_points

func _populate_upgrades() -> void:
	for child in upgrade_container.get_children():
		if child != no_upgrades_label:
			child.queue_free()

	var available = UpgradeManager.get_available_upgrades()
	if available.is_empty():
		no_upgrades_label.visible = true
		return

	no_upgrades_label.visible = false

	for upgrade in available:
		var card = _create_upgrade_card(upgrade)
		upgrade_container.add_child(card)

func _create_upgrade_card(upgrade: Dictionary) -> Panel:
	var card = Panel.new()
	card.custom_minimum_size = Vector2(0, 80)

	var margin = MarginContainer.new()
	margin.theme_override_constants["margin_left"] = 12
	margin.theme_override_constants["margin_right"] = 12
	margin.theme_override_constants["margin_top"] = 8
	margin.theme_override_constants["margin_bottom"] = 8
	card.add_child(margin)

	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(hbox)

	# Info
	var info = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info)

	var name_lbl = Label.new()
	name_lbl.text = upgrade.get("name", "Unknown Upgrade")
	name_lbl.theme_override_font_sizes = {"font_size": 16}
	name_lbl.theme_override_colors = {"font_color": Color(1, 0.75, 0.35)}
	info.add_child(name_lbl)

	var desc_lbl = Label.new()
	desc_lbl.text = upgrade.get("description", "")
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_lbl.theme_override_font_sizes = {"font_size": 12}
	desc_lbl.theme_override_colors = {"font_color": Color(0.7, 0.65, 0.5)}
	desc_lbl.custom_minimum_size = Vector2(0, 24)
	info.add_child(desc_lbl)

	# Buy button
	var btn_vbox = VBoxContainer.new()
	btn_vbox.alignment = BoxContainer.ALIGN_CENTER
	hbox.add_child(btn_vbox)

	var buy_btn = Button.new()
	var cost = upgrade.get("cost", 0)
	var upg_id = upgrade.get("id", "")
	buy_btn.text = "Buy: $%d" % cost
	buy_btn.custom_minimum_size = Vector2(130, 40)
	buy_btn.disabled = EconomyManager.money < cost

	buy_btn.pressed.connect(func():
		if UpgradeManager.purchase_upgrade(upg_id):
			_refresh_display()
			_populate_upgrades()
			_show_success("Purchased: %s!" % upgrade.get("name", ""))
		else:
			_show_success("Not enough money!")
	)
	btn_vbox.add_child(buy_btn)

	return card

func _show_success(msg: String) -> void:
	success_label.text = msg
	success_label.visible = true
	await get_tree().create_timer(2.0).timeout
	success_label.visible = false

func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/hub.tscn")