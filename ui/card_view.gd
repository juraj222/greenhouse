class_name CardView
extends PanelContainer

signal card_clicked(index: int)

var card_index: int = -1
var plant_def: PlantDef

@onready var _name_label: Label = %NameLabel
@onready var _info_label: Label = %InfoLabel
@onready var _icon: ColorRect = %ColorBar
@onready var _days_label: Label = %DaysLabel


func setup(index: int, def: PlantDef, selected: bool) -> void:
	card_index = index
	plant_def = def
	if _name_label == null:
		await ready
	_name_label.text = def.display_name
	_days_label.text = "%d d" % def.growth_days
	_info_label.text = "svetlo %s | voda %d d | %d b" % [
		def.light_need_label(),
		maxi(def.water_interval_days, 1),
		def.score_value,
	]
	_icon.color = def.border_color
	_apply_selected(selected)


func _apply_selected(selected: bool) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.14, 0.16, 0.12, 0.94)
	style.border_color = plant_def.border_color if plant_def else Color.WHITE
	style.set_border_width_all(4 if selected else 2)
	style.set_corner_radius_all(12)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	if selected:
		style.shadow_color = Color(
			plant_def.border_color.r,
			plant_def.border_color.g,
			plant_def.border_color.b,
			0.45
		)
		style.shadow_size = 8
	add_theme_stylebox_override("panel", style)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		card_clicked.emit(card_index)
