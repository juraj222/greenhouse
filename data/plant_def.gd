class_name PlantDef
extends Resource

enum LightLevel { LOW = 0, MID = 1, HIGH = 2 }
enum RowKind { LOW = 0, TALL = 1, HANGING = 2 }

@export var id: StringName = &""
@export var display_name: String = ""
@export var border_color: Color = Color.WHITE
@export var growth_days: int = 4
@export var light_need: LightLevel = LightLevel.MID
@export var water_interval_days: int = 1
@export var allowed_rows: Array[int] = []
@export var score_value: int = 10
@export var icon: Texture2D


func allows_row(_row: RowKind) -> bool:
	# Kazdy slot je vhodny pro kazdou sazenici.
	return true


func light_need_label() -> String:
	match light_need:
		LightLevel.LOW:
			return "málo"
		LightLevel.MID:
			return "střed"
		LightLevel.HIGH:
			return "hodně"
		_:
			return "?"
