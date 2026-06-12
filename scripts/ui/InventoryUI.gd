extends Control

## Inventory and ingredient display

@onready var ingredient_list: ItemList = $VBoxContainer/IngredientList
@onready var equipment_list_widget: ItemList = $VBoxContainer/EquipmentList
@onready var detail_label: Label = $VBoxContainer/DetailLabel
@onready var storage_label: Label = $VBoxContainer/StorageLabel

func _ready() -> void:
	ingredient_list.item_selected.connect(_on_ingredient_selected)
	InventoryManager.inventory_changed.connect(_on_inventory_changed)

func refresh_display() -> void:
	ingredient_list.clear()
	var inv = InventoryManager.get_inventory_as_dict()
	var ingredients = inv.get("ingredients", {})
	
	for item_id in ingredients:
		var count = ingredients[item_id]
		ingredient_list.add_item("%s: %d" % [item_id.capitalize(), count])
	
	storage_label.text = "Storage: %d/%d" % [inv.get("storage_used", 0), inv.get("storage_capacity", 20)]
	show_equipment_list(inv.get("equipment", {}))

func show_ingredient_detail(item_id: String) -> void:
	var count = InventoryManager.get_item_count(item_id)
	detail_label.text = "%s\nCount: %d" % [item_id.capitalize(), count]

func show_equipment_list(equipment: Dictionary) -> void:
	equipment_list_widget.clear()
	for equip_id in equipment:
		if equipment[equip_id]:
			equipment_list_widget.add_item(equip_id.capitalize())

func _on_ingredient_selected(index: int) -> void:
	var metadata = ingredient_list.get_item_text(index)
	var item_id = metadata.split(":")[0].strip_edges().to_lower()
	show_ingredient_detail(item_id)

func _on_inventory_changed(item_id: String, count: int) -> void:
	refresh_display()