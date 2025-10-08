extends Node2D
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
	
	# Создаём окно выбора языка
	_create_language_window()
	
	# Применяем текущий язык
	_apply_language()
	
	#print("Меню загружено")

func _find_buttons():
	return
	play_button = find_child("Play") as Button
	options_button = find_child("Options") as Button
	
	if play_button:
		play_button.pressed.connect(_on_play_pressed)
	if options_button:
		options_button.pressed.connect(_on_options_pressed)
	
	# Добавляем окна как дети текущей сцены
	add_child(random_skin_window)
	add_child(daily_skins_window)
	add_child(quests_window)
	
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
	ru_button.pressed.connect(_on_any_button_pressed)  # Звук для динамической кнопки
	vbox.add_child(ru_button)
	
	# Кнопка английского языка
	var en_button = Button.new()
	en_button.text = "English"
	en_button.custom_minimum_size = Vector2(260, 40)
	en_button.pressed.connect(_on_english_selected)
	en_button.pressed.connect(_on_any_button_pressed)  # Звук для динамической кнопки
	vbox.add_child(en_button)
	
	add_child(language_window)

func _apply_language():
	var texts = language_texts[current_language]
	
	# Обновляем тексты кнопок
	if play_button:
		play_button.text = texts["play"]
	if options_button:
		options_button.text = texts["options"]

func _check_all_windows_closed():
	# Проверяем, все ли окна закрыты
	var all_closed = !random_skin_window.visible and !daily_skins_window.visible and !quests_window.visible
	
	if all_closed:
		show_windows_button.visible = true
	else:
		show_windows_button.visible = false

# Функция для воспроизведения звука кнопок
func play_button_sound():
	var sound_player = AudioStreamPlayer.new()
	get_tree().root.add_child(sound_player)
	
	var sound = load("res://project/sounds/9e5204b502b116c.mp3")
	if sound:
		sound_player.stream = sound
		sound_player.volume_db = -5.0
		sound_player.play()
		sound_player.finished.connect(sound_player.queue_free)

# Универсальный обработчик звука для всех кнопок
func _on_any_button_pressed():
	play_button_sound()

func _on_play_pressed():
	play_button_sound()  # Звук для кнопки Play
	#print("Играть нажато")
	get_tree().change_scene_to_file("res://project/scenes/menu/nickname_select.tscn")
	
func _on_options_pressed():
	play_button_sound()  # Звук для кнопки Options
	#print("Настройки нажаты")
	# Показываем окно выбора языка
	language_window.visible = true

func _on_russian_selected():
	play_button_sound()  # Звук для кнопки русского языка
	current_language = "ru"
	_apply_language()
	language_window.visible = false

func _on_english_selected():
	play_button_sound()  # Звук для кнопки английского языка
	current_language = "en"
	_apply_language()
	language_window.visible = false
