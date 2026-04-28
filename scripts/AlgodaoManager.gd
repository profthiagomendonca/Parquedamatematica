extends Node2D

@onready var reference_row = $UI/GameCenter/ReferencePanel/VBox/ReferenceRow
@onready var workspace_row = $UI/GameCenter/WorkspaceRow
@onready var options_container = $UI/SideOptionsPanel/VBox/OptionsContainer
@onready var stars_container = $UI/HUD/StarsContainer
@onready var instruction_label = $UI/GameCenter/ReferencePanel/VBox/InstructionLabel
@onready var confetti = $BackgroundLayer/ConfettiParticles
@onready var music = $Music

const ITEM_SCENE = preload("res://scenes/AlgodaoItem.tscn")

const TEXTURES = {
	0: preload("res://assets/Urso_algodao.png"),
	1: preload("res://assets/Estrela_algodao.png"),
	2: preload("res://assets/Coracao_algodao.png"),
	3: preload("res://assets/Gato_algodao.png"),
	4: preload("res://assets/Flor_algodao.png")
}

@onready var star_viva = preload("res://assets/estrela_viva.png")
@onready var star_vazia = preload("res://assets/estrela_vazia.png")

# Estatísticas e Níveis
var total_stars_earned: int = 0
var streak: int = 0
var max_streak: int = 5

# Lógica de Rodada
var current_logic_ids = []
var current_logic_rot = []
var missing_indices = []
var current_gap_step = 0

var som_acerto: AudioStreamPlayer
var som_erro: AudioStreamPlayer

func _ready():
	setup_audio()
	$UI/Footer/FooterHBox/BackButton.pressed.connect(_on_back_pressed)
	start_new_level()

func setup_audio():
	music.finished.connect(func(): music.play())
	if not music.playing: music.play()
	
	som_acerto = AudioStreamPlayer.new()
	som_acerto.stream = preload("res://Acerto.mp3")
	add_child(som_acerto)
	
	som_erro = AudioStreamPlayer.new()
	som_erro.stream = preload("res://Erro.mp3") if FileAccess.file_exists("res://Erro.mp3") else preload("res://Acerto.mp3")
	if not FileAccess.file_exists("res://Erro.mp3"): som_erro.pitch_scale = 0.5
	add_child(som_erro)

func get_difficulty_config():
	var cfg = {"length": 4, "gaps": 1, "angles": [0], "options": 3, "pattern_complexity": 0}
	if total_stars_earned < 5:
		cfg.pattern_complexity = 0 # ABAB
	elif total_stars_earned < 10:
		cfg.length = 5; cfg.gaps = 1; cfg.options = 4; cfg.pattern_complexity = 1 # AABB
	elif total_stars_earned < 15:
		cfg.length = 6; cfg.gaps = 2; cfg.options = 4; cfg.pattern_complexity = 2 # ABC
		cfg.angles = [0, 180] # Adiciona ponta-cabeça
	elif total_stars_earned < 20:
		cfg.length = 6; cfg.gaps = 2; cfg.options = 5; cfg.angles = [0, 90, -90]; cfg.pattern_complexity = 3 # Deitado de lado
	elif total_stars_earned < 25:
		cfg.length = 7; cfg.gaps = 3; cfg.options = 5; cfg.angles = [0, 90, -90, 180]; cfg.pattern_complexity = 4 # Todas posições
	elif total_stars_earned < 30:
		cfg.length = 8; cfg.gaps = 3; cfg.options = 5; cfg.angles = [0, 90, -90, 180]; cfg.pattern_complexity = 4
	else: # Nível Mestre
		cfg.length = 8; cfg.gaps = 4; cfg.options = 5; cfg.angles = [0, 90, -90, 180]; cfg.pattern_complexity = 4
	return cfg

func start_new_level():
	for child in reference_row.get_children(): child.queue_free()
	for child in workspace_row.get_children(): child.queue_free()
	for child in options_container.get_children(): child.queue_free()
	await get_tree().process_frame
	create_game_loop()
	update_stars_ui()

func on_level_complete():
	streak += 1; total_stars_earned += 1
	update_stars_ui() # CORREÇÃO 2: A Estrela acende IMEDIATAMENTE antes da festa!
	if streak >= max_streak:
		instruction_label.text = "NÍVEL CONCLUÍDO! 🍭✨"; confetti.emitting = true
		await get_tree().create_timer(3.0).timeout
		streak = 0
		if total_stars_earned % 5 == 0:
			instruction_label.text = "VOCÊ ESTÁ FICANDO CRAQUE!"; await get_tree().create_timer(1.0).timeout
	else:
		instruction_label.text = "ISSO! CONTINUA ASSIM! 🌟"; await get_tree().create_timer(1.0).timeout
	instruction_label.text = "Complete a sequência"; start_new_level()

func on_wrong():
	som_erro.play()
	var target_idx = missing_indices[current_gap_step]
	var item = workspace_row.get_child(target_idx); var tween = create_tween()
	tween.tween_property(item, "modulate", Color.RED, 0.1); tween.tween_property(item, "modulate", Color(0,0,0,0.3), 0.1)
	if total_stars_earned > 0: total_stars_earned -= 1
	if streak > 0: streak -= 1
	update_stars_ui()

func build_pattern(index: int, type: int, items: Array):
	match type:
		0: return items[0] if index % 2 == 0 else items[1]
		1: return items[0] if (index / 2) % 2 == 0 else items[1]
		2: return items[index % 3]
		3: return items[0] if (index % 4 == 0 or index % 4 == 3) else items[1]
		4: return items[index % 4]
	return items[0]

func create_game_loop():
	var cfg = get_difficulty_config()
	current_logic_ids = []; current_logic_rot = []; missing_indices = []; current_gap_step = 0
	
	var ids = TEXTURES.keys(); ids.shuffle()
	
	var ptype_id = randi() % (cfg.pattern_complexity + 1)
	var ptype_rot = 0
	var ang_table = [0, 0, 0, 0]
	
	if cfg.angles.size() > 1:
		ptype_rot = randi() % (cfg.pattern_complexity + 1)
		var shuffled_angles = cfg.angles.duplicate()
		shuffled_angles.shuffle()
		for a in range(4):
			if a < shuffled_angles.size(): ang_table[a] = shuffled_angles[a]
			else: ang_table[a] = shuffled_angles[a % shuffled_angles.size()]
	
	for i in range(cfg.length):
		var id = build_pattern(i, ptype_id, ids)
		current_logic_ids.append(id)
		
		var rot = 0
		if cfg.angles.size() > 1:
			rot = build_pattern(i, ptype_rot, ang_table)
		current_logic_rot.append(rot)

	for i in range(cfg.gaps): missing_indices.append(cfg.length - cfg.gaps + i)
	
	# UNIFICAÇÃO DE TAMANHO Quadrado perfeito
	var item_size = Vector2(170, 170)
	if cfg.length >= 6: item_size = Vector2(140, 140)
	if cfg.length >= 8: item_size = Vector2(110, 110)

	for i in range(cfg.length):
		var item = ITEM_SCENE.instantiate()
		reference_row.add_child(item)
		item.custom_minimum_size = item_size
		item.setup(TEXTURES[current_logic_ids[i]], current_logic_ids[i], current_logic_rot[i])
	
	for i in range(cfg.length):
		var item = ITEM_SCENE.instantiate()
		workspace_row.add_child(item)
		item.custom_minimum_size = item_size
		if not i in missing_indices:
			item.setup(TEXTURES[current_logic_ids[i]], current_logic_ids[i], current_logic_rot[i])
		else:
			item.setup(TEXTURES[current_logic_ids[i]], current_logic_ids[i], current_logic_rot[i], true)
	
	create_options(cfg)

func create_options(cfg):
	var final_options = []
	var target_idx = missing_indices[current_gap_step]
	final_options.append({"id": current_logic_ids[target_idx], "rot": current_logic_rot[target_idx]})
	
	var pool = []
	for id in TEXTURES.keys():
		for ang in cfg.angles:
			pool.append({"id": id, "rot": ang})
		# Se as angulações forem muito simples (nível 1), garante ter opções puras base.
		if cfg.angles.size() == 1:
			pool.append({"id": id, "rot": 0})
		
	pool.shuffle()
	for p in pool:
		if final_options.size() >= cfg.options: break
		
		var is_duplicate = false
		var same_id_count = 0
		
		for opt in final_options:
			# Contabiliza quantos existem dessa mesma familia
			if opt.id == p.id: same_id_count += 1
			# Protege contra repetição exata
			if opt.id == p.id and opt.rot == p.rot:
				is_duplicate = true
			# Em fases fáceis, protege 100% repetição de forma
			if cfg.angles.size() == 1 and opt.id == p.id:
				is_duplicate = true
		
		# Limitador Absoluto Antifrustração: NUNCA apresentar a mesma forma (Cor) que já esteja na Tela. Apenas o Doce correto e as formas Distintas de brinde!
		if same_id_count >= 1:
			is_duplicate = true
		
		if not is_duplicate: final_options.append(p)
	
	final_options.shuffle()
	for child in options_container.get_children(): child.queue_free()
	for opt in final_options:
		var cent = CenterContainer.new()
		options_container.add_child(cent)
		
		var btn = Button.new()
		# Tamanho amigável
		btn.custom_minimum_size = Vector2(95, 95)
		btn.flat = true
		cent.add_child(btn)
		
		var item = ITEM_SCENE.instantiate()
		btn.add_child(item)
		# Garante que as imagens não fiquem minusculas
		item.custom_minimum_size = Vector2(95, 95)
		
		# IGNORA o mouse no container do doce, passando o clique limpo pro Botao
		item.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for sub_no in item.get_children():
			if sub_no is Control:
				sub_no.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		# E manda iniciar a arte do doce embutindo o Shader de borda que faltava!
		item.setup(TEXTURES[opt.id], opt.id, opt.rot)
		
		btn.pressed.connect(_on_option_selected.bind(opt))

func _on_option_selected(opt: Dictionary):
	# PROTEÇÃO CÍBER-MECÂNICA DE OVERCLICK! 🚀 
	# Evita Crash Absoluto na Scene se a criança clicar duas vezes seguida bem rápido enquanto vibra com a Vitória de Fim de Nível.
	if current_gap_step >= missing_indices.size(): return
	
	var target_idx = missing_indices[current_gap_step]
	if opt.id == current_logic_ids[target_idx] and opt.rot == current_logic_rot[target_idx]:
		on_correct_step(target_idx)
	else: on_wrong()

func on_correct_step(idx):
	som_acerto.play()
	var item = workspace_row.get_child(idx)
	if item:
		item.reveal_anim()
	current_gap_step += 1
	if current_gap_step >= missing_indices.size(): on_level_complete()
	else:
		instruction_label.text = "Muito bem! Falta mais um..."
		create_options(get_difficulty_config())

# Fim das funcoes de ciclo

func update_stars_ui():
	if stars_container:
		var stars = stars_container.get_children()
		for i in range(stars.size()): stars[i].texture = star_viva if i < streak else star_vazia

func _on_back_pressed():
	get_tree().change_scene_to_file("res://node_2d.tscn")
