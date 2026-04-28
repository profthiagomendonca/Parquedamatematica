extends Node2D

@onready var label_target = $UI/TopArea/Panel/Margin/VBox/LabelTarget
@onready var label_current = $UI/TopArea/Panel/Margin/VBox/LabelCurrent
@onready var items_container = $ItemsContainer
@onready var back_button = $UI/FooterMargin/FooterHBox/BackButton
@onready var stars_container = $UI/FooterMargin/FooterHBox/HUD/StarsContainer
@onready var confetti = $BackgroundLayer/ConfettiParticles

const ITEM_SCENE = preload("res://scenes/PopcornItem.tscn")
const TEX_UNIT = preload("res://assets/Pipoca_unidade.png")
const TEX_FIVE = preload("res://assets/Saco_cinco.png")
const TEX_TEN = preload("res://assets/Saco_dezena.png")

@onready var star_viva = preload("res://assets/estrela_viva.png")
@onready var star_vazia = preload("res://assets/estrela_vazia.png")

var target_number: int = 0
var current_number: int = 0
var streak: int = 0
var max_streak: int = 5
var item_stack: Array = []
var level_finished: bool = false

var som_acerto: AudioStreamPlayer
var som_pop: AudioStreamPlayer
var bg_music: AudioStreamPlayer

func _ready():
	som_acerto = AudioStreamPlayer.new()
	som_acerto.stream = preload("res://Acerto.mp3")
	add_child(som_acerto)
	
	som_pop = AudioStreamPlayer.new()
	som_pop.stream = preload("res://Acerto.mp3") 
	som_pop.pitch_scale = 1.5
	add_child(som_pop)
	
	bg_music = AudioStreamPlayer.new()
	bg_music.stream = preload("res://Jogo 2.mp3")
	bg_music.volume_db = -15.0
	add_child(bg_music)
	bg_music.play()
	bg_music.finished.connect(bg_music.play)
	
	$UI/SideButtons/VBox/Add10.pressed.connect(_on_add_10)
	$UI/SideButtons/VBox/Add5.pressed.connect(_on_add_5)
	$UI/SideButtons/VBox/Add1.pressed.connect(_on_add_1)
	$UI/SideButtons/VBox/Undo.pressed.connect(_on_undo)
	back_button.pressed.connect(_on_back_pressed)
	
	start_new_level()

func start_new_level():
	for child in items_container.get_children():
		child.queue_free()
	item_stack.clear()
	current_number = 0
	level_finished = false
	
	var min_val = 5 + (streak * 5)
	var max_val = 20 + (streak * 15)
	target_number = randi_range(min_val, min(max_val, 99))
	
	update_ui()

func update_ui():
	label_target.text = "Pedido: %d pipocas" % target_number
	label_current.text = "Na bancada: %d" % current_number
	
	if stars_container:
		var stars = stars_container.get_children()
		for i in range(stars.size()):
			stars[i].texture = star_viva if i < streak else star_vazia

func _on_add_10(): spawn_item(TEX_TEN, 10)
func _on_add_5(): spawn_item(TEX_FIVE, 5)
func _on_add_1(): spawn_item(TEX_UNIT, 1)

func spawn_item(tex: Texture2D, val: int):
	if level_finished: return
	
	var item = ITEM_SCENE.instantiate()
	items_container.add_child(item)
	item.setup(tex, val)
	
	# Espalha no balcão frontal (ajustado para não estourar na borda)
	var rx = randi_range(300, 1000)
	var ry = randi_range(560, 640)
	item.position = Vector2(rx, ry)
	
	current_number += val
	item_stack.append(item)
	som_pop.play()
	update_ui()
	check_victory()

func _on_undo():
	if level_finished: return
	if item_stack.size() > 0:
		var last_item = item_stack.pop_back()
		current_number -= last_item.value
		last_item.queue_free()
		update_ui()

func check_victory():
	if current_number == target_number and not level_finished:
		level_finished = true
		som_acerto.play()
		streak += 1
		update_ui()
		
		if streak >= max_streak:
			label_target.text = "MESTRE DA PIPOCA! 🎉"
			confetti.emitting = true
			await get_tree().create_timer(3.5).timeout
			streak = 0
		else:
			label_target.text = "MUITO BEM! ✨"
			await get_tree().create_timer(1.2).timeout
			
		start_new_level()

func _on_back_pressed():
	get_tree().change_scene_to_file("res://node_2d.tscn")
