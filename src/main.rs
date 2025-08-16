#![cfg_attr(bevy_lint, feature(register_tool), register_tool(bevy))]
#![cfg_attr(not(feature = "console"), windows_subsystem = "windows")]

use bevy::prelude::*;

fn main() -> AppExit {
    App::new()
        .add_plugins(DefaultPlugins)
        .add_systems(Startup, setup)
        .run()
}

fn setup(mut commands: Commands) {
    commands.spawn(Camera3d::default());
}
