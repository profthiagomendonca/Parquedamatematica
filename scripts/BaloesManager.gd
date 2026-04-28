extends Node2D

@onready var cards_container = $CardsContainer
@onready var score_label = $UI/HBoxContainer/ScoreLabel
@onready var music = $Music

var card_scene = preload("res://scenes/BaloonCard.tscn")

var shapes = {
	"circulo": preload("res://assets/Circulo.png"),
	"quadrado": preload("res://assets/Quadrado.png"),
	"triangulo": preload("res://assets/Triangulo.png"),
	"estrela": preload("res://assets/Estrela.png"),
	"hexagono": preload("res://assets/Hexágono.png"),
	"losango": preload("res://assets/Losango.png"),
	"pentagono": preload("res://assets/Pentagono.png"),
	"octogono": preload("res://assets/Octogono8.png"),
	"oval": preload("res://assets/Oval.png"),
	"paralelogramo": preload("res://assets/Paralelogramo.png"),
	"semicirculo": preload("res://assets/Semi_circulo.png"),
	"heptagono": preload("res://assets/Heptagono.png"),
	"eneagono": preload("res://assets/Eneagono.png"),
	"decagono": preload("res://assets/Decagono.png")
}

var first_choice = null
var second_choice = null
var can_click = true
var pairs_found = 0

# Sistema de Níveis: Pares [4, 6, 8, 10, 12, 14]
var current_level = 1
var grid_cols = 4
var grid_rows = 2
var total_pairs_needed = 4

func _ready():
	$UI/HBoxContainer/BackButton.pressed.connect(_on_back_pressed)
	music.play()
	setup_game()

func setup_game():
	# Limpa balões antigos
	for c in cards_container.get_children(): c.queue_free()
	
	pairs_found = 0
	total_pairs_needed = (grid_cols * grid_rows) / 2
	score_label.text = "Pares: 0 / " + str(total_pairs_needed)
	
	# 2. SELEÇÃO ALEATÓRIA DE FORMAS (Resolve o Ponto 2)
	var deck = []
	var shape_ids = shapes.keys()
	shape_ids.shuffle() # Embaralha as formas disponíveis
	
	# Pega apenas a quantidade necessária de formas para o nível atual
	for i in range(total_pairs_needed):
		var selected_shape = shape_ids[i]
		deck.append(selected_shape)
		deck.append(selected_shape)
	
	deck.shuffle()
	
	# 3. ESCALA E ESPAÇAMENTO DINÂMICO (Resolve o Ponto 1)
	var spacing_x = 320
	var spacing_y = 220
	var baloon_scale = 0.35
	
	if grid_cols == 4:
		spacing_x = 320
		spacing_y = 180 if grid_rows == 4 else 220
	elif grid_cols == 5:
		spacing_x = 240
		spacing_y = 170
		baloon_scale = 0.28
	elif grid_cols >= 6:
		spacing_x = 175 # Mais compacto
		spacing_y = 120 # Mais compacto verticalmente
		baloon_scale = 0.22
	
	for i in range(deck.size()):
		var card = card_scene.instantiate()
		card.scale = Vector2(baloon_scale, baloon_scale)
		cards_container.add_child(card)
		
		var col = i % grid_cols
		var row = i / grid_cols
		# Calculamos a posição e subimos 20 pixels (no Y) para tirar do limite de baixo
		var target_pos = Vector2((col - (grid_cols-1)/2.0) * spacing_x, ((row - (grid_rows-1)/2.0) * spacing_y) - 20)
		
		# MEMÓRIA VISUAL: Começa no centro, vai para o lugar
		card.position = Vector2.ZERO # Começa unido no centro
		card.setup(deck[i], shapes[deck[i]])
		
		# Animação de "se espalhar" (Vindo do centro para os lados)
		var t = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.tween_interval(0.05 * i) # Efeito cascata
		t.tween_property(card, "position", target_pos, 0.8)
		t.tween_callback(card.update_anchor)
		card.clicked.connect(_on_card_clicked)

func _on_card_clicked(card):
	if not can_click or card.is_open or card.is_matched:
		return
		
	# Evita clicar duas vezes na mesma carta
	if first_choice == card:
		return
		
	card.reveal_shape()
	_play_sound("res://Botao.mp3")
	
	if first_choice == null:
		first_choice = card
	else:
		second_choice = card
		_check_match()

func _check_match():
	can_click = false # Trava cliques durante a conferência (Bug prevention)
	
	if first_choice.shape_id == second_choice.shape_id:
		# ACERTOU!
		_play_sound("res://Acerto.mp3")
		first_choice.match_found()
		second_choice.match_found()
		pairs_found += 1
		score_label.text = "Pares: " + str(pairs_found) + " / " + str(total_pairs_needed)
		
		if pairs_found == total_pairs_needed:
			_victory()
	else:
		# ERROU! (Sem perder vida agora, só esconde)
		_play_sound("res://Erro.mp3")
		
		await get_tree().create_timer(0.5).timeout
		first_choice.hide_shape()
		second_choice.hide_shape()
	
	first_choice = null
	second_choice = null
	can_click = true

func _victory():
	_play_sound("res://Acerto.mp3")
	
	# Progride o nível seguindo a sequência de pares: [4, 6, 8, 10, 12, 14]
	current_level += 1
	match current_level:
		2: # 6 pares
			grid_cols = 4; grid_rows = 3
		3: # 8 pares
			grid_cols = 4; grid_rows = 4
		4: # 10 pares
			grid_cols = 5; grid_rows = 4
		5: # 12 pares
			grid_cols = 6; grid_rows = 4
		6: # 14 pares
			grid_cols = 7; grid_rows = 4
		_: # Reinicia
			current_level = 1
			grid_cols = 4; grid_rows = 2
	
	# Chuva de confetes
	var confete = Sprite2D.new()
	confete.texture = preload("res://assets/confete.png")
	confete.position = Vector2(640, 360)
	confete.scale = Vector2(0.1, 0.1)
	add_child(confete)
	
	var t = create_tween()
	t.tween_property(confete, "scale", Vector2(1.5, 1.5), 1.0).set_trans(Tween.TRANS_ELASTIC)
	
	await get_tree().create_timer(2.0).timeout
	confete.queue_free()
	setup_game()

func _game_over():
	# No jogo de memória sem vidas, o game over não é mais necessário
	# Mas podemos deixar o feedback visual se quiser
	pass

func _play_sound(path):
	var p = AudioStreamPlayer.new(); p.stream = load(path); add_child(p); p.play(); p.finished.connect(p.queue_free)

func _on_back_pressed():
	get_tree().change_scene_to_file("res://node_2d.tscn")
