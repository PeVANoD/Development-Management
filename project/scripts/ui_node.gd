extends Control
var colors = [
	"#FF0000",  # Красный
	"#00FF00",  # Зеленый
	"#0000FF",  # Синий
	"#FFFF00",  # Желтый
	"#FF00FF",  # Пурпурный
	"#00FFFF",  # Голубой
	"#FF8000",  # Оранжевый
	"#8000FF",  # Фиолетовый
	"#FF0080",  # Розовый
	"#00FF80",  # Весенний зеленый
	"#80FF00",  # Лаймовый
	"#0080FF",  # Ярко-синий
	"#FF8040",  # Коралловый
	"#40FF80",  # Мятный
	"#8040FF",  # Лавандовый
	"#FF4080"   # Фуксия
]
@onready var map = $"../SubViewportContainer/SubViewport/Map"

func _ready():
	$"Leaders/Terrain/VBoxContainer/1/Name".text = G.nickname
	$"Leaders/Size/VBoxContainer/1/Name".text = G.nickname
	colorBoard()

func colorBoard():
	for i in range(1,9):
		$Leaders/Terrain/VBoxContainer.get_node(str(i)+"/ColorRect").modulate = colors[i-1]
		$Leaders/Size/VBoxContainer.get_node(str(i)+"/ColorRect").modulate = colors[i-1]

func _process(delta):
	setAliveSnakes()
	sortTerrain()
	sortSize()


func setAliveSnakes():
	var snakes = map.get_node("Snakes").get_children()
	var board = $Leaders/Terrain/VBoxContainer.get_children()
	if snakes.size() < board.size()-1:
		for j in range(1, board.size()):
			var board_name = board[j].name
			var found = false
			for snake in snakes:
				if snake.name == board_name:
					found = true
					break
			if not found:
				$Leaders/Terrain/VBoxContainer.get_node(str(board_name)).modulate.a = 0.3
				$Leaders/Size/VBoxContainer.get_node(str(board_name)).modulate.a = 0.3
func sortTerrain():
	var sorted_indices = range(0, 8)
	sorted_indices.sort_custom(func(a, b): 
		return G.tera.get_territory_area(a) > G.tera.get_territory_area(b)
	)
	var container = $Leaders/Terrain/VBoxContainer
	var pos = 1
	for i in sorted_indices:
		var node = container.get_node(str(i + 1))
		if node.modulate.a > 0.9:
			node.get_node("Count").text = str(round(float(G.tera.get_territory_area(i))/5226191*1000)/10)+"%"
			container.move_child(node, pos)
		pos += 1
	

func sortSize():
	var snakes = map.get_node("Snakes").get_children()
	snakes.sort_custom(func(a, b): 
		return a.length > b.length
	)
	var container = $Leaders/Size/VBoxContainer
	var pos = 1
	for snake in snakes:
		var node_name = str(snake.snakeNum + 1)
		if container.has_node(node_name):
			var node = container.get_node(node_name)
			if node.modulate.a > 0.9:
				node.get_node("Count").text = str(snake.length)
				container.move_child(node, pos)
				pos += 1
