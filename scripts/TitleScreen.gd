extends Control

var bg_music: AudioStreamPlayer

func _ready() -> void:
	if ResourceLoader.exists("res://Tela inicial.png"):
		$Background.texture = preload("res://Tela inicial.png")

	# Estilização do botão via código para garantir visual rico
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.1, 0.7, 0.3) # Verde Vibrante
	style_normal.corner_radius_top_left = 30
	style_normal.corner_radius_top_right = 30
	style_normal.corner_radius_bottom_left = 30
	style_normal.corner_radius_bottom_right = 30
	style_normal.border_width_bottom = 12
	style_normal.border_color = Color(0.05, 0.5, 0.2)
	
	var style_hover = style_normal.duplicate()
	style_hover.bg_color = Color(0.2, 0.8, 0.4)
	
	var style_pressed = style_normal.duplicate()
	style_pressed.border_width_bottom = 0
	style_pressed.bg_color = Color(0.05, 0.5, 0.2)
	style_pressed.content_margin_top = 12 # Faz o texto "afundar" ao clicar
	
	var btn = $CenterContainer/VBoxContainer/PlayButton
	btn.add_theme_stylebox_override("normal", style_normal)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_stylebox_override("pressed", style_pressed)
	
	btn.pressed.connect(_on_play_pressed)
	
	# Animação super discreta de brilho suave (fade lento)
	var title = $CenterContainer/VBoxContainer/Title
	var title_tween = get_tree().create_tween().set_loops()
	title_tween.tween_property(title, "modulate:a", 0.8, 2.0).set_trans(Tween.TRANS_SINE)
	title_tween.tween_property(title, "modulate:a", 1.0, 2.0).set_trans(Tween.TRANS_SINE)
	
	bg_music = AudioStreamPlayer.new()
	if ResourceLoader.exists("res://Som abertura.mp3"):
		bg_music.stream = preload("res://Som abertura.mp3")
		bg_music.volume_db = -5.0
		add_child(bg_music)
		bg_music.play()
		bg_music.finished.connect(bg_music.play)

func _on_play_pressed() -> void:
	$CenterContainer/VBoxContainer/PlayButton.disabled = true
	get_tree().change_scene_to_file("res://node_2d.tscn")
