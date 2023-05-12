/*
 * Copyright © 2023 Dustin Collins (Strega's Gate)
 * All Rights Reserved.
 *
 * http://stregasgate.com
 */

import Foundation
import GateEngine

@main
final class RotatingCubeGameDelegate: GameDelegate {
    
    // didFinishLaunching() is executed immediatley after the game is ready to start
    func didFinishLaunching(game: Game, options: LaunchOptions) {
        
        // Add the cube update system to the game. System implementation is below
        game.insertSystem(RotatingCubeSystem.self)
        
        // Add the cube rendering system to the game. RenderingSystem implementation is below
        game.insertSystem(RotatingCubeRenderingSystem.self)
        
        // Create a new entity to store the camera
        let camera = Entity()
        
        // Add the camera component to the entity
        camera.insert(CameraComponent.self)
        
        // Unwrap a Transform3Component
        camera.configure(Transform3Component.self) { component in
            
            // Move the camera backward, relative to it's rotation, by 1 units
            component.position.move(1, toward: component.rotation.backward)
        }
        
        // Add the camera entity to the game
        game.insertEntity(camera)
    }
    
    #if os(WASI)
    // GateEngine automatically searches for resources on most platforms, however...
    // HTML5 can't search becuase its a website. GateEngine will automatically search "ModuleName_ModuleName.resources".
    // But this module has a different name then it's package. There is no way to obtain the package name at runtime.
    // So We need to tell GateEngine the resource bundle name for this project, if you plan to deploy to HTML5.
    func resourceSearchPaths() -> [URL] {
        return [URL(string: "GateEngineDemos_3D_01_RotatingCube.resources")!]
    }
    #endif
}

// System subclasses are used to manipulate the simulation. They can't be used to draw content.
class RotatingCubeSystem: System {
    
    // setup() is executed a single time when the System is added to the game
    override func setup(game: Game, input: HID) {
        
        // Create a new entity
        let cube = Entity()
        
        // Give the entity a 3D transform
        cube.configure(Transform3Component.self) {component in
            
            // Move 1 unit forward, so it's in front of the camera
            component.position.move(1, toward: .forward)
        }
        
        // Give the entity 3D geometry
        cube.configure(RenderingGeometryComponent.self) { component in
            // Load the engine provided unit cube. A unit cube is 1x1x1 units
            component.geometry = Geometry(path: "GateEngine/Primitives/Unit Cube.obj")
        }
        
        // Give the entity a material
        cube.configure(MaterialComponent.self) { material in
            // Begin modifying material channel zero
            material.channel(0) { channel in
                // Load the engine provided placeholder texture
                channel.texture = Texture(path: "GateEngine/Textures/CheckerPattern.png")
            }
        }
        
        // Add the entity to the game
        game.insertEntity(cube)
    }
    
    // update() is executed every simulation tick, which may or may not be every frame
    override func update(game: Game, input: HID, withTimePassed deltaTime: Float) {
        
        // Loop through all entites in the game
        for entity in game.entities {
            
            // Make sure the entity is not the camera
            guard entity.hasComponent(CameraComponent.self) == false else {continue}
                        
            // Get the 3D transform component if one exists, otherwise skip to the next entity
            entity.configure(Transform3Component.self) {component in
                // Create an angle based on how much time has passed
                let angle = Degrees(deltaTime * 15)
                // Rotate around the forward axis
                component.rotation *= Quaternion(angle, axis: .forward)
                // Rotate around the up axis
                component.rotation *= Quaternion(angle, axis: .up)
            }
        }
    }
    
    // phase determines at which point the system should be updated relative to other systems
    override class var phase: System.Phase {.simulation}
}

// RenderingSystem subclasses can draw content
// However, updating the simulation from a RenderingSystem is a programming error
// GateEngine allows for frame drops and headless execution for servers
// In these cases RenderingSystems do not get updated
class RotatingCubeRenderingSystem: RenderingSystem {
    
    // render() is called only wehn drawing needs to be done
    override func render(game: Game, window: Window, withTimePassed deltaTime: Float) {
        
        // To draw something in GateEngine you must create a container to store the renderable objects
        // A Scene is a container for 3D renderable objects and it requires a Camera
        // So we'll create a Camera from the game's cameraEntity
        guard let camera = Camera(game.cameraEntity) else {return}
        
        // Create a Scene with the scene camera
        // Scene is light weight and you're meant to create a new one every frame
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
        
        // A framebuffer is a RenderTarget that represents the window
        // The frameBuffer will automatically draw the scene
        window.insert(scene)
    }
}
