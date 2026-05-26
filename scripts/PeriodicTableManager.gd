extends Control

@onready var grid = $GridContainer

const SLOT_SCENE = preload("res://scenes/ElementSlot.tscn")

# Lista de recursos que vamos carregar (depois podemos automatizar para ler a pasta)
var test_elements = [
	preload("res://resources/PeriodicTable/Hidrogenio.tres"),
	preload("res://resources/PeriodicTable/Helio.tres")
]

func _ready():
	# Limpa a grade por segurança
	for child in grid.get_children():
		child.queue_free()
		
	# Para cada elemento na nossa lista, cria um slot na tela
	for data in test_elements:
		var slot = SLOT_SCENE.instantiate()
		grid.add_child(slot)
		slot.setup(data)
		slot.pressed.connect(_on_element_pressed.bind(data))

func _on_element_pressed(data: ElementResource):
	print("Clicou no elemento: ", data.name)
	print("Descrição: ", data.description)
	# Aqui no futuro abriremos um pop-up com mais detalhes
