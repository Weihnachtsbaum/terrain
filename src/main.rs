#![cfg_attr(bevy_lint, feature(register_tool), register_tool(bevy))]
#![cfg_attr(not(feature = "console"), windows_subsystem = "windows")]

use std::{f32::consts::FRAC_PI_2, time::Duration};

use bevy::{
    input::mouse::AccumulatedMouseMotion,
    prelude::*,
    render::{
        mesh::PlaneMeshBuilder,
        render_resource::{AsBindGroup, ShaderRef},
    },
    time::common_conditions::on_timer,
};
use noisy_bevy::NoisyShaderPlugin;

fn main() -> AppExit {
    App::new()
        .add_plugins((
            DefaultPlugins,
            NoisyShaderPlugin,
            MaterialPlugin::<TerrainMaterial>::default(),
            #[cfg(feature = "frame_time_diagnostics")]
            (
                bevy::diagnostic::LogDiagnosticsPlugin::default(),
                bevy::diagnostic::FrameTimeDiagnosticsPlugin::default(),
            ),
        ))
        .add_systems(Startup, (setup, update_chunks).chain())
        .add_systems(
            Update,
            (
                update_chunks.run_if(on_timer(Duration::from_secs(1))),
                move_cam,
            ),
        )
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

#[derive(Component)]
struct Chunk;

#[derive(Resource)]
struct ChunkMeshHandle(Handle<Mesh>);

#[derive(Resource)]
struct TerrainMaterialHandle(Handle<TerrainMaterial>);

const CHUNK_SIZE: f32 = 200.0;

fn setup(
    mut commands: Commands,
    mut meshes: ResMut<Assets<Mesh>>,
    mut materials: ResMut<Assets<TerrainMaterial>>,
) {
    commands.spawn((Camera3d::default(), Transform::from_xyz(0.0, 0.2, 1.0)));

    let mesh = PlaneMeshBuilder {
        plane: Plane3d {
            half_size: Vec2::splat(CHUNK_SIZE / 2.0),
            ..default()
        },
        subdivisions: 1000,
    }
    .build();

    commands.insert_resource(ChunkMeshHandle(meshes.add(mesh)));
    commands.insert_resource(TerrainMaterialHandle(materials.add(TerrainMaterial {})));
}

const RENDER_DIST: i32 = 2;

fn update_chunks(
    chunk_q: Query<(&Transform, Entity), With<Chunk>>,
    mut commands: Commands,
    mesh: Res<ChunkMeshHandle>,
    material: Res<TerrainMaterialHandle>,
    cam: Single<&Transform, With<Camera>>,
) {
    for (tf, e) in chunk_q.iter() {
        if tf.translation.distance_squared(cam.translation)
            > (RENDER_DIST * RENDER_DIST) as f32 * CHUNK_SIZE * CHUNK_SIZE
        {
            commands.entity(e).despawn();
        }
    }
    for z in -RENDER_DIST..RENDER_DIST {
        for x in -RENDER_DIST..RENDER_DIST {
            let pos = Vec2::new(x as f32, z as f32);
            if pos.length_squared() > (RENDER_DIST * RENDER_DIST) as f32 {
                continue;
            }
            let pos = (pos + (cam.translation.xz() / CHUNK_SIZE).round()) * CHUNK_SIZE;
            let pos = Vec3::new(pos.x, 0.0, pos.y);
            if chunk_q.iter().any(|(tf, _)| tf.translation == pos) {
                continue;
            }
            commands.spawn((
                Chunk,
                Mesh3d(mesh.0.clone()),
                MeshMaterial3d(material.0.clone()),
                Transform::from_translation(pos),
            ));
        }
    }
}

fn move_cam(
    accumulated_mouse_motion: Res<AccumulatedMouseMotion>,
    kb: Res<ButtonInput<KeyCode>>,
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

    let mut dir = Vec3::ZERO;

    if kb.pressed(KeyCode::KeyW) {
        dir.z -= 1.0;
    }
    if kb.pressed(KeyCode::KeyS) {
        dir.z += 1.0;
    }
    if kb.pressed(KeyCode::KeyA) {
        dir.x -= 1.0;
    }
    if kb.pressed(KeyCode::KeyD) {
        dir.x += 1.0;
    }
    if kb.pressed(KeyCode::ShiftLeft) {
        dir.y -= 1.0;
    }
    if kb.pressed(KeyCode::Space) {
        dir.y += 1.0;
    }

    const SPEED: f32 = 0.5;

    let rot = tf.rotation;
    tf.translation += rot * dir.normalize_or_zero() * SPEED;
}
