extends Control

## Upgrade shop and skill tree UI

@onready var upgrade_list: ItemList = $VBoxContainer/UpgradeList
@onready var upgrade_desc: Label = $VBoxContainer/UpgradeDesc
@onready var purchase_btn: Button = $VBoxContainer/PurchaseBtn
@onready var skill_tree_container: VBoxContainer = $VBoxContainer/SkillTreeContainer
@onready var skill_points_label: Label = $VBoxContainer/SkillPointsLabel

var _available_upgrades: Array = []
var _selected_upgrade_id: String = ""

func _ready() -> void:
	purchase_btn.pressed.connect(_on_purchase)
	upgrade_list.item_selected.connect(_on_upgrade_selected)

func populate_upgrade_list(upgrades: Array) -> void:
	_available_upgrades = upgrades
	upgrade_list.clear()
	for upgrade in upgrades:
		upgrade_list.add_item(upgrade.get("name", "Unknown"))
	skill_points_label.text = "Skill Points: %d" % GameManager.skill_points

func _on_upgrade_selected(index: int) -> void:
	if index < 0 or index >= _available_upgrades.size():
		return
	var upgrade = _available_upgrades[index]
	_selected_upgrade_id = upgrade.get("id", "")
	upgrade_desc.text = upgrade.get("description", "")
	upgrade_desc.text += "\n\nCost: $%.0f" % upgrade.get("cost", 0)
	purchase_btn.disabled = not EconomyManager.can_afford(upgrade.get("cost", 0))

func _on_purchase() -> void:
	if _selected_upgrade_id.is_empty():
		return
	if UpgradeManager.purchase_upgrade(_selected_upgrade_id):
		populate_upgrade_list(UpgradeManager.get_available_upgrades())
		upgrade_desc.text = ""
		_selected_upgrade_id = ""

func populate_skill_tree(skills: Dictionary) -> void:
	for child in skill_tree_container.get_children():
		child.queue_free()
	
	for skill_id in skills:
		var level = skills[skill_id]
		var hbox = HBoxContainer.new()
		var name_label = Label.new()
		name_label.text = "%s (Level %d)" % [skill_id, level]
		hbox.add_child(name_label)
		
		var level_btn = Button.new()
		level_btn.text = "+"
		level_btn.pressed.connect(_on_level_skill.bind(skill_id))
		hbox.add_child(level_btn)
		
		skill_tree_container.add_child(hbox)

func _on_level_skill(skill_id: String) -> void:
	if UpgradeManager.spend_skill_point(skill_id):
		populate_skill_tree(UpgradeManager.skill_levels)
		skill_points_label.text = "Skill Points: %d" % UpgradeManager.skill_points