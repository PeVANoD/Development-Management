extends Node2D 

#region переменные персонажа
@export var speed = 150.0
@export var partDistance = 6
#endregion
#region переменные межфункций
@onready var map_node = $"../.."
@export var length = 0
@export var snakeNum = 0
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

func _ready():
	# инициирует размер змейки
	for i in range(maxHistoryLength):
		positionHistory.push_front($Head.global_position)
	bodyGrow(30)
	await get_tree().create_timer(0.1).timeout
	changeBody()
@export var ai_control = false
var aiSpeed = false

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
			territory_capture.finish_external_capture()
			$TerritoryCaptureSound.play()
			was_in_territory = false
			territory_capture.update_external_capture(snake_index, local_head_pos + direction.normalized()*4)
			territory_capture.update_external_capture(snake_index, local_head_pos + direction.normalized()*12)
			territory_capture.update_external_capture(snake_index, local_head_pos + direction.normalized()*20)
			territory_capture.finish_external_capture(snake_index)
			if !ai_control:
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
	
func changeBody():
	var length = ($Body.get_child_count()+20.0)/40.0
	var scaling = max(pow(length,0.3),1.0)
	var countSpeed = max(pow(territory_capture.get_territory_area(snake_index)/31000,0.05),1.0)
	targetZoom = 0.8*1/scaling
	startSpeed = baseSpeed*countSpeed
	maxSpeed = baseSpeed*1.5
	scale = Vector2(scaling,scaling)

# уменьшение змейки
func loseGrowth():
	map_node.genFood(1,$Body.get_child(0).global_position)
	$Body.get_child(0).queue_free()
	maxHistoryLength -= addLength
	length -= 1
	changeBody()

# увеличение змейки
func bodyGrow(amount = 1):
	for i in range(amount):
		var newPart = $Body.get_child(0).duplicate()
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
	self.queue_free()
	map_node.clearSnake()

# при попадании головы во что-то
func _in_mouth_body_entered(body):
	if body.is_in_group("Food"):
		body.queue_free()
		if !$EatSound.playing and !ai_control:
			$EatSound.play()
		if !randi_range(0,2):
			bodyGrow()
		map_node.genFood()
	if body.is_in_group("Snake") and body.get_node("../../..") != self:
		kill_snake()

var aiTimer = 0.0
var ai_direction = Vector2(0,0)
@onready var headOutPos = null
var firstPartInside = 0
func get_ai_direction(delta):
	aiTimer += delta
	if aiTimer >= 0.5:
		if !aiSpeed:
			aiSpeed = randi_range(0,10)
			if aiSpeed:
				aiSpeed = 3
		else:
			aiSpeed -= 1
		aiTimer = 0.0
		create_ai_direction()
	return ai_direction

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
func debuff_out_territory(delta):
	if debuff_timer > 0.5:
		debuff_timer = 0.0
		if $Body.get_child_count() < 2:
			if !ai_control:
				G.alive = false
			queue_free()
		loseGrowth()
		#print_rich("losing grow")
	debuff_timer += delta
