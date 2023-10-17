/*
 * Copyright © 2023 Dustin Collins (Strega's Gate)
 * All Rights Reserved.
 *
 * http://stregasgate.com
 */

// 3D Model/Texture by: https://sketchfab.com/3d-models/toon-cat-free-b2bd1ee7858444bda366110a2d960386

import Foundation
import GateEngine

@main
final class SkinnedCharacterGameDelegate: GameDelegate {
    
    // didFinishLaunching() is executed immediatley after the game is ready to start
    func didFinishLaunching(game: Game, options: LaunchOptions) async {
        // Add the engine provided RigSystem so our character can animate
        game.insertSystem(Rig3DSystem.self)
        
        // Add the skinned character update system to the game. System implementation is below
        game.insertSystem(SkinnedCharacterSystem.self)
        
        // Add the skinned character rendering system to the game. RenderingSystem implementation is below
        game.insertSystem(SkinnedCharacterRenderingSystem.self)
        
        // Create a new entity to store the camera
        let camera = Entity()
        
        // Add the camera component to the entity
        camera.insert(CameraComponent.self)
        
        // Unwrap a Transform3Component
        camera.insert(Transform3Component.self) { component in
            
            // Move the camera backward, relative to it's rotation, by 5 units
            component.position.move(5, toward: component.rotation.backward)
        }
        
        // Add the camera entity to the game
        game.insertEntity(camera)
        
        // Set the main window's title
        game.windowManager.mainWindow?.title = "Skinned Character"
    }
    
    #if os(WASI)
    // GateEngine automatically searches for resources on most platforms, however...
    // HTML5 can't search because its a website. GateEngine will automatically search "ModuleName_ModuleName.resources".
    // But this module has a different name then it's package. There is no way to obtain the package name at runtime.
    // So We need to tell GateEngine the resource bundle name for this project, if you plan to deploy to HTML5.
    func customResourceLocations() -> [String] {
        return ["GateEngineDemos_3D_02_SkinnedCharacter.resources"]
    }
    #endif
}

// System subclasses are used to manipulate the simulation. They can't be used to draw content.
class SkinnedCharacterSystem: System {
    
    // setup() is executed a single time when the System is added to the game
    override func setup(game: Game, input: HID) async {
        
        // Create a new entity
        let character = Entity()
        
        // Give the entity a 3D transform
        character.insert(Transform3Component.self) { component in
            
            // // Move 2 units down, so it's centered on camera
            component.position.move(2, toward: .down)
        }
        
        // Give the entity rig
        character.insert(Rig3DComponent.self) { component in
            
            // Load the characters skeleton from the characters source file
            component.skeleton = Skeleton(path: "Resources/Cat.glb")
            
            // Load an animation set from the characters source file
            component.animationSet = [SkeletalAnimation(path: "Resources/Cat.glb")]
            
            // Convert the first skeletal animation into a repeating rig animation
            component.activeAnimation = Rig3DAnimation(component.animationSet![0], repeats: true)
        }
        
        // Give the entity 3D geometry
        character.insert(RenderingGeometryComponent.self) { component in
            
            // Load the characters geometry from the characters source file
            component.insert(SkinnedGeometry(path: "Resources/Cat.glb"))
        }
        
        // Give the entity a material
        character.insert(MaterialComponent.self) { component in
            // Begin modifying material channel zero
            component.channel(0) { channel in
                // Load the characters texture
                channel.texture = Texture(path: "Resources/Cat.png")
            }
        }
        
        // Add the entity to the game
        game.insertEntity(character)
    }
    
    // update() is executed every simulation tick, which may or may not be every frame
    override func update(game: Game, input: HID, withTimePassed deltaTime: Float) async {
        
        // Loop through all entites in the game
        for entity in game.entities {
            // Make sure the entity is not the camera
            guard entity.hasComponent(CameraComponent.self) == false else {continue}
            
            // Get the 3D transform component if one exists, otherwise skip to the next entity
            entity.modify(Transform3Component.self) { component in
                
                // Rotate the character around the up axis based on deltaTime
                component.rotation *= Quaternion(Degrees(deltaTime * 15), axis: .up)
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
class SkinnedCharacterRenderingSystem: RenderingSystem {
    
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
            
            // Make sure the entity has a rig and get it's current pose, otherwise move on
            // A Pose is the state of a skeleton at it's current animation frame
            guard let pose = entity.component(ofType: Rig3DComponent.self)?.skeleton.getPose() else {continue}
            
            // Make sure the entity has a material, otherwise move on
            guard let material = entity.component(ofType: MaterialComponent.self)?.material else {continue}

            // Make sure the entity has a 3D transform, otherwise move on
            guard let transform = entity.component(ofType: Transform3Component.self)?.transform else {continue}
            
            // Make sure the entity has geometry and unwrap it
            if let geometryComponent = entity.component(ofType: RenderingGeometryComponent.self) {
                
                // Loop through all SkinnedGeometry in the RenderingGeometryComponent
                for geometry in geometryComponent.skinnedGeometries {
                    
                    // Add the geometry to the scene with it's material and transform
                    scene.insert(geometry, withPose: pose, material: material, at: transform)
                }
            }
        }
        
        // Add the scene to the window to be drawn
        window.insert(scene)
    }
}
