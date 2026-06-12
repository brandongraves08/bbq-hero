extends Node
class_name RecipeManager

## Manages all recipes from data JSON and tracks which are unlocked

var _all_recipes: Array = []
var _unlocked_recipes: Array = []

signal recipe_unlocked(recipe_id: String)

func _ready() -> void:
	load_recipes()

func load_recipes() -> void:
	var file = FileAccess.open("res://data/recipes.json", FileAccess.READ)
	if file == null:
		push_error("Failed to load recipes.json")
		return
	var content = file.get_as_text()
	file.close()
	var json = JSON.new()
	var parse_result = json.parse(content)
	if parse_result != OK:
		push_error("Failed to parse recipes.json: ", json.get_error_message())
		return
	_all_recipes = json.data
	# Auto-unlock basic recipes
	for recipe in _all_recipes:
		var unlock = recipe.get("unlockCondition", {})
		if unlock.get("phase", 1) == 1 and unlock.get("reputationRequired", 0) == 0:
			_unlocked_recipes.append(recipe["id"])

func get_recipe(recipe_id: String) -> Dictionary:
	for recipe in _all_recipes:
		if recipe["id"] == recipe_id:
			return recipe
	return {}

func get_unlocked_recipes() -> Array:
	var result: Array = []
	for rid in _unlocked_recipes:
		result.append(get_recipe(rid))
	return result

func unlock_recipe(recipe_id: String) -> void:
	if recipe_id in _unlocked_recipes:
		return
	_unlocked_recipes.append(recipe_id)
	emit_signal("recipe_unlocked", recipe_id)

func is_recipe_unlocked(recipe_id: String) -> bool:
	return recipe_id in _unlocked_recipes

func get_recipes_by_type(type: String) -> Array:
	var result: Array = []
	for recipe in _all_recipes:
		if recipe.get("type") == type:
			result.append(recipe)
	return result

func get_recipes_for_meat(meat_category: String) -> Array:
	var result: Array = []
	for rid in _unlocked_recipes:
		var recipe = get_recipe(rid)
		var best_for = recipe.get("bestForMeats", [])
		if meat_category in best_for:
			result.append(recipe)
	return result

func check_and_unlock_new(phase: int, reputation: float) -> void:
	for recipe in _all_recipes:
		var unlock = recipe.get("unlockCondition", {})
		var req_phase = unlock.get("phase", 1)
		var req_rep = unlock.get("reputationRequired", 0)
		if phase >= req_phase and reputation >= req_rep:
			unlock_recipe(recipe["id"])