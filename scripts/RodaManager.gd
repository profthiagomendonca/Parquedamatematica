extends Node2D

@onready var back_button = $UI/HBoxContainer/MarginContainer/BackButton
@onready var instruction_label = $UI/InstructionLabel
@onready var status_label = $UI/HBoxContainer/ScoreLabel
@onready var music = $Music

var hora_alvo = 0
var minuto_alvo = -1 # -1 significa que estamos pedindo Hora Cheia
var pontuacao = 0
var game_active = true
@onready var cabines = [
	$UI/Cabine1, $UI/Cabine2, $UI/Cabine3, $UI/Cabine4,
	$UI/Cabine5, $UI/Cabine6, $UI/Cabine7, $UI/Cabine8,
	$UI/Cabine9, $UI/Cabine10, $UI/Cabine11, $UI/Cabine12
]

@onready var ponteiro_hora = %PonteiroHora
@onready var ponteiro_min = %PonteiroMin

var ponteiro_hora_orig: Sprite2D # Mantido para compatibilidade se necessário
var ponteiro_min_orig: Sprite2D

# Escalas-base dos ponteiros (ajustadas durante exibição conforme distância real)
var hora_base_scale := Vector2(0.3, 0.3)
var min_base_scale  := Vector2(0.25, 0.25)
const BASE_RADIUS   := 245.0 # raio médio da roda (média de 255 e 235)

@export var acerto_sfx: AudioStream
@export var erro_sfx: AudioStream

func _ready():
	_setup_hands()
	back_button.pressed.connect(_on_back_pressed)
	
	music.play()
	music.finished.connect(music.play)
	
	await get_tree().create_timer(0.5).timeout
	if not is_inside_tree(): return # Escudo de Colisão (async shield)
	
	_setup_manual_cabins()
	start_game()

func _setup_manual_cabins():
	for i in range(12):
		var btn = cabines[i]
		
		# Torna os botões invisíveis (mas ainda clicáveis!)
		var empty = StyleBoxEmpty.new()
		for state_name in ["normal", "hover", "pressed", "focus", "disabled"]:
			btn.add_theme_stylebox_override(state_name, empty)
			
		# Apagamos o texto (1 a 12) que estava só pra guiar o Godot Editor
		btn.text = "" 
		
		btn.pressed.connect(_on_cabin_pressed.bind(i + 1))

func _setup_hands():
	# Deixamos o quadrado vermelho invisível durante o jogo
	$UI/CentroDaRoda.visible = false
	
	# COPIA O DNA DO AMARELO e RECUAMOS UM POUCO (Pedida do usuário)
	ponteiro_min.global_position = ponteiro_hora.global_position
	# Adicionamos 15 ao Y para "puxar" o ponteiro mais para o centro (sentido da base)
	ponteiro_min.offset = Vector2(ponteiro_hora.offset.x, ponteiro_hora.offset.y + 15)
	
	# Ajustamos a base_scale para serem uniformes
	hora_base_scale = ponteiro_hora.scale
	min_base_scale = Vector2(ponteiro_hora.scale.x * 0.85, ponteiro_hora.scale.y * 1.2) # Um tiquinho mais fino e longo
	
	ponteiro_hora.visible = false
	ponteiro_min.visible = false

func next_question():
	game_active = true
	ponteiro_hora.visible = false
	ponteiro_min.visible = false
	
	# Sorteio 50/50 entre pedir Hora ou Minuto
	if randf() > 0.5:
		# Pede MINUTOS (Todos os múltiplos de 5)
		var todos_minutos = [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55]
		minuto_alvo = todos_minutos.pick_random()
		hora_alvo = -1
		instruction_label.text = "Onde ficam os " + str(minuto_alvo) + " minutos?"
	else:
		# Pede HORAS (1 a 12)
		minuto_alvo = -1
		hora_alvo = randi_range(1, 12)
		instruction_label.text = "Clique na cabine das " + str(hora_alvo) + " horas!"

func _on_cabin_pressed(id_cabine: int):
	if not game_active: return
	
	# Cálculo de validação
	var acertou = false
	if minuto_alvo != -1:
		# Minutos: Cabine 1 = 5, 2 = 10, ..., 12 = 0
		var min_convertido = (id_cabine * 5) % 60
		if min_convertido == minuto_alvo: acertou = true
		_mostrar_ponteiro(ponteiro_min, id_cabine)
	else:
		if id_cabine == hora_alvo: acertou = true
		_mostrar_ponteiro(ponteiro_hora, id_cabine)
		
	if acertou:
		_acertou()
	else:
		_errou()

func _mostrar_ponteiro(ponteiro: Sprite2D, id_cabine: int):
	# Pega o centro REAL do botão que o usuário posicionou na mão!
	var btn_center = cabines[id_cabine - 1].global_position + (cabines[id_cabine - 1].size / 2)
	
	# Se o Amarelo está perfeito, usamos a posição DELE como centro para ambos!
	var center_pos = ponteiro_hora.global_position 
	var direction = btn_center - center_pos
	
	ponteiro.rotation = direction.angle() + PI / 2
	
	# Escala de COMPRIMENTO dinâmica para compensar a perspectiva oval
	var base_scale = hora_base_scale if ponteiro == ponteiro_hora else min_base_scale
	
	# Calculamos o fator baseado na distância real da cabine selecionada
	# Usamos um raio de referência de 210px (média das distâncias)
	var fator_comprimento = direction.length() / 210.0
	
	# Aplicamos o fator apenas no Y (comprimento), mantendo o X (largura) fixo
	ponteiro.scale.x = base_scale.x
	ponteiro.scale.y = base_scale.y * fator_comprimento
	
	ponteiro.visible = true

func _acertou():
	game_active = false
	pontuacao += 1
	_update_score()
	instruction_label.text = "Muito bem! Acertou!"
	
	var p = AudioStreamPlayer.new()
	p.stream = preload("res://Acerto.mp3")
	add_child(p)
	p.play()
	p.finished.connect(p.queue_free)
	
	await get_tree().create_timer(2.0).timeout
	if not is_inside_tree(): return
	next_question()

func _errou():
	game_active = false # TRAVA CLIQUES enquanto o som de erro toca
	instruction_label.text = "Tente de novo! Onde estão as " + str(hora_alvo) + "h?"
	var p = AudioStreamPlayer.new()
	p.stream = preload("res://Erro.mp3") if FileAccess.file_exists("res://Erro.mp3") else preload("res://Acerto.mp3")
	if not FileAccess.file_exists("res://Erro.mp3"): p.pitch_scale = 0.5
	add_child(p)
	p.play()
	p.finished.connect(p.queue_free)
	
	# Aguarda a mensagem e som esfriarem antes de permitir novos cliques
	await get_tree().create_timer(2.0).timeout
	if not is_inside_tree(): return
	
	# Restaura o texto original do problema atual
	if minuto_alvo != -1:
		instruction_label.text = "Onde ficam os " + str(minuto_alvo) + " minutos?"
	else:
		instruction_label.text = "Clique na cabine das " + str(hora_alvo) + " horas!"
		
	game_active = true # LIBERA CLIQUES novamente

func _update_score():
	status_label.text = "Acertos: " + str(pontuacao)

func start_game():
	pontuacao = 0
	_update_score()
	next_question()



func _on_back_pressed():
	get_tree().change_scene_to_file("res://node_2d.tscn")
