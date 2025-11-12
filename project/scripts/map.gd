extends Node2D
const FOOD = preload("res://project/scenes/food.tscn")
const SNAKE = preload("res://project/scenes/snake.tscn")

var radius = 1300
@export var curSnake = null
@export var snakeArr = []
var territory_capture: TerritoryCapture
var ai_snakes: Array = []

var food_spawners: Array = []  # Массив позиций спавнеров
var spawner_radius = 80
var max_food_count = 100
var start_food_count = 200

var min_food_in_point = 15
var max_food_in_point = 25

var snake_count = 8

var active_spawner_position: Vector2 = Vector2.ZERO
var active_spawner_food_count: int = 0
var active_spawner_max_food: int = 10

func _ready():
	G.alive = true
	$Music.play()
	territory_capture = TerritoryCapture.new()
	G.tera = territory_capture
	add_child(territory_capture)
	territory_capture.position = Vector2.ZERO
	$Music.play()
	
	create_new_active_spawner()
	genFood(start_food_count)
	spawn_initial_snakes()

func spawn_initial_snakes():
	# Выбираем случайный индекс цвета для игрока
	var player_color_index = randi() % snake_count
	
	genSnake(0, player_color_index)
	
	for i in range(1, snake_count):
		genSnake(i, i)

func create_new_active_spawner():
	var angle = randf() * 2 * PI
	var distance = randf() * (radius - 400)
	active_spawner_position = Vector2(cos(angle) * (distance + 300), sin(angle) * (distance + 300))
	
	active_spawner_max_food = randi_range(min_food_in_point, max_food_in_point)
	active_spawner_food_count = 0

func get_current_food_count() -> int:
	return $Food.get_child_count()

func get_spawn_position_near_active_spawner() -> Vector2:
	var angle = randf() * 2 * PI
	var distance = randf() * spawner_radius
	var offset = Vector2(cos(angle) * distance, sin(angle) * distance)
	var final_pos = active_spawner_position + offset
	
	if final_pos.length() > radius - 50:
		distance = randf() * (spawner_radius * 0.5)
		offset = Vector2(cos(angle) * distance, sin(angle) * distance)
		final_pos = active_spawner_position + offset
	
	return final_pos

func genFood(amount = 1, pos = false, exact_position = false):
	for i in range(amount):
		if not pos and get_current_food_count() >= max_food_count:
			break
			
		var createFood = FOOD.instantiate()
		if !pos:
			if active_spawner_food_count >= active_spawner_max_food:
				create_new_active_spawner()
			
			createFood.global_position = get_spawn_position_near_active_spawner()
			active_spawner_food_count += 1
		else:
			if exact_position:
				createFood.global_position = pos
			else:
				createFood.global_position = get_spawn_position_near_active_spawner()
		var scalee = randf_range(1.5, 2.5)
		createFood.scale = Vector2(scalee,scalee)
		$Food.call_deferred("add_child", createFood)

func smooth_modulate_transition(node,target_color: Color, duration: float) -> void:
	var tween = create_tween()
	tween.tween_property(node, "modulate", target_color, duration).set_trans(Tween.TransitionType.TRANS_SINE).set_ease(Tween.EaseType.EASE_IN_OUT)
@onready var change_view_node = $"../.."

func check_game():
	if !G.alive:
		G.result_is_win = false
		Engine.time_scale = 0.5
		smooth_modulate_transition(change_view_node,Color8(0x45, 0x21, 0x12, 255), 0.2)
		await get_tree().create_timer(1).timeout
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) || Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT): 
			Engine.time_scale = 1.0
			get_tree().change_scene_to_file("res://project/scenes/menu/main_menu.tscn")
	elif $Snakes.get_child_count() < 2:
		G.result_is_win = true
		smooth_modulate_transition(change_view_node,Color8(0x00, 0x82, 0x31, 255), 0.5)
		Engine.time_scale = 1.5
		await get_tree().create_timer(2).timeout
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) || Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			Engine.time_scale = 1.0
			get_tree().change_scene_to_file("res://project/scenes/menu/main_menu.tscn")

var turnAI = true
func _physics_process(_delta):
	handle_input()
	check_game()
	# Обновляем управление для всех змеек
	for i in range(snakeArr.size()):
		if snakeArr[i]:
			var snake = snakeArr[i]
			snake.is_controlled = (i == curSnake)

func handle_input():
	# Создание новой змейки
	if Input.is_action_just_pressed("Esc"):
		if G.alive:
			$Snakes.get_child(0).kill_snake()
	
	# Информация о территории
	if Input.is_action_just_pressed("Enter"):
		if curSnake != null and curSnake < snakeArr.size():
			print("Территория текущей змейки: ", territory_capture.get_territory_area(curSnake))
		print("Общая территория: ", territory_capture.get_total_territory_area())
	
	# Выбор змейки для управления
	for i in range(10):  # Клавиши 0-9
		if Input.is_key_pressed(KEY_0 + i) and snakeArr.size() > i and snakeArr[i]:
			# Проверяем, не нажат ли Ctrl
			if not Input.is_key_pressed(KEY_CTRL) and not Input.is_key_pressed(KEY_ALT):
				curSnake = i
				#print("Выбрана змейка ", i + 1)
	
	for i in range(12):  # Клавиши 0-9
		if Input.is_key_pressed(KEY_F1 + i):
			pass
	
	# Включение/выключение AI (Ctrl + цифра)
	if Input.is_key_pressed(KEY_CTRL):
		for i in range(10):  # Клавиши 0-9
			if Input.is_physical_key_pressed(KEY_0 + i) and snakeArr.size() > i and turnAI:
				turnAI = false
	else:
		turnAI = true


func clearSnake():
	snakeArr[curSnake] = null
	for i in range(snakeArr.size()):
		if snakeArr[i]:
			curSnake = i
			break
	return

func genSnake(i = 0, color_index = -1):
	var newSnake = SNAKE.instantiate()
	if i > 0:
		newSnake.ai_control = true
	newSnake.territory_capture = territory_capture
	
	# snake_index - это уникальный индекс змейки в массиве (всегда по порядку)
	newSnake.snake_index = snakeArr.size()
	
	# Если color_index не указан, используем snake_index
	if color_index < 0:
		color_index = snakeArr.size()
	
	# Устанавливаем начальную позицию
	var angle = (snakeArr.size() * 2 * PI / 8) if snakeArr.size() < 8 else randf() * 2 * PI
	var distance = radius * 0.8
	var pos = Vector2(cos(angle) * distance, sin(angle) * distance)
	newSnake.global_position = pos
	newSnake.snakeNum = $Snakes.get_child_count()
	newSnake.name = str(newSnake.snakeNum + 1)
	
	snakeArr.push_back(newSnake)
	$Snakes.add_child(newSnake)
	
	# Создаем начальную территорию с правильным индексом, но используем color_index для цвета
	territory_capture.create_initial_territory_for_snake(newSnake.snake_index, pos, color_index)
	
	if snakeArr.size() == 1:
		curSnake = 0

# Получить список змеек с AI
func get_ai_snakes() -> Array:
	return ai_snakes

# Получить список управляемых змеек
func get_controlled_snakes() -> Array:
	var controlled = []
	for i in range(snakeArr.size()):
		if not (i in ai_snakes):
			controlled.append(i)
	return controlled
