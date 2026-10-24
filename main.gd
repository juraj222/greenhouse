extends Node2D

@onready var _backdrop: Sprite2D = $Backdrop


func _ready() -> void:
	_fit_backdrop()


func _fit_backdrop() -> void:
	if _backdrop == null or _backdrop.texture == null:
		return
	var tex_size := _backdrop.texture.get_size()
	var view := get_viewport_rect().size
	var scale := maxf(view.x / tex_size.x, view.y / tex_size.y)
	_backdrop.scale = Vector2(scale, scale)
	_backdrop.position = view * 0.5
