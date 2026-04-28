extends Node2D

@onready var back_button = $UI/HBoxContainer/MarginContainer/BackButton
@onready var instruction_label = $UI/InstructionLabel
@onready var status_label = $UI/HBoxContainer/ScoreLabel
@onready var buttons_container = $UI/ButtonsContainer
@onready var music = $Music

# Precisamos criar 5 Labels na cena Montanha.tscn (vazios por padrão)
# e anexá-los aos personagens/carrinhos.
@onready var paineis_texto = [
	$UI/Painel1, $UI/Painel2, $UI/Painel3, $UI/Painel4, $UI/Painel5, $UI/Painel6, $UI/Painel7
]

var pontuacao = 0
var resposta_certa = 0
var posicao_vazia = 0
var game_active = true

func _ready():
	back_button.pressed.connect(_on_back_pressed)
	music.play()
	music.finished.connect(music.play)
	
	# Aguardar cena
	await get_tree().create_timer(0.1).timeout
	if not is_inside_tree(): return
	
	_setup_buttons()
	start_game()

func _setup_buttons():
	for btn in buttons_container.get_children():
		if btn is Button:
			if btn.pressed.get_connections().size() == 0:
				btn.pressed.connect(_on_option_pressed.bind(btn))
			
			var style = StyleBoxFlat.new()
			style.bg_color = Color(0.1, 0.4, 0.8, 0.9)
			style.set_corner_radius_all(30)
			style.set_border_width_all(6)
			style.border_color = Color(1.0, 1.0, 1.0, 1.0)
			btn.add_theme_stylebox_override("normal", style)
			
			var style_hover = style.duplicate()
			style_hover.bg_color = Color(0.2, 0.6, 1.0, 1.0)
			style_hover.set_border_width_all(8)
			btn.add_theme_stylebox_override("hover", style_hover)

func start_game():
	pontuacao = 0
	_update_score()
	next_question()

func next_question():
	game_active = true
	instruction_label.text = "Ajude o Mágico! Qual número falta?"
	
	# Lógica da Sequência
	var regras = [1, 2, 3, 4, 5, 10]
	var salto = regras.pick_random()
	var valor_inicial = randi_range(1, 10)
	
	# Escolhe o passageiro que estará com a placa "?"
	posicao_vazia = randi() % 7
	
	# Preenche os 7 paineis na tela
	for i in range(7):
		var num_real = valor_inicial + (i * salto)
		if i == posicao_vazia:
			resposta_certa = num_real
			paineis_texto[i].text = "?"
			paineis_texto[i].add_theme_color_override("font_color", Color.YELLOW)
		else:
			paineis_texto[i].text = str(num_real)
			paineis_texto[i].add_theme_color_override("font_color", Color.WHITE)
			
	_preencher_opcoes(resposta_certa)

func _preencher_opcoes(correta: int):
	var opcoes = [correta]
	while opcoes.size() < 3:
		var falsa = correta + randi_range(-5, 5)
		if falsa > 0 and not falsa in opcoes:
			opcoes.append(falsa)
			
	opcoes.shuffle()
	
	var idx = 0
	for btn in buttons_container.get_children():
		if btn is Button:
			btn.text = str(opcoes[idx])
			btn.disabled = false
			idx += 1
			var style = btn.get_theme_stylebox("normal") as StyleBoxFlat
			if style: style.bg_color = Color(0.1, 0.4, 0.8, 0.9)

func _on_option_pressed(btn: Button):
	if not game_active: return
	
	if int(btn.text) == resposta_certa:
		_acertou(btn)
	else:
		_errou(btn)

func _acertou(btn: Button):
	game_active = false
	pontuacao += 1
	_update_score()
	instruction_label.text = "Incrível! Tudo pronto para partir!"
	
	# Revela a resposta na plaquinha
	paineis_texto[posicao_vazia].text = str(resposta_certa)
	paineis_texto[posicao_vazia].add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))
	
	var style = btn.get_theme_stylebox("normal") as StyleBoxFlat
	if style: style.bg_color = Color(0.2, 0.8, 0.2, 0.9)
	
	var p = AudioStreamPlayer.new()
	p.stream = preload("res://Acerto.mp3")
	add_child(p)
	p.play()
	p.finished.connect(p.queue_free)
	
	# Tiramos o efeito de tremer o fundo que dava vertigem na Roda Gigante inteira!
	# Apenas uma comemoração verde suave na placa.
	
	await get_tree().create_timer(2.0).timeout
	if not is_inside_tree(): return
	next_question()

func _errou(btn: Button):
	game_active = false
	var texto_antigo = instruction_label.text
	instruction_label.text = "Oops! Observe o padrão saltando..."
	
	var style = btn.get_theme_stylebox("normal") as StyleBoxFlat
	if style: style.bg_color = Color(0.8, 0.2, 0.2, 0.9)
	
	var p = AudioStreamPlayer.new()
	p.stream = preload("res://Erro.mp3") if FileAccess.file_exists("res://Erro.mp3") else preload("res://Acerto.mp3")
	if not FileAccess.file_exists("res://Erro.mp3"): p.pitch_scale = 0.5
	add_child(p)
	p.play()
	p.finished.connect(p.queue_free)
	
	await get_tree().create_timer(3.0).timeout
	if not is_inside_tree(): return
	
	if style: style.bg_color = Color(0.1, 0.4, 0.8, 0.9)
	instruction_label.text = texto_antigo
	game_active = true

func _update_score():
	status_label.text = "Acertos: " + str(pontuacao)

func _on_back_pressed():
	get_tree().change_scene_to_file("res://node_2d.tscn")
