#import bevy_pbr::{
    forward_io::Vertex,
    mesh_functions,
    view_transformations::position_world_to_clip
}
#import noisy_bevy::fbm_simplex_2d

// vector pointing to the light
const light_dir = vec3(0.8137977, 0.3420201, 0.4698463);
const light_intensity = 1.0;

struct VertexOutput {
    @builtin(position) clip_pos: vec4<f32>,
    @location(0) slope: vec2<f32>,
}

@vertex
fn vertex(in: Vertex) -> VertexOutput {
    var out: VertexOutput;
    let noise = noise(in.position.xz);
    // TODO: calculate using the derivative
    out.slope = vec2(
        (noise(vec2(in.position.x + 0.01, in.position.z)) - noise) / 0.01,
        (noise(vec2(in.position.x, in.position.z + 0.01)) - noise) / 0.01,
    );
    let pos = vec3(in.position.x, noise, in.position.z);

    let world_from_local = mesh_functions::get_world_from_local(in.instance_index);
    let world_pos = mesh_functions::mesh_position_local_to_world(world_from_local, vec4(pos, 1.0));
    out.clip_pos = position_world_to_clip(world_pos.xyz);
    return out;
}

@fragment
fn fragment(in: VertexOutput) -> @location(0) vec4<f32> {
    let normal = normalize(vec3(-in.slope.x, 1.0, -in.slope.y));
    let brightness = clamp(dot(normal, light_dir) * light_intensity, 0.1, 1.0);
    let slope = clamp(length(in.slope * 0.5), 0.0, 1.0);
    let albedo = (1.0 - slope) * vec3(0.1, 0.4, 0.0) + slope * vec3(0.2, 0.2, 0.1);
    return vec4(albedo * brightness, 1.0);
}

fn noise(pos: vec2<f32>) -> f32 {
    return fbm_simplex_2d(pos * 0.005, 10, 2.0, 0.5) * 20.0;
}
