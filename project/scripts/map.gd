extends Node2D
const FOOD = preload("res://project/scenes/food.tscn")
const SNAKE = preload("res://project/scenes/snake.tscn")

var radius = 1300
@export var curSnake = null
@export var snakeArr = []
var territory_capture: TerritoryCapture
var ai_snakes: Array = []  # Массив змеек с включенным AI

func _ready():
	G.alive = true
	$Music.play()
	# Создаем общую территорию
	territory_capture = TerritoryCapture.new()
	G.tera = territory_capture
	add_child(territory_capture)
	territory_capture.position = Vector2.ZERO
	$Music.play()
	
	
	genFood(radius)
	spawn_initial_snakes()

func spawn_initial_snakes():
	var snake_count = 8
	for i in range(snake_count):
		genSnake(i)


func genFood(amount = 1, pos = false):
	for i in range(amount):
		var createFood = FOOD.instantiate()
		if !pos:
			var fX = randi_range(-radius,radius)
			var maxY = sqrt(radius * radius - fX * fX)
			var fY = randi_range(-maxY,maxY)
			createFood.global_position = Vector2(fX,fY)
		else:
			createFood.global_position = pos
		var scalee = randf_range(0.5,1.3)
		createFood.scale = Vector2(scalee,scalee)
		$Food.call_deferred("add_child", createFood)

func smooth_modulate_transition(node,target_color: Color, duration: float) -> void:
	var tween = create_tween()
	tween.tween_property(node, "modulate", target_color, duration).set_trans(Tween.TransitionType.TRANS_SINE).set_ease(Tween.EaseType.EASE_IN_OUT)
@onready var change_view_node = $"../.."

func check_game():
	if !G.alive:
		#print("Loooooose...")
		G.result_is_win = false
		Engine.time_scale = 0.5
		smooth_modulate_transition(change_view_node,Color8(0x45, 0x21, 0x12, 255), 0.2)
		await get_tree().create_timer(1).timeout
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) || Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT): 
			Engine.time_scale = 1.0
			get_tree().change_scene_to_file("res://project/scenes/menu/main_menu.tscn")
	elif $Snakes.get_child_count() < 2:
		print("WIN!!!")
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
	print("index: ",curSnake," snake: ",snakeArr[curSnake])
	return
	for i in range(snakeArr.size()):
		if snakeArr[i] == snakeArr[curSnake]:
			snakeArr.pop_at(i)
			ai_snakes.erase(i)  # Удаляем из AI списка
			if snakeArr:
				curSnake = 0
				$DeathSound.play()
			break

func genSnake(i = 0):
	var newSnake = SNAKE.instantiate()
	if i > 0:
		newSnake.ai_control = true
	newSnake.territory_capture = territory_capture
	newSnake.snake_index = snakeArr.size()
	
	# Устанавливаем начальную позицию
	var angle = (snakeArr.size() * 2 * PI / 8) if snakeArr.size() < 8 else randf() * 2 * PI
	var distance = radius * 0.8
	var pos = Vector2(cos(angle) * distance, sin(angle) * distance)
	newSnake.global_position = pos
	newSnake.snakeNum = $Snakes.get_child_count()
	newSnake.name = str(newSnake.snakeNum + 1)
	
	snakeArr.push_back(newSnake)
	$Snakes.add_child(newSnake)
	
	# Создаем начальную территорию
	territory_capture.create_initial_territory_for_snake(snakeArr.size() - 1, pos)
	
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
