extends Node2D

@onready var sprite = $Sprite
var value: int = 1 # 1 para pipoca, 10 para saco

func setup(tex: Texture2D, val: int):
	if not is_inside_tree():
		await ready
	
	if sprite:
		sprite.texture = tex
	value = val
	
	# Animação de entrada (pulo/escala)
	scale = Vector2.ZERO
	var tween = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.6)
