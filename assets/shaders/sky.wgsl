#import bevy_core_pipeline::fullscreen_vertex_shader::FullscreenVertexOutput
#import bevy_pbr::atmosphere::functions::uv_to_ray_direction

const low_color = vec3(1.0, 0.7, 0.5);
const high_color = vec3(0.2, 0.4, 0.7);
const exp = 0.3;

const sun_color = vec3(1.0, 0.9, 0.8);
const sun_size = 0.04;
const bloom_intensity = 0.00005;

@fragment
fn main(in: FullscreenVertexOutput) -> @location(0) vec4<f32> {
    let ray_dir = uv_to_ray_direction(in.uv);
    let t = pow(smoothstep(0.0, 1.0, ray_dir.y), exp);
    let color = mix(low_color, high_color, t);
    
    let sun_dist = distance(ray_dir.xyz, common::sun_dir);
    var sun_intensity: f32;
    if sun_dist < sun_size {
        sun_intensity = mix(1.0, 0.9, sun_dist / sun_size);
    } else {
        sun_intensity = pow(bloom_intensity, sun_dist);
    }
    
    let out = mix(color, sun_color, sun_intensity);
    return vec4(out, 1.0);
}
