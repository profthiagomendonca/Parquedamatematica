extends Area2D

class_name Cup

signal dropped_on_table(cup)

# Trava global para garantir que só 1 copo seja arrastado por vez
static var global_drag_active: bool = false

# Array contendo as 4 cores possíveis pré-carregadas para rodar suave
var cup_colors = [
	preload("res://assets/Copinho_amarelo.png"),
	preload("res://assets/Copinho_azul.png"),
	preload("res://assets/Copinho_laranja.png"),
	preload("res://assets/Copinho_vermelho.png")
]

var is_dragging: bool = false
var original_position: Vector2

# Guarda onde ocorreu o clique em relação ao centro do copo para que ele nao 'pule' pro mouse
var drag_offset: Vector2 = Vector2.ZERO 

# Verifica se ele já está encaixado na torre
var is_stacked: bool = false
var current_snap_point: Node2D = null

# Ponto magnético de encaixe onde ele pode se soltar
var hovered_snap_point: Node2D = null

func _ready() -> void:
	add_to_group("cup")
	
	# Assim que o copo nasce, sorteia a cor do Sprite dele
	set_random_color()
	
	# Salva de onde o copo saiu da bandeja
	original_position = global_position
	
	# Conecta os sinais do Area2D para ele sentir os SnapPoints
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

func _input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# Bloqueia se um outro copo qualquer já estiver sendo arrastado!
			if Cup.global_drag_active and not is_dragging:
				return
				
			# Se ele já estava em um ímã, agora que o jogador o agarrou de novo ele se solta 
			if is_stacked:
				is_stacked = false
				if current_snap_point != null and current_snap_point.has_method("free_point"):
					current_snap_point.free_point()
					current_snap_point = null
					
			# Inicia o arraste
			Cup.global_drag_active = true
			is_dragging = true
			drag_offset = global_position - get_global_mouse_position()
			
			# Joga esse copo na frente dos outros desenhados para não bugar a UI
			z_index = 100 
		elif not event.pressed and is_dragging:
			# Soltou o dedo da tela / botao do mouse
			Cup.global_drag_active = false
			is_dragging = false
			z_index = 1
			_on_drop()

func _process(_delta: float) -> void:
	if is_dragging:
		# Faz o copo seguir o mouse mantendo a distancia de offset do toque
		global_position = get_global_mouse_position() + drag_offset

func _on_drop() -> void:
	# O usuario soltou o copo. Ele esta no "imã" E o imã está vazio?
	if hovered_snap_point != null and not hovered_snap_point.is_occupied:
		# Puxa o copo para a posicao exata usando tweening (animacao suave)
		var tween = get_tree().create_tween()
		tween.tween_property(self, "global_position", hovered_snap_point.global_position, 0.1)
		
		is_stacked = true
		
		# Truque visual ajustado: Se os copos são construídos de ponta cabeça (como uma pirâmide real), 
		# o copo mais alto (menor valor de Y) fica repousando POR CIMA da base do copo de baixo. 
		# Portanto invertemos o Y com sinal negativo para quem estiver mais alto ter o Z maior!
		z_index = int(-hovered_snap_point.global_position.y)
		
		# Conta ao Ponto Magnético que fomos nós que ocupamos essa área
		if hovered_snap_point.has_method("occupy_point"):
			hovered_snap_point.occupy_point(self)
			current_snap_point = hovered_snap_point
			
		print("Copo encaixado magicamente no ponto livre!")
	else:
		# Se não estava em cima do ímã da torre, OU se o imã já estava ocupado:
		# O copo foi solto fisicamente na mesa!
		var tween = get_tree().create_tween()
		var y_mesa = 525
		tween.tween_property(self, "global_position", Vector2(global_position.x, y_mesa), 0.2).set_trans(Tween.TRANS_SINE)
		original_position = Vector2(global_position.x, y_mesa)
		emit_signal("dropped_on_table", self)

# Funcoes para serem conectadas aos sinais das "zonas de iman" depois
func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("snap_point"):
		hovered_snap_point = area

func _on_area_exited(area: Area2D) -> void:
	if area == hovered_snap_point:
		hovered_snap_point = null

func reset_cup() -> void:
	if is_stacked:
		is_stacked = false
		if current_snap_point != null and current_snap_point.has_method("free_point"):
			current_snap_point.free_point()
			current_snap_point = null
			
	Cup.global_drag_active = false
	is_dragging = false
	z_index = 1
	var tween = get_tree().create_tween()
	tween.tween_property(self, "global_position", original_position, 0.5).set_trans(Tween.TRANS_SINE)

func celebrate() -> void:
	var tween = get_tree().create_tween()
	var jump_height = 30
	var original_y = global_position.y
	tween.tween_property(self, "global_position:y", original_y - jump_height, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "global_position:y", original_y, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	# Pequeno brilho visual
	tween.parallel().tween_property(self, "modulate", Color(1.5, 1.5, 1.5), 0.2)
	tween.tween_property(self, "modulate", Color(1, 1, 1), 0.2)

func set_random_color() -> void:
	if $Sprite2D != null:
		var tex = cup_colors[randi() % cup_colors.size()]
		$Sprite2D.texture = tex


