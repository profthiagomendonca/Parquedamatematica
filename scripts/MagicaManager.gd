extends Node2D

@onready var back_button = $UI/HBoxContainer/MarginContainer/BackButton
@onready var container_botoes = $UI/ItensCartolaContainer
@onready var instruction_label = $UI/InstructionLabel
@onready var status_label = $UI/HBoxContainer/ScoreLabel
@onready var confetti = $BackgroundLayer/ConfettiParticles
@onready var music = $Music

const ITEM_SCENE = preload("res://scenes/MagicaItem.tscn")

var cores_genius = [
	Color(0.9, 0.2, 0.3), # Vermelho
	Color(0.2, 0.8, 0.3), # Verde
	Color(0.2, 0.5, 0.9), # Azul
	Color(0.9, 0.8, 0.1), # Amarelo
	Color(0.6, 0.2, 0.8)  # Roxo
]

var ai_sequence = []
var player_step = 0
var player_turn = false
var pontuacao = 0

var audio_notas: Array[AudioStreamPlayer] = []
var som_erro: AudioStreamPlayer

func _ready():
	_setup_nodes()
	_setup_audio()
	back_button.pressed.connect(_on_back_pressed)
	
	music.finished.connect(func(): music.play())
	if not music.playing: music.play()
	
	# Aguarda a UI se estabilizar no primeiro quadro antes de criar os itens físicos
	await get_tree().process_frame
	
	build_magica_table()
	start_game()

func _setup_nodes():
	var posicoes = [$UI/Posicao1, $UI/Posicao2, $UI/Posicao3, $UI/Posicao4, $UI/Posicao5]
	for p in posicoes:
		p.visible = false # Esconde os quadrados vermelhos na hora do jogo

func _setup_audio():
	var base_stream = preload("res://Acerto.mp3")
	# Criando 5 tocadores isolados pra cada tom!
	for i in range(5):
		var p = AudioStreamPlayer.new()
		p.stream = base_stream
		p.pitch_scale = 0.8 + (i * 0.15) # Gera 5 alturas sonoras distintas (0.8, 0.95, 1.1...)
		add_child(p)
		audio_notas.append(p)
		
	som_erro = AudioStreamPlayer.new()
	som_erro.stream = preload("res://Erro.mp3") if FileAccess.file_exists("res://Erro.mp3") else base_stream
	if not FileAccess.file_exists("res://Erro.mp3"): som_erro.pitch_scale = 0.4
	add_child(som_erro)

func build_magica_table():
	for c in container_botoes.get_children():
		c.queue_free()
		
	var posicoes = [$UI/Posicao1, $UI/Posicao2, $UI/Posicao3, $UI/Posicao4, $UI/Posicao5]
		
	for i in range(5):
		var item = ITEM_SCENE.instantiate()
		container_botoes.add_child(item)
		# Centraliza o MEIO da cartola exatamente no meio do quadradinho vermelho!
		# Subtraímos o item.custom_minimum_size / 2 porque os nós Control ancoram pelo canto superior esquerdo!
		item.position = posicoes[i].position + (posicoes[i].size / 2) - (item.custom_minimum_size / 2)
		
		# 1, 2, 3, 4, 5. Indices 0 a 4
		item.setup(i + 1, cores_genius[i])
		item.item_pressed.connect(_on_item_pressed)

func start_game():
	ai_sequence.clear()
	pontuacao = 0
	_update_score()
	next_round()

func _update_score():
	status_label.text = "Acertos: " + str(pontuacao)

func next_round():
	player_turn = false
	player_step = 0
	
	# Adiciona mais 1 item de dificuldade
	ai_sequence.append(randi_range(1, 5))
	
	instruction_label.text = "Observe as luzes..."
	await get_tree().create_timer(1.0).timeout
	
	await play_sequence()
	
	instruction_label.text = "Sua vez!"
	player_turn = true

func play_sequence():
	for num in ai_sequence:
		if not is_inside_tree(): return # Corta a Mágica instantaneamente se a criança apertar Voltar durante o pisca-pisca.
		
		var btn = get_item_by_id(num)
		if btn and is_instance_valid(btn):
			btn.pisca()
			audio_notas[num - 1].play()
		await get_tree().create_timer(0.7).timeout

func get_item_by_id(id: int):
	for c in container_botoes.get_children():
		if c.identifier == id:
			return c
	return null

func _on_item_pressed(id: int):
	if not player_turn: return
	
	var expected_id = ai_sequence[player_step]
	var btn = get_item_by_id(id)
	
	if id == expected_id:
		# Acertou este passo
		btn.pisca()
		audio_notas[id - 1].play()
		player_step += 1
		
		# Venceu a rodada?
		if player_step >= ai_sequence.size():
			player_turn = false
			pontuacao += 1
			_update_score()
			instruction_label.text = "Muito bem!"
			if pontuacao % 5 == 0:
				confetti.emitting = true
			await get_tree().create_timer(1.5).timeout
			if not is_inside_tree(): return # Proteção cibernética de colapso Async - Caso a criança tenha ido pra tela inicial no meio do processo!
			next_round()
	else:
		# Errou a sequencia!
		player_turn = false
		btn.set_color_wrong()
		som_erro.play()
		instruction_label.text = "Ah não! Você errou :("
		
		var expected_btn = get_item_by_id(expected_id)
		if expected_btn:
			expected_btn.pisca() # Mostra qual era o botão que ele devia ter apertado!
		
		await get_tree().create_timer(3.0).timeout
		if not is_inside_tree(): return # Escudo de Colisão!
		
		instruction_label.text = "Vamos tentar novamente!"
		# Recomeça pra tela do inicio com itens apagados corretamente
		for c in container_botoes.get_children():
			if is_instance_valid(c): c.apaga()
		
		await get_tree().create_timer(1.0).timeout
		if not is_inside_tree(): return
		start_game()

func _on_back_pressed():
	get_tree().change_scene_to_file("res://node_2d.tscn")
