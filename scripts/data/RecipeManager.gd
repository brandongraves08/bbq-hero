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

## Crafted recipe inventory: recipe_id -> servings/batches on hand
var _crafted_recipes: Dictionary = {}

## Attempt to craft a recipe: checks affordability, deducts money, adds yield
func craft_recipe(recipe_id: String) -> bool:
	var recipe = get_recipe(recipe_id)
	if recipe.is_empty():
		return false
	var cost = recipe.get("costPerBatch", 0.0)
	if not EconomyManager.can_afford(cost):
		return false
	EconomyManager.spend(cost)
	var yield_amount = recipe.get("yieldAmount", 1)
	_crafted_recipes[recipe_id] = _crafted_recipes.get(recipe_id, 0) + yield_amount
	return true

## Check if player has at least `count` servings of a crafted recipe
func has_crafted_recipe(recipe_id: String, count: int = 1) -> bool:
	return _crafted_recipes.get(recipe_id, 0) >= count

## Use/consume crafted recipe servings
func use_recipe(recipe_id: String, count: int = 1) -> bool:
	if _crafted_recipes.get(recipe_id, 0) < count:
		return false
	_crafted_recipes[recipe_id] -= count
	if _crafted_recipes[recipe_id] <= 0:
		_crafted_recipes.erase(recipe_id)
	return true

## Get count of crafted servings for a recipe
func get_crafted_count(recipe_id: String) -> int:
	return _crafted_recipes.get(recipe_id, 0)

## Get all crafted recipes as {recipe_id: count}
func get_all_crafted() -> Dictionary:
	return _crafted_recipes.duplicate()

## Get recipes the player can afford
func get_craftable_recipes() -> Array:
	var result = []
	for rid in _unlocked_recipes:
		var recipe = get_recipe(rid)
		var cost = recipe.get("costPerBatch", 0.0)
		if EconomyManager.can_afford(cost):
			result.append(recipe)
	return result

## Get cook quality effects for a recipe
## Returns dict with bonus fields like bark_bonus, moisture_bonus, flavor_bonus
func get_recipe_effects(recipe_id: String) -> Dictionary:
	var recipe = get_recipe(recipe_id)
	if recipe.is_empty():
		return {}
	var rtype = recipe.get("type", "")
	match rtype:
		"rub":
			return {"bark_bonus": 0.15, "flavor_bonus": 0.10}
		"brine":
			return {"moisture_bonus": 0.15, "flavor_bonus": 0.05}
		"marinade":
			return {"moisture_bonus": 0.10, "tenderness_bonus": 0.10, "flavor_bonus": 0.05}
		"sauce":
			return {"taste_bonus": 0.15, "appearance_bonus": 0.05}
		"glaze":
			return {"appearance_bonus": 0.20, "caramelization_bonus": 0.10}
		_:
			return {"flavor_bonus": 0.05}