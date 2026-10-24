extends CanvasLayer

const CardViewScene := preload("res://ui/card_view.tscn")

@onready var _day_label: Label = %DayLabel
@onready var _score_label: Label = %ScoreLabel
@onready var _prompt_label: Label = %PromptLabel
@onready var _hand: HBoxContainer = %Hand
@onready var _end_day_button: Button = %EndDayButton
@onready var _harvest_button: Button = %HarvestButton
@onready var _status_panel: PanelContainer = %StatusPanel


func _ready() -> void:
	_style_status_panel()
	GameState.day_changed.connect(_on_day_changed)
	GameState.score_changed.connect(_on_score_changed)
	GameState.hand_changed.connect(_on_hand_changed)
	GameState.selected_card_changed.connect(_on_selected_changed)
	GameState.prompt_changed.connect(_on_prompt_changed)
	GameState.cards_played_changed.connect(_on_cards_played_changed)
	GameState.plants_changed.connect(_refresh_action_buttons)
	_end_day_button.pressed.connect(GameState.end_day)
	_harvest_button.pressed.connect(func() -> void: GameState.harvest_all_ready())
	_on_day_changed(GameState.day)
	_on_score_changed(GameState.score)
	_on_hand_changed(GameState.hand)
	_on_cards_played_changed(GameState.cards_played_today)
	_on_prompt_changed("Vyber kartu")


func _style_status_panel() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.1, 0.08, 0.82)
	style.border_color = Color(0.55, 0.65, 0.4, 0.55)
	style.set_border_width_all(1)
	style.set_corner_radius_all(14)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	_status_panel.add_theme_stylebox_override("panel", style)


func _on_day_changed(day: int) -> void:
	_day_label.text = "Den %d" % day
	_refresh_action_buttons()


func _on_score_changed(score: int) -> void:
	_score_label.text = "Skóre %d" % score


func _on_prompt_changed(text: String) -> void:
	_prompt_label.text = text


func _on_selected_changed(_index: int) -> void:
	_rebuild_hand()


func _on_hand_changed(_cards: Array) -> void:
	_rebuild_hand()
	_refresh_action_buttons()


func _on_cards_played_changed(_count: int) -> void:
	_refresh_action_buttons()


func _refresh_action_buttons() -> void:
	_end_day_button.disabled = not GameState.can_end_day()
	if GameState.can_end_day():
		_end_day_button.text = "Ukončit den"
	else:
		_end_day_button.text = "Ukončit den (zahraj kartu)"



func _rebuild_hand() -> void:
	for child in _hand.get_children():
		child.queue_free()
	for i in GameState.hand.size():
		var card: CardView = CardViewScene.instantiate()
		_hand.add_child(card)
		card.setup(i, GameState.hand[i], i == GameState.selected_card_index)
		card.card_clicked.connect(GameState.select_card)
