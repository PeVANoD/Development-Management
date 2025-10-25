extends Node2D

# Переменные для музыки и звуков
var is_muted_music = false
var is_muted_sound = false
var sound_level
var music_level

# Тексты для разных языков
var language_texts = {
	"ru": {
		"play": "ИГРАТЬ",
		"options": "НАСТРОЙКИ",
		"music": "Музыка",
		"sounds": "Звуки",
		"show_windows": "ПОКАЗАТЬ ОКНА",
		"random_skin": "Случайный скин",
		"daily_skins": "Ежедневные скины", 
		"quests": "Квесты",
		"language": "Язык",
		"russian": "Русский",
		"english": "English",
		"nickname": "Введите ваш никнейм"
	},
	"en": {
		"play": "PLAY",
		"options": "OPTIONS",
		"music": "Music",
		"sounds": "Sounds",
		"show_windows": "SHOW WINDOWS",
		"random_skin": "Random Skin",
		"daily_skins": "Daily Skins",
		"quests": "Quests",
		"language": "Language",
		"russian": "Русский",
		"english": "English",
		"nickname": "Enter your nickname"
	}
}

var current_language = "ru"

func _ready():
	# Применяем текущий язык
	_apply_language()
	
	#print("Меню загружено")


func _apply_language():
	var texts = language_texts[current_language]
	# Обновляем тексты кнопок
	$CanvasLayer/Button_menu/Play.text = texts["play"]
	$CanvasLayer/MusicButton.text = texts["music"]
	$CanvasLayer/SoundButton.text = texts["sounds"]
	$CanvasLayer/Label.text = texts["nickname"]

# Функция для воспроизведения звука кнопок
func play_button_sound(): 
	$ButtonSound.play()


# Универсальный обработчик звука для всех кнопок
func _on_any_button_pressed():
	play_button_sound()


func _on_play_pressed(): 
	play_button_sound()  # Звук для кнопки Play
	_go_to_map()
	
	
func _go_to_map():
	var nickname = $CanvasLayer/NicknameInput.text
	if nickname.length() <= 25:
		if nickname == "":
			nickname = "Player"
			
		G.nickname = nickname
		# Воспроизводим звук и ЖДЕМ его окончания
		await play_transition_sound()
		# Только потом переходим
		get_tree().change_scene_to_file("res://project/scenes/ui.tscn")
	else:
		pass


func play_transition_sound():
	$TransitionSound.play()
	await $TransitionSound.finished
	$TransitionSound.queue_free()


# Слайдер для музыки
func _on_music_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), value)
	if value == -30:
		is_muted_music == true
	else:
		is_muted_music = false
	 
# Кнопка для музыки
func _on_music_button_pressed() -> void:
	if $CanvasLayer/MusicSlider.value != -70 and is_muted_music == false:
		music_level = $CanvasLayer/MusicSlider.value
		$CanvasLayer/MusicSlider.value = -70
		is_muted_music = true
	elif $CanvasLayer/MusicSlider.value == -70 and is_muted_music == true:
		$CanvasLayer/MusicSlider.value = music_level
		is_muted_music = false
	
	
# Слайдер для звуков
func _on_sound_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Sounds"), value)
	if value == -70:
		is_muted_sound == true
	else:
		is_muted_sound = false


# Кнопка для звуков
func _on_sound_button_pressed() -> void:
	if $CanvasLayer/SoundSlider.value != -70 and is_muted_sound == false:
		sound_level = $CanvasLayer/SoundSlider.value
		$CanvasLayer/SoundSlider.value = -70
		is_muted_sound = true
	elif $CanvasLayer/SoundSlider.value == -70 and is_muted_sound == true:
		$CanvasLayer/SoundSlider.value = sound_level
		is_muted_sound = false


func _on_language_button_pressed() -> void:
	play_button_sound()
	if current_language == "ru":
		current_language = "en"
		$CanvasLayer/LanguageButton.text = "EN"
	else:
		current_language = "ru"
		$CanvasLayer/LanguageButton.text = "RU"
	_apply_language()
