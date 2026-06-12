extends Node
class_name CookerManager

## Manages cooker data, ownership, and factory creation of FireSystem instances

var _all_cookers: Array = []
var _owned_cookers: Array = []
var _active_cooker_id: String = "rusty_offset"

signal cooker_purchased(cooker_id: String)
signal cooker_equipped(cooker_id: String)

func _ready() -> void:
	load_cookers()
	# Starting cooker
	_owned_cookers.append("rusty_offset")

func load_cookers() -> void:
	var file = FileAccess.open("res://data/smokers.json", FileAccess.READ)
	if file == null:
		push_error("Failed to load smokers.json")
		return
	var content = file.get_as_text()
	file.close()
	var json = JSON.new()
	var parse_result = json.parse(content)
	if parse_result != OK:
		push_error("Failed to parse smokers.json: ", json.get_error_message())
		return
	_all_cookers = json.data

func get_cooker(cooker_id: String) -> Dictionary:
	for cooker in _all_cookers:
		if cooker["id"] == cooker_id:
			return cooker
	return {}

func get_available_cookers() -> Array:
	var available: Array = []
	var phase = GameManager.current_phase
	var rep = GameManager.reputation
	for cooker in _all_cookers:
		if cooker["id"] in _owned_cookers:
			continue
		var unlock = cooker.get("unlockCondition", {})
		var req_phase = unlock.get("phase", 1)
		var req_rep = unlock.get("reputationRequired", 0)
		if phase >= req_phase and rep >= req_rep:
			available.append(cooker)
	return available

func purchase_cooker(cooker_id: String) -> bool:
	if cooker_id in _owned_cookers:
		return false
	var cooker = get_cooker(cooker_id)
	if cooker.is_empty():
		return false
	var price = cooker.get("price", 0)
	if not EconomyManager.spend(price, "equipment"):
		return false
	_owned_cookers.append(cooker_id)
	emit_signal("cooker_purchased", cooker_id)
	return true

func equip_cooker(cooker_id: String) -> void:
	if cooker_id not in _owned_cookers:
		return
	_active_cooker_id = cooker_id
	emit_signal("cooker_equipped", cooker_id)

func get_owned_cookers() -> Array:
	var result: Array = []
	for cid in _owned_cookers:
		result.append(get_cooker(cid))
	return result

func make_cooker_instance(cooker_id: String) -> FireSystem:
	var cooker_data = get_cooker(cooker_id)
	if cooker_data.is_empty():
		return null
	var fire_system = FireSystem.new()
	fire_system.configure(cooker_data)
	return fire_system

func get_upgrade_slots(cooker_id: String) -> Array:
	var cooker = get_cooker(cooker_id)
	return cooker.get("upgradeSlots", [])