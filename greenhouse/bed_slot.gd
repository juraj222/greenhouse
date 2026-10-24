class_name BedSlot
extends Area2D

enum PlantState { EMPTY, THIRSTY, SHADED, GROWING, READY }

signal slot_pressed(slot: BedSlot)

@export var row_kind: PlantDef.RowKind = PlantDef.RowKind.LOW
@export var light_level: PlantDef.LightLevel = PlantDef.LightLevel.MID
@export var slot_size: Vector2 = Vector2(96, 72)

var _plant_def: PlantDef
var _days_elapsed: float = 0.0
var _water_days_left: int = 0
var _spoil_progress: float = 0.0

## Plne svetlo = 1.0 / den. O 1 stupen mene = 0.5. O 2 = 0.25.
const LIGHT_SLOW_RATES := {1: 0.5, 2: 0.25}
## Rychleji rostouci (mene growth_days) se kazi rychleji. Ref 3d = ~1 den kazeni pri plnem svetle.
const SPOIL_SPEED_REF := 3.0

@onready var _collision: CollisionShape2D = %Collision
@onready var _light_glow: Polygon2D = %LightGlow
@onready var _chip: PanelContainer = %StatusChip
@onready var _name_label: Label = %NameLabel
@onready var _progress: ProgressBar = %GrowthBar
@onready var _badge: Label = %BadgeLabel
@onready var _state_ring: Panel = %StateRing


func _ready() -> void:
	input_pickable = true
	_setup_layout()
	_refresh_visual()
	if GameState:
		GameState.register_slot(self)
		GameState.plants_changed.connect(_refresh_visual)


func _setup_layout() -> void:
	var shape := RectangleShape2D.new()
	shape.size = slot_size
	_collision.shape = shape
	var chip_h := clampf(slot_size.y * 0.42, 64.0, 88.0)
	_chip.position = Vector2(-slot_size.x * 0.5, -slot_size.y * 0.5 - chip_h * 0.35)
	_chip.size = Vector2(slot_size.x, chip_h)
	_state_ring.position = -slot_size * 0.5
	_state_ring.size = slot_size
	_name_label.add_theme_font_size_override("font_size", 16 if slot_size.x >= 160.0 else 12)
	_badge.add_theme_font_size_override("font_size", 14 if slot_size.x >= 160.0 else 11)
	_rebuild_light_glow()


func _rebuild_light_glow() -> void:
	var half := slot_size * 0.5
	_light_glow.polygon = PackedVector2Array([
		Vector2(-half.x, -half.y),
		Vector2(half.x, -half.y),
		Vector2(half.x, half.y),
		Vector2(-half.x, half.y),
	])


func _input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		slot_pressed.emit(self)
		_handle_click()


func _handle_click() -> void:
	if is_empty():
		GameState.try_plant_in_slot(self)
	elif is_ready_to_harvest():
		GameState.try_harvest_slot(self)
	elif needs_water():
		GameState.try_water_slot(self)
	else:
		GameState.prompt_changed.emit("Rostlina ted zalivku nepotrebuje")


func is_empty() -> bool:
	return _plant_def == null


func get_plant_def() -> PlantDef:
	return _plant_def


func needs_water() -> bool:
	if is_empty() or is_ready_to_harvest():
		return false
	return _water_days_left <= 0


func is_watered_today() -> bool:
	return not needs_water()


func is_ready_to_harvest() -> bool:
	if _plant_def == null:
		return false
	if _spoil_progress >= 1.0:
		return false
	return _days_elapsed >= float(_plant_def.growth_days)


func has_full_light() -> bool:
	if _plant_def == null:
		return true
	return light_level >= _plant_def.light_need


func light_growth_rate() -> float:
	if _plant_def == null or has_full_light():
		return 1.0
	var deficit := int(_plant_def.light_need) - int(light_level)
	return float(LIGHT_SLOW_RATES.get(deficit, 0.25))


func spoil_rate() -> float:
	## Stejne tempo jako rust: rychlejsi rust (kratke growth_days + vic svetla) = rychlejsi kazeni.
	var growth_days := float(maxi(_plant_def.growth_days, 1))
	return light_growth_rate() * (SPOIL_SPEED_REF / growth_days)


func get_plant_state() -> PlantState:
	if is_empty():
		return PlantState.EMPTY
	if is_ready_to_harvest():
		return PlantState.READY
	if needs_water():
		return PlantState.THIRSTY
	if not has_full_light():
		return PlantState.SHADED
	return PlantState.GROWING


func plant(def: PlantDef) -> bool:
	if not is_empty():
		return false
	_plant_def = def
	_days_elapsed = 0.0
	_spoil_progress = 0.0
	_water_days_left = maxi(def.water_interval_days, 1)
	_refresh_visual()
	return true


func water() -> void:
	if is_empty() or is_ready_to_harvest():
		return
	_water_days_left = maxi(_plant_def.water_interval_days, 1)
	_refresh_visual()


## Vraci true, pokud se sazenice behem tohoto dne zkazila.
func advance_day() -> bool:
	if is_empty():
		_refresh_visual()
		return false
	if is_ready_to_harvest():
		_spoil_progress += spoil_rate()
		if _spoil_progress >= 1.0:
			clear_plant()
			return true
		_refresh_visual()
		return false
	var water_ok := _water_days_left > 0
	if water_ok:
		_days_elapsed += light_growth_rate()
		_days_elapsed = minf(_days_elapsed, float(_plant_def.growth_days))
	if _water_days_left > 0:
		_water_days_left -= 1
	_refresh_visual()
	return false


func clear_plant() -> void:
	_plant_def = null
	_days_elapsed = 0.0
	_water_days_left = 0
	_spoil_progress = 0.0
	_refresh_visual()


func _refresh_visual() -> void:
	if _chip == null:
		return
	var state := get_plant_state()
	_apply_light_glow(state)
	_apply_state_ring(state)
	if state == PlantState.EMPTY:
		_chip.visible = false
		return
	_chip.visible = true
	_name_label.text = _plant_def.display_name
	match state:
		PlantState.READY:
			_progress.max_value = 1.0
			_progress.value = _spoil_progress
			_badge.text = "SKLID! kazi se %.0f%%" % (_spoil_progress * 100.0)
			_badge.modulate = Color(1.0, 0.85, 0.35)
			_set_chip_style(Color(0.28, 0.18, 0.08, 0.92), Color(0.95, 0.7, 0.2, 1), 3)
			_progress.modulate = Color(0.9, 0.45, 0.2)
		PlantState.THIRSTY:
			_progress.max_value = float(_plant_def.growth_days)
			_progress.value = _days_elapsed
			_badge.text = "chce vodu"
			_badge.modulate = Color(0.55, 0.8, 1.0)
			_set_chip_style(Color(0.25, 0.12, 0.1, 0.92), Color(0.95, 0.35, 0.25, 1), 3)
			_progress.modulate = Color(1.0, 0.5, 0.4)
		PlantState.SHADED:
			_progress.max_value = float(_plant_def.growth_days)
			_progress.value = _days_elapsed
			_badge.text = "pomalu (%.0f%% svetla)" % (light_growth_rate() * 100.0)
			_badge.modulate = Color(0.7, 0.75, 0.85)
			_set_chip_style(Color(0.12, 0.14, 0.2, 0.9), Color(0.45, 0.5, 0.65, 1), 2)
			_progress.modulate = Color(0.6, 0.65, 0.8)
		_:
			_progress.max_value = float(_plant_def.growth_days)
			_progress.value = _days_elapsed
			_badge.text = "ok | voda %dd" % _water_days_left
			_badge.modulate = Color(0.75, 0.95, 0.7)
			_set_chip_style(Color(0.1, 0.18, 0.1, 0.88), _plant_def.border_color, 2)
			_progress.modulate = Color(0.55, 0.9, 0.45)


func _set_chip_style(bg: Color, border: Color, width: int) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(10)
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	_chip.add_theme_stylebox_override("panel", style)


func _apply_state_ring(state: PlantState) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.set_corner_radius_all(8)
	match state:
		PlantState.EMPTY:
			_state_ring.visible = false
			return
		PlantState.READY:
			_state_ring.visible = true
			var warn := clampf(_spoil_progress, 0.0, 1.0)
			style.border_color = Color(1.0, 0.88, 0.2, 0.95).lerp(Color(0.55, 0.2, 0.1, 1.0), warn)
			style.set_border_width_all(3)
			style.bg_color = Color(1.0, 0.9, 0.3, 0.12).lerp(Color(0.4, 0.1, 0.05, 0.25), warn)
		PlantState.THIRSTY:
			_state_ring.visible = true
			style.border_color = Color(0.95, 0.3, 0.2, 0.9)
			style.set_border_width_all(3)
			style.bg_color = Color(0.9, 0.2, 0.15, 0.18)
		PlantState.SHADED:
			_state_ring.visible = true
			style.border_color = Color(0.4, 0.45, 0.6, 0.7)
			style.set_border_width_all(2)
			style.bg_color = Color(0.1, 0.12, 0.2, 0.22)
		_:
			_state_ring.visible = true
			style.border_color = Color(
				_plant_def.border_color.r,
				_plant_def.border_color.g,
				_plant_def.border_color.b,
				0.75
			)
			style.set_border_width_all(2)
			style.bg_color = Color(0.2, 0.45, 0.2, 0.08)
	_state_ring.add_theme_stylebox_override("panel", style)


func _apply_light_glow(state: PlantState) -> void:
	if state != PlantState.EMPTY:
		_light_glow.visible = false
		return
	_light_glow.visible = true
	match light_level:
		PlantDef.LightLevel.HIGH:
			_light_glow.color = Color(1.0, 0.92, 0.45, 0.22)
		PlantDef.LightLevel.MID:
			_light_glow.color = Color(0.85, 0.9, 0.55, 0.12)
		_:
			_light_glow.color = Color(0.35, 0.4, 0.35, 0.1)
