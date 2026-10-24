extends Node

signal day_changed(day: int)
signal score_changed(score: int)
signal hand_changed(hand: Array)
signal selected_card_changed(index: int)
signal prompt_changed(text: String)
signal plants_changed
signal cards_played_changed(count: int)
signal run_started

const STARTING_HAND_SIZE := 7

var draw_table: Resource
var day: int = 1
var score: int = 0
var hand: Array = []
var selected_card_index: int = -1
var cards_played_today: int = 0
var _slots: Array = []


func _ready() -> void:
	if draw_table == null:
		draw_table = load("res://data/draw_table.tres")
	start_run()


func register_slot(slot: Node) -> void:
	if slot not in _slots:
		_slots.append(slot)


func start_run() -> void:
	day = 1
	score = 0
	cards_played_today = 0
	hand.clear()
	selected_card_index = -1
	for slot in _slots:
		slot.clear_plant()
	if draw_table != null and draw_table.has_method("draw_many"):
		hand = draw_table.draw_many(STARTING_HAND_SIZE)
	_emit_all()
	_update_prompt()
	run_started.emit()


func select_card(index: int) -> void:
	if index < 0 or index >= hand.size():
		selected_card_index = -1
	else:
		selected_card_index = index
	selected_card_changed.emit(selected_card_index)
	_update_prompt()


func get_selected_plant() -> Resource:
	if selected_card_index < 0 or selected_card_index >= hand.size():
		return null
	return hand[selected_card_index]


func can_end_day() -> bool:
	return cards_played_today >= 1


func try_plant_in_slot(slot: Node) -> bool:
	var plant_def = get_selected_plant()
	if plant_def == null:
		prompt_changed.emit("Nejdřív vyber kartu v ruce")
		return false
	if not slot.is_empty():
		prompt_changed.emit("Slot je obsazený")
		return false
	# Kazde misto je vhodne na kazdou sazenici.
	if not slot.plant(plant_def):
		return false
	hand.remove_at(selected_card_index)
	selected_card_index = -1
	cards_played_today += 1
	cards_played_changed.emit(cards_played_today)
	hand_changed.emit(hand)
	selected_card_changed.emit(selected_card_index)
	plants_changed.emit()
	_update_prompt()
	return true


func try_water_slot(slot: Node) -> bool:
	if slot.is_empty():
		return false
	if slot.is_ready_to_harvest():
		return false
	if not slot.needs_water():
		prompt_changed.emit("Rostlina teď zálivku nepotřebuje")
		return false
	slot.water()
	plants_changed.emit()
	_update_prompt()
	return true


func try_harvest_slot(slot: Node) -> bool:
	if slot.is_empty() or not slot.is_ready_to_harvest():
		return false
	return _harvest_slots([slot])


func harvest_all_ready() -> int:
	var harvestable: Array = []
	for slot in _slots:
		if slot.is_ready_to_harvest():
			harvestable.append(slot)
	if harvestable.is_empty():
		prompt_changed.emit("Nic ke sklizni")
		return 0
	_harvest_slots(harvestable)
	return harvestable.size()


func end_day() -> void:
	if not can_end_day():
		prompt_changed.emit("Nejdřív zahraj alespoň jednu kartu")
		return
	var spoiled := 0
	for slot in _slots:
		if slot.advance_day():
			spoiled += 1
	day += 1
	cards_played_today = 0
	cards_played_changed.emit(cards_played_today)
	day_changed.emit(day)
	plants_changed.emit()
	if spoiled > 0:
		prompt_changed.emit("Zkazilo se %d sazenic — priste sklid vcas" % spoiled)
	else:
		_update_prompt()


func combo_bonus_cards(harvest_count: int) -> int:
	if harvest_count <= 1:
		return 0
	return harvest_count - 1


func cards_from_harvest(harvest_count: int) -> int:
	return harvest_count + combo_bonus_cards(harvest_count)


func _harvest_slots(slots: Array) -> bool:
	var n := slots.size()
	if n == 0:
		return false
	var gained_score := 0
	for slot in slots:
		var def = slot.get_plant_def()
		if def != null:
			gained_score += def.score_value
		slot.clear_plant()
	score += gained_score
	score_changed.emit(score)
	var draws := cards_from_harvest(n)
	if draw_table != null and draw_table.has_method("draw_many"):
		var new_cards = draw_table.draw_many(draws)
		hand.append_array(new_cards)
	hand_changed.emit(hand)
	plants_changed.emit()
	if n >= 2:
		prompt_changed.emit("Combo ×%d! +%d karet, +%d skóre" % [n, draws, gained_score])
	else:
		prompt_changed.emit("Sklizeno! +%d karta, +%d skóre" % [draws, gained_score])
	return true


func _update_prompt() -> void:
	if get_selected_plant() != null:
		prompt_changed.emit("Vybrat místo pro výsadbu")
		return
	for slot in _slots:
		if slot.is_ready_to_harvest():
			prompt_changed.emit("Sklidit připravené sazenice")
			return
	for slot in _slots:
		if not slot.is_empty() and slot.needs_water():
			prompt_changed.emit("Některé rostliny chtějí zálivku")
			return
	if not can_end_day():
		prompt_changed.emit("Zahraj aspoň 1 kartu, pak ukonči den")
		return
	if hand.is_empty():
		prompt_changed.emit("Můžeš ukončit den")
	else:
		prompt_changed.emit("Sázej dál, zalévej potřebné, nebo ukonči den")


func _emit_all() -> void:
	day_changed.emit(day)
	score_changed.emit(score)
	hand_changed.emit(hand)
	selected_card_changed.emit(selected_card_index)
	cards_played_changed.emit(cards_played_today)
	plants_changed.emit()
