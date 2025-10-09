extends Control

func _ready():
	# Сначала выведем отладочную информацию о структуре сцены
	#print("=== СТРУКТУРА СЦЕНЫ ===")
	#print("Дети корневого узла:")
	for child in get_children():
		#print(" - ", child.name, " (", child.get_class(), ")")
		# Выводим детей второго уровня
		for grandchild in child.get_children():
			pass
			#print("   - ", grandchild.name, " (", grandchild.get_class(), ")")
	
	# Ищем узлы рекурсивно
	var nickname_input = find_child("NicknameInput", true, false)
	var continue_button = find_child("ContinueButton", true, false)
	var _error_label = find_child("ErrorLabel", true, false)  # Префикс _ так как не используется
	
	#print("=== РЕЗУЛЬТАТЫ ПОИСКА ===")
	#print("NicknameInput: ", nickname_input)
	#print("ContinueButton: ", continue_button)
	#print("ErrorLabel: ", _error_label)
	
	if nickname_input and continue_button:
		continue_button.disabled = false
		nickname_input.grab_focus()
		#continue_button.pressed.connect(_on_continue_button_pressed)
		nickname_input.text_changed.connect(_on_nickname_input_text_changed)
		nickname_input.text_submitted.connect(_on_nickname_text_submitted)
		
		# Устанавливаем placeholder для подсказки
		nickname_input.placeholder_text = "Введите никнейм"
		#print("UI элементы успешно инициализированы!")
	else:
		pass
		#print("Ошибка: Не все UI элементы найдены!")

func _on_continue_button_pressed():
	_go_to_map()

func _on_nickname_text_submitted(new_text: String):
	_go_to_map()

func _on_nickname_input_text_changed(new_text: String):
	var continue_button = find_child("ContinueButton", true, false)
	var _error_label = find_child("ErrorLabel", true, false)
	
	if continue_button:
		continue_button.disabled = false
	
	# Проверка длины ника (исправлено на 25 символов как в условии выше)
	if new_text.length() > 25:
		if _error_label:
			_error_label.text = "Максимум 25 символов"
			continue_button.disabled = true
	elif _error_label:
		_error_label.text = ""

func _go_to_map():
	var nickname_input = find_child("NicknameInput")
	if nickname_input:
		var nickname = nickname_input.text.strip_edges()
		
		# Исправлено: проверяем на 25 символов как в условии выше
		if nickname.length() <= 25:
			if nickname == "":
				nickname = "Player"
			
			G.nickname = nickname
			#print("Никнейм сохранен: ", nickname)
			
			# Воспроизводим звук и ЖДЕМ его окончания
			play_transition_sound()
			await get_tree().create_timer(0.3).timeout
			# Только потом переходим
			get_tree().change_scene_to_file("res://project/scenes/ui.tscn")
		else:
			pass
			#print("Никнейм слишком длинный")

func play_transition_sound():
	var sound_player = AudioStreamPlayer.new()
	add_child(sound_player)
	
	var sound = load("res://project/sounds/play_button_load_map_soundeffect.mp3")
	if sound:
		sound_player.stream = sound
		sound_player.pitch_scale = 1.3
		sound_player.volume_db = -12.0
		sound_player.play()
		
		await sound_player.finished
		sound_player.queue_free()
