#![cfg_attr(bevy_lint, feature(register_tool), register_tool(bevy))]
#![cfg_attr(not(feature = "console"), windows_subsystem = "windows")]

use std::f32::consts::FRAC_PI_2;

use bevy::{
    input::mouse::AccumulatedMouseMotion,
    prelude::*,
    render::render_resource::{AsBindGroup, ShaderRef},
};

fn main() -> AppExit {
    App::new()
        .add_plugins((DefaultPlugins, MaterialPlugin::<TerrainMaterial>::default()))
        .add_systems(Startup, setup)
        .add_systems(Update, move_cam)
        .run()
}

#[derive(AsBindGroup, Clone, Asset, TypePath)]
struct TerrainMaterial {}

impl Material for TerrainMaterial {
    fn vertex_shader() -> ShaderRef {
        "shaders/terrain.wgsl".into()
    }

    fn fragment_shader() -> ShaderRef {
        "shaders/terrain.wgsl".into()
    }
}

fn setup(
    mut commands: Commands,
    mut meshes: ResMut<Assets<Mesh>>,
    mut materials: ResMut<Assets<TerrainMaterial>>,
) {
    commands.spawn((Camera3d::default(), Transform::from_xyz(0.0, 0.2, 1.0)));

    commands.spawn((
        Mesh3d(meshes.add(Plane3d::default())),
        MeshMaterial3d(materials.add(TerrainMaterial {})),
    ));
}

fn move_cam(
    accumulated_mouse_motion: Res<AccumulatedMouseMotion>,
    mut tf: Single<&mut Transform, With<Camera>>,
) {
    let sensi = Vec2::new(0.003, 0.002);

    let delta = accumulated_mouse_motion.delta;

    if delta != Vec2::ZERO {
        // Note that we are not multiplying by delta_time here.
        // The reason is that for mouse movement, we already get the full movement that happened since the last frame.
        // This means that if we multiply by delta_time, we will get a smaller rotation than intended by the user.
        // This situation is reversed when reading e.g. analog input from a gamepad however, where the same rules
        // as for keyboard input apply. Such an input should be multiplied by delta_time to get the intended rotation
        // independent of the framerate.
        let delta_yaw = -delta.x * sensi.x;
        let delta_pitch = -delta.y * sensi.y;

        let (yaw, pitch, roll) = tf.rotation.to_euler(EulerRot::YXZ);
        let yaw = yaw + delta_yaw;

        // If the pitch was ±¹⁄₂ π, the camera would look straight up or down.
        // When the user wants to move the camera back to the horizon, which way should the camera face?
        // The camera has no way of knowing what direction was "forward" before landing in that extreme position,
        // so the direction picked will for all intents and purposes be arbitrary.
        // Another issue is that for mathematical reasons, the yaw will effectively be flipped when the pitch is at the extremes.
        // To not run into these issues, we clamp the pitch to a safe range.
        const PITCH_LIMIT: f32 = FRAC_PI_2 - 0.01;
        let pitch = (pitch + delta_pitch).clamp(-PITCH_LIMIT, PITCH_LIMIT);

        tf.rotation = Quat::from_euler(EulerRot::YXZ, yaw, pitch, roll);
    }
}
