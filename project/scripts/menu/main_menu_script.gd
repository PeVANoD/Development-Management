extends Control

# Переменные для музыки и звуков
var is_muted_music = false
var is_muted_sound = false
var sound_level
var music_level

# Переменные для списка результатов
#var nickname_res
#var terrain_res
#var size_res

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
		"nickname_enter": "Введите ваш никнейм",
		"nickname_result": "Никнейм: ",
		"terrain_result": "Территории захвачено: ",
		"size_result": "Размер: "
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
		"nickname_enter": "Enter your nickname",
		"nickname_result": "Nickname: ",
		"terrain_result": "Terrain captured: ",
		"size_result": "Size: "
	}
}

var current_language = "ru"

func _ready():
	# Применяем текущий язык
	_apply_language()
	#prev_session_results()
	#print("Меню загружено")


func _apply_language():
	var texts = language_texts[current_language]
	# Обновляем тексты меню
	$CanvasLayer/Button_menu/Play.text = texts["play"]
	$CanvasLayer/MusicButton.text = texts["music"]
	$CanvasLayer/SoundButton.text = texts["sounds"]
	$CanvasLayer/Label.text = texts["nickname_enter"]
	#nickname_res = texts["nickname_result"]
	#terrain_res = texts["terrain_result"]
	#size_res = texts["size_result"]
	#prev_session_results() # нужно переписать текст в заголовках

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

# Результаты предыдущей сессии
#func prev_session_results():
	#if G.alive == false:
		#$CanvasLayer/PassSessionBox.visible = true
		#$CanvasLayer/PassSessionBox/NicknameLabel.text = nickname_res + G.nickname
		#$CanvasLayer/PassSessionBox/TerrainLabel.text = terrain_res + G.terrain
		#$CanvasLayer/PassSessionBox/SizeLabel.text = size_res + G.size


# Слайдер для музыки
func _on_music_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), value)
	if value == -40.0:
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), true)
		is_muted_music = true
	else:
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), false)
		is_muted_music = false
	print(value, is_muted_music)
	 
# Кнопка для музыки
func _on_music_button_pressed() -> void:
	if $CanvasLayer/MusicSlider.value != -40.0 and is_muted_music == false:
		music_level = $CanvasLayer/MusicSlider.value
		$CanvasLayer/MusicSlider.value = -40.0
		is_muted_music = true
	elif $CanvasLayer/MusicSlider.value == -40.0 and is_muted_music == true:
		$CanvasLayer/MusicSlider.value = music_level
		is_muted_music = false
	
	
# Слайдер для звуков
func _on_sound_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Sounds"), value)
	if value == -40.0:
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Sounds"), true)
		is_muted_sound = true
	else:
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Sounds"), false)
		is_muted_sound = false


# Кнопка для звуков
func _on_sound_button_pressed() -> void:
	if $CanvasLayer/SoundSlider.value != -40.0 and is_muted_sound == false:
		sound_level = $CanvasLayer/SoundSlider.value
		$CanvasLayer/SoundSlider.value = -40.0
		is_muted_sound = true
	elif $CanvasLayer/SoundSlider.value == -40.0 and is_muted_sound == true:
		$CanvasLayer/SoundSlider.value = sound_level
		is_muted_sound = false


func _on_language_button_pressed() -> void:
	play_button_sound()
	if current_language == "ru":
		current_language = "en"
		G.language = "en"
		$CanvasLayer/LanguageButton.text = "EN"
	else:
		current_language = "ru"
		G.language = "ru"
		$CanvasLayer/LanguageButton.text = "RU"
	_apply_language()
