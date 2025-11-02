shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform float outline_width : hint_range(0.0, 5.0) = 2.0;
uniform float alpha_threshold : hint_range(0.0, 1.0) = 0.1;

void fragment() {
    vec4 texture_color = texture(TEXTURE, UV);
    
    if (texture_color.a > alpha_threshold) {
        COLOR = texture_color;
    }
    
    vec2 pixel_size = outline_width / TEXTURE_PIXEL_SIZE;
    
    // Проверяем только 4 направления (быстрее)
    float outline_alpha = 0.0;
    
    vec4 up = texture(TEXTURE, UV + vec2(0.0, -pixel_size.y));
    vec4 down = texture(TEXTURE, UV + vec2(0.0, pixel_size.y));
    vec4 left = texture(TEXTURE, UV + vec2(-pixel_size.x, 0.0));
    vec4 right = texture(TEXTURE, UV + vec2(pixel_size.x, 0.0));
    
    if (up.a > alpha_threshold || down.a > alpha_threshold || 
        left.a > alpha_threshold || right.a > alpha_threshold) {
        outline_alpha = 1.0;
    }
    
    if (outline_alpha > 0.0) {
        COLOR = outline_color;
    } else {
        COLOR = vec4(0.0);
    }
}