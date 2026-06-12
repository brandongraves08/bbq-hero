extends Node
class_name InventoryManager

## Manages ingredients, equipment, storage, and equipped smoker

var ingredients: Dictionary = {}
var equipment: Dictionary = {}
var current_smoker_id: String = "rusty_offset"
var storage_capacity: int = 20
var storage_used: int = 0

signal inventory_changed(item_id: String, new_count: int)
signal smoker_changed(smoker_id: String)

func _ready() -> void:
	# Starter ingredients
	ingredients["salt"] = 5
	ingredients["black_pepper"] = 5
	ingredients["garlic_powder"] = 3
	ingredients["paprika"] = 2
	ingredients["brown_sugar"] = 2

func add_item(item_id: String, count: int) -> void:
	if ingredients.has(item_id):
		ingredients[item_id] += count
	else:
		ingredients[item_id] = count
	storage_used += count
	emit_signal("inventory_changed", item_id, ingredients[item_id])

func remove_item(item_id: String, count: int) -> bool:
	if not ingredients.has(item_id) or ingredients[item_id] < count:
		return false
	ingredients[item_id] -= count
	storage_used -= count
	if ingredients[item_id] <= 0:
		ingredients.erase(item_id)
	emit_signal("inventory_changed", item_id, ingredients.get(item_id, 0))
	return true

func has_item(item_id: String, count: int = 1) -> bool:
	return ingredients.get(item_id, 0) >= count

func get_item_count(item_id: String) -> int:
	return ingredients.get(item_id, 0)

func equip_smoker(smoker_id: String) -> void:
	current_smoker_id = smoker_id
	emit_signal("smoker_changed", smoker_id)

func get_equipped_smoker_id() -> String:
	return current_smoker_id

func get_inventory_as_dict() -> Dictionary:
	return {
		"ingredients": ingredients.duplicate(),
		"equipment": equipment.duplicate(),
		"current_smoker": current_smoker_id,
		"storage_used": storage_used,
		"storage_capacity": storage_capacity
	}

func get_storage_full_percent() -> float:
	return float(storage_used) / float(storage_capacity)

func is_storage_full() -> bool:
	return storage_used >= storage_capacity

func has_equipment(item_id: String) -> bool:
	return equipment.get(item_id, false)