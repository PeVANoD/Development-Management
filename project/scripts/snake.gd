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
var maxHistoryLength = 4
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
	print($Body/part1/StaticBody2D.collision_layer, " ",$Body/part1/StaticBody2D.collision_mask)
	if !ai_control:
		no_ai()
	else:
		enable_ai()
	# инициирует размер змейки
	for i in range(maxHistoryLength):
		positionHistory.push_front($Head.global_position)
	bodyGrow(60)
	await get_tree().create_timer(0.1).timeout
	changeBody()

func no_ai():
	$Head.animation = G.chosen_skin
	$Body/part1.animation = G.chosen_skin

func enable_ai():
	modulate = lerp(Color(0,1,0),Color.html(colors[snakeNum]),0.85)
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
	if (!territory_capture or !is_controlled) and !ai_control:
		$Head/Camera2D.enabled = false
		return
	$Head/Camera2D.enabled = true
	var new_zoom = lerp($Head/Camera2D.zoom.x, targetZoom, 0.1)
	$Head/Camera2D.zoom = Vector2(new_zoom, new_zoom)
	
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
		time_since_last_growth += delta
		if time_since_last_growth >= 0.2:
			if !randi_range(0,1):
				loseGrowth()
				if !$SpeedUpSound.playing and !ai_control:
					$SpeedUpSound.play()
			time_since_last_growth = 0.0
	else:
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
	$Head.rotation = angle
	
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
		var local_body_pos = territory_capture.global_to_territory_local(body_part.global_position)
		if territory_capture.is_point_in_territory_global(body_part.global_position, snake_index):
			tail_in_own_territory = true
			firstPartInside = i
			break
	
	# Логика захвата территории
	if not head_in_own_territory and tail_in_own_territory and not capture_started:
		# Начинаем захват
		headOutPos = head_pos
		var start_point = local_head_pos
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
		debuff_out_territory(delta)
	else:
		debuff_amount = 1.0
	
func changeBody():
	var length = ($Body.get_child_count()+20.0)/40.0
	var scaling = max(pow(length,0.3),1.0)
	var countSpeed = max(pow(territory_capture.get_territory_area(snake_index)/31000,0.05),1.0)
	targetZoom = 0.8*1/scaling
	startSpeed = baseSpeed*countSpeed
	maxSpeed = baseSpeed*1.5
	scale = Vector2(scaling,scaling)

# уменьшение змейки
func loseGrowth(amount = 1):
	for i in range(amount):
		var part_count = $Body.get_child_count()
		if part_count > 1:
			var lose_part = $Body.get_child(part_count-1)
			map_node.genFood(1,lose_part.global_position)
			lose_part.queue_free()
			maxHistoryLength -= addLength
			length -= 1
			changeBody()
			await get_tree().create_timer(0.01).timeout

# увеличение змейки
func bodyGrow(amount = 1):
	for i in range(amount):
		var newPart = $Body.get_child(0).duplicate()
		newPart.z_index = $Body.get_child_count() - 1
		length += 1
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
	if parts.size() == 0:
		return
	
	# ОПТИМИЗАЦИЯ: проверяем нужно ли вообще обновлять тело
	if positionHistory.size() < partDistance:
		return
	
	for i in range(parts.size()-1,-1,-1):
		var target_index = i * partDistance
		if target_index < positionHistory.size():
			parts[i].global_position = positionHistory[target_index]
			var scaling = min(1,float(parts.size()-1-i)/40+0.7)
			parts[i].scale = Vector2(scaling,scaling)
			
			# Упрощенный поворот - смотрим на следующую часть
			if i < parts.size():
				var next_part_pos = positionHistory[min((i + 1) * partDistance, positionHistory.size() - 1)]
				var dir = (next_part_pos - parts[i].global_position).normalized()
				parts[i].rotation = atan2(dir.y, dir.x)
				#if i == parts.size()-1:
					#parts[i].rotation_degrees = 90
					
# перерасчет направления
func countAngle():
	var max_rotation_speed = 0.04
	var angle_diff = direction.angle_to(desiredDirection)
	angle_diff = clamp(angle_diff, -max_rotation_speed, max_rotation_speed)
	direction = direction.rotated(angle_diff)

func kill_snake():
	territory_capture.clear_territory(snakeNum)
	if !ai_control:
		G.alive = false
		G.kills = kills
		G.total_kills += kills
		G.max_kills = max(G.max_kills, kills)
	self.queue_free()
	map_node.clearSnake()

# при попадании головы во что-то
func _in_mouth_body_entered(body):
	if body.is_in_group("Food"):
		body.get_node("CollisionShape2D").set_deferred("disabled", true)
		suck_food(body)
		if !randi_range(0,2):
			bodyGrow()
		map_node.genFood()
	if body.is_in_group("Snake") and body.get_node("../../..") != self:
		body.get_node("../../..").kills += 1
		kill_snake()

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


var aiTimer = 0.0
var feedTimer = 0.0
@export var feedTime = 0.8
@export var miss_chance = 0.2
var ai_direction = Vector2(0,0)
@onready var headOutPos = null
var firstPartInside = 0
func get_ai_direction(delta):
	check_colisions()
	aiTimer += delta
	feedTimer += delta
	if feedTimer > feedTime:
		bodyGrow(1)
		feedTimer = 0.0
	if aiTimer > 0.5:
		if !aiSpeed:
			aiSpeed = randi_range(0,10)
			if aiSpeed:
				aiSpeed = 3
		else:
			aiSpeed -= 1
		aiTimer = 0.0
		create_ai_direction()
	return ai_direction

func check_colisions():
	var changed = false
	if $"Head/0".is_colliding() and aiTimer > 0.2:
		changed = true
		if $Head/CRight.is_colliding() or $"Head/90".is_colliding() or $"Head/45".is_colliding():
			collided(-60)
		else:
			collided(60)
	elif $"Head/-45".is_colliding() and aiTimer > 0.2:
		changed = true
		collided(45)
	elif $"Head/45".is_colliding() and aiTimer > 0.2:
		changed = true
		collided(-45)
	elif $"Head/-90".is_colliding() and aiTimer > 0.2:
		changed = true
		collided(15)
	elif $"Head/90".is_colliding() and aiTimer > 0.2:
		changed = true
		collided(-15)
	if changed:
		aiTimer = 0.0

func collided(degr = 0):
	var current_rotation = int($Head.rotation_degrees+90) % 360
	if current_rotation < 0:
		current_rotation += 360
	if current_rotation > 180:
		current_rotation -= 360
	if randi_range(0,100)/100 < miss_chance:
		#print(str(snakeNum+1," missed! On: ", degr))
		if abs(degr) == 60:
			degr = 0
		elif abs(degr) == 15:
			degr *= -6
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
		var xPos = randf_range(-1.0,1.0)
		var preYPos = 1-abs(xPos)
		var yPos = randf_range(-preYPos, preYPos)
		ai_direction = Vector2(xPos,yPos)

func find_closest_polygon_point(position: Vector2, polygon: PackedVector2Array) -> Vector2:
	if polygon.is_empty():
		return position
	
	var closest_point = polygon[0]
	var min_distance = position.distance_to(polygon[0])
	
	for i in range(1, polygon.size()):
		var distance = position.distance_to(polygon[i])
		if distance < min_distance:
			min_distance = distance
			closest_point = polygon[i]
	
	return closest_point

var debuff_timer = 0.0
var debuff_amount = 1.0
var max_debuff_amount = 2.0
func debuff_out_territory(delta):
	if debuff_timer > 1.0/debuff_amount:
		debuff_timer = 0.0
		if $Body.get_child_count() < 1:
			kill_snake()
		debuff_amount = clamp(debuff_amount*1.05,1.0,max_debuff_amount)
		loseGrowth(round(debuff_amount))
		#print(debuff_amount)
		#print_rich("losing grow")
	debuff_timer += delta
