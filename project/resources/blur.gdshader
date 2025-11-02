shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest_mipmap;
uniform float blur_intensity : hint_range(0.0, 10.0) = 2.0;
uniform int samples : hint_range(1, 32) = 16;
uniform float quality : hint_range(0.1, 2.0) = 1.0;
uniform vec2 direction = vec2(1.0, 1.0);

// Гауссово размытие с настраиваемыми параметрами
void fragment() {
    vec2 blur_dir = normalize(direction) * blur_intensity * 0.001;
    vec4 color = texture(screen_texture, SCREEN_UV);
    
    float total_weight = 1.0;
    
    for (int i = 1; i < samples; i++) {
        float weight = exp(-float(i * i) / (2.0 * blur_intensity * blur_intensity));
        
        // Положительное направление
        vec2 offset1 = SCREEN_UV + blur_dir * float(i) * quality;
        color += texture(screen_texture, offset1) * weight;
        
        // Отрицательное направление
        vec2 offset2 = SCREEN_UV - blur_dir * float(i) * quality;
        color += texture(screen_texture, offset2) * weight;
        
        total_weight += 2.0 * weight;
    }
    
    COLOR = color / total_weight * COLOR;
}