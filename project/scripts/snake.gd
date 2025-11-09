extends Node2D

var colors = [
	"#FF0000",  # Красный
	"#00FF00",  # Зеленый
	"#0000FF",  # Синий
	"#FFFF00",  # Желтый
	"#FF00FF",  # Пурпурный
	"#00FFFF",  # Голубой
	"#FF8000",  # Оранжевый
	"#8000FF",  # Фиолетовый
	"#FF0080",  # Розовый
	"#00FF80",  # Весенний зеленый
	"#80FF00",  # Лаймовый
	"#0080FF",  # Ярко-синий
	"#FF8040",  # Коралловый
	"#40FF80",  # Мятный
	"#8040FF",  # Лавандовый
	"#FF4080"   # Фуксия
]

var skins = ["1","2","3"]

#region переменные персонажа
@export var speed = 150.0
@export var partDistance = 6
#endregion
#region переменные межфункций
@onready var map_node = $"../.."
@onready var ui_node = get_node("/root/UI/CanvasLayer/uiNode")
@export var length = 0
@export var snakeNum = 0
@export var kills = 0
var targetZoom = 0.8
var isRotating
var direction = Vector2(0,-1)
var desiredDirection = Vector2(0,-1)
var lastPos = Vector2(0,1)
var lastAngle = 1.0
var lastBodyAngle = 1.0
@onready var startSpeed = speed
@onready var baseSpeed = speed
@onready var maxSpeed = speed*1.5
var positionHistory = []
var maxHistoryLength = 6
var addLength = 6
var time_since_last_growth: float = 0.0
@export var is_controlled: bool = false  # Управляется ли эта змейка
#endregion

# Территории
var territory_capture: TerritoryCapture
@export var snake_index: int = 0  # Индекс этой змейки
var was_in_territory: bool = false

@export var ai_control = false
var aiSpeed = false
func _ready():
	$Body/part1/StaticBody2D.set_collision_layer_value(snakeNum+9,true)
	$Body/part1/StaticBody2D.set_collision_mask_value(snakeNum+9,true)
	$Head/CPU.color = lerp(Color(0,0,0),Color.html(colors[snakeNum]),0.5)
	if !ai_control:
		no_ai()
	else:
		enable_ai()
	# инициирует размер змейки
	for i in range(maxHistoryLength):
		positionHistory.push_front($Head.global_position)
	bodyGrow(40)
	await get_tree().create_timer(0.1).timeout
	changeBody()

func no_ai():
	$Head/Nick.text = G.nickname
	$Head.animation = G.chosen_skin
	$Body/part1.animation = G.chosen_skin
	$Head/Nick.modulate = lerp(Color(1,1,1),Color.html(colors[snakeNum]),0.4)


func enable_ai():
	$Head/Nick.text = str("Player ",snakeNum)
	$Head.self_modulate = lerp(Color(0,0,0),Color.html(colors[snakeNum]),0.85)
	$Body.modulate = lerp(Color(0,0,0),Color.html(colors[snakeNum]),0.85)
	$Head/Nick.modulate = lerp(Color(1,1,1),Color.html(colors[snakeNum]),0.4)
	territory_capture.set_territory_effect(snake_index, randi() % 8) # randi() % 8)
	$"Head/-90".enabled = true
	$"Head/-45".enabled = true
	$"Head/0".enabled = true
	$"Head/45".enabled = true
	$"Head/90".enabled = true
	$"Head/-90".set_collision_mask_value(9+snakeNum,false)
	$"Head/-45".set_collision_mask_value(9+snakeNum,false)
	$"Head/0".set_collision_mask_value(9+snakeNum,false)
	$"Head/45".set_collision_mask_value(9+snakeNum,false)
	$"Head/90".set_collision_mask_value(9+snakeNum,false)

func _physics_process(delta):
	update_camera()
	checkInputs(delta)
	update_position_history()
	update_direction(delta)
	move_head(delta)
	keep_inside_bounds()
	update_territory_capture(delta)
	checkBody()
	
func update_camera():
	if ai_control:
		$Head/Camera2D.enabled = false
		return
	$Head/Camera2D.enabled = true
	var new_zoom = lerp($Head/Camera2D.zoom.x, targetZoom, 0.1)
	$Head/Camera2D.zoom = Vector2(new_zoom, new_zoom)

var lock_eyes = false
func checkInputs(delta):
	if is_controlled:
		# Оригинальное управление игрока
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			isRotating = true
		else:
			isRotating = false
		
		if Input.is_action_just_pressed("ui_up"):
			pass
			#print("ChildCount: ",$Body.get_child_count(), " Length: ", $Head.global_position.distance_to($Body.get_child(0).global_position))
		
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and $Body.get_child_count() > 2 and (!ai_control or aiSpeed):
		speed = lerp(speed, maxSpeed, 0.1)
		lock_eyes = true
		$Head/Eyes/eyeT.start()
		if $"Head/Eyes/1".animation != "2":
			$"Head/Eyes/1".speed_scale = 1
			$"Head/Eyes/2".speed_scale = 1
			$"Head/Eyes/1".play("2")
			$"Head/Eyes/2".play("2")
		time_since_last_growth += delta
		if time_since_last_growth >= 0.2:
			if !randi_range(0,1):
				loseGrowth()
				if !$SpeedUpSound.playing and !ai_control:
					$SpeedUpSound.play()
			time_since_last_growth = 0.0
	else:
		if $"Head/Eyes/1".animation == "2" and $"Head/Eyes/1".frame == 3:
			$"Head/Eyes/1".speed_scale = 1.5
			$"Head/Eyes/2".speed_scale = 1.5
			$"Head/Eyes/1".play_backwards("2")
			$"Head/Eyes/2".play_backwards("2")
		if !lock_eyes:
			$"Head/Eyes/1".animation = "1"
			$"Head/Eyes/2".animation = "1"
		speed = lerp(speed, startSpeed, 0.1)
		if !ai_control:
			$SpeedUpSound.stop()
	
func update_position_history():
	if positionHistory.is_empty() or $Head.global_position.distance_to(positionHistory[0]) > 2.0:
		positionHistory.push_front($Head.global_position)
	var max_needed_history = $Body.get_child_count() * partDistance + 10
	if positionHistory.size() > max_needed_history:
		positionHistory.resize(max_needed_history)
		
func update_direction(delta):
	if isRotating or ai_control:
		if ai_control:
			desiredDirection = get_ai_direction(delta)
		else:
			desiredDirection = (get_global_mouse_position() - $Head.global_position).normalized()
	countAngle()
	
func move_head(delta):
	$Head.position += direction * delta * speed
	var angle = lerp_angle(lastAngle, atan2(-direction.y, -direction.x), 0.2)
	lastAngle = angle
	$Head/Nick.rotation_degrees = lerp($Head/Nick.rotation_degrees,-rad_to_deg(angle),0.2)
	$Head/Nick.position = lerp($Head/Nick.position, Vector2(-65, -10 + 50*sin(angle+rad_to_deg(90))),0.2)
	$Head.rotation = angle
	eyes_process(angle)

var eye_dir = Vector2(0,0)
func eyes_process(angle):
	eye_dir = lerp(eye_dir,desiredDirection.rotated(-angle - deg_to_rad(90)), 0.1)
	var eX = clamp(-3,eye_dir.x*3,3)
	var eY = clamp(-3,eye_dir.y*3,3)
	$"Head/Eyes/1/pupil".position = Vector2(-eX,eY)
	$"Head/Eyes/2/pupil".position = Vector2(eX,eY)

func keep_inside_bounds():
	var head_pos = $Head.global_position
	var distance_from_center = head_pos.length()
	var margin = 10.0
	
	if distance_from_center > map_node.radius - margin:
		var normal = head_pos.normalized()
		if direction.dot(normal) > 0:
			var tangent = Vector2(-normal.y, normal.x)
			if direction.dot(tangent) < 0:
				tangent = -tangent
			direction = direction.lerp(tangent, 0.2).normalized()
			$Head.global_position = normal * (map_node.radius - margin)

var capture_started = false
# проверка захвата территории
func update_territory_capture(delta):
	var head_pos = $Head.global_position
	var local_head_pos = territory_capture.global_to_territory_local(head_pos)
	
	# Проверяем, находится ли голова на территории этой змейки
	var head_in_own_territory = territory_capture.is_point_in_territory_global(head_pos, snake_index)
	
	# Находим первую часть тела, которая находится на территории
	var tail_in_own_territory = false
	firstPartInside = -1
	
	for i in range($Body.get_child_count()):
		var body_part = $Body.get_child(i)
		var _local_body_pos = territory_capture.global_to_territory_local(body_part.global_position)
		if territory_capture.is_point_in_territory_global(body_part.global_position, snake_index):
			tail_in_own_territory = true
			firstPartInside = i
			break
	
	# Логика захвата территории
	if not head_in_own_territory and tail_in_own_territory and not capture_started:
		# Начинаем захват
		headOutPos = head_pos
		var _start_point = local_head_pos
		territory_capture.start_external_capture(snake_index,  local_head_pos - direction.normalized()*16)
		territory_capture.update_external_capture(snake_index, local_head_pos)
		capture_started = true
	
	elif capture_started and tail_in_own_territory:
		# Продолжаем захват
		var current_point = local_head_pos
		territory_capture.update_external_capture(snake_index, current_point)
		
		if head_in_own_territory:
			# Завершаем захват
			territory_capture.update_external_capture(snake_index, local_head_pos + direction.normalized()*4)
			territory_capture.update_external_capture(snake_index, local_head_pos + direction.normalized()*12)
			territory_capture.update_external_capture(snake_index, local_head_pos + direction.normalized()*20)
			territory_capture.finish_external_capture(snake_index)
			if !ai_control:
				G.terrain = round(float(G.tera.get_territory_area(snake_index))/5226191*1000)/10
				G.max_territory = max(G.max_territory, G.terrain)
			if !ai_control:
				$TerritoryCaptureSound.pitch_scale = randf_range(0.7,1.3)
				$TerritoryCaptureSound.play()
			capture_started = false
			headOutPos = null
			changeBody()
	
	elif capture_started and not tail_in_own_territory:
		# Прерываем захват
		territory_capture.cancel_external_capture(snake_index)
		capture_started = false
		headOutPos = null
	
	if head_in_own_territory:
		goingToBase = false
	
	if not tail_in_own_territory and not head_in_own_territory:
		show_territory_warning()  # Показываем предупреждение
		debuff_out_territory(delta)
	else:
		hide_territory_warning()  # Скрываем предупреждение
		debuff_amount = 1.0
		first_debuff_timer = 0.0

var last_scaling = 1.0
func changeBody():
	var lengthB = ($Body.get_child_count()+20.0)/40.0
	var scaling = lerp(last_scaling, max(pow(lengthB,0.3),1.0),0.01)
	last_scaling = scaling
	var countSpeed = max(pow(territory_capture.get_territory_area(snake_index)/31000,0.05),1.0)
	targetZoom = 0.8*1/scaling
	startSpeed = baseSpeed*countSpeed
	maxSpeed = baseSpeed*1.5
	scale = Vector2(scaling,scaling)

# уменьшение змейки
func loseGrowth(amount = 1):
	# Проверяем, что змейка еще существует
	if not is_inside_tree():
		return
		
	for i in range(amount):
		var part_count = $Body.get_child_count()
		if part_count > 0:
			var lose_part = $Body.get_child(part_count-1)
			if map_node and is_inside_tree():  # Проверяем что map_node существует
				map_node.genFood(1, lose_part.global_position, true)  # Точная позиция
			lose_part.queue_free()
			maxHistoryLength -= addLength
			length -= 1
			if is_inside_tree():  # Проверяем перед вызовом changeBody
				changeBody()
			await get_tree().create_timer(0.01).timeout

# увеличение змейки
func bodyGrow(amount = 1):
	# Проверяем, что змейка еще жива и у неё есть части тела
	if not is_inside_tree() or $Body.get_child_count() == 0:
		return
	if amount < 0:
		loseGrowth(-amount)
		return
	for i in range(amount):
		# Дополнительная проверка на каждой итерации
		if $Body.get_child_count() == 0:
			break
		var newPart = $Body.get_child(0).duplicate()
		newPart.z_index = $Body.get_child_count() - 1
		length += 1
		if !ai_control:
			G.size = length
			G.max_size = max(G.max_size, length)
		maxHistoryLength += addLength
		$Body.call_deferred("add_child", newPart)
		$Body.call_deferred("move_child", newPart,0)
		# Добавляем больше точек в историю при создании новой части
		for j in range(addLength):
			positionHistory.push_back(positionHistory[-1] if positionHistory.size() > 0 else $Head.global_position)
	changeBody()
	
# перемещение каждой части тела по следу головы
func checkBody():
	var parts = $Body.get_children()
	var parts_count = parts.size()
	if parts_count == 0 or positionHistory.size() < partDistance:
		return
	var history_size = positionHistory.size()
	for i in range(parts_count - 1, -1, -1):
		var target_index = i * partDistance
		if target_index >= history_size:
			continue
		var part = parts[i]
		part.z_index = -i
		part.global_position = positionHistory[target_index]
		# Оптимизация вычисления масштаба
		var scaling = 0.7 + (parts_count - 1 - i) * 0.025  # 1/40 = 0.025
		scaling = min(scaling, 1.0)
		part.scale = Vector2(scaling, scaling)
		# Оптимизация поворота
		if i < parts_count - 1:
			var next_index = min((i + 1) * partDistance, history_size - 1)
			var dir = (positionHistory[next_index] - part.global_position).normalized()
			part.rotation = atan2(dir.y, dir.x)
					
# перерасчет направления
func countAngle():
	var max_rotation_speed = 0.06
	var angle_diff = direction.angle_to(desiredDirection)
	angle_diff = clamp(angle_diff, -max_rotation_speed, max_rotation_speed)
	direction = direction.rotated(angle_diff)

func kill_snake():
	if !ai_control:
		deathActivate()
	
	spawn_food_from_body()
	
	# Просто очищаем территорию умершей змейки
	territory_capture.clear_territory(snake_index)
		
	if !ai_control:
		G.alive = false
		G.kills = kills
		G.total_kills += kills
		G.max_kills = max(G.max_kills, kills)
	self.queue_free()
	map_node.clearSnake()

# Создание еды от всех частей тела змейки
func spawn_food_from_body():
	if not map_node:
		return
		
	# Спавним еду от головы точно на её позиции
	map_node.genFood(1, $Head.global_position, true)
	
	# Спавним еду от каждой части тела точно на их позициях
	var parts = $Body.get_children()
	for part in parts:
		if part and is_instance_valid(part):
			map_node.genFood(1, part.global_position, true)

var which_CPU = 0
func _in_mouth_body_entered(body):
	if body.is_in_group("Food"):
		# Проверяем, что змейка еще жива перед поеданием
		if not is_inside_tree() or $Body.get_child_count() == 0:
			return
		body.get_node("CollisionShape2D").set_deferred("disabled", true)
		suck_food(body)
		if !lock_eyes:
			print("FOOD")
			$"Head/Eyes/1".animation = "4"
			$"Head/Eyes/2".animation = "4"
			$Head/Eyes/eyeT.start()
			lock_eyes = true
		
		if !randi_range(0,2):
			bodyGrow()
		# Спавним новую еду только если текущее количество меньше максимального
		if map_node.get_current_food_count() < map_node.max_food_count:
			map_node.genFood()
		await get_tree().create_timer(0.2).timeout
		match which_CPU:
			0:
				$Head/Mouth/CPU1.restart()
				$Head/Mouth/CPU1.emitting = true
			1:
				$Head/Mouth/CPU2.restart()
				$Head/Mouth/CPU2.emitting = true
			2:
				$Head/Mouth/CPU3.restart()
				$Head/Mouth/CPU3.emitting = true
			3:
				$Head/Mouth/CPU4.restart()
				$Head/Mouth/CPU4.emitting = true
				which_CPU = -1
		which_CPU += 1

		which_CPU != which_CPU
	if body:
		if body.is_in_group("Snake") and body.get_node("../../..") != self:
			var other_snake = body.get_node("../../..")
			print(other_snake.name, " ",other_snake.kills)
			other_snake.kills += 1  # Другая змейка получает убийство
			$"../..".delCPU()
			kill_snake()  # Эта змейка (которая врезалась) умирает

func deathActivate():
	var newCam = $Head/Camera2D.duplicate()
	newCam.global_position = $Head/Camera2D.global_position
	$"../..".add_child(newCam)
	$Head/Camera2D.queue_free()
	var newCPU = $Head/CPU.duplicate()
	newCPU.amount = max(length / 3 , 16)
	newCPU.global_position = $Head/CPU.global_position
	$"../..".add_child(newCPU)
	$Head/CPU.queue_free()
	$"../..".CPUarr.push_back(newCPU)
	newCPU.emitting = true

func _on_eye_t_timeout():
	lock_eyes = false

func suck_food(node):
	if Engine.time_scale == 1.0:
		for i in range(10):
			if node:
				node.global_position = lerp(node.global_position,$Head.global_position+direction*32,0.1)
			else:
				return
			await get_tree().create_timer(0.02).timeout
		if node:
			if !ai_control:
				$EatSound.pitch_scale = randf_range(2.0,5.0)
				$EatSound.play()
			node.queue_free()
	else:
		node.queue_free()


var ai_Timer = 0.0
var feed_Timer = 0.0
@export var base_feed_Time = 1.4
@onready var adds_Time : float = (1.0-1.0/(sqrt(float(G.difficulty))))
@onready var feed_Time = base_feed_Time - adds_Time
@export var miss_chance = 0.2
var ai_direction = Vector2(0,0)
@onready var headOutPos = null
var firstPartInside = 0
func get_ai_direction(delta):
	check_RC_colisions()
	ai_Timer += delta
	feed_Timer += delta
	if feed_Timer > feed_Time:
		bodyGrow(1)
		feed_Timer = 0.0
	if ai_Timer > 0.2:
		if !aiSpeed:
			aiSpeed = randi_range(0,10)
			if aiSpeed:
				aiSpeed = 3
		else:
			aiSpeed -= 1
		ai_Timer = 0.0
		create_ai_direction()
	return ai_direction

func check_RC_colisions():
	var changed = false
	if $"Head/0".is_colliding() and ai_Timer > 0.1:
		changed = true
		if $Head/CRight.is_colliding() or $"Head/90".is_colliding() or $"Head/45".is_colliding():
			RC_collided(-60)
		else:
			RC_collided(60)
	elif $"Head/-45".is_colliding() and ai_Timer > 0.1:
		changed = true
		RC_collided(45)
	elif $"Head/45".is_colliding() and ai_Timer > 0.1:
		changed = true
		RC_collided(-45)
	if changed:
		ai_Timer = 0.0

func RC_collided(degr = 0):
	var current_rotation = int($Head.rotation_degrees+90) % 360
	if current_rotation < 0:
		current_rotation += 360
	if current_rotation > 180:
		current_rotation -= 360
	if float(randi_range(0,100))/100.0 < miss_chance:
		#print(str(snakeNum+1," missed! On: ", degr))
		if abs(degr) == 60:
			degr = 0
		elif abs(degr) == 5:
			degr *= -16
		else:
			degr *= -1
		#print("new degr = ",degr)
	var total_angle = current_rotation + degr
	var rad_angle = deg_to_rad(total_angle)
	ai_direction = Vector2.from_angle(rad_angle)


var goingToBase = false
func create_ai_direction():
	var lengthLeft = ($Body.get_child_count()-firstPartInside)*14.2
	var closestEntryPoint = find_closest_polygon_point($Head.global_position, territory_capture.territories[snake_index])
	if $Head.global_position.distance_to(closestEntryPoint) + 330 > lengthLeft or goingToBase:
		goingToBase = true
		ai_direction = (closestEntryPoint - $Head.global_position).normalized()
	else:
		var food_hunt = find_closest_food($Head.global_position)
		if food_hunt and randi_range(0,4):
			ai_direction = food_hunt
		else:
			var xPos = randf_range(-1.0,1.0)
			var preYPos = 1-abs(xPos)
			var yPos = randf_range(-preYPos, preYPos)
			ai_direction = Vector2(xPos,yPos)

func find_closest_food(pos: Vector2):
	var targets = $Head/FindFood.get_overlapping_bodies()
	var nearest_distance = INF
	var new_nearest: Node2D = null
	for target in targets:
		if target.is_in_group("Food"):
			var distance = pos.distance_to(target.global_position)
			if distance < nearest_distance and distance > 80:
				nearest_distance = distance
				new_nearest = target
	if new_nearest:
		var directionNEW = (new_nearest.global_position - pos).normalized()
		return directionNEW
	else:
		return false

func find_closest_polygon_point(pos: Vector2, polygon: PackedVector2Array) -> Vector2:
	if polygon.is_empty():
		return pos
	
	var closest_point = polygon[0]
	var min_distance = pos.distance_to(polygon[0])
	
	for i in range(1, polygon.size()):
		var distance = pos.distance_to(polygon[i])
		if distance < min_distance:
			min_distance = distance
			closest_point = polygon[i]
	
	return closest_point

var debuff_amount = 1.0
var max_debuff_amount = 5.0
var time_to_debuff = 5.0
var debuff_timer = 0.0
var first_debuff_timer = 0.0

func debuff_out_territory(delta):
	if first_debuff_timer >= 4:
		if debuff_timer >= 0.3 / debuff_amount:
			debuff_timer = 0.0
			if $Body.get_child_count() <= 2:
				kill_snake()
				return
			debuff_amount += 0.07
			loseGrowth(1)
		debuff_timer += delta
	first_debuff_timer += delta

func show_territory_warning():
	if ai_control: return
	ui_node.show_territory_warning()

func hide_territory_warning():
	if ai_control: return
	ui_node.hide_territory_warning()
