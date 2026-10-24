class_name DrawTable
extends Resource

## Unlimited weighted deck. Each draw picks one PlantDef by weight.
@export var entries: Array[DrawEntry] = []


func draw_one() -> PlantDef:
	var total := 0.0
	for entry in entries:
		if entry == null or entry.plant == null:
			continue
		total += maxf(entry.weight, 0.0)
	if total <= 0.0:
		push_error("DrawTable has no weighted entries")
		return null
	var roll := randf() * total
	var acc := 0.0
	for entry in entries:
		if entry == null or entry.plant == null:
			continue
		acc += maxf(entry.weight, 0.0)
		if roll <= acc:
			return entry.plant
	return entries[-1].plant


func draw_many(count: int) -> Array[PlantDef]:
	var result: Array[PlantDef] = []
	for _i in count:
		var card := draw_one()
		if card != null:
			result.append(card)
	return result
