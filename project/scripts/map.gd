extends Node2D
const FOOD = preload("res://project/scenes/food.tscn")
const SNAKE = preload("res://project/scenes/snake.tscn")

var radius = 500
@export var curSnake = null
@export var snakeArr = []
var territory_capture: TerritoryCapture

func _ready():
	# Создаем общую территорию
	territory_capture = TerritoryCapture.new()
	add_child(territory_capture)
	territory_capture.position = Vector2.ZERO
	$Music.play()
	
	genFood(350)

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

func _physics_process(_delta):
	if Input.is_action_just_pressed("Space"):
		genSnake()
	if Input.is_action_just_pressed("Enter"):
		print(territory_capture.get_territory_area(curSnake))
		print(territory_capture.get_total_territory_area())
	# Система выбора змейки для управления
	if Input.is_physical_key_pressed(KEY_1) and snakeArr.size() > 0:
		curSnake = 0
	if Input.is_physical_key_pressed(KEY_2) and snakeArr.size() > 1:
		curSnake = 1
	if Input.is_physical_key_pressed(KEY_3) and snakeArr.size() > 2:
		curSnake = 2
	if Input.is_physical_key_pressed(KEY_4) and snakeArr.size() > 3:
		curSnake = 3
	if Input.is_physical_key_pressed(KEY_5) and snakeArr.size() > 4:
		curSnake = 4
	
	# Обновляем управление для всех змеек
	for i in range(snakeArr.size()):
		var snake = snakeArr[i]
		snake.is_controlled = (snake == snakeArr[curSnake])

func clearSnake():
	for i in range(snakeArr.size()):
		if snakeArr[i] == snakeArr[curSnake]:
			snakeArr.pop_at(i)
			if snakeArr:
				curSnake = 0
				$DeathSound.play()
			break

func genSnake():
	var newSnake = SNAKE.instantiate()
	newSnake.territory_capture = territory_capture  # Передаем общую территорию
	newSnake.snake_index = snakeArr.size()  # Устанавливаем индекс змейки
	
	# Устанавливаем начальную позицию для змейки
	var angle = randf() * 2 * PI
	var distance = radius * 0.7  # Размещаем ближе к центру
	var pos = Vector2(cos(angle) * distance, sin(angle) * distance)
	newSnake.global_position = pos
	
	curSnake = snakeArr.size()-1
	snakeArr.push_back(newSnake)
	$Snakes.add_child(newSnake)
	
	# Создаем начальную территорию для этой змейки
	territory_capture.create_initial_territory_for_snake(snakeArr.size() - 1, pos)
