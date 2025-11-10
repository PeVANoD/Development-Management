shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform float outline_width : hint_range(1, 10) = 2.0;

void fragment() {
    // Текущий пиксель
    vec4 current = texture(TEXTURE, UV);
    
    // Если уже есть содержимое - рисуем как есть
    if (current.a > 0.1) {
        COLOR = current;
    }
    
    // Проверяем соседние пиксели
    vec2 pixel_size = 1.0 / TEXTURE_PIXEL_SIZE;
    bool should_outline = false;
    
    for (float x = -outline_width; x <= outline_width; x++) {
        for (float y = -outline_width; y <= outline_width; y++) {
            vec2 offset = vec2(x, y) * pixel_size;
            vec4 neighbor = texture(TEXTURE, UV + offset);
            
            if (neighbor.a > 0.1) {
                should_outline = true;
                break;
            }
        }
        if (should_outline) break;
    }
    
    if (should_outline) {
        COLOR = outline_color;
    } else {
        COLOR = vec4(0.0);
    }
}