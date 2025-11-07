extends Control

# Переменные для музыки и звуков
var is_muted_music = false
var is_muted_sound = false
var sound_level
var music_level


var max_exp_value : int = 100
var min_exp_value : int = 0
var level : int = 1

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
		"wins_result": "Победы: ",
		"total_kills_result": "Всего убийств: ",
		"max_kills_result": "Макс убийств: ",
		"size_result": "Макс размер: ",
		"terrain_result": "Макс захвачено территории: ",
		"player_level": "Уровень: "
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
		"wins_result": "Wins: ",
		"total_kills_result": "Total kills: ",
		"max_kills_result": "Max kills: ",
		"size_result": "Max size: ",
		"terrain_result": "Max terrain captured: ",
		"player_level": "Level: "
	}
}

var current_language = "ru"

func _ready():
	# Применяем текущий язык
	$CanvasLayer/NicknameInput.text = G.nickname
	_apply_language()
	$CanvasLayer/ExpBar/MinValue.text = str(G.exp)
	set_exp_value(G.exp)
	set_player_stats(G.wins, G.total_kills, G.max_kills, G.max_territory ,G.max_size)
	#print("Меню загружено")

func _apply_language():
	var texts = language_texts[current_language]
	# Обновляем тексты меню
	$CanvasLayer/Button_menu/Play.text = texts["play"]
	$CanvasLayer/MusicButton.text = texts["music"]
	$CanvasLayer/SoundButton.text = texts["sounds"]
	$CanvasLayer/Label.text = texts["nickname_enter"]
	$CanvasLayer/ExpBar/LevelValue.text = texts["player_level"] + str(level)
	set_player_stats(G.wins, G.total_kills, G.max_kills, G.max_territory ,G.max_size)

# Функция для воспроизведения звука кнопок
func play_button_sound(): 
	$ButtonSound.play()


# Универсальный обработчик звука для всех кнопок
func _on_any_button_pressed():
	play_button_sound()


func _on_play_pressed(): 
	play_button_sound()  # Звук для кнопки Play
	_go_to_map()
	

var went_to_map = false
func _go_to_map():
	if went_to_map:
		return
	var nickname = $CanvasLayer/NicknameInput.text
	if nickname.length() <= 25:
		if nickname == "":
			nickname = "Player"
		
		went_to_map = true
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
	if value == -40.0:
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), true)
		is_muted_music = true
	else:
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), false)
		is_muted_music = false
	#print(value, is_muted_music)
	 
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
	

# Шкала опыта
func set_exp_value(new_value):
	var temp_value : int = 0
	if $CanvasLayer/ExpBar.value + new_value > max_exp_value:
		temp_value = new_value - max_exp_value
	$CanvasLayer/ExpBar.value += new_value
	if $CanvasLayer/ExpBar.value >= max_exp_value:
		level += 1
		$CanvasLayer/ExpBar.min_value = max_exp_value
		min_exp_value = max_exp_value
		max_exp_value *= 5
		$CanvasLayer/ExpBar.max_value = max_exp_value
		$CanvasLayer/ExpBar.value += temp_value
	$CanvasLayer/ExpBar/MinValue.text = str($CanvasLayer/ExpBar.value)
	$CanvasLayer/ExpBar/MaxValue.text = str($CanvasLayer/ExpBar.max_value)
	$CanvasLayer/ExpBar/LevelValue.text = language_texts[current_language]["player_level"] + str(level)


# Статистика игрока
func set_player_stats(wins, total_kills, max_kills, max_territory, max_size):
	var texts = language_texts[current_language]
	$CanvasLayer/PlayerStatsPanel/PassSesBox/WinsCount.text = texts["wins_result"] + str(wins)
	$CanvasLayer/PlayerStatsPanel/PassSesBox/AllKiilsCount.text = texts["total_kills_result"] + str(total_kills)
	$CanvasLayer/PlayerStatsPanel/PassSesBox/MaxKiilsCount.text = texts["max_kills_result"] + str(max_kills)
	$CanvasLayer/PlayerStatsPanel/PassSesBox/MaxSizeCount.text = texts["size_result"] + str(max_size)
	$CanvasLayer/PlayerStatsPanel/PassSesBox/MaxTerritoryCount.text = texts["terrain_result"] + str(max_territory) + "%"
	
	
