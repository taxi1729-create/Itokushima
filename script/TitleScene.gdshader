shader_type canvas_item;

// --- インスペクターから操作できる変数 (Uniforms) ---
uniform vec4 bg_color : source_color = vec4(0.1, 0.1, 0.1, 1.0);
uniform vec4 shape_color : source_color = vec4(0.0, 0.8, 1.0, 1.0);
uniform float size : hint_range(1.0, 50.0) = 10.0;     // 全体の密度（拡大縮小）
uniform float move_speed : hint_range(-5.0, 5.0) = 0.5; // 移動速度
uniform float global_rotation_speed : hint_range(-5.0, 5.0) = 0.2; // 全体の回転
uniform float local_rotation_speed : hint_range(-5.0, 5.0) = 1.0;  // 各個の回転
uniform float shape_size : hint_range(0.1, 0.5) = 0.3; // 三角形の大きさ

// 回転行列を作る関数
mat2 rotate(float angle) {
    return mat2(vec2(cos(angle), -sin(angle)), vec2(sin(angle), cos(angle)));
}

// 正三角形を描く関数
float sdTriangle(vec2 p, float r) {
    const float k = sqrt(3.0);
    p.x = abs(p.x) - r;
    p.y = p.y + r / k;
    if (p.x + k * p.y > 0.0) p = vec2(p.x - k * p.y, -k * p.x - p.y) / 2.0;
    p.x -= clamp(p.x, -2.0 * r, 0.0);
    return -length(p) * sign(p.y);
}

void fragment() {
    // 1. 全体の回転と移動
    vec2 uv = UV - 0.6;
    uv *= rotate(TIME * global_rotation_speed);
    uv += vec2(TIME * move_speed * 0.1);
    
    // 2. グリッドの分割（拡大縮小）
    vec2 g_uv = fract(uv * size) - 0.5;
    
    // 3. 各三角形の回転
    g_uv *= rotate(TIME * local_rotation_speed);
    
    // 4. 三角形の描画
    float d = sdTriangle(g_uv, shape_size);
    
    // 5. 色の合成
    float mask = smoothstep(0.02, 0.0, d); // 境界を滑らかに
    vec4 final_color = mix(bg_color, shape_color, mask);
    
    COLOR = final_color;
}