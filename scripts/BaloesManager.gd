extends Node2D

@onready var cards_container = $CardsContainer
@onready var back_button = $UI/HBoxContainer/BackButton
@onready var score_label = $UI/HBoxContainer/ScoreLabel
@onready var instruction_label = $UI/InstructionLabel
@onready var music = $Music
@onready var stars = [$UI/StarsContainer/Star1, $UI/StarsContainer/Star2, $UI/StarsContainer/Star3]

var card_scene = preload("res://scenes/BaloonCard.tscn")
var tex_star_full = preload("res://assets/estrela_viva.png")
var tex_star_empty = preload("res://assets/estrela_vazia.png")

var shapes = {
	"circulo": preload("res://assets/Circulo.png"),
	"quadrado": preload("res://assets/Quadrado.png"),
	"triangulo": preload("res://assets/Triangulo.png"),
	"estrela": preload("res://assets/Estrela.png"),
	"hexagono": preload("res://assets/Hexágono.png"),
	"losango": preload("res://assets/Losango.png")
}

var first_choice = null
var second_choice = null
var can_click = true
var pairs_found = 0
var vidas = 3

func _ready():
	back_button.pressed.connect(_on_back_pressed)
	music.play()
	
	update_stars_ui()
	setup_game()

func update_stars_ui():
	for i in range(stars.size()):
		stars[i].texture = tex_star_full if i < vidas else tex_star_empty

func setup_game():
	# Limpa balões antigos
	for c in cards_container.get_children(): c.queue_free()
	
	pairs_found = 0
	score_label.text = "Pares: 0"
	instruction_label.text = "Encontre os pares de formas!"
	vidas = 3
	update_stars_ui()
	
	# Cria 12 itens (6 pares)
	var deck = []
	for id in shapes.keys():
		deck.append(id)
		deck.append(id)
	
	deck.shuffle()
	
	# Posidionamento em Grid 4 colunas x 3 linhas - Espaçamento aumentado para evitar sobreposição
	var cols = 4
	var spacing_x = 320 # Aumentado significativamente
	var spacing_y = 200 # Aumentado significativamente
	
	for i in range(deck.size()):
		var card = card_scene.instantiate()
		card.scale = Vector2(0.32, 0.32) # Um pouco menor para garantir o espaço
		cards_container.add_child(card)
		
		var col = i % cols
		var row = i / cols
		# Centraliza com o novo espaçamento
		card.position = Vector2((col - 1.5) * spacing_x, (row - 1.0) * spacing_y)
		
		card.setup(deck[i], shapes[deck[i]])
		card.clicked.connect(_on_card_clicked)

func _on_card_clicked(card):
	if not can_click or card == first_choice: return
	
	_play_sound("res://Acerto.mp3") # Som de clique/inflar
	card.reveal()
	
	if first_choice == null:
		first_choice = card
	else:
		second_choice = card
		can_click = false
		_check_match()

func _check_match():
	await get_tree().create_timer(0.6).timeout
	
	if first_choice.shape_id == second_choice.shape_id:
		# ACERTOU!
		_play_sound("res://Acerto.mp3")
		first_choice.match_found()
		second_choice.match_found()
		pairs_found += 1
		score_label.text = "Pares: " + str(pairs_found)
		
		if pairs_found == 6:
			_victory()
	else:
		# ERROU!
		vidas -= 1
		update_stars_ui()
		_play_sound("res://Erro.mp3")
		
		await get_tree().create_timer(0.5).timeout
		first_choice.hide_shape()
		second_choice.hide_shape()
		
		if vidas <= 0:
			_game_over()
	
	first_choice = null
	second_choice = null
	can_click = true

func _victory():
	instruction_label.text = "Incrível! Você completou a barraca!"
	_play_sound("res://Acerto.mp3")
	
	# Chuva de confetes
	var confete = Sprite2D.new()
	confete.texture = preload("res://assets/confete.png")
	confete.position = Vector2(640, 360)
	confete.scale = Vector2(0.1, 0.1)
	add_child(confete)
	
	var t = create_tween()
	t.tween_property(confete, "scale", Vector2(1.5, 1.5), 1.0).set_trans(Tween.TRANS_ELASTIC)
	
	await get_tree().create_timer(3.0).timeout
	setup_game()

func _game_over():
	instruction_label.text = "Que pena! Tente de novo!"
	await get_tree().create_timer(2.0).timeout
	setup_game()

func _play_sound(path):
	var p = AudioStreamPlayer.new(); p.stream = load(path); add_child(p); p.play(); p.finished.connect(p.queue_free)

func _on_back_pressed():
	get_tree().change_scene_to_file("res://node_2d.tscn")
