extends Node2D

signal clicked(card)

@onready var balloon_base = %BalloonBase
@onready var shape_sprite = %ShapeSprite
@onready var area = $Area2D

var shape_id = ""
var is_open = false
var is_matched = false

func _ready():
	# Cria a colisão dinamicamente baseado na textura
	if balloon_base.texture:
		var collision = CollisionShape2D.new()
		var shape = CircleShape2D.new()
		shape.radius = balloon_base.texture.get_width() / 2.5
		collision.shape = shape
		area.add_child(collision)
	
	area.input_event.connect(_on_input_event)
	_start_float_animation()

func _start_float_animation():
	var tween = create_tween().set_loops()
	var offset = randf_range(10, 20)
	var duration = randf_range(1.5, 2.5)
	
	tween.tween_property(self, "position:y", position.y - offset, duration).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "position:y", position.y, duration).set_trans(Tween.TRANS_SINE)

func setup(id, texture):
	shape_id = id
	shape_sprite.texture = texture
	# Ajusta a cor do balão aleatoriamente para ficar festivo
	balloon_base.modulate = Color(randf(), randf(), randf(), 1.0)

func reveal():
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
