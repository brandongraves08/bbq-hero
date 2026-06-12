extends Node
class_name FuelManager

## Manages fuel data, retrieval, and compatibility queries

var _all_fuels: Array = []

func _ready() -> void:
	load_fuels()

func load_fuels() -> void:
	var file = FileAccess.open("res://data/fuels.json", FileAccess.READ)
	if file == null:
		push_error("Failed to load fuels.json")
		return
	var content = file.get_as_text()
	file.close()
	var json = JSON.new()
	var parse_result = json.parse(content)
	if parse_result != OK:
		push_error("Failed to parse fuels.json: ", json.get_error_message())
		return
	_all_fuels = json.data

func get_fuel(fuel_id: String) -> Dictionary:
	for fuel in _all_fuels:
		if fuel["id"] == fuel_id:
			return fuel
	return {}

func get_fuels_by_type(type: String) -> Array:
	var result: Array = []
	for fuel in _all_fuels:
		if fuel.get("type") == type:
			result.append(fuel)
	return result

func get_compatible_fuels(cooker_type: String) -> Array:
	var result: Array = []
	for fuel in _all_fuels:
		var compatible = fuel.get("compatibleCookerTypes", [])
		if cooker_type in compatible:
			result.append(fuel)
	return result

func get_all_fuels() -> Array:
	return _all_fuels