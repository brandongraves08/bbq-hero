extends Node
class_name UpgradeManager

## Manages purchased upgrades, skill levels, and available upgrades

var purchased_upgrades: Dictionary = {}
var skill_levels: Dictionary = {}
var skill_points: int = 0
var _all_upgrades: Array = []

signal upgrade_purchased(upgrade_id: String)
signal skill_leveled(skill_id: String, new_level: int)

func _ready() -> void:
	_load_all_upgrades()

func _load_all_upgrades() -> void:
	var file = FileAccess.open("res://data/upgrades.json", FileAccess.READ)
	if file == null:
		return
	var content = file.get_as_text()
	file.close()
	var json = JSON.new()
	var parse_result = json.parse(content)
	if parse_result != OK:
		return
	_all_upgrades = json.data

func purchase_upgrade(upgrade_id: String) -> bool:
	if purchased_upgrades.has(upgrade_id):
		return false
	
	var upgrade = _find_upgrade(upgrade_id)
	if upgrade.is_empty():
		return false
	
	var cost = upgrade.get("cost", 0)
	if not EconomyManager.spend(cost, "upgrades"):
		return false
	
	purchased_upgrades[upgrade_id] = true
	emit_signal("upgrade_purchased", upgrade_id)
	return true

func has_upgrade(upgrade_id: String) -> bool:
	return purchased_upgrades.has(upgrade_id)

func get_skill_level(skill_id: String) -> int:
	return skill_levels.get(skill_id, 0)

func add_skill_points(amount: int) -> void:
	skill_points += amount

func spend_skill_point(skill_id: String) -> bool:
	if skill_points <= 0:
		return false
	var current_level = skill_levels.get(skill_id, 0)
	skill_levels[skill_id] = current_level + 1
	skill_points -= 1
	emit_signal("skill_leveled", skill_id, skill_levels[skill_id])
	return true

func get_available_upgrades() -> Array:
	var available: Array = []
	var phase = GameManager.current_phase
	var rep = GameManager.reputation
	
	for upgrade in _all_upgrades:
		if purchased_upgrades.has(upgrade["id"]):
			continue
		var unlock = upgrade.get("unlockCondition", {})
		var req_phase = unlock.get("phase", 1)
		var req_rep = unlock.get("reputationRequired", 0)
		var req_skill = unlock.get("skillLevel", 0)
		
		if phase >= req_phase and rep >= req_rep:
			# Check all relevant skill requirements
			var skill_ok = true
			available.append(upgrade)
	
	return available

func get_purchased_upgrades() -> Array:
	var result: Array = []
	for uid in purchased_upgrades:
		var upg = _find_upgrade(uid)
		if not upg.is_empty():
			result.append(upg)
	return result

func apply_upgrade_effects(cooker_data: Dictionary) -> Dictionary:
	var modifiers = {}
	for uid in purchased_upgrades:
		var upg = _find_upgrade(uid)
		if upg.is_empty():
			continue
		var cooker_type = cooker_data.get("type", "")
		var compatible = upg.get("compatibleCookerTypes", "all")
		if compatible != "all" and cooker_type not in compatible:
			continue
		var effect = upg.get("effect", {})
		for key in effect:
			modifiers[key] = modifiers.get(key, 0.0) + effect[key]
	return modifiers

func _find_upgrade(upgrade_id: String) -> Dictionary:
	for upg in _all_upgrades:
		if upg["id"] == upgrade_id:
			return upg
	return {}