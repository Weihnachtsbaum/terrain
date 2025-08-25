#import bevy_core_pipeline::fullscreen_vertex_shader::FullscreenVertexOutput
#import bevy_pbr::{
    atmosphere::{
        bindings::view,
        functions::uv_to_ray_direction,
    },
    mesh_view_bindings::globals,
}

@group(0) @binding(0) var depth_texture: texture_depth_multisampled_2d;

const see_dist = 100.0;
const falloff = 0.5;
const color = vec3(0.0, 0.2, 0.6);
const specular_size = 1.0;

@fragment
fn main(in: FullscreenVertexOutput) -> @location(0) vec4<f32> {
    let ray_dir = uv_to_ray_direction(in.uv);

    let depth = textureLoad(depth_texture, vec2<i32>(in.position.xy), 0);
    let cam_terrain_dist = ndc_to_camera_dist(vec3(uv_to_ndc(in.uv), depth));

    let pos = view.world_position;
    let terrain_pos = pos + ray_dir.xyz * cam_terrain_dist;
    let surface_dist = -pos.y / ray_dir.y;
    let surface_pos = pos + ray_dir.xyz * surface_dist;

    var water_depth: f32;
    if terrain_pos.y < 0.0 && pos.y <= 0.0 {
        // below water, looking at a point below water
        water_depth = distance(pos, terrain_pos);
    } else if terrain_pos.y < 0.0 && pos.y > 0.0 {
        // above water, looking at a point below water
        water_depth = distance(surface_pos, terrain_pos);
    } else if terrain_pos.y >= 0.0 && pos.y < 0.0 {
        // below water, looking at a point above water
        water_depth = distance(pos, surface_pos);
    } else {
        // above water, looking at a point above water
        water_depth = 0.0;
    }

    let intensity = min(pow(water_depth / see_dist, falloff), 1.0);

    let normal = normal(surface_pos.xz);
    let lambertian = dot(normal, common::sun_dir);
    let specular = pow(dot(ray_dir.xyz + common::sun_dir, normal), specular_size);
    let brightness = clamp((lambertian + specular) * common::sun_intensity, 0.1, 1.0);

    if surface_dist > 0.0 && surface_dist < cam_terrain_dist {
        return vec4(color * brightness, intensity);
    } else {
        return vec4(color, intensity);
    }
}

const wave_octaves = 5;
const speed = 1.0;

fn normal(pos: vec2<f32>) -> vec3<f32> {
    var sum = vec2(0.0);
    var freq = 0.1;
    var amp = 0.5;
    var angle = 0.0;
    for (var i = 0; i < wave_octaves; i++) {
        let dir = vec2(cos(angle), sin(angle));
        sum += cos(globals.time * speed + dot(pos, dir) * freq) * amp * dir * freq;
        freq *= 2.0;
        amp *= 0.5;
        angle += 1.0;
    }
    return normalize(vec3(sum.x, 1.0, sum.y));
}

fn uv_to_ndc(uv: vec2<f32>) -> vec2<f32> {
    return uv * vec2(2.0, -2.0) + vec2(-1.0, 1.0);
}

fn ndc_to_camera_dist(ndc: vec3<f32>) -> f32 {
    let view_pos = view.view_from_clip * vec4(ndc, 1.0);
    let t = length(view_pos.xyz / view_pos.w);
    return t;
}
