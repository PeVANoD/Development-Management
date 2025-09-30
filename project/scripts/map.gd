extends Node2D
const FOOD = preload("res://project/scenes/food.tscn")
const SNAKE = preload("res://project/scenes/snake.tscn")

var radius = 1300
@export var curSnake = null
@export var snakeArr = []
var territory_capture: TerritoryCapture
var ai_snakes: Array = []  # Массив змеек с включенным AI

func _ready():
	# Создаем общую территорию
	territory_capture = TerritoryCapture.new()
	add_child(territory_capture)
	territory_capture.position = Vector2.ZERO
	
	genFood(radius)
	spawn_initial_snakes()

func spawn_initial_snakes():
	var snake_count = 8
	for i in range(snake_count):
		genSnake()
		if i > 0:
			toggle_snake_ai(i)

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

var turnAI = true
func _physics_process(_delta):
	handle_input()
	
	# Обновляем управление для всех змеек
	for i in range(snakeArr.size()):
		if snakeArr[i]:
			var snake = snakeArr[i]
			snake.is_controlled = (i == curSnake)

func handle_input():
	# Создание новой змейки
	if Input.is_action_just_pressed("Space"):
		#genSnake()
		pass
	
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
				print("Выбрана змейка ", i + 1)
	
	for i in range(12):  # Клавиши 0-9
		if Input.is_key_pressed(KEY_F1 + i):
			pass
	
	# Включение/выключение AI (Ctrl + цифра)
	if Input.is_key_pressed(KEY_CTRL):
		for i in range(10):  # Клавиши 0-9
			if Input.is_physical_key_pressed(KEY_0 + i) and snakeArr.size() > i and turnAI:
				turnAI = false
				toggle_snake_ai(i)
	else:
		turnAI = true

func toggle_snake_ai(snake_index: int):
	if snake_index >= snakeArr.size():
		print("Ошибка: змейки с индексом ", snake_index, " не существует")
		return
	
	var snake = snakeArr[snake_index]
	
	if snake.ai_control:
		snake.ai_control = false
		print("AI выключен для змейки ", snake_index + 1)
	else:
		snake.ai_control = true
		print("AI включен для змейки ", snake_index + 1)
		if curSnake == snake_index:
			curSnake = null
			for i in range(snakeArr.size()):
				if not (i in ai_snakes):
					curSnake = i
					print("Автоматически переключились на змейку ", i + 1)
					break

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
			break

func genSnake():
	var newSnake = SNAKE.instantiate()
	newSnake.territory_capture = territory_capture
	newSnake.snake_index = snakeArr.size()
	
	# Устанавливаем начальную позицию
	var angle = (snakeArr.size() * 2 * PI / 8) if snakeArr.size() < 8 else randf() * 2 * PI
	var distance = radius * 0.8
	var pos = Vector2(cos(angle) * distance, sin(angle) * distance)
	newSnake.global_position = pos
	newSnake.snakeNum = $Snakes.get_child_count()
	
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
