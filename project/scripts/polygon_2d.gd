extends MeshInstance2D

class_name TerritoryCapture

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

# Настройки
var snake_colors: Array = []  # Цвета для каждой змейки
var line_thickness: float = 1.0
var point_radius: float = 1.0
var min_distance: float = 15.0

# Состояние для КАЖДОЙ змейки
var snake_capture_states: Array = []  # Массив состояний захвата для каждой змейки

var territories: Array = []  # Массив территорий для каждой змейки

func _ready():
	mesh = ArrayMesh.new()
	# Инициализируем массив территорий
	territories = []
	snake_capture_states = []

# Класс для хранения состояния захвата каждой змейки
class SnakeCaptureState:
	var is_capturing: bool = false
	var capture_points: PackedVector2Array = []
	
	func _init():
		is_capturing = false
		capture_points = []

# Создаем начальную территорию для змейки
func create_initial_territory_for_snake(snake_index: int, center: Vector2):
	if snake_index >= colors.size():
		# Если цветов не хватает, генерируем случайный
		var random_color = Color(randf(), randf(), randf())
		snake_colors.append(random_color)
	else:
		snake_colors.append(Color(colors[snake_index]))
	
	# Убедимся, что массивы достаточно большие
	if territories.size() <= snake_index:
		territories.resize(snake_index + 1)
	if snake_capture_states.size() <= snake_index:
		snake_capture_states.resize(snake_index + 1)
		snake_capture_states[snake_index] = SnakeCaptureState.new()
	
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
	if state.capture_points.size() % 3 == 0:  # был каждый раз
		#queue_redraw()
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
	
	
	# Замыкаем путь если нужно
	var first_point = state.capture_points[0]
	var last_point = state.capture_points[-1]
	
	if first_point.distance_to(last_point) > min_distance:
		state.capture_points.append(first_point)
	
	process_capture(snake_index, state.capture_points)
	state.is_capturing = false
	#queue_redraw()

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

func process_capture(snake_index: int, capture_points: PackedVector2Array):
	if capture_points.size() < 3:
		return
	
	# Проверяем замкнутость полигона
	var first_point = capture_points[0]
	var last_point = capture_points[-1]
	
	if first_point.distance_to(last_point) > min_distance * 2:
		# Автоматически замыкаем если точки близки
		if first_point.distance_to(last_point) < min_distance * 3:
			capture_points.append(first_point)
		else:
			return
	
	var capture_polygon = simplify_polygon(capture_points)
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
		else:
			pass
			#print("Объединение не удалось")
	
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

func combine_polygons(polygons: Array) -> PackedVector2Array:
	# Объединяем все полигоны в один (простая реализация)
	if polygons.size() == 1:
		return polygons[0]
	
	# Для сложных случаев - возвращаем самый большой или объединяем
	var largest = get_largest_polygon(polygons)
	# TODO: Реализовать proper union всех полигонов
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
	
	# Убеждаемся, что полигон замкнут
	if simplified.size() >= 3 and simplified[0].distance_to(simplified[-1]) > min_distance:
		simplified.append(simplified[0])
	
	return simplified

func update_territory_mesh():
	mesh.clear_surfaces()
	
	var all_vertices := PackedVector2Array()
	var all_colors := PackedColorArray()
	var all_indices := PackedInt32Array()
	
	for i in range(territories.size()):
		if i < snake_colors.size() and territories[i].size() >= 3:
			# ОПТИМИЗАЦИЯ: пропускаем триангуляцию для очень маленьких территорий
			if calculate_polygon_area(territories[i]) < 10.0:
				continue
				
			var indices = Geometry2D.triangulate_polygon(territories[i])
			if indices.size() >= 3 and indices.size() % 3 == 0:
				var start_index = all_vertices.size()
				all_vertices.append_array(territories[i])
				
				for j in range(territories[i].size()):
					all_colors.append(snake_colors[i])
				
				for index in indices:
					if start_index + index < all_vertices.size():
						all_indices.append(start_index + index)
	
	if all_vertices.size() > 0 and all_indices.size() > 0:
		var arrays = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = all_vertices
		arrays[Mesh.ARRAY_COLOR] = all_colors  
		arrays[Mesh.ARRAY_INDEX] = all_indices
		
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

func clear_territories():
	territories.clear()
	snake_colors.clear()
	snake_capture_states.clear()
	update_territory_mesh()
	queue_redraw()

func clear_territory(snake_index):
	if snake_index < territories.size():
		territories[snake_index].clear()
	if snake_index < snake_capture_states.size():
		snake_capture_states[snake_index] = null
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
	# Проверяем валидность индексов
	if from_snake_index >= territories.size() or to_snake_index >= territories.size():
		print("Ошибка: неверные индексы змеек ", from_snake_index, " -> ", to_snake_index)
		return
	if from_snake_index < 0 or to_snake_index < 0:
		print("Ошибка: отрицательные индексы змеек ", from_snake_index, " -> ", to_snake_index)
		return
	if territories[from_snake_index].is_empty():
		print("Предупреждение: у убитой змейки ", from_snake_index, " нет территории")
		return
	
	print("Передача территории: змейка ", from_snake_index, " (площадь: ", get_territory_area(from_snake_index), ") -> змейка ", to_snake_index, " (площадь: ", get_territory_area(to_snake_index), ")")
		
	# Сохраняем исходную территорию получателя
	var receiver_territory = territories[to_snake_index].duplicate()
	var victim_territory = territories[from_snake_index].duplicate()
	
	# Объединяем территории
	if receiver_territory.is_empty():
		# Если у получателя нет территории, просто передаем всю территорию жертвы
		territories[to_snake_index] = victim_territory
	else:
		# Объединяем обе территории
		var union_result = Geometry2D.merge_polygons(receiver_territory, victim_territory)
		if not union_result.is_empty():
			territories[to_snake_index] = combine_polygons(union_result)
		else:
			# Если объединение не удалось, просто добавляем территорию жертвы
			print("Объединение территорий не удалось, добавляем территорию жертвы")
			territories[to_snake_index] = victim_territory
	
	# Очищаем территорию убитой змейки
	territories[from_snake_index].clear()
	if from_snake_index < snake_capture_states.size():
		snake_capture_states[from_snake_index] = null
	
	# Обновляем визуализацию
	update_territory_mesh()
	queue_redraw()
	
	print("Территория передана от змейки ", from_snake_index, " к змейке ", to_snake_index)
	print("Новая площадь территории получателя: ", get_territory_area(to_snake_index))
