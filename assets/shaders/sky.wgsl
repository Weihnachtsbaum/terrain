#import bevy_core_pipeline::fullscreen_vertex_shader::FullscreenVertexOutput
#import bevy_pbr::atmosphere::functions::uv_to_ray_direction

const low_color = vec3(1.0, 0.7, 0.5);
const high_color = vec3(0.2, 0.4, 0.7);
const exp = 0.3;

@fragment
fn main(in: FullscreenVertexOutput) -> @location(0) vec4<f32> {
    let height = uv_to_ray_direction(in.uv).y;
    let t = pow(smoothstep(0.0, 1.0, height), exp);
    return vec4(mix(low_color, high_color, t), 1.0);
}
