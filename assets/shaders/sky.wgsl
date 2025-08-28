#import bevy_core_pipeline::fullscreen_vertex_shader::FullscreenVertexOutput
#import bevy_pbr::{
    atmosphere::functions::uv_to_ray_direction,
    mesh_view_bindings::globals,
}
#import noisy_bevy::fbm_simplex_3d

const exp = 0.3;

const sun_color = vec3(1.0, 0.9, 0.8);
const sun_size = 0.04;
const bloom_intensity = 0.00005;

const cloud_vel = vec2(0.02, 0.05);
const morph_factor = 0.05;
const cloud_height = 0.5;
const bright_cloud_brightness = 0.8;
const dark_cloud_brightness = 0.4;

@fragment
fn main(in: FullscreenVertexOutput) -> @location(0) vec4<f32> {
    let ray_dir = uv_to_ray_direction(in.uv);
    let t = pow(smoothstep(0.0, 1.0, ray_dir.y), exp);
    var out = mix(common::low_sky_color, common::high_sky_color, t);
    
    let sun_dist = distance(ray_dir.xyz, common::sun_dir);
    var sun_intensity: f32;
    if sun_dist < sun_size {
        sun_intensity = mix(1.0, 0.9, sun_dist / sun_size);
    } else {
        sun_intensity = pow(bloom_intensity, sun_dist);
    }
    out = mix(out, sun_color, sun_intensity);

    let cloud_pos = vec2(
        ray_dir.x * cloud_height / ray_dir.y + cloud_vel.x * globals.time,
        ray_dir.z * cloud_height / ray_dir.y + cloud_vel.y * globals.time,
    );
    let noise = fbm_simplex_3d(vec3(cloud_pos, globals.time * morph_factor), 4, 2.0, 0.5) / 2.0 + 0.5;
    let cloud_color = vec3(mix(bright_cloud_brightness, dark_cloud_brightness, noise));
    let dist_scale = pow(max(ray_dir.y, 0.0), 0.2);
    out = mix(out, cloud_color, noise * dist_scale);
    
    return vec4(out, 1.0);
}
