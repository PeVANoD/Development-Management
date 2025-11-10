extends Control

# Данные туториала - 8 слайдов
var tutorial_data = [
	{
		"title": "Добро пожаловать в Snake.io!",
		"description": "Это игра про управление змейкой на общей карте.\n\nТы начинаешь с маленькой змейки и должен расти, захватывать территорию и побеждать других игроков!",
		"image": "res://project/images/tutorial_screenshots/slide_1_start.png"
	},
	{
		"title": "Управление змейкой",
		"description": "Используйте ЛКМ для управления движением своей змейки.\n\nТвоя змейка всегда движется, ты можешь менять направление в любой момент.",
		"image": "res://project/images/tutorial_screenshots/slide_2_move.png"
	},
	{
		"title": "Границы карты",
		"description": "Ты не можешь выйти за края карты - они блокируют твой проход.\n\nИспользуй границы как стратегическое преимущество!",
		"image": "res://project/images/tutorial_screenshots/slide_3_dangers.png"
	},
	{
		"title": "Собирай очки на карте",
		"description": "На карте лежат яркие точки - это еда/очки.\n\nСобирай их головой, чтобы расти и получать очки. Каждая съеденная точка добавляет 1 сегмент к твоей змейке!",
		"image": "res://project/images/tutorial_screenshots/slide_4_collect_points.png"
	},
	{
		"title": "Рост змейки от еды",
		"description": "Каждый собранный очко удлиняет твою змейку на 1 сегмент.\n\nСъел 5 точек = твоя змейка стала на 5 сегментов длиннее! Чем больше змейка - тем сильнее ты!",
		"image": "res://project/images/tutorial_screenshots/slide_5_growth.png"
	},
	{
		"title": "Захват территории",
		"description": "Когда ты замыкаешь ЗАМКНУТУЮ ЛИНИЮ из своего тела на уже СВОЕЙ территории - вся пустая площадь внутри этой линии становится ТВОЕЙ!\n\nБольшая территория = больше очков за каждую секунду пребывания в ней!",
		"image": "res://project/images/tutorial_screenshots/slide_6_territory.png"
	},
	{
		"title": "Опасность вне своей территории",
		"description": "Если твоя змейка выходит за пределы СВОЕЙ территории (на БЕЛУЮ зону), она начинает ТЕРЯТЬ очки!\n\nЕсли полностью покидаешь территорию или теряешь все очки вне неё - ты погибнешь! Срочно вернись на свою территорию!",
		"image": "res://project/images/tutorial_screenshots/slide_7_losts.png"
	},
	{
		"title": "Сражение с врагами",
		"description": "Если голова ДРУГОЙ змейки коснётся любой части ТВОЕГО тела (включая хвост) - эта змейка умрёт!\n\nНо помни: если ТВОЯ голова коснётся ИХ тела - умрёшь ТЫ! Используй свою длину как защиту!",
		"image": "res://project/images/tutorial_screenshots/slide_8_enemies.png"
	}
]

# Ссылки на UI элементы - ПРАВИЛЬНЫЕ ПУТИ
@onready var title_label = $DialogPanel/VBoxContainer/TitleLabel
@onready var description_label = $DialogPanel/VBoxContainer/DescriptionLabel
@onready var image_rect = $DialogPanel/VBoxContainer/TutorialImage
@onready var page_indicator = $DialogPanel/VBoxContainer/PageIndicator
@onready var prev_btn = $DialogPanel/VBoxContainer/ButtonContainer/PrevButton
@onready var skip_btn = $DialogPanel/VBoxContainer/ButtonContainer/SkipButton
@onready var next_btn = $DialogPanel/VBoxContainer/ButtonContainer/NextButton

@onready var button_sound = $ButtonSound

var current_page = 0

func _ready():
	
	# Обновление первой страницы
	_update_page()

func play_button_sound():
	"""Воспроизводит звук кнопки"""
	if button_sound:
		button_sound.play()
	else:
		print("⚠️ Звук не воспроизведен - ButtonSound не найден")

func _update_page():
	"""Обновляет содержимое текущей страницы"""
	var page = tutorial_data[current_page]
	
	# Обновляем текст
	if title_label:
		title_label.text = page.title
	if description_label:
		description_label.text = page.description
	
	# Загружаем изображение с отладкой
	if image_rect and page.has("image") and page.image:
		var image = load(page.image)
		if image:
			image_rect.texture = image
			image_rect.visible = true
		else:
			image_rect.visible = false
	else:
		if image_rect:
			image_rect.visible = false
	
	# Обновляем индикатор страницы
	if page_indicator:
		page_indicator.text = "Слайд %d из %d" % [current_page + 1, tutorial_data.size()]
	
	# Обновляем доступность кнопок
	if prev_btn:
		prev_btn.disabled = (current_page == 0)
	if next_btn:
		next_btn.disabled = (current_page == tutorial_data.size() - 1)
	
	# Изменяем текст последней кнопки
	if next_btn:
		if current_page == tutorial_data.size() - 1:
			next_btn.text = "Закрыть"
		else:
			next_btn.text = "Далее →"

func _on_prev_button_pressed() -> void:
	"""Переход на предыдущую страницу"""
	play_button_sound()
	if current_page > 0:
		current_page -= 1
		_update_page()

func _on_skip_button_pressed() -> void:
	"""Пропустить туториал и закрыть окно"""
	play_button_sound()
	_close_tutorial()

func _on_next_button_pressed() -> void:
	"""Переход на следующую страницу или закрытие"""
	play_button_sound()
	if current_page < tutorial_data.size() - 1:
		current_page += 1
		_update_page()
	else:
		_close_tutorial()

func _close_tutorial():
	"""Просто закрывает окно туториала"""
	queue_free()
