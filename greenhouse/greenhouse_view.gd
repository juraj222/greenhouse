extends Node2D

const BedSlotScene := preload("res://greenhouse/bed_slot.tscn")

## Velké sloty přímo v hlíně dřevěného truhlíku (viewport 1536×1024).
const COLS := 5
const SLOT_W := 200.0
const SLOT_H := 150.0
const GAP_X := 22.0
## Levý okraj první díry v hlíně + osa zadní / přední řady.
const BED_LEFT := 290.0
const ROW_TALL_Y := 500.0
const ROW_LOW_Y := 640.0

const BED_LIGHT := [
	PlantDef.LightLevel.LOW,
	PlantDef.LightLevel.LOW,
	PlantDef.LightLevel.MID,
	PlantDef.LightLevel.HIGH,
	PlantDef.LightLevel.HIGH,
]

const HANGING_LIGHT := [
	PlantDef.LightLevel.MID,
	PlantDef.LightLevel.HIGH,
	PlantDef.LightLevel.HIGH,
]


func _ready() -> void:
	_spawn_bed_row(PlantDef.RowKind.TALL, ROW_TALL_Y)
	_spawn_bed_row(PlantDef.RowKind.LOW, ROW_LOW_Y)
	_spawn_hanging()


func _spawn_bed_row(row: PlantDef.RowKind, y: float) -> void:
	for col in COLS:
		var slot: BedSlot = BedSlotScene.instantiate()
		slot.row_kind = row
		slot.light_level = BED_LIGHT[col]
		slot.position = Vector2(BED_LEFT + col * (SLOT_W + GAP_X) + SLOT_W * 0.5, y)
		slot.slot_size = Vector2(SLOT_W, SLOT_H)
		add_child(slot)


func _spawn_hanging() -> void:
	## Závěsy nad záhonem — menší než půdní sloty, ale pořád velké na klik.
	const hang_w := 140.0
	const hang_h := 110.0
	const hang_gap := 48.0
	var start_x := BED_LEFT + SLOT_W * 0.5 + 40.0
	for i in 3:
		var slot: BedSlot = BedSlotScene.instantiate()
		slot.row_kind = PlantDef.RowKind.HANGING
		slot.light_level = HANGING_LIGHT[i]
		slot.position = Vector2(start_x + i * (hang_w + hang_gap), 290.0)
		slot.slot_size = Vector2(hang_w, hang_h)
		add_child(slot)
