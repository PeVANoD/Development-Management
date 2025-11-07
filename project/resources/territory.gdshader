shader_type canvas_item;

// Параметры эффектов
uniform float pattern_scale = 8.0;
uniform float noise_scale = 4.0;
uniform float animation_speed = 0.4;
uniform float pattern_intensity = 0.8;
uniform float noise_intensity = 0.8;
uniform float scanline_speed = 3.0;
uniform float scanline_intensity = 0.3;

// Параметры для обработки краев
uniform float edge_fade_distance : hint_range(0.0, 0.5) = 0.3;
uniform float edge_darkness : hint_range(0.0, 1.0) = 0.4;

// Генерируем процедурный шум
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// Функция для расчета затемнения краев
float calculate_edge_darkness(vec2 uv, float fade_dist) {
    vec2 dist_to_edge = min(uv, vec2(1.0) - uv) / fade_dist;
    float edge_factor = min(dist_to_edge.x, dist_to_edge.y);
    return clamp(1.0 - edge_factor, 0.0, 1.0);
}

// Все функции паттернов остаются без изменений...
float circles_pattern(vec2 uv, float scale) {
    uv *= scale;
    vec2 grid = fract(uv) - 0.5;
    float radius = 0.4;
    return 1.0 - smoothstep(radius - 0.15, radius + 0.15, length(grid));
}

float hexagons_pattern(vec2 uv, float scale) {
    uv *= scale;
    vec2 grid = vec2(uv.x * 1.2, uv.y + uv.x * 0.6);
    grid = fract(grid) - 0.5;
    float hex = max(abs(grid.x), abs(grid.y * 0.866 + grid.x * 0.5));
    return 1.0 - smoothstep(0.3, 0.32, hex);
}

float waves_pattern(vec2 uv, float scale) {
    uv *= scale;
    return sin(uv.x * 3.1416 + TIME * 1.0) * 0.5 + 0.5;
}

float voronoi_pattern(vec2 uv, float scale) {
    uv *= scale;
    vec2 i_uv = floor(uv);
    vec2 f_uv = fract(uv);
    
    float min_dist = 1.0;
    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            vec2 neighbor = vec2(float(x), float(y));
            vec2 point = vec2(hash(i_uv + neighbor)) * 0.5 + 0.25;
            float dist = length(neighbor + point - f_uv);
            min_dist = min(min_dist, dist);
        }
    }
    return min_dist * 1.5;
}

float large_dots_pattern(vec2 uv, float scale) {
    uv *= scale * 0.7;
    vec2 grid = fract(uv) - 0.5;
    float radius = 0.45;
    return 1.0 - smoothstep(radius - 0.2, radius + 0.2, length(grid));
}

float stripes_pattern(vec2 uv, float scale) {
    uv *= scale;
    return abs(sin(uv.x * 6.2831 * 0.5)) > 0.7 ? 1.0 : 0.0;
}

float checkerboard_pattern(vec2 uv, float scale) {
    uv *= scale;
    vec2 grid = floor(uv * 2.0);
    return mod(grid.x + grid.y, 2.0);
}

float diamonds_pattern(vec2 uv, float scale) {
    uv *= scale;
    vec2 grid = fract(uv) - 0.5;
    float diamond = abs(grid.x) + abs(grid.y);
    return 1.0 - smoothstep(0.4, 0.45, diamond);
}

float spiral_pattern(vec2 uv, float scale) {
    uv = (uv - 0.5) * scale;
    float angle = atan(uv.y, uv.x);
    float radius = length(uv);
    return sin(radius * 10.0 - angle * 3.0 + TIME) * 0.5 + 0.5;
}

float organic_cells_pattern(vec2 uv, float scale) {
    uv *= scale * 0.8;
    float n = noise(uv * 2.0 + TIME * 0.1);
    n += noise(uv * 4.0 - TIME * 0.05) * 0.5;
    return n;
}

float plasma_pattern(vec2 uv, float scale) {
    uv *= scale;
    float value = sin(uv.x * 4.0 + TIME);
    value += sin(uv.y * 6.0 + TIME * 1.3);
    value += sin((uv.x + uv.y) * 5.0 + TIME * 0.7);
    return value * 0.3 + 0.5;
}

float circuit_pattern(vec2 uv, float scale) {
    uv *= scale;
    vec2 grid = floor(uv * 3.0);
    float hash_val = hash(grid);
    float lines = sin(uv.x * 20.0 * hash_val) * sin(uv.y * 20.0 * (1.0 - hash_val));
    return abs(lines) > 0.8 ? 1.0 : 0.0;
}

float crystal_pattern(vec2 uv, float scale) {
    uv *= scale;
    float angle = atan(uv.y, uv.x);
    float radius = length(uv);
    float crystals = sin(radius * 8.0 + angle * 6.0);
    crystals += sin(radius * 12.0 - angle * 4.0 + TIME) * 0.5;
    return crystals * 0.3 + 0.5;
}

float maze_pattern(vec2 uv, float scale) {
    uv *= scale * 2.0;
    vec2 grid = floor(uv);
    float hash_val = hash(grid);
    float walls = sin(uv.x * 30.0 * hash_val) * cos(uv.y * 30.0 * (1.0 - hash_val));
    return abs(walls) > 0.9 ? 1.0 : 0.0;
}

float bubbles_pattern(vec2 uv, float scale) {
    uv *= scale * 0.6;
    float n = noise(uv * 3.0);
    n = smoothstep(0.3, 0.7, n);
    n -= noise(uv * 8.0) * 0.3;
    return n;
}

float fractal_pattern(vec2 uv, float scale) {
    uv *= scale;
    float value = 0.0;
    float amplitude = 0.5;
    for (int i = 0; i < 3; i++) {
        value += amplitude * noise(uv);
        uv *= 2.0;
        amplitude *= 0.5;
    }
    return value;
}

// Функция для получения паттерна по индексу
float get_pattern_by_index(int index, vec2 uv, float scale) {
    if (index == 0) return large_dots_pattern(uv, scale);
    else if (index == 1) return hexagons_pattern(uv, scale);
    else if (index == 2) return waves_pattern(uv, scale);
    else if (index == 3) return 1.0 - voronoi_pattern(uv, scale);
    else if (index == 4) return stripes_pattern(uv, scale);
    else if (index == 5) return checkerboard_pattern(uv, scale);
    else if (index == 6) return diamonds_pattern(uv, scale);
    else if (index == 7) return spiral_pattern(uv, scale);
    else if (index == 8) return organic_cells_pattern(uv, scale);
    else if (index == 9) return plasma_pattern(uv, scale);
    else if (index == 10) return circuit_pattern(uv, scale);
    else if (index == 11) return crystal_pattern(uv, scale);
    else if (index == 12) return maze_pattern(uv, scale);
    else if (index == 13) return bubbles_pattern(uv, scale);
    else if (index == 14) return fractal_pattern(uv, scale);
    else return circles_pattern(uv, scale);
}

void fragment() {
    vec4 original_color = COLOR;
    
    if (original_color.a < 0.1) {
        COLOR = original_color;
    }
    
    // Используем оригинальные UV координаты
    vec2 world_uv = FRAGCOORD.xy / (100.0 * pattern_scale);
    
    // ОПРЕДЕЛЯЕМ ЭФФЕКТ ИЗ АЛЬФА-КАНАЛА ЦВЕТА
    // Альфа-канал содержит информацию о типе эффекта (0-1, нормализованный)
    float effect_index_normalized = original_color.a;
    int effect_index = int(effect_index_normalized * 15.0); // Денормализуем обратно в 0-15
    
    // Получаем паттерн на основе эффекта
    float pattern_value = get_pattern_by_index(effect_index, world_uv, 1.0);
    
    // Добавляем анимацию к паттерну
    pattern_value += sin(TIME * animation_speed + world_uv.x * 5.0) * 0.1;
    
    // Процедурный шум
    float procedural_noise = noise(world_uv * noise_scale + TIME * 0.1);
    
    // Эффект сканирующих линий
    float scanline = sin(UV.y * 20.0 + TIME * scanline_speed) * 0.5 + 0.5;
    scanline = 1.0 - scanline * scanline_intensity;
    
    // Смешиваем эффекты
    vec3 final_color = original_color.rgb;
    
    // Применяем паттерн - используем оригинальный цвет, но с паттерном
    vec3 pattern_color = mix(final_color, final_color * (1.0 - pattern_value * 0.7), pattern_intensity);
    final_color = mix(final_color, pattern_color, pattern_intensity);
    
    // Добавляем шум
    final_color += (procedural_noise - 0.5) * noise_intensity * 0.3;
    
    // Сканирующие линии
    final_color *= scanline;
    
    // Пульсация в такт
    float pulse = 1.0 + sin(TIME * 2.0) * 0.05;
    final_color *= pulse;
    
    // Затемнение по краям (обводка)
    float edge_darkness_factor = calculate_edge_darkness(UV, edge_fade_distance) * edge_darkness;
    final_color *= (1.0 - edge_darkness_factor);
    
    // Восстанавливаем оригинальную прозрачность (убираем информацию об эффекте)
    float final_alpha = 0.85; // Фиксированная прозрачность для территории
    
    COLOR = vec4(final_color, final_alpha);
}