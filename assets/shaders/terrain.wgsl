#import bevy_pbr::{
    forward_io::Vertex,
    mesh_functions,
    view_transformations::position_world_to_clip
}

struct VertexOutput {
    @builtin(position) clip_pos: vec4<f32>,
    @location(0) world_pos: vec4<f32>,
}

@vertex
fn vertex(in: Vertex) -> VertexOutput {
    let world_from_local = mesh_functions::get_world_from_local(in.instance_index);
    var out: VertexOutput;
    out.world_pos = mesh_functions::mesh_position_local_to_world(world_from_local, vec4(in.position, 1.0));
    out.clip_pos = position_world_to_clip(out.world_pos.xyz);
    return out;
}

@fragment
fn fragment(in: VertexOutput) -> @location(0) vec4<f32> {
    return vec4(1.0);
}
