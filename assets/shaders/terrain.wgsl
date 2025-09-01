#import bevy_pbr::{
    forward_io::Vertex,
    mesh_functions,
    mesh_view_bindings::view,
    view_transformations::position_world_to_clip
}
#import noisy_bevy::fbm_simplex_2d

const fog_density = 0.0002;
const fog_color = vec3(0.6, 0.6, 0.8);

struct VertexOutput {
    @builtin(position) clip_pos: vec4<f32>,
    @location(0) world_pos: vec3<f32>,
    @location(1) slope: vec2<f32>,
}

@vertex
fn vertex(in: Vertex) -> VertexOutput {
    var out: VertexOutput;

    let world_from_local = mesh_functions::get_world_from_local(in.instance_index);
    out.world_pos = mesh_functions::mesh_position_local_to_world(world_from_local, vec4(in.position, 1.0)).xyz;
    out.world_pos.y = noise(out.world_pos.xz);

    // TODO: calculate using the derivative
    out.slope = vec2(
        (noise(vec2(out.world_pos.x + 0.01, out.world_pos.z)) - out.world_pos.y) / 0.01,
        (noise(vec2(out.world_pos.x, out.world_pos.z + 0.01)) - out.world_pos.y) / 0.01,
    );

    out.clip_pos = position_world_to_clip(out.world_pos.xyz);
    return out;
}

@fragment
fn fragment(in: VertexOutput) -> @location(0) vec4<f32> {
    let normal = normalize(vec3(-in.slope.x, 1.0, -in.slope.y));
    let brightness = clamp(dot(normal, common::sun_dir) * common::sun_intensity, 0.1, 1.0);
    let slope = clamp(length(in.slope * 0.5), 0.0, 1.0);
    let albedo = (1.0 - slope) * vec3(0.1, 0.4, 0.0) + slope * vec3(0.2, 0.2, 0.1);
    var out = albedo * brightness;
    let fog = exp(-fog_density * distance(in.world_pos, view.world_position));
    out = mix(fog_color, out, fog);
    return vec4(out, 1.0);
}

fn noise(pos: vec2<f32>) -> f32 {
    // Update `TERRAIN_MAX_HEIGHT` when changing these values
    return fbm_simplex_2d(pos * 0.005, 10, 2.0, 0.5) * 20.0;
}
