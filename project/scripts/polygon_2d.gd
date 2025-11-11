extends MeshInstance2D

class_name TerritoryCapture

# Настройки
var snake_colors: Array = []  # Цвета для каждой змейки
var line_thickness: float = 0.0
var point_radius: float = 1.0
var min_distance: float = 15.0

# Состояние для КАЖДОЙ змейки
var snake_capture_states: Array = []  # Массив состояний захвата для каждой змейки

var territories: Array = []  # Массив территорий для каждой змейки

# Шейдер и текстуры
const TERRITORY_SHADER = preload("res://project/resources/territory.gdshader")
@export var pattern_texture: Texture2D
@export var noise_texture: Texture2D

# Новые переменные для поддержки разных шейдеров
var territory_effect_types: Array = []  # Массив типов эффектов для каждой змейки
var territory_meshes: Array = []  # Массив отдельных мешей для каждой змейки

func _ready():
	mesh = ArrayMesh.new()
	z_index = -4095
	
	# Инициализируем шейдерный материал
	_setup_territory_material()
	
	# Инициализируем массив территорий
	territories = []
	snake_capture_states = []
	territory_effect_types = []
	territory_meshes = []

func _setup_territory_material():
	var shader_material = ShaderMaterial.new()
	shader_material.shader = TERRITORY_SHADER
	
	# Устанавливаем текстуры если они заданы
	if pattern_texture:
		shader_material.set_shader_parameter("texture_pattern", pattern_texture)
	if noise_texture:
		shader_material.set_shader_parameter("noise_texture", noise_texture)
	
	# Устанавливаем параметры шейдера
	shader_material.set_shader_parameter("pattern_scale", 0.5)
	shader_material.set_shader_parameter("noise_scale", 30.0)
	shader_material.set_shader_parameter("animation_speed", 0.1)
	shader_material.set_shader_parameter("pattern_intensity", 0.8)
	shader_material.set_shader_parameter("noise_intensity", 0.35)
	shader_material.set_shader_parameter("scanline_speed",0.5)
	shader_material.set_shader_parameter("scanline_intensity", 0.5)
	shader_material.set_shader_parameter("edge_fade_distance",0.3)
	shader_material.set_shader_parameter("edge_darkness", 0.4)
	
	material = shader_material

# Класс для хранения состояния захвата каждой змейки
class SnakeCaptureState:
	var is_capturing: bool = false
	var capture_points: PackedVector2Array = []
	
	func _init():
		is_capturing = false
		capture_points = []

# Создаем начальную территорию для змейки
func create_initial_territory_for_snake(snake_index: int, center: Vector2, initial_effect_type: int = -1):
	if snake_index >= G.colors.size():
		# Если цветов не хватает, генерируем случайный
		var random_color = Color(randf(), randf(), randf())
		snake_colors.append(random_color)
	else:
		snake_colors.append(Color(G.colors[snake_index]))
	
	# Убедимся, что массивы достаточно большие
	if territories.size() <= snake_index:
		territories.resize(snake_index + 1)
	if snake_capture_states.size() <= snake_index:
		snake_capture_states.resize(snake_index + 1)
		snake_capture_states[snake_index] = SnakeCaptureState.new()
	if territory_effect_types.size() <= snake_index:
		territory_effect_types.resize(snake_index + 1)
		# Устанавливаем случайный эффект если не указан
		if initial_effect_type == -1:
			territory_effect_types[snake_index] = randi() % 16
		else:
			territory_effect_types[snake_index] = initial_effect_type
	
	# Создаем начальную территорию вокруг позиции змейки
	territories[snake_index] = generate_initial_territory(center, 100)
	update_territory_mesh()

func generate_initial_territory(center: Vector2, radius: float, segments: int = 32) -> PackedVector2Array:
	var points := PackedVector2Array()
	
	# Создаем круглую территорию
	for i in range(segments):
		var angle = 2 * PI * i / segments
		var point = center + Vector2(cos(angle), sin(angle)) * radius
		points.append(point)
	
	return points

# Внешний метод для начала захвата
func start_external_capture(snake_index: int, start_point: Vector2):
	# Убедимся, что состояние для этой змейки существует
	if snake_capture_states.size() <= snake_index:
		snake_capture_states.resize(snake_index + 1)
	if snake_capture_states[snake_index] == null:
		snake_capture_states[snake_index] = SnakeCaptureState.new()
	
	var state = snake_capture_states[snake_index]
	if state.is_capturing:
		return
	
	state.is_capturing = true
	state.capture_points.clear()
	state.capture_points.append(start_point)

# Внешний метод для обновления захвата
func update_external_capture(snake_index: int, new_point: Vector2):
	# Проверяем валидность индекса и состояния
	if snake_index >= snake_capture_states.size() or snake_capture_states[snake_index] == null:
		return
	
	var state = snake_capture_states[snake_index]
	if not state.is_capturing or state.capture_points.is_empty():
		return
	
	var last_point = state.capture_points[-1]
	if last_point.distance_to(new_point) > min_distance:
		state.capture_points.append(new_point)
	
	# ОПТИМИЗАЦИЯ: перерисовываем только при значительных изменениях
	if state.capture_points.size() % 3 == 0:
		pass

# Внешний метод для завершения захвата
func finish_external_capture(snake_index: int):
	if snake_index >= snake_capture_states.size() or snake_capture_states[snake_index] == null:
		return
	
	var state = snake_capture_states[snake_index]
	if not state.is_capturing:
		return
	
	if state.capture_points.size() < 3:
		state.is_capturing = false
		return
	
	# Замыкаем путь всегда, чтобы создать замкнутый полигон
	var first_point = state.capture_points[0]
	var last_point = state.capture_points[-1]
	
	# Всегда замыкаем полигон, даже если точки близко
	if first_point != last_point:
		state.capture_points.append(first_point)
	
	process_capture(snake_index, state.capture_points)
	state.is_capturing = false

# Останавливаем захват без обработки
func cancel_external_capture(snake_index: int):
	if snake_index < snake_capture_states.size() and snake_capture_states[snake_index] != null:
		snake_capture_states[snake_index].is_capturing = false
		snake_capture_states[snake_index].capture_points.clear()

func global_to_territory_local(point: Vector2) -> Vector2:
	return to_local(point)

func is_point_in_territory_global(point: Vector2, snake_index: int) -> bool:
	var local_point = global_to_territory_local(point)
	return is_point_in_territory(local_point, snake_index)

# Основная функция обработки захвата
func process_capture(snake_index: int, capture_points: PackedVector2Array):
	if capture_points.size() < 3:
		return
	
	# Проверяем замкнутость полигона
	var first_point = capture_points[0]
	var last_point = capture_points[-1]
	
	# Всегда замыкаем полигон если он не замкнут
	if first_point != last_point:
		capture_points.append(first_point)
	
	# Используем улучшенную обработку полигона
	var capture_polygon = create_polygon_from_path(capture_points)
	if capture_polygon.size() < 3:
		return
	
	# Расширяем массив территорий если нужно
	while territories.size() <= snake_index:
		territories.append(PackedVector2Array())
	
	# Объединяем с существующей территорией
	if territories[snake_index].is_empty():
		territories[snake_index] = capture_polygon
	else:
		var union_result = Geometry2D.merge_polygons(
			territories[snake_index], 
			capture_polygon
		)
		if not union_result.is_empty():
			territories[snake_index] = combine_polygons(union_result)
	
	# Вычитаем у других змеек
	for i in range(territories.size()):
		if i != snake_index and not territories[i].is_empty():
			var clip_result = Geometry2D.clip_polygons(territories[i], capture_polygon)
			if not clip_result.is_empty():
				territories[i] = combine_polygons(clip_result)
			else:
				territories[i] = PackedVector2Array()
	
	update_territory_mesh()
	queue_redraw()

func create_polygon_from_path(path_points: PackedVector2Array) -> PackedVector2Array:
	if path_points.size() < 3:
		return PackedVector2Array()
	
	# Проверяем, является ли полигон самопересекающимся
	# Используем offset_polygon для создания несамопересекающегося полигона
	var offset_result = Geometry2D.offset_polygon(path_points, 0.0)
	
	if not offset_result.is_empty():
		# Берем первый (внешний) контур
		return offset_result[0]
	else:
		# Если offset не сработал, пробуем триангуляцию
		var indices = Geometry2D.triangulate_polygon(path_points)
		if not indices.is_empty() and indices.size() >= 3:
			# Если триангуляция успешна, используем исходные точки
			return path_points
	
	# Если все методы не сработали, возвращаем упрощенный полигон
	return simplify_polygon(path_points)

func combine_polygons(polygons: Array) -> PackedVector2Array:
	if polygons.size() == 1:
		return polygons[0]
	var largest = get_largest_polygon(polygons)
	return largest

func get_largest_polygon(polygons: Array) -> PackedVector2Array:
	var largest_area = -1.0
	var largest_polygon = PackedVector2Array()
	
	for polygon in polygons:
		var area = calculate_polygon_area(polygon)
		if area > largest_area:
			largest_area = area
			largest_polygon = polygon
	
	return largest_polygon

func calculate_polygon_area(points: PackedVector2Array) -> float:
	var area = 0.0
	var j = points.size() - 1
	
	for i in range(points.size()):
		area += (points[j].x + points[i].x) * (points[j].y - points[i].y)
		j = i
	
	return abs(area / 2.0)

func simplify_polygon(points: PackedVector2Array) -> PackedVector2Array:
	if points.size() < 4:
		return points
	
	var simplified := PackedVector2Array()
	simplified.append(points[0])
	
	for i in range(1, points.size()):
		if simplified[-1].distance_to(points[i]) > min_distance * 0.5:
			simplified.append(points[i])
	
	# Всегда замыкаем полигон
	if simplified.size() >= 3 and simplified[0] != simplified[-1]:
		simplified.append(simplified[0])
	
	return simplified

# Обновленная функция обновления меша - УПРОЩЕННАЯ ВЕРСИЯ
func update_territory_mesh():
	mesh.clear_surfaces()
	
	var all_vertices := PackedVector2Array()
	var all_colors := PackedColorArray()
	var all_indices := PackedInt32Array()
	var all_uvs := PackedVector2Array()
	
	for i in range(territories.size()):
		if i < snake_colors.size() and territories[i].size() >= 3:
			if calculate_polygon_area(territories[i]) < 10.0:
				continue
				
			var indices = Geometry2D.triangulate_polygon(territories[i])
			if indices.size() >= 3 and indices.size() % 3 == 0:
				var start_index = all_vertices.size()
				all_vertices.append_array(territories[i])
				
				# Генерируем UV координаты для текстуры
				var uv_rect = _calculate_uv_rect(territories[i])
				for point in territories[i]:
					var uv = Vector2(
						(point.x - uv_rect.position.x) / uv_rect.size.x,
						(point.y - uv_rect.position.y) / uv_rect.size.y
					)
					all_uvs.append(uv)
				
				# Используем цвет для передачи информации об эффекте через альфа-канал
				var effect_color = snake_colors[i]
				effect_color.a = float(territory_effect_types[i]) / 15.0  # Нормализуем до 0-1
				
				for j in range(territories[i].size()):
					all_colors.append(effect_color)
				
				for index in indices:
					if start_index + index < all_vertices.size():
						all_indices.append(start_index + index)
	
	if all_vertices.size() > 0 and all_indices.size() > 0:
		var arrays = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = all_vertices
		arrays[Mesh.ARRAY_COLOR] = all_colors  
		arrays[Mesh.ARRAY_TEX_UV] = all_uvs
		arrays[Mesh.ARRAY_INDEX] = all_indices
		
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	
	# Обновляем шейдер с информацией о эффектах
	update_shader_effects()

# Функция для обновления параметров шейдера с учетом разных эффектов
func update_shader_effects():
	if material is ShaderMaterial:
		# Собираем все уникальные эффекты
		var unique_effects = []
		for i in range(territory_effect_types.size()):
			if i < territories.size() and not territories[i].is_empty():
				var effect_typeS = territory_effect_types[i]
				if not effect_typeS in unique_effects:
					unique_effects.append(effect_typeS)
		
		# Если нет эффектов, используем один по умолчанию
		if unique_effects.is_empty():
			unique_effects.append(0)
		
		# Создаем массив эффектов для шейдера
		var effect_array = []
		effect_array.resize(16)
		for i in range(16):
			if i < unique_effects.size():
				effect_array[i] = float(unique_effects[i])
			else:
				effect_array[i] = 0.0
		
		material.set_shader_parameter("effect_types", effect_array)
		material.set_shader_parameter("active_effects_count", unique_effects.size())

# Вычисляем UV координаты для полигона
func _calculate_uv_rect(points: PackedVector2Array) -> Rect2:
	if points.is_empty():
		return Rect2()
	
	var min_point = points[0]
	var max_point = points[0]
	
	for point in points:
		min_point.x = min(min_point.x, point.x)
		min_point.y = min(min_point.y, point.y)
		max_point.x = max(max_point.x, point.x)
		max_point.y = max(max_point.y, point.y)
	
	return Rect2(min_point, max_point - min_point)

func clear_territories():
	territories.clear()
	snake_colors.clear()
	snake_capture_states.clear()
	territory_effect_types.clear()
	update_territory_mesh()
	queue_redraw()

func clear_territory(snake_index):
	if snake_index < territories.size():
		territories[snake_index].clear()
	if snake_index < snake_capture_states.size():
		snake_capture_states[snake_index] = null
	if snake_index < territory_effect_types.size():
		territory_effect_types[snake_index] = 0
	update_territory_mesh()
	queue_redraw()

func _draw():
	# Рисуем территории всех змеек
	for i in range(territories.size()):
		if territories[i].size() > 1 and i < snake_colors.size():
			draw_polyline(territories[i], snake_colors[i], line_thickness)
			for point in territories[i]:
				draw_circle(point, point_radius, snake_colors[i].darkened(0.3))
	
	# Рисуем текущие следы захвата для ВСЕХ змеек
	for i in range(snake_capture_states.size()):
		if snake_capture_states[i] != null and snake_capture_states[i].is_capturing and snake_capture_states[i].capture_points.size() > 1 and i < snake_colors.size():
			var draw_color = snake_colors[i]
			draw_polyline(snake_capture_states[i].capture_points, draw_color, line_thickness)
			
			for point in snake_capture_states[i].capture_points:
				draw_circle(point, point_radius, draw_color)

func is_point_in_territory(point: Vector2, snake_index: int) -> bool:
	if snake_index < territories.size():
		return Geometry2D.is_point_in_polygon(point, territories[snake_index])
	return false

# Функции для получения информации о территориях
func get_territory_area(snake_index: int) -> float:
	if snake_index < territories.size():
		return calculate_polygon_area(territories[snake_index])
	return 0.0

func get_total_territory_area() -> float:
	var total = 0.0
	for territory in territories:
		total += calculate_polygon_area(territory)
	return total

# Проверяем, находится ли змейка в процессе захвата
func is_snake_capturing(snake_index: int) -> bool:
	if snake_index < snake_capture_states.size() and snake_capture_states[snake_index] != null:
		return snake_capture_states[snake_index].is_capturing
	return false

# Передача территории от одной змейки к другой
func transfer_territory(from_snake_index: int, to_snake_index: int):
	if from_snake_index >= territories.size() or to_snake_index >= territories.size():
		return
	if from_snake_index < 0 or to_snake_index < 0:
		return
	if territories[from_snake_index].is_empty():
		return
	
	# Сохраняем исходную территорию получателя
	var receiver_territory = territories[to_snake_index].duplicate()
	var victim_territory = territories[from_snake_index].duplicate()
	
	# Объединяем территории
	if receiver_territory.is_empty():
		territories[to_snake_index] = victim_territory
		# Переносим эффект
		if from_snake_index < territory_effect_types.size():
			territory_effect_types[to_snake_index] = territory_effect_types[from_snake_index]
	else:
		var union_result = Geometry2D.merge_polygons(receiver_territory, victim_territory)
		if not union_result.is_empty():
			territories[to_snake_index] = combine_polygons(union_result)
		else:
			territories[to_snake_index] = victim_territory
	
	# Очищаем территорию убитой змейки
	territories[from_snake_index].clear()
	if from_snake_index < snake_capture_states.size():
		snake_capture_states[from_snake_index] = null
	
	# Обновляем визуализацию
	update_territory_mesh()
	queue_redraw()

# НОВЫЕ ФУНКЦИИ ДЛЯ УПРАВЛЕНИЯ ЭФФЕКТАМИ

# Установить эффект для территории змейки
func set_territory_effect(snake_index: int, effect_typeE: int):
	if snake_index < territory_effect_types.size():
		territory_effect_types[snake_index] = effect_typeE
		update_territory_mesh()
		queue_redraw()

# Получить текущий эффект территории змейки
func get_territory_effect(snake_index: int) -> int:
	if snake_index < territory_effect_types.size():
		return territory_effect_types[snake_index]
	return 0

# Установить случайный эффект для территории змейки
func set_random_territory_effect(snake_index: int):
	if snake_index < territory_effect_types.size():
		territory_effect_types[snake_index] = randi() % 16
		update_territory_mesh()
		queue_redraw()

# Циклически переключить эффект территории змейки
func cycle_territory_effect(snake_index: int):
	if snake_index < territory_effect_types.size():
		territory_effect_types[snake_index] = (territory_effect_types[snake_index] + 1) % 16
		update_territory_mesh()
		queue_redraw()
