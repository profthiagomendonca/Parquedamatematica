extends Node2D

@onready var back_button = $UI/HBoxContainer/MarginContainer/BackButton
@onready var score_label = $UI/HBoxContainer/ScoreLabel
@onready var instruction_label = $UI/InstructionLabel
@onready var target_label = $UI/TargetNumber
@onready var music = $Music

@onready var cavalos = [
	$UI/Cavalo1, $UI/Cavalo2, $UI/Cavalo3, $UI/Cavalo4, $UI/Cavalo5
]

var pontuacao = 0
var game_active = true
var target_value = 0
var som_acerto: AudioStreamPlayer
var som_erro: AudioStreamPlayer

func _ready():
	back_button.pressed.connect(_on_back_pressed)
	music.play()
	music.finished.connect(music.play)
	
	_setup_audio()
	
	for cavalo in cavalos:
		cavalo.pressed.connect(_on_cavalo_pressed.bind(cavalo))
	
	start_game()

func _setup_audio():
	som_acerto = AudioStreamPlayer.new()
	som_acerto.stream = preload("res://Acerto.mp3")
	add_child(som_acerto)
	
	som_erro = AudioStreamPlayer.new()
	if FileAccess.file_exists("res://Erro.mp3"):
		som_erro.stream = preload("res://Erro.mp3")
	else:
		som_erro.stream = preload("res://Acerto.mp3")
		som_erro.pitch_scale = 0.5
	add_child(som_erro)

func start_game():
	pontuacao = 0
	_update_score()
	next_round()

func _update_score():
	score_label.text = "Acertos: " + str(pontuacao)

func next_round():
	game_active = true
	instruction_label.text = "Ache a conta de resultado:"
	
	var is_division = randf() > 0.6 # 40% chance de ser divisão
	var result = 0
	var correct_str = ""
	
	if not is_division:
		var n1 = randi_range(2, 10)
		var n2 = randi_range(2, 10)
		result = n1 * n2
		correct_str = str(n1) + " x " + str(n2)
	else:
		var divisor = randi_range(2, 8)
		var target_ans = randi_range(2, 9)
		result = target_ans
		var div_total = divisor * target_ans
		correct_str = str(div_total) + " ÷ " + str(divisor)
		
	target_value = result
	target_label.text = str(result)
	
	# Restaurar estilo visual
	for cavalo in cavalos:
		cavalo.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1))
	
	# Criar 4 erradas
	var eq_strings = [correct_str]
	var results_present = [target_value]
	
	while eq_strings.size() < 5:
		var fake_str = ""
		var f_val = 0
		if randf() > 0.5:
			var fn1 = randi_range(2, 10)
			var fn2 = randi_range(2, 10)
			f_val = fn1 * fn2
			fake_str = str(fn1) + " x " + str(fn2)
		else:
			var fdiv = randi_range(2, 8)
			var f_ans = randi_range(2, 10)
			f_val = f_ans
			var ftot = fdiv * f_ans
			fake_str = str(ftot) + " ÷ " + str(fdiv)
				
		if fake_str != "" and not f_val in results_present:
			eq_strings.append(fake_str)
			results_present.append(f_val)
			
	eq_strings.shuffle()
	
	for i in range(5):
		cavalos[i].text = eq_strings[i]

func evaluate_string(expr: String) -> int:
	var parts = []
	if "x" in expr:
		parts = expr.split(" x ")
		return int(parts[0]) * int(parts[1])
	elif "÷" in expr:
		parts = expr.split(" ÷ ")
		if int(parts[1]) == 0: return 0
		return int(parts[0]) / int(parts[1])
	return 0

func _on_cavalo_pressed(btn: Button):
	if not game_active: return
	
	var val = evaluate_string(btn.text)
	
	if val == target_value:
		game_active = false
		som_acerto.play()
		btn.add_theme_color_override("font_color", Color(0.1, 0.9, 0.2))
		pontuacao += 1
		_update_score()
		instruction_label.text = "Exatamente!"
		
		# Animação de sucesso
		var tw = create_tween().set_trans(Tween.TRANS_SINE)
		btn.pivot_offset = btn.size / 2.0
		btn.scale = Vector2.ONE * 1.5
		tw.tween_property(btn, "scale", Vector2.ONE, 0.5)
		
		await get_tree().create_timer(1.5).timeout
		if not is_inside_tree(): return
		next_round()
	else:
		game_active = false
		som_erro.play()
		btn.add_theme_color_override("font_color", Color(0.9, 0.1, 0.1))
		
		var tw = create_tween().set_trans(Tween.TRANS_BOUNCE)
		btn.pivot_offset = btn.size / 2.0
		tw.tween_property(btn, "rotation", 0.2, 0.1)
		tw.tween_property(btn, "rotation", -0.2, 0.1)
		tw.tween_property(btn, "rotation", 0.0, 0.1)
		
		var texto_antigo = instruction_label.text
		instruction_label.text = "Não! " + btn.text + " = " + str(val)
		
		await get_tree().create_timer(2.0).timeout
		if not is_inside_tree(): return
		instruction_label.text = texto_antigo
		btn.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1))
		game_active = true

func _on_back_pressed():
	get_tree().change_scene_to_file("res://node_2d.tscn")
