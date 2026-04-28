extends Node

class_name LevelManager

@onready var label_status: Label = $UI/VBoxContainer/FooterMargin/FooterHBox/HUD/LabelStatus
@onready var back_button: Button = $UI/VBoxContainer/FooterMargin/FooterHBox/BackButton
@onready var stars_container: HBoxContainer = $UI/VBoxContainer/FooterMargin/FooterHBox/HUD/StarsContainer

const CUP_SCENE = preload("res://scenes/Cup.tscn")
const SNAP_POINT_SCENE = preload("res://scenes/SnapPoint.tscn")

var target_cups: int = 0
var current_cups: int = 0
var num1: int = 0
var num2: int = 0
var is_subtraction: bool = false
var is_setup: bool = false
var level_finished: bool = false
var streak: int = 0
var max_streak: int = 5

@onready var confetti: CPUParticles2D = $BackgroundLayer/ConfettiParticles
@onready var star_viva = preload("res://assets/estrela_viva.png")
@onready var star_vazia = preload("res://assets/estrela_vazia.png")

var som_acerto: AudioStreamPlayer
var bg_music: AudioStreamPlayer

func _ready() -> void:
	som_acerto = AudioStreamPlayer.new()
	som_acerto.stream = preload("res://Acerto.mp3")
	add_child(som_acerto)
	
	bg_music = AudioStreamPlayer.new()
	bg_music.stream = preload("res://Jogo 1.mp3")
	bg_music.volume_db = -18.0
	add_child(bg_music)
	bg_music.play()
	bg_music.finished.connect(bg_music.play)
	
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
	
	call_deferred("start_new_level")

func clear_table() -> void:
	for c in get_tree().get_nodes_in_group("cup"):
		c.queue_free()
	for sp in get_tree().get_nodes_in_group("snap_point"):
		sp.queue_free()

func start_new_level() -> void:
	clear_table()
	is_setup = true
	is_subtraction = randf() > 0.5
	current_cups = 0
	level_finished = false
	
	if is_subtraction:
		# Dificuldade progressiva baseada no streak
		var min_val = 4 + (streak * 2)
		var max_val = 10 + (streak * 3)
		num1 = randi_range(min_val, max_val) 
		num2 = randi_range(2, num1 - 1)
		target_cups = num1 - num2
		
		update_ui()
		generate_pyramid(num1, true) 
	else:
		# Dificuldade progressiva para adição
		var max_sum = 5 + (streak * 2)
		num1 = randi_range(1, max_sum / 2 + 1)
		num2 = randi_range(1, max_sum / 2 + 1) 
		target_cups = num1 + num2
		
		update_ui()
		generate_pyramid(target_cups, false)
		# Agora spawnamos MAIS copos do que o necessário, como solicitado!
		var extra_cups = randi_range(2, 4)
		spawn_cups(target_cups + extra_cups)
		
	is_setup = false
	check_win_condition()
	
func generate_pyramid(count: int, prefill: bool) -> void:
	var row = 0
	var base_y = 525 
	
	var spacing_x = 100 
	var spacing_y = 135 

	var cups_per_row = 1
	while (cups_per_row * (cups_per_row + 1)) / 2 < count:
		cups_per_row += 1
		
	var current_row_cups = cups_per_row
	var cups_placed = 0
	
	while current_row_cups > 0:
		var start_x = 640 - ((current_row_cups - 1) * spacing_x) / 2.0
		for i in range(current_row_cups):
			
			var sp = SNAP_POINT_SCENE.instantiate()
			sp.position = Vector2(start_x + i * spacing_x, base_y - (row * spacing_y))
			add_child(sp)
			
			sp.cup_snapped_in_point.connect(_on_cup_snapped)
			sp.cup_removed_from_point.connect(_on_cup_removed)
			
			# Imanta mágica e inteligentemente os copos logo de saída
			if prefill and cups_placed < count:
				var cup = CUP_SCENE.instantiate()
				cup.global_position = sp.global_position
				add_child(cup)
				
				cup.dropped_on_table.connect(_on_cup_dropped_on_table)
				
				cup.is_stacked = true
				cup.current_snap_point = sp
				cup.z_index = -sp.global_position.y
				sp.occupy_point(cup) # Usa a função oficial que já desliga colisão, troca de var e dispara o sinal!
				cups_placed += 1

			
		row += 1
		current_row_cups -= 1

func spawn_cups(count: int) -> void:
	var left_x = 100
	var right_x = 900
	for i in range(count):
		var cup = CUP_SCENE.instantiate()
		var rx = 0
		
		# Distribui um copo pra esquerda, um pra direita, em fila indiana perfeitamente alinhada na mesa
		if i % 2 == 0:
			rx = left_x
			left_x += 70
		else:
			rx = right_x
			right_x += 70
			
		# Y perfeitamente no 525 fixo da mesa! Fim dos copos voadores independentes.
		cup.position = Vector2(rx, 525)
		cup.dropped_on_table.connect(_on_cup_dropped_on_table)
		add_child(cup)

func update_ui() -> void:
	if label_status != null:
		if is_subtraction:
			label_status.text = "Resolva: " + str(num1) + " - " + str(num2) + " = ?"
		else:
			label_status.text = "Resolva: " + str(num1) + " + " + str(num2) + " = ?"
			
	# Atualiza as estrelas visualmente
	if stars_container:
		var stars = stars_container.get_children()
		for i in range(stars.size()):
			if i < streak:
				stars[i].texture = star_viva
			else:
				stars[i].texture = star_vazia

func _on_cup_snapped(_cup_node: Node2D) -> void:
	current_cups += 1
	if not is_setup:
		check_win_condition()
	
func _on_cup_removed(_cup_node: Node2D) -> void:
	if current_cups > 0:
		current_cups -= 1
		update_ui()
		# Mantemos SILÊNCIO aqui até o jogador fisicamente soltar o copo na mesa.
		# Nota: Removemos daqui a verificação da vitória para não dar o acerto enquanto o copo estiver voando na mão da criança!

# Engatilho novo: Ouve quando exatamente o copo toca no pranchão de volta
func _on_cup_dropped_on_table(_cup_node: Node2D) -> void:
	if not is_setup:
		check_win_condition()

func check_win_condition() -> void:
	if current_cups == target_cups and not level_finished:
		level_finished = true
		if is_subtraction:
			label_status.text = "VITÓRIA! ✨ " + str(num1) + " - " + str(num2) + " = " + str(target_cups) + "!"
		else:
			label_status.text = "VITÓRIA! ✨ " + str(num1) + " + " + str(num2) + " = " + str(target_cups) + "!"
		
		streak += 1
		update_ui() # Mostra a estrela nova imediatamente
		
		som_acerto.play()
		
		# Feedback visual em todos os copos na torre
		for c in get_tree().get_nodes_in_group("cup"):
			if c.is_stacked and c.has_method("celebrate"):
				c.celebrate()
		
		await get_tree().create_timer(2.2).timeout
		
		if streak >= max_streak:
			# GRANDE CELEBRAÇÃO!
			label_status.text = "PARABÉNS! VOCÊ É UM MESTRE! 🎉"
			if confetti:
				confetti.emitting = true
			
			# Toca o som de acerto de novo ou um som mais longo se tiver
			som_acerto.play()
			
			await get_tree().create_timer(4.0).timeout
			streak = 0 # Reinicia o ciclo
		
		reset_level()

func reset_level() -> void:
	var all_cups = get_tree().get_nodes_in_group("cup")
	for c in all_cups:
		if c.has_method("reset_cup"):
			c.reset_cup()
			
	await get_tree().create_timer(1.0).timeout
	start_new_level()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://node_2d.tscn")
