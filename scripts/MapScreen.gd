extends Control

var bg_music: AudioStreamPlayer

func _ready() -> void:
	if ResourceLoader.exists("res://Mapa do jogo.png"):
		$Background.texture = preload("res://Mapa do jogo.png")
		
	# Estilo interativo fofinho
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.9, 0.4, 0.1, 0.95) # Laranja quentinho
	style_normal.corner_radius_top_left = 25
	style_normal.corner_radius_top_right = 25
	style_normal.corner_radius_bottom_left = 25
	style_normal.corner_radius_bottom_right = 25
	style_normal.border_width_bottom = 10
	style_normal.border_color = Color(0.7, 0.2, 0.0)
	
	var style_hover = style_normal.duplicate()
	style_hover.bg_color = Color(1.0, 0.5, 0.2, 1.0)
	
	var style_pressed = style_normal.duplicate()
	style_pressed.border_width_bottom = 0
	style_pressed.bg_color = Color(0.7, 0.2, 0.0)
	style_pressed.content_margin_top = 10
	
	# Conexão dos pins (agora até 9)
	for i in range(1, 10):
		var pin_name = "PinMath" if i == 1 else "Pin" + str(i)
		var pin = $PinsContainer.get_node_or_null(pin_name)
		if pin:
			# Desconectamos tudo para garantir uma conexão limpa
			for sig in pin.pressed.get_connections():
				pin.pressed.disconnect(sig.callable)
			
			pin.pressed.connect(_on_pin_pressed.bind(i))
			print("Pin conectado: ", pin_name, " para ID ", i)

	# Animação suave global dos pins
	for p in $PinsContainer.get_children():
		var tween = get_tree().create_tween().set_loops()
		tween.tween_property(p, "scale", Vector2(1.1, 1.1), 1.0).set_trans(Tween.TRANS_SINE)
		tween.tween_property(p, "scale", Vector2(1.0, 1.0), 1.0).set_trans(Tween.TRANS_SINE)
		p.pivot_offset = Vector2(32, 32)
	
	var btn_back = $BackButton
	btn_back.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/TitleScreen.tscn")
	)

	bg_music = AudioStreamPlayer.new()
	if ResourceLoader.exists("res://Som mapa.mp3"):
		bg_music.stream = preload("res://Som mapa.mp3")
		bg_music.volume_db = -8.0
		add_child(bg_music)
		bg_music.play()
		bg_music.finished.connect(bg_music.play)

func _on_pin_pressed(pin_id: int):
	match pin_id:
		1: get_tree().change_scene_to_file("res://scenes/Main.tscn")
		2: get_tree().change_scene_to_file("res://scenes/Pipoca.tscn")
		3: get_tree().change_scene_to_file("res://scenes/Algodao.tscn")
		4: get_tree().change_scene_to_file("res://scenes/Magica.tscn")
		5: get_tree().change_scene_to_file("res://scenes/Roda.tscn")
		6: get_tree().change_scene_to_file("res://scenes/Baloes.tscn")
		7: get_tree().change_scene_to_file("res://scenes/Carrossel.tscn")
		8: get_tree().change_scene_to_file("res://scenes/Montanha.tscn")
		9: get_tree().change_scene_to_file("res://scenes/Tangram.tscn")
		_: print("Jogo em desenvolvimento")

func _on_locked_pin_pressed() -> void:
	print("Este jogo ainda não está disponível!")
