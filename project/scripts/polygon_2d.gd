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
var line_thickness: float = 3.0
var point_radius: float = 4.0
var min_distance: float = 15.0

# Состояние
var is_capturing: bool = false
var capturing_snake_index: int = -1  # Индекс змейки, которая захватывает
var capture_points: PackedVector2Array = []
var territories: Array = []  # Массив территорий для каждой змейки

func _ready():
	mesh = ArrayMesh.new()
	# Инициализируем массив территорий
	territories = []

# Создаем начальную территорию для змейки
func create_initial_territory_for_snake(snake_index: int, center: Vector2):
	if snake_index >= colors.size():
		# Если цветов не хватает, генерируем случайный
		var random_color = Color(randf(), randf(), randf())
		snake_colors.append(random_color)
	else:
		snake_colors.append(Color(colors[snake_index]))
	
	# Убедимся, что массив территорий достаточно большой
	if territories.size() <= snake_index:
		territories.resize(snake_index + 1)
	
	# Создаем начальную территорию вокруг позиции змейки
	territories[snake_index] = generate_initial_territory(center, Vector2(80, 80))
	update_territory_mesh()

func generate_initial_territory(center: Vector2, size: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	
	# Создаем квадратную территорию
	points.append(center + Vector2(-size.x, -size.y))
	points.append(center + Vector2(size.x, -size.y))
	points.append(center + Vector2(size.x, size.y))
	points.append(center + Vector2(-size.x, size.y))
	
	return points

# Внешний метод для начала захвата
func start_external_capture(snake_index: int, start_point: Vector2):
	if is_capturing:
		return
	
	is_capturing = true
	capturing_snake_index = snake_index
	capture_points.clear()
	capture_points.append(start_point)

# Внешний метод для обновления захвата
func update_external_capture(new_point: Vector2):
	if not is_capturing or capture_points.is_empty():
		return
	
	var last_point = capture_points[-1]
	if last_point.distance_to(new_point) > min_distance:
		capture_points.append(new_point)
	
	queue_redraw()

# Внешний метод для завершения захвата
func finish_external_capture():
	if not is_capturing or capture_points.size() < 3:
		is_capturing = false
		return
	
	# Замыкаем путь если нужно
	if capture_points[0].distance_to(capture_points[-1]) > min_distance:
		capture_points.append(capture_points[0])
	
	# Обрабатываем захват для выбранной змейки
	process_capture()
	
	is_capturing = false
	queue_redraw()

func process_capture():
	if capture_points.size() < 3:
		return
	
	# Если путь не замкнут, не обрабатываем
	if capture_points[0].distance_to(capture_points[-1]) > min_distance:
		return
	
	# Создаем полигон из точек захвата
	var capture_polygon = simplify_polygon(capture_points)
	
	# Объединяем с территорией захватывающей змейки
	if territories.size() <= capturing_snake_index:
		territories.resize(capturing_snake_index + 1)
	
	if territories[capturing_snake_index].is_empty():
		territories[capturing_snake_index] = capture_polygon
	else:
		var union_result = Geometry2D.merge_polygons(territories[capturing_snake_index], capture_polygon)
		if not union_result.is_empty():
			territories[capturing_snake_index] = get_largest_polygon(union_result)
	
	# Вычитаем из территорий других змеек
	for i in range(territories.size()):
		if i != capturing_snake_index and not territories[i].is_empty():
			var clip_result = Geometry2D.clip_polygons(territories[i], capture_polygon)
			if not clip_result.is_empty():
				territories[i] = get_largest_polygon(clip_result)
	
	update_territory_mesh()

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
	
	# Создаем общий массив вершин для всех территорий
	var all_vertices := PackedVector2Array()
	var all_colors := PackedColorArray()
	var all_indices := PackedInt32Array()
	
	# Добавляем территории всех змеек
	for i in range(territories.size()):
		if territories[i].size() >= 3 and i < snake_colors.size():
			var indices = Geometry2D.triangulate_polygon(territories[i])
			if not indices.is_empty():
				var start_index = all_vertices.size()
				all_vertices.append_array(territories[i])
				
				for j in range(territories[i].size()):
					all_colors.append(snake_colors[i])
				
				for index in indices:
					all_indices.append(start_index + index)
	
	# Создаем меш только если есть что отображать
	if all_vertices.size() > 0 and all_indices.size() > 0:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = all_vertices
		arrays[Mesh.ARRAY_COLOR] = all_colors
		arrays[Mesh.ARRAY_INDEX] = all_indices
		
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

func clear_territories():
	territories.clear()
	snake_colors.clear()
	update_territory_mesh()
	queue_redraw()

func clear_territory(snake_index):
	territories[snake_index].clear()
	update_territory_mesh()
	queue_redraw()

func _draw():
	# Рисуем территории всех змеек
	for i in range(territories.size()):
		if territories[i].size() > 1 and i < snake_colors.size():
			draw_polyline(territories[i], snake_colors[i], line_thickness)
			for point in territories[i]:
				draw_circle(point, point_radius, snake_colors[i].darkened(0.3))
	
	# Рисуем текущий след захвата
	if is_capturing and capture_points.size() > 1 and capturing_snake_index < snake_colors.size():
		var draw_color = snake_colors[capturing_snake_index]
		draw_polyline(capture_points, draw_color, line_thickness)
		
		for point in capture_points:
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
