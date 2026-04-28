extends Node2D

signal clicked(card)

@onready var balloon_base = %BalloonBase
@onready var shape_sprite = %ShapeSprite
@onready var area = $Area2D

var shape_id = ""
var is_open = false
var is_matched = false
var initial_y = 0.0

func _ready():
	# Cria a colisão dinamicamente baseado na textura
	if balloon_base.texture:
		var collision = CollisionShape2D.new()
		var shape = CircleShape2D.new()
		shape.radius = balloon_base.texture.get_width() / 2.0
		collision.shape = shape
		area.add_child(collision)
	
	# Apenas conecta o clique
	area.input_event.connect(_on_input_event)

func update_anchor():
	initial_y = position.y
	_start_float_animation()

func _start_float_animation():
	var tween = create_tween().set_loops()
	var offset = randf_range(10, 20)
	var duration = randf_range(1.5, 2.5)
	
	tween.tween_property(self, "position:y", initial_y - offset, duration).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "position:y", initial_y, duration).set_trans(Tween.TRANS_SINE)

func setup(id, texture):
	shape_id = id
	shape_sprite.texture = texture
	
	# Paleta de Cores "Neon Candy" para destacar do fundo
	var vibrant_colors = [
		Color(1, 0.1, 0.1), # Vermelho Vivo
		Color(0.1, 0.9, 0.1), # Verde Lima
		Color(0.1, 0.6, 1),   # Azul Piscina
		Color(1, 1, 0.1),     # Amarelo Sol
		Color(1, 0.1, 1),     # Magenta Vibrante
		Color(0.1, 1, 1),     # Ciano
		Color(1, 0.5, 0),     # Laranja
		Color(0.7, 0.3, 1),   # Roxo
		Color(0.5, 1, 0)      # Verde Ácido
	]
	
	balloon_base.modulate = vibrant_colors.pick_random()

func reveal_shape():
	if is_open or is_matched: return
	is_open = true
	
	# Animação de revelação "estouro/inflar"
	var tween = create_tween().set_parallel(true)
	tween.tween_property(balloon_base, "scale", Vector2(1.2, 1.2), 0.2).set_trans(Tween.TRANS_BACK)
	tween.tween_callback(func(): shape_sprite.visible = true)
	tween.tween_property(shape_sprite, "scale", Vector2(0.8, 0.8), 0.3).set_trans(Tween.TRANS_ELASTIC)

func hide_shape():
	if is_matched: return
	is_open = false
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(balloon_base, "scale", Vector2(1.0, 1.0), 0.2)
	tween.tween_property(shape_sprite, "scale", Vector2(0.01, 0.01), 0.2)
	await tween.finished
	shape_sprite.visible = false

func match_found():
	is_matched = true
	# Voar para o fundo
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "global_position", Vector2(640, 300), 0.8).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "scale", Vector2(0.1, 0.1), 0.8)
	tween.tween_property(self, "modulate:a", 0.0, 0.8)
	await tween.finished
	queue_free()

func _on_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not is_open and not is_matched:
			clicked.emit(self)
