extends Node

var tera

var nickname = ""
var terrain = 0
var size = 0

# Для вывода статистики 
var max_territory = 0.0
var max_size = 0.0
var max_kills = 0
var total_kills = 0
var kills = 0
var wins = 0

var difficulty = 1

var alive = true
var result_is_win = false
var language = "ru"

var chosen_skin = "1"

var player_exp: int = 0

func _ready():
	colors.shuffle()

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
