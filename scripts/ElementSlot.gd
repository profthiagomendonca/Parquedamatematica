extends Button

@onready var number_label = $VBox/Number
@onready var symbol_label = $VBox/Symbol
@onready var name_label = $VBox/Name

var element_data: ElementResource

func setup(data: ElementResource):
	element_data = data
	number_label.text = str(data.atomic_number)
	symbol_label.text = data.symbol
	name_label.text = data.name
	
	# Aplica a cor da família ao fundo do botão
	self.self_modulate = data.color
