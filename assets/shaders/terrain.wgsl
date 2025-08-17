#import bevy_pbr::{
    forward_io::Vertex,
    mesh_functions,
    view_transformations::position_world_to_clip
}
#import noisy_bevy::fbm_simplex_2d

struct VertexOutput {
    @builtin(position) clip_pos: vec4<f32>,
    @location(0) world_pos: vec4<f32>,
    @location(1) noise: f32,
}

@vertex
fn vertex(in: Vertex) -> VertexOutput {
    var out: VertexOutput;
    out.noise = fbm_simplex_2d(in.position.xz * 0.005, 10, 2.0, 0.5);
    let pos = vec3(in.position.x, out.noise * 20.0, in.position.z);

    let world_from_local = mesh_functions::get_world_from_local(in.instance_index);
    out.world_pos = mesh_functions::mesh_position_local_to_world(world_from_local, vec4(pos, 1.0));
    out.clip_pos = position_world_to_clip(out.world_pos.xyz);
    return out;
}

@fragment
fn fragment(in: VertexOutput) -> @location(0) vec4<f32> {
    let noise = (in.noise + 1.0) / 2.0;
    return (1.0 - noise) * vec4(0.1, 0.4, 0.0, 1.0) + noise * vec4(0.2, 0.2, 0.1, 1.0);
}
