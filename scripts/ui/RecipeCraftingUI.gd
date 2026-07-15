extends Control
class_name RecipeCraftingUI

## Recipe / Prep Station screen — craft rubs, sauces, brines for cook bonuses

var _current_tab: int = 0
var _selected_recipe_id: String = ""
var _tab_filters: Array = ["rub", "sauce", "brine", "marinade", "glaze"]
var _tab_labels: Array = ["🌿 Rubs", "🍯 Sauces", "💧 Brines", "⚗️ Marinades", "🍯 Glazes"]
var _displayed_recipes: Array = []

## UI references (created in _setup_ui)
var _money_label: Label
var _tab_container: HBoxContainer
var _recipe_list_container: VBoxContainer
var _detail_panel: Panel
var _detail_name: Label
var _detail_type: Label
var _detail_ingredients: Label
var _detail_best_for: Label
var _detail_cost: Label
var _detail_owned: Label
var _notice_label: Label
var _craft_btn: Button

func _ready() -> void:
	_setup_background()
	_setup_ui()
	_refresh_list()
	_refresh_money()

func _setup_background() -> void:
	var bg = ColorRect.new()
	bg.color = Color(0.15, 0.08, 0.04)
	bg.anchors_preset = Control.PRESET_FULL_RECT
	add_child(bg)

func _setup_ui() -> void:
	var margin = MarginContainer.new()
	margin.anchors_preset = Control.PRESET_FULL_RECT
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.anchors_preset = Control.PRESET_FULL_RECT
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)
	
	# Header row
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 20)
	vbox.add_child(header)
	
	var title = Label.new()
	title.text = "🧑‍🍳 PREP STATION"
	title.theme_override_font_sizes["font_size"] = 28
	title.theme_override_colors["font_color"] = Color(1, 0.6, 0.2)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	
	_money_label = Label.new()
	_money_label.theme_override_font_sizes["font_size"] = 22
	header.add_child(_money_label)
	
	# Tab row
	_tab_container = HBoxContainer.new()
	_tab_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_tab_container.add_theme_constant_override("separation", 8)
	vbox.add_child(_tab_container)
	
	# Separator
	vbox.add_child(HSeparator.new())
	
	# Main content area (HBox: list + detail)
	var main_hbox = HBoxContainer.new()
	main_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_hbox.add_theme_constant_override("separation", 16)
	vbox.add_child(main_hbox)
	
	# Left: Recipe list (scrollable panel)
	var list_panel = Panel.new()
	list_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_panel.custom_minimum_size = Vector2(400, 0)
	main_hbox.add_child(list_panel)
	
	var list_margin = MarginContainer.new()
	list_margin.anchors_preset = Control.PRESET_FULL_RECT
	list_margin.add_theme_constant_override("margin_left", 12)
	list_margin.add_theme_constant_override("margin_right", 12)
	list_margin.add_theme_constant_override("margin_top", 12)
	list_margin.add_theme_constant_override("margin_bottom", 12)
	list_panel.add_child(list_margin)
	
	var list_vbox = VBoxContainer.new()
	list_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list_margin.add_child(list_vbox)
	
	var list_header = Label.new()
	list_header.text = "Available Recipes"
	list_header.theme_override_font_sizes["font_size"] = 16
	list_header.theme_override_colors["font_color"] = Color(1, 0.75, 0.35)
	list_vbox.add_child(list_header)
	
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list_vbox.add_child(scroll)
	
	_recipe_list_container = VBoxContainer.new()
	_recipe_list_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_recipe_list_container.add_theme_constant_override("separation", 4)
	scroll.add_child(_recipe_list_container)
	
	# Right: Detail panel
	_detail_panel = Panel.new()
	_detail_panel.custom_minimum_size = Vector2(350, 0)
	_detail_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	main_hbox.add_child(_detail_panel)
	
	var detail_margin = MarginContainer.new()
	detail_margin.anchors_preset = Control.PRESET_FULL_RECT
	detail_margin.add_theme_constant_override("margin_left", 16)
	detail_margin.add_theme_constant_override("margin_right", 16)
	detail_margin.add_theme_constant_override("margin_top", 12)
	detail_margin.add_theme_constant_override("margin_bottom", 12)
	_detail_panel.add_child(detail_margin)
	
	var detail_vbox = VBoxContainer.new()
	detail_vbox.add_theme_constant_override("separation", 6)
	detail_margin.add_child(detail_vbox)
	
	_detail_name = Label.new()
	_detail_name.theme_override_font_sizes["font_size"] = 20
	_detail_name.theme_override_colors["font_color"] = Color(1, 0.7, 0.3)
	detail_vbox.add_child(_detail_name)
	
	_detail_type = Label.new()
	_detail_type.theme_override_font_sizes["font_size"] = 14
	_detail_type.theme_override_colors["font_color"] = Color(0.8, 0.6, 0.4)
	detail_vbox.add_child(_detail_type)
	
	detail_vbox.add_child(HSeparator.new())
	
	_detail_best_for = Label.new()
	_detail_best_for.theme_override_font_sizes["font_size"] = 14
	_detail_best_for.theme_override_colors["font_color"] = Color(0.7, 0.8, 0.6)
	detail_vbox.add_child(_detail_best_for)
	
	_detail_ingredients = Label.new()
	_detail_ingredients.theme_override_font_sizes["font_size"] = 13
	_detail_ingredients.theme_override_colors["font_color"] = Color(0.75, 0.7, 0.55)
	detail_vbox.add_child(_detail_ingredients)
	
	_detail_cost = Label.new()
	_detail_cost.theme_override_font_sizes["font_size"] = 15
	detail_vbox.add_child(_detail_cost)
	
	_detail_owned = Label.new()
	_detail_owned.theme_override_font_sizes["font_size"] = 14
	detail_vbox.add_child(_detail_owned)
	
	_notice_label = Label.new()
	_notice_label.theme_override_font_sizes["font_size"] = 12
	_notice_label.theme_override_colors["font_color"] = Color(0.6, 0.5, 0.4)
	_notice_label.text = "Recipes are applied during cook setup.\nSelect a recipe before starting your cook."
	_notice_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_vbox.add_child(_notice_label)
	
	# Spacer
	var detail_spacer = Control.new()
	detail_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_vbox.add_child(detail_spacer)
	
	_craft_btn = Button.new()
	_craft_btn.text = "🔨 Craft Recipe"
	_craft_btn.custom_minimum_size = Vector2(0, 40)
	_craft_btn.theme_override_font_sizes["font_size"] = 16
	_craft_btn.pressed.connect(_on_craft)
	_craft_btn.disabled = true
	detail_vbox.add_child(_craft_btn)
	
	# Footer
	vbox.add_child(HSeparator.new())
	
	var footer = HBoxContainer.new()
	footer.add_theme_constant_override("separation", 12)
	vbox.add_child(footer)
	
	var back_btn = Button.new()
	back_btn.text = "🔙 Back to Hub"
	back_btn.custom_minimum_size = Vector2(200, 40)
	back_btn.theme_override_font_sizes["font_size"] = 16
	back_btn.pressed.connect(_on_back)
	footer.add_child(back_btn)
	
	var filler = Control.new()
	filler.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(filler)
	
	# Apply default font
	for child in get_tree().root.get_children():
		pass  # Theme is inherited

func _refresh_money() -> void:
	if EconomyManager:
		_money_label.text = "💰 $%.0f" % EconomyManager.money
		_money_label.theme_override_colors["font_color"] = Color(0.6, 1.0, 0.3)

func _refresh_tabs() -> void:
	for child in _tab_container.get_children():
		child.queue_free()
	
	for i in range(_tab_labels.size()):
		var btn = Button.new()
		btn.text = _tab_labels[i]
		btn.custom_minimum_size = Vector2(120, 32)
		btn.theme_override_font_sizes["font_size"] = 13
		var idx = i
		btn.pressed.connect(func(): _select_tab(idx))
		if i == _current_tab:
			btn.self_modulate = Color(1, 0.85, 0.3)
		_tab_container.add_child(btn)

func _select_tab(index: int) -> void:
	_current_tab = index
	_selected_recipe_id = ""
	_refresh_tabs()
	_refresh_list()
	_clear_detail()

func _refresh_list() -> void:
	for child in _recipe_list_container.get_children():
		child.queue_free()
	
	_displayed_recipes.clear()
	
	var filter = _tab_filters[_current_tab]
	
	# If "marinade_glaze" tab, show both marinades and glazes
	for rid in RecipeManager._unlocked_recipes:
		var recipe = RecipeManager.get_recipe(rid)
		if recipe.is_empty():
			continue
		var rtype = recipe.get("type", "")
		if rtype == filter:
			_displayed_recipes.append(recipe)
		# For the combined marinades/glazes tab (index 3), show both
		if _current_tab == 3 and (rtype == "marinade" or rtype == "glaze"):
			if recipe not in _displayed_recipes:
				_displayed_recipes.append(recipe)
	
	if _displayed_recipes.is_empty():
		var empty = Label.new()
		empty.text = "No recipes unlocked yet.\nComplete gigs to earn reputation and unlock more!"
		empty.theme_override_font_sizes["font_size"] = 13
		empty.theme_override_colors["font_color"] = Color(0.6, 0.5, 0.35)
		_recipe_list_container.add_child(empty)
		return
	
	for recipe in _displayed_recipes:
		var recipe_id = recipe.get("id", "")
		var name = recipe.get("name", "Unknown")
		var cost = recipe.get("costPerBatch", 0.0)
		var owned = RecipeManager.get_crafted_count(recipe_id)
		var can_afford = EconomyManager.can_afford(cost)
		
		var btn = Button.new()
		btn.text = "%s  ($%.0f)" % [name, cost]
		if owned > 0:
			btn.text += "  [Owned: %d]" % owned
		btn.size_flags_horizontal = Control.SIZE_FILL
		btn.custom_minimum_size = Vector2(0, 38)
		btn.theme_override_font_sizes["font_size"] = 14
		
		var rid = recipe_id
		btn.pressed.connect(func(): _select_recipe(rid))
		
		if not can_afford:
			btn.self_modulate = Color(0.4, 0.35, 0.3)
		
		_recipe_list_container.add_child(btn)

func _select_recipe(recipe_id: String) -> void:
	_selected_recipe_id = recipe_id
	var recipe = RecipeManager.get_recipe(recipe_id)
	if recipe.is_empty():
		return
	
	var name = recipe.get("name", "Unknown")
	var rtype = recipe.get("type", "unknown").capitalize()
	var best_for = recipe.get("bestForMeats", [])
	var ingredients = recipe.get("ingredients", [])
	var cost = recipe.get("costPerBatch", 0.0)
	var owned = RecipeManager.get_crafted_count(recipe_id)
	var effects = RecipeManager.get_recipe_effects(recipe_id)
	
	_detail_name.text = name
	_detail_type.text = "Type: %s" % rtype
	
	# Best for
	var best_text = "Best for: "
	for i in range(best_for.size()):
		best_text += best_for[i].capitalize()
		if i < best_for.size() - 1:
			best_text += ", "
	_detail_best_for.text = best_text
	
	# Ingredients
	var ing_text = "📋 Ingredients:\n"
	for ing in ingredients:
		var amt = ing.get("amount", 0)
		var unit = ing.get("unit", "")
		var ing_name = ing.get("name", "")
		ing_text += "  • %s %s %s\n" % [amt, unit, ing_name]
	_detail_ingredients.text = ing_text
	
	# Cost
	var can_afford = EconomyManager.can_afford(cost)
	_detail_cost.text = "💰 Cost: $%.0f per batch (yield: %d)" % [cost, recipe.get("yieldAmount", 1)]
	_detail_cost.theme_override_colors["font_color"] = Color(0.6, 1.0, 0.3) if can_afford else Color(1.0, 0.3, 0.3)
	
	# Owned
	_detail_owned.text = "🏪 In stock: %d servings" % owned
	_detail_owned.theme_override_colors["font_color"] = Color(0.85, 0.75, 0.5)
	
	# Effects
	var effect_text = "\n✨ Effects: "
	var effect_parts = []
	for key in effects:
		var val = effects[key] * 100
		effect_parts.append("%s +%.0f%%" % [key.replace("_bonus", "").capitalize(), val])
	effect_text += ", ".join(effect_parts)
	_notice_label.text = effect_text + "\n(Applied during cook setup.)"
	
	# Craft button
	_craft_btn.disabled = not can_afford
	_craft_btn.text = "🔨 Craft ($%.0f)" % cost

func _clear_detail() -> void:
	_detail_name.text = ""
	_detail_type.text = ""
	_detail_best_for.text = ""
	_detail_ingredients.text = ""
	_detail_cost.text = ""
	_detail_owned.text = ""
	_notice_label.text = "Select a recipe to see details."
	_craft_btn.disabled = true

func _on_craft() -> void:
	if _selected_recipe_id.is_empty():
		return
	if RecipeManager.craft_recipe(_selected_recipe_id):
		# Refresh
		_refresh_money()
		_refresh_list()
		_select_recipe(_selected_recipe_id)
		if AudioManager:
			AudioManager.play_ui_click()

func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/hub.tscn")
