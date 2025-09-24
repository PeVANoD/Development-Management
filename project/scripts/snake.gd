extends Node2D

#region переменные межфункций
var isRotating
var direction = Vector2(0,-1)
var desiredDirection = Vector2(0,-1)
var lastPos = Vector2(0,1)
var lastAngle = 1.0
var lastBodyAngle = 1.0
@onready var startSpeed = speed
@onready var maxSpeed = speed*1.5
var positionHistory = []
var maxHistoryLength = 4
var addLength = 6
var time_since_last_growth: float = 0.0
var is_controlled: bool = false  # Управляется ли эта змейка
#endregion

#region переменные персонажа
@export var speed = 130.0
@export var partDistance = 6
#endregion

# Территории
var territory_capture: TerritoryCapture
var snake_index: int = 0  # Индекс этой змейки
var was_in_territory: bool = false

func _ready():
	for i in range(maxHistoryLength):
		positionHistory.push_front($Head.global_position)
	bodyGrow(50)

func _physics_process(delta):
	if !territory_capture or !is_controlled:
		$Head/Camera2D.enabled = false
		return
	$Head/Camera2D.enabled = true
	checkInputs(delta)
	positionHistory.push_front($Head.global_position)
	
	if positionHistory.size() > maxHistoryLength:
		positionHistory.resize(maxHistoryLength)
	
	if isRotating:
		desiredDirection = (get_global_mouse_position() - $Head.global_position).normalized()
	
	countAngle()
	$Head.position += direction * delta * speed
	
	var angle = lerp_angle(lastAngle, atan2(-direction.y, -direction.x), 0.2)
	lastAngle = angle
	angle = rad_to_deg(angle)
	$Head.rotation_degrees = angle
	
	update_territory_capture()
	checkBody()

func checkInputs(delta):
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		isRotating = true
	else:
		isRotating = false
		
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and $Body.get_child_count() > 2:
		speed = lerp(speed, maxSpeed, 0.1)
		time_since_last_growth += delta
		if time_since_last_growth >= 0.2:
			if !randi_range(0,1):
				loseGrowth()
			time_since_last_growth = 0.0
	else:
		speed = lerp(speed, startSpeed, 0.1)

func update_territory_capture():
	var head_pos = $Head.global_position
	var local_head_pos = territory_capture.to_local(head_pos)
	
	# Проверяем, находится ли голова на территории этой змейки
	var head_in_own_territory = territory_capture.is_point_in_territory(local_head_pos, snake_index)
	
	# Проверяем, находится ли хвост на территории этой змейки
	var tail_in_own_territory = false
	for i in range($Body.get_child_count()-1, -1, -1):
		var tail_pos = $Body.get_child(i).global_position
		var local_tail_pos = territory_capture.to_local(tail_pos)
		tail_in_own_territory = territory_capture.is_point_in_territory(local_tail_pos, snake_index)
		if tail_in_own_territory:
			break
	
	if not head_in_own_territory and tail_in_own_territory and not was_in_territory:
		# Начинаем захват
		territory_capture.start_external_capture(snake_index, local_head_pos - direction.normalized()*16)
		territory_capture.start_external_capture(snake_index, local_head_pos - direction.normalized()*4)
		was_in_territory = true
	
	if was_in_territory and tail_in_own_territory:
		# Продолжаем захват
		territory_capture.update_external_capture(local_head_pos + direction.normalized()*4)
		territory_capture.update_external_capture(local_head_pos + direction.normalized()*16)
		
		if head_in_own_territory:
			# Завершаем захват
			territory_capture.finish_external_capture()
			was_in_territory = false
	
	if was_in_territory and not tail_in_own_territory:
		# Прерываем захват
		territory_capture.is_capturing = false
		territory_capture.finish_external_capture()
		was_in_territory = false

func loseGrowth():
	$"../..".genFood(1,$Body.get_child(0).global_position)
	$Body.get_child(0).queue_free()
	maxHistoryLength -= addLength
	changeBody()

func changeBody():
	var length = $Body.get_child_count()
	var scaling = max(pow(length,0.02),1.0)
	scale = Vector2(scaling,scaling)

func bodyGrow(amount = 1):
	for i in range(amount):
		var newPart = $Body.get_child(0).duplicate()
		maxHistoryLength += addLength
		$Body.call_deferred("add_child", newPart)
		$Body.call_deferred("move_child", newPart,0)
		
		
		
		# Добавляем больше точек в историю при создании новой части
		for j in range(addLength):
			positionHistory.push_back(positionHistory[-1] if positionHistory.size() > 0 else $Head.global_position)
	changeBody()

func checkBody():
	var parts = $Body.get_children()
	if parts.size() == 0:
		return
	for i in range(parts.size() - 1, -1, -1):
		var targetIndex = i * partDistance
		if targetIndex < positionHistory.size():
			# Плавное перемещение
			parts[i].global_position = lerp(parts[i].global_position, positionHistory[positionHistory.size()-1-targetIndex], 0.3)
			
			# Определяем направление для поворота
			var targetPos
			if i == parts.size()-1:
				targetPos = $Head.global_position
			else:
				# Остальные части смотрят на предыдущую часть (ближе к голове)
				targetPos = parts[i+1].global_position
			
			var dir = (targetPos - parts[i].global_position).normalized()
			var targetAngle = atan2(dir.y, dir.x)
			parts[i].rotation = lerp_angle(parts[i].rotation, targetAngle, 0.8)

func countAngle():
	var max_rotation_speed = 0.04
	var angle_diff = direction.angle_to(desiredDirection)
	angle_diff = clamp(angle_diff, -max_rotation_speed, max_rotation_speed)
	direction = direction.rotated(angle_diff)

func _in_mouth_body_entered(body):
	if body.is_in_group("Food"):
		body.queue_free()
		if !randi_range(0,2):
			bodyGrow()
		$"../..".genFood()
	if body.is_in_group("Snake") and body.get_node("../../..") != self:
		territory_capture.clear_territory($"../..".snakeArr.size()-1)
		$"../..".clearSnake()
		self.queue_free()
