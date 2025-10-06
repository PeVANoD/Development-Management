extends Node2D

# Загружаем сцены окон
@onready var random_skin_scene = preload("res://project/scenes/menu/random_skin_window.tscn")
@onready var daily_skins_scene = preload("res://project/scenes/menu/daily_skin_window.tscn")
@onready var quests_scene = preload("res://project/scenes/menu/quests_window.tscn")
# Переменные для кнопок

# Переменные для кнопок
@onready var play_button: Button
@onready var options_button: Button

# Переменные для окон
var random_skin_window
var daily_skins_window
var quests_window
var language_window

# Кнопка для открытия окон
var show_windows_button: Button

# Тексты для разных языков
var language_texts = {
	"ru": {
		"play": "ИГРАТЬ",
		"options": "НАСТРОЙКИ",
		"show_windows": "ПОКАЗАТЬ ОКНА",
		"random_skin": "Случайный скин",
		"daily_skins": "Ежедневные скины", 
		"quests": "Квесты",
		"language": "Язык",
		"russian": "Русский",
		"english": "English"
	},
	"en": {
		"play": "PLAY",
		"options": "OPTIONS",
		"show_windows": "SHOW WINDOWS",
		"random_skin": "Random Skin",
		"daily_skins": "Daily Skins",
		"quests": "Quests",
		"language": "Language",
		"russian": "Русский",
		"english": "English"
	}
}

var current_language = "ru"

func _ready():
	# Находим кнопки
	_find_buttons()
	
	# Создаём кнопку для показа окон
	_create_show_windows_button()
	
	# Создаём окна
	_create_windows()
	
	# Создаём окно выбора языка
	_create_language_window()
	
	# Применяем текущий язык
	_apply_language()
	
	print("Меню загружено")

func _find_buttons():
	play_button = find_child("Play") as Button
	options_button = find_child("Options") as Button
	
	if play_button:
		play_button.pressed.connect(_on_play_pressed)
	if options_button:
		options_button.pressed.connect(_on_options_pressed)

func _create_show_windows_button():
	# Создаём кнопку для показа окон
	show_windows_button = Button.new()
	show_windows_button.size = Vector2(200, 50)
	show_windows_button.position = Vector2(500, 50)
	show_windows_button.pressed.connect(_show_all_windows)
	add_child(show_windows_button)
	show_windows_button.visible = false  # Изначально скрыта

func _create_windows():
	# Создаём окна один раз
	random_skin_window = random_skin_scene.instantiate()
	daily_skins_window = daily_skins_scene.instantiate()
	quests_window = quests_scene.instantiate()
	
	# Добавляем окна как дети текущей сцены
	add_child(random_skin_window)
	add_child(daily_skins_window)
	add_child(quests_window)
	
	# Устанавливаем фиксированные позиции
	_set_window_positions()
	
	# Подключаем сигналы закрытия
	random_skin_window.close_requested.connect(_on_window_closed.bind("random_skin"))
	daily_skins_window.close_requested.connect(_on_window_closed.bind("daily_skins"))
	quests_window.close_requested.connect(_on_window_closed.bind("quests"))

func _set_window_positions():
	# Фиксированные позиции для окон
	random_skin_window.position = Vector2(50, 100)
	random_skin_window.size = Vector2i(350, 250)
	
	daily_skins_window.position = Vector2(450, 100)
	daily_skins_window.size = Vector2i(350, 250)
	
	quests_window.position = Vector2(250, 400)
	quests_window.size = Vector2i(400, 200)

func _create_language_window():
	# Создаём окно выбора языка
	language_window = Window.new()
	language_window.title = "Выбор языка / Language"
	language_window.size = Vector2i(300, 150)
	language_window.position = Vector2(350, 200)
	language_window.visible = false
	
	# Контейнер для кнопок
	var vbox = VBoxContainer.new()
	vbox.size = Vector2(280, 120)
	vbox.position = Vector2(10, 30)
	language_window.add_child(vbox)
	
	# Кнопка русского языка
	var ru_button = Button.new()
	ru_button.text = "Русский"
	ru_button.custom_minimum_size = Vector2(260, 40)
	ru_button.pressed.connect(_on_russian_selected)
	vbox.add_child(ru_button)
	
	# Кнопка английского языка
	var en_button = Button.new()
	en_button.text = "English"
	en_button.custom_minimum_size = Vector2(260, 40)
	en_button.pressed.connect(_on_english_selected)
	vbox.add_child(en_button)
	
	add_child(language_window)

func _apply_language():
	var texts = language_texts[current_language]
	
	# Обновляем тексты кнопок
	if play_button:
		play_button.text = texts["play"]
	if options_button:
		options_button.text = texts["options"]
	if show_windows_button:
		show_windows_button.text = texts["show_windows"]
	
	# Обновляем заголовки окон
	if random_skin_window:
		random_skin_window.title = texts["random_skin"]
	if daily_skins_window:
		daily_skins_window.title = texts["daily_skins"]
	if quests_window:
		quests_window.title = texts["quests"]
	if language_window:
		language_window.title = texts["language"]

func _show_all_windows():
	# Показываем все окна
	random_skin_window.visible = true
	daily_skins_window.visible = true
	quests_window.visible = true
	show_windows_button.visible = false

func _check_all_windows_closed():
	# Проверяем, все ли окна закрыты
	var all_closed = !random_skin_window.visible and !daily_skins_window.visible and !quests_window.visible
	
	if all_closed:
		show_windows_button.visible = true
	else:
		show_windows_button.visible = false

func _on_play_pressed():
	print("Играть нажато")
	_hide_all_windows()
	get_tree().change_scene_to_file("res://project/scenes/map.tscn")
	
func _on_options_pressed():
	print("Настройки нажаты")
	# Показываем окно выбора языка
	language_window.visible = true

func _on_window_closed(window_name: String):
	print("Окно закрыто: ", window_name)
	# Проверяем, не все ли окна закрыты
	_check_all_windows_closed()

func _on_russian_selected():
	current_language = "ru"
	_apply_language()
	language_window.visible = false

func _on_english_selected():
	current_language = "en"
	_apply_language()
	language_window.visible = false

func _hide_all_windows():
	random_skin_window.visible = false
	daily_skins_window.visible = false
	quests_window.visible = false
	language_window.visible = false
	show_windows_button.visible = false
