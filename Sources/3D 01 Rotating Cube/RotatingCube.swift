/*
 * Copyright © 2023 Dustin Collins (Strega's Gate)
 * All Rights Reserved.
 *
 * http://stregasgate.com
 */

import GateEngine

@main
final class RotatingCubeGameDelegate: GameDelegate {
    func didFinishLaunching(game: Game, options: LaunchOptions) {
        // Add the cube update system to the game. System implimentation is below.
        game.insertSystem(RotatingCubeSystem.self)
        
        // Add the cube rendering system to the game. RenderingSystem implimentation is below.
        game.insertSystem(RotatingCubeRenderingSystem.self)
        
        // Create a new entity to store the camera
        let camera = Entity()
        
        // Add the camera component to the entity
        camera.insert(CameraComponent.self)
        
        // Add and modify a 3D transform
        camera.configure(Transform3Component.self) { component in
            // Move the camera backward 2 units
            component.position.move(1, toward: component.rotation.backward)
        }
        
        // Add the camera entity to the game
        game.insertEntity(camera)
    }
}

class RotatingCubeSystem: System {
    override func setup() {
        // Create a new entity
        let cube = Entity()
        
        // Give the entity a 3D transform
        cube.configure(Transform3Component.self) {component in
            // Move 1 unit forward, so it's in front of the camera
            component.position.move(1, toward: .forward)
        }
        
        // Give the entity 3D geometry
        cube.configure(RenderingGeometryComponent.self) { component in
            // Load the engine provided unit cube. A unit cube is 1x1x1 units.
            component.geometry = Geometry(path: "GateEngine/Primitives/Unit Cube.obj")
        }
        
        // Give the entity a material
        cube.configure(MaterialComponent.self) { material in
            // Begine modifying material channel zero.
            material.channel(0) { channel in
                // Load the engine provided placeholder texture.
                channel.texture = Texture(path: "GateEngine/Textures/CheckerPattern.png")
            }
        }
        
        // Add the entity to the game
        game.insertEntity(cube)
    }
    
    override func update(withTimePassed deltaTime: Float) {
        for entity in game.entities {
            
            /// Make sure the entity has geometry, otherwise we will end up rotations other entities like the camera.
            guard entity.hasComponent(CameraComponent.self) == false else {continue}
                        
            /// Get the 3D transform component if one exists, otherwise skip to the next entity
            entity.configure(Transform3Component.self) {component in
                /// Rotate by time passed around the forward axis
                component.rotation *= Quaternion(Degrees(deltaTime * 15), axis: .forward)
                /// Rotate by time passed around the up axis
                component.rotation *= Quaternion(Degrees(deltaTime * 15), axis: .up)
            }
        }
    }
}

class RotatingCubeRenderingSystem: RenderingSystem {
    override func render(window: Window, into framebuffer: RenderTarget, withTimePassed deltaTime: Float) {
        
        // To draw something in Gate Engine you must create a container to store the renderable objects.
        // A Scene is a container for 3D renderable objects and it requires a camera, so we'll create a scene camera from the games camera entity.
        guard let camera = Camera(game.cameraEntity) else {return}
        
        // Create a Scene with the scene camera.
        // Scene is light weight and you're meant to create a new one every frame.
        var scene = Scene(camera: camera)

        // Loop through all entites in the game
        for entity in game.entities {
            // Make sure the entity has a material, otherwise move on
            guard let material = entity.component(ofType: MaterialComponent.self)?.material else {continue}
            
            // Make sure the entity has a 3D transform, otherwise move on
            guard let transform = entity.component(ofType: Transform3Component.self)?.transform else {continue}

            // Make sure the entity has geometry and unwrap it
            if let geometry = entity.component(ofType: RenderingGeometryComponent.self)?.geometry {
                // Add the geometry to the scene with it's material and transform
                scene.insert(geometry, withMaterial: material, at: transform)
            }
        }
        
        // A framebuffer is a RenderTarget that represents thw window.
        // We'll add our scene to the frameBuffer and the frameBUffer will automatically draw everything in order.
        framebuffer.insert(scene)
    }
}
