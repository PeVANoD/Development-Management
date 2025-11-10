shader_type canvas_item;

uniform float dash_length = 10.0;
uniform float gap_length = 5.0;
uniform float outline_width = 2.0;
uniform float dash_speed = 3.0;

void fragment() {
    // Получаем исходный цвет текстуры
    vec4 original_color = texture(TEXTURE, UV);

    // Проверяем пиксели вокруг для определения границы
    float alpha = original_color.a;
    float alpha_up = texture(TEXTURE, UV + vec2(0.0, TEXTURE_PIXEL_SIZE.y)).a;
    float alpha_down = texture(TEXTURE, UV - vec2(0.0, TEXTURE_PIXEL_SIZE.y)).a;
    float alpha_left = texture(TEXTURE, UV + vec2(TEXTURE_PIXEL_SIZE.x, 0.0)).a;
    float alpha_right = texture(TEXTURE, UV - vec2(TEXTURE_PIXEL_SIZE.x, 0.0)).a;

    // Определяем границу (пиксель является границей если он прозрачный, но рядом есть непрозрачный)
    float is_border = 0.0;
    if (alpha < 0.5 && (alpha_up > 0.5 || alpha_down > 0.5 || alpha_left > 0.5 || alpha_right > 0.5)) {
        is_border = 1.0;
    }

    // Альтернативный метод: находим края с помощью производных
    float edge = fwidth(alpha);
    float border_alpha = smoothstep(0.0, edge, alpha);
    float is_border_alt = (1.0 - border_alpha) * step(edge, alpha + 0.1);

    // Создаем пунктирный паттерн вдоль границы
    // Используем UV координаты для создания равномерного паттерна
    float time = TIME * dash_speed;
    vec2 screen_uv = FRAGCOORD.xy ;
    float angle = atan(screen_uv.y - 0.5, screen_uv.x - 0.5);
    float circumference = length(screen_uv - 0.5);

    // Создаем паттерн на основе угла и времени для анимированного пунктира
    float pattern_pos = (angle / (2.0 * 3.14159) + time) * (dash_length + gap_length);
    float pattern = mod(pattern_pos, 1.0);
    float is_dash = step(pattern, dash_length / (dash_length + gap_length));

    // Комбинируем границу с пунктирным паттерном
    float final_outline = is_border * is_dash;

    // Прозрачный спрайт с белой пунктирной обводкой по границе
    COLOR = vec4(1.0, 1.0, 1.0, final_outline);
}