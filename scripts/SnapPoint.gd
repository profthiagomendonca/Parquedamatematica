extends Area2D

class_name SnapPoint

# Sinal para avisar o gerenciador da fase que um copo "grudou" aqui
signal cup_snapped_in_point(cup_node)
signal cup_removed_from_point(cup_node)

# Variáveis para controle do ímã
var is_occupied: bool = false
var occupying_cup: Node2D = null

func _ready() -> void:
	# Fundamental: Adiciona o objeto ao grupo para o Cup.gd reconhecer que chegou num ímã
	add_to_group("snap_point")

func _process(_delta: float) -> void:
	# Como o Cup.gd apenas move sua própria posição até nós,
	# ficamos de olho se o copo que fomos avisados estar por perto realmente resolveu ficar aqui
	pass

# Quando o Cup.gd decidir se soltar aqui em cima, ele (ou o LevelManager) chamará essa função
func occupy_point(cup: Node2D) -> void:
	is_occupied = true
	occupying_cup = cup
	
	# Desativa a colisão deste iman para outro copo não tentar grudar junto no mesmo lugar
	$CollisionShape2D.set_deferred("disabled", true)
	
	print("SnapPoint: Fui ocupado pelo copo!")
	emit_signal("cup_snapped_in_point", cup)

# Se fizermos o modo Subtração, o jogador vai tirar o copo do ímã
func free_point() -> void:
	var cup = occupying_cup
	is_occupied = false
	occupying_cup = null
	$CollisionShape2D.set_deferred("disabled", false)
	
	print("SnapPoint: Copo retirado!")
	emit_signal("cup_removed_from_point", cup)
