/*
 * Copyright © 2023 Dustin Collins (Strega's Gate)
 * All Rights Reserved.
 *
 * http://stregasgate.com
 */

import Foundation
import GateEngine

@main
final class MousePickingGameDelegate: GameDelegate {
    
    // didFinishLaunching() is executed immediatley after the game is ready to start
    func didFinishLaunching(game: Game, options: LaunchOptions) async {
        
        // Add the engine provided 3D collision system
        game.insertSystem(Collision3DSystem.self)
        
        // Add the engine provided rendering system
        game.insertSystem(StandardRenderingSystem.self)
        
        // Add the world system. Implemetation below.
        game.insertSystem(WorldSystem.self)
        
        // Create a new entity to store the camera
        let camera = Entity()
        
        // Add the camera component to the entity
        camera.insert(CameraComponent.self)
        
        // Unwrap a Transform3Component
        await camera.configure(Transform3Component.self) { component in
            
            // Move the camera backward, relative to it's rotation
            component.position.move(15, toward: component.rotation.backward)
        }
        
        // Add the camera entity to the game
        game.insertEntity(camera)
        
        // Set the main window's title
        game.windowManager.mainWindow?.title = "Mouse Picking"
    }
}

// System subclasses are used to manipulate the simulation. They can't be used to draw content.
class WorldSystem: System {
    
    // setup() is executed a single time when the System is added to the game
    override func setup(game: Game, input: HID) async {
        
        // Add 128 cubes at random locations
        for _ in 0 ..< 128 {
            // Create am entity for this cube
            let cube = Entity()
            
            // Add a Transform3Component
            await cube.configure(Transform3Component.self) { component in
                // Give this a cube a random X location in 3D space
                let x: Float = Float((-15 ..< 15).randomElement()!)
                // Give this a cube a random Y location in 3D space
                let y: Float = Float((-10 ..< 10).randomElement()!)
                // Keep all cube Z locations the same
                let z: Float = 0
                // Set the cubs postion
                component.position = Position3(x, y, z)
            }
            
            // Add a Collision3DComponent
            await cube.configure(Collision3DComponent.self) { component in
                
                // Set the collider radius to half our unit cube, which will cover the whole cube.
                component.collider = AxisAlignedBoundingBox3D(radius: Size3(0.5))
            }
            
            // Give the entity 3D geometry
            await cube.configure(RenderingGeometryComponent.self) { component in
                
                // Load the engine provided unit cube. A unit cube is 1x1x1 units.
                component.insert(Geometry(as: .unitCube))
            }
            
            await cube.configure(MaterialComponent.self) { component in
                
                // Use the system shader that renderers channel.color
                component.fragmentShader = .materialColor
               
                component.channel(0) { channel in
                    
                    // Give this a cube a random color
                    channel.color = [.lightRed, .lightGreen, .lightBlue].randomElement()!
                }
            }
            
            // Add this cube to the game
            game.insertEntity(cube)
        }
    }
    
    // update() is executed every simulation tick, which may or may not be every frame
    override func update(game: Game, input: HID, withTimePassed deltaTime: Float) async {
        // Make sure the mainWindow exists
        guard let window = game.windowManager.mainWindow else {return}
        
        // Create a camera from the cameraEntity for our Canvas later
        guard let camera = Camera(game.cameraEntity) else {return}
        
        // Grab the current mouse position if there is one
        guard let mousePosition = input.mouse.position else {return}
        
        // Make a canvas with the window and camera
        // Canvas has the ability to convert from 2D and 3D spaces,
        // we won't be drawing anything with this canvas.
        let canvas = Canvas(window: window, camera: camera)
        
        // Obtain a Ray3D from the canvas pointing from tnhe screen toward 3D space
        // The ray.origin is on the screen and the ray.direction will hit anything otward into 3D space
        // We'll use this to find an entity under the mouse cursor
        let ray = canvas.convertTo3DSpace(mousePosition)
        
        // Ask the game for collision and get the first hit from our ray.
        // We only care about entites, so we'll grab the hit.entity
        if let entity = game.collision3DSystem.closestHit(from: ray)?.entity {
            
            // Change the color of the hit cube to yellow
            entity[MaterialComponent.self].channel(0) { channel in
                channel.color = .yellow
            }
        }
    }
    
    // phase determines at which point the system should be updated relative to other systems
    override class var phase: System.Phase {.simulation}
}
