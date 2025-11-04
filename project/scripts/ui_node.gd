extends Control

var language_texts = {
	"ru" = {
		"victory": "ПОБЕДА!",
		"defeat": ":'(",
		"nickname_result": "Никнейм: ",
		"terrain_result": "Территории захвачено: ",
		"size_result": "Размер: ",
		"kills_result": "Убито: ",
		"exp_result": "Опыта получено: "
	},
	"en" = {
		"victory": "VICTORY!",
		"defeat": ":'(",
		"nickname_result": "Nickname: ",
		"terrain_result": "Terrain captured: ",
		"size_result": "Size: ",
		"kills_result": "Kills: ",
		"exp_result": "Exp gained: "
	}
}

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
var exp: int = 0
var session_finished = false

func _ready():
	$"Leaders/Terrain/VBoxContainer/1/Name".text = G.nickname
	$"Leaders/Size/VBoxContainer/1/Name".text = G.nickname
	$PassSessionPanel.visible = false
	colorBoard()

func colorBoard():
	for i in range(1,9):
		$Leaders/Terrain/VBoxContainer.get_node(str(i)+"/ColorRect").modulate = colors[i-1]
		$Leaders/Size/VBoxContainer.get_node(str(i)+"/ColorRect").modulate = colors[i-1]

func _process(delta):
	setAliveSnakes()
	sortTerrain()
	sortSize()
	sessionEnd()


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

# Передача инфы про настоящую сессию после смерти/победы
func sessionEnd() -> void:
	if session_finished:
		return
	var text = language_texts[G.language]
	if !G.alive and !$PassSessionPanel.visible:
		session_finished = true
		await get_tree().create_timer(1).timeout
		sessionEndText(text, "defeat")
	elif G.result_is_win and !$PassSessionPanel.visible:
		session_finished = true
		await get_tree().create_timer(2).timeout
		exp += 100
		sessionEndText(text, "victory")
		
		
func sessionEndText(text, match_res):
	exp += int($"Leaders/Terrain/VBoxContainer/1/Count".text) + int($"Leaders/Size/VBoxContainer/1/Count".text) + (G.kills*100)
	$PassSessionPanel.visible = true
	$PassSessionPanel/PassSessionBox/EndResLabel.text = text[match_res]
	$PassSessionPanel/PassSessionBox/NicknameLabel.text = text["nickname_result"] + G.nickname
	$PassSessionPanel/PassSessionBox/TerrainLabel.text = text["terrain_result"] + $"Leaders/Terrain/VBoxContainer/1/Count".text
	$PassSessionPanel/PassSessionBox/SizeLabel.text = text["size_result"] + $"Leaders/Size/VBoxContainer/1/Count".text
	$PassSessionPanel/PassSessionBox/KillsLabel.text = text["kills_result"] + str(G.kills)
	$PassSessionPanel/PassSessionBox/ExpLabel.text = text["exp_result"] + str(exp)
	G.exp += exp 
