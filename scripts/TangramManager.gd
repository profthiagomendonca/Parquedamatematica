extends Node2D

@onready var back_button = $UI/HBoxContainer/BackButton
@onready var score_label = $UI/HBoxContainer/ScoreLabel
@onready var instruction_label = $UI/InstructionLabel
@onready var music = $Music

@onready var silhouette_pos = $Anchors/CentroDaSombra
@onready var slot1 = $Anchors/Slot1
@onready var slot2 = $Anchors/Slot2
@onready var slot3 = $Anchors/Slot3
@onready var pieces_container = $PiecesContainer
@onready var stars = [$UI/StarsContainer/Star1, $UI/StarsContainer/Star2, $UI/StarsContainer/Star3]

var tex_star_full = preload("res://assets/estrela_viva.png")
var tex_star_empty = preload("res://assets/estrela_vazia.png")

var selected_animal = null
var drag_offset = Vector2.ZERO
var pontuacao = 0
var level = 0
var vidas = 3

# BANCO DE DADOS FINAL (43 Níveis ativos)
var animals_db = {
	0: {"name": "Águia", "file": "res://assets/tangram/Aguia.png"},
	1: {"name": "Alce", "file": "res://assets/tangram/Alce.png"},
	2: {"name": "Árvore", "file": "res://assets/tangram/Arvore.png"},
	3: {"name": "Avião", "file": "res://assets/tangram/Aviao.png"},
	4: {"name": "Bailarina", "file": "res://assets/tangram/Bailarina.png"},
	5: {"name": "Balão", "file": "res://assets/tangram/Balão.png"},
	6: {"name": "Barco", "file": "res://assets/tangram/Barco.png"},
	7: {"name": "Borboleta", "file": "res://assets/tangram/Borboleta.png"},
	8: {"name": "Bota", "file": "res://assets/tangram/Bota.png"},
	9: {"name": "Cachorro", "file": "res://assets/tangram/Cachorro.png"},
	10: {"name": "Camelo", "file": "res://assets/tangram/Camelo.png"},
	11: {"name": "Canguru", "file": "res://assets/tangram/Canguru.png"},
	12: {"name": "Caracol", "file": "res://assets/tangram/Caracol.png"},
	13: {"name": "Casa", "file": "res://assets/tangram/Casa.png"},
	14: {"name": "Cavalo", "file": "res://assets/tangram/Cavalo.png"},
	15: {"name": "Chapéu", "file": "res://assets/tangram/Chapeu.png"},
	16: {"name": "Chave", "file": "res://assets/tangram/Chave.png"},
	17: {"name": "Cisne", "file": "res://assets/tangram/Cisne.png"},
	18: {"name": "Coelho", "file": "res://assets/tangram/Coelho.png"},
	19: {"name": "Coração", "file": "res://assets/tangram/Coracao.png"},
	20: {"name": "Coruja", "file": "res://assets/tangram/Coruja.png"},
	21: {"name": "Elefante", "file": "res://assets/tangram/Elefante.png"},
	22: {"name": "Estrela", "file": "res://assets/tangram/Estrela.png"},
	23: {"name": "Foguete", "file": "res://assets/tangram/Foguete.png"},
	24: {"name": "Fórmula 1", "file": "res://assets/tangram/Formula 1.png"},
	25: {"name": "Gato", "file": "res://assets/tangram/Gato.png"},
	26: {"name": "Girafa", "file": "res://assets/tangram/Girafa.png"},
	27: {"name": "Guarda-chuva", "file": "res://assets/tangram/Guarda_chuva.png"},
	28: {"name": "Helicóptero", "file": "res://assets/tangram/Helicoptero.png"},
	29: {"name": "Atleta", "file": "res://assets/tangram/Homem_correndo.png"},
	30: {"name": "Leão", "file": "res://assets/tangram/Leao.png"},
	31: {"name": "Lua", "file": "res://assets/tangram/Lua.png"},
	32: {"name": "Martelo", "file": "res://assets/tangram/Martelo.png"},
	33: {"name": "Pato", "file": "res://assets/tangram/Pato.png"},
	34: {"name": "Peixe", "file": "res://assets/tangram/Peixe.png"},
	35: {"name": "T-Rex", "file": "res://assets/tangram/Rex.png"},
	36: {"name": "Sorvete", "file": "res://assets/tangram/Sorvete.png"},
	37: {"name": "Tartaruga", "file": "res://assets/tangram/Tartaruga.png"},
	38: {"name": "Trator", "file": "res://assets/tangram/Trator.png"},
	39: {"name": "Tubarão", "file": "res://assets/tangram/Tubarao.png"},
	40: {"name": "Vela", "file": "res://assets/tangram/Vela.png"},
	41: {"name": "Violão", "file": "res://assets/tangram/Violao.png"},
	42: {"name": "Xícara", "file": "res://assets/tangram/Xicara.png"}
}

func _ready():
	back_button.pressed.connect(_on_back_pressed)
	music.play()
	music.finished.connect(music.play)
	silhouette_pos.visible = false
	slot1.visible = false
	slot2.visible = false
	slot3.visible = false
	
	vidas = 3
	update_stars_ui()
	setup_level()

func update_stars_ui():
	for i in range(3):
		stars[i].texture = tex_star_full if i < vidas else tex_star_empty

func setup_level():
	# Limpeza de segurança
	selected_animal = null
	drag_offset = Vector2.ZERO
	
	for c in pieces_container.get_children(): c.queue_free()
	for c in get_tree().get_nodes_in_group("current_silhouette"): c.queue_free()
	
	instruction_label.text = "Qual imagem completa a sombra?"
	
	if not FileAccess.file_exists(animals_db[level].file):
		level = (level + 1) % animals_db.size()
		return

	var current_animal_data = animals_db[level]
	var silhouette = _create_animal_object(current_animal_data, true)
	if silhouette:
		silhouette.global_position = silhouette_pos.global_position
		silhouette.add_to_group("current_silhouette")
		silhouette.scale = Vector2(1.5, 1.5)
		add_child(silhouette)
	
	var available_options = []
	for k in animals_db.keys():
		if FileAccess.file_exists(animals_db[k].file):
			available_options.append(k)
	
	var option_indices = [level]
	while option_indices.size() < min(3, available_options.size()):
		var r = available_options[randi() % available_options.size()]
		if not r in option_indices: option_indices.append(r)
	option_indices.shuffle()
	
	var slots = [slot1, slot2, slot3]
	var i = 0
	for idx in option_indices:
		var animal_opt = _create_animal_object(animals_db[idx], false)
		if animal_opt:
			animal_opt.scale = Vector2(0.85, 0.85)
			animal_opt.global_position = slots[i].global_position 
			animal_opt.set_meta("animal_id", idx)
			animal_opt.set_meta("original_pos", animal_opt.global_position)
			pieces_container.add_child(animal_opt)
			_make_interactive(animal_opt)
		i += 1

func _create_animal_object(data, is_silhouette):
	var node = Sprite2D.new()
	var tex = load(data.file)
	if tex:
		node.texture = tex
		if is_silhouette:
			node.modulate = Color(0.1, 0.1, 0.1, 0.7)
		return node
	return null

func _make_interactive(node):
	var area = Area2D.new()
	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new(); shape.size = Vector2(300, 300)
	col.shape = shape
	area.add_child(col)
	node.add_child(area)
	area.input_event.connect(_on_animal_input.bind(node))

func _on_animal_input(_v, event, _idx, node):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			selected_animal = node
			drag_offset = node.global_position - get_global_mouse_position()
			node.z_index = 100
			get_viewport().set_input_as_handled()

func _input(event):
	if selected_animal:
		if event is InputEventMouseMotion:
			selected_animal.global_position = get_global_mouse_position() + drag_offset
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			_check_match(selected_animal)
			selected_animal.z_index = 0
			selected_animal = null

func _check_match(node):
	var dist = node.global_position.distance_to(silhouette_pos.global_position)
	if dist < 80 and node.get_meta("animal_id") == level:
		node.global_position = silhouette_pos.global_position
		var shadow = get_tree().get_nodes_in_group("current_silhouette")[0]
		shadow.visible = false
		var tween = get_tree().create_tween().set_parallel(true)
		tween.tween_property(node, "scale", Vector2(1.5, 1.5), 0.2)
		instruction_label.text = "Acertou! É o(a) " + animals_db[level].name
		_play_sound("res://Acerto.mp3")
		pontuacao += 1; score_label.text = "Puzzles: " + str(pontuacao)
		await get_tree().create_timer(2.0).timeout
		
		# SORTEIO ALEATÓRIO: Escolhe um novo nível que não seja o atual
		var next_level = level
		while next_level == level:
			next_level = randi() % animals_db.size()
		level = next_level
		
		setup_level()
	else:
		# ERROU: Perde uma vida
		vidas -= 1
		update_stars_ui()
		_play_sound("res://Erro.mp3")
		
		# Feedback visual de erro rápido
		instruction_label.text = "Ops! Tente outro!"
		
		if vidas <= 0:
			instruction_label.text = "Que pena, você perdeu!"
			_play_sound("res://Erro.mp3") # Som de derrota
			await get_tree().create_timer(2.5).timeout
			vidas = 3
			update_stars_ui()
			level = randi() % animals_db.size() # Sorteia um novo para o recomeço
			setup_level()
		else:
			# Troca a imagem mesmo no erro (conforme solicitado)
			await get_tree().create_timer(1.0).timeout
			level = randi() % animals_db.size()
			setup_level()

func _play_sound(path):
	var p = AudioStreamPlayer.new(); p.stream = load(path); add_child(p); p.play(); p.finished.connect(p.queue_free)

func _on_back_pressed():
	get_tree().change_scene_to_file("res://node_2d.tscn")
