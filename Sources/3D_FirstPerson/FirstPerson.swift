/*
 * Copyright © 2023 Dustin Collins (Strega's Gate)
 * All Rights Reserved.
 *
 * http://stregasgate.com
 */

import Foundation
import GateEngine

// Atlas.png pixelart by: Jestan https://jestan.itch.io/pixel-texture-pack

@main
final class FirstPersonGameDelegate: GameDelegate {
    let gravity = Gravity()
    
    // didFinishLaunching() is executed immediatley after the game is ready to start
    func didFinishLaunching(game: Game, options: LaunchOptions) async {
        
        // Add our LevelLoadingSystem system to the game. Implementation is below
        game.insertSystem(LevelLoadingSystem.self)
        
        // Add the engine provided Physics3DSystem
        game.insertSystem(Physics3DSystem.self)
        
        // Add the engine provided Collision3DSystem
        game.insertSystem(Collision3DSystem.self)
        
        // Add the engine provided StandardRenderingSystem
        game.insertSystem(StandardRenderingSystem.self)

        // Create a camera entity and add it to the game
        let camera = Entity(components: [Transform3Component.self, CameraComponent.self])
        game.insertEntity(camera)
        
        // Set the main window's title
        game.windowManager.mainWindow?.title = "First Person"
        
        // Set the mainWindow's clearColor to lightBlue so it kinda looks like a sky
        game.windowManager.mainWindow?.clearColor = .lightBlue
    }
    
    #if os(WASI)
    // GateEngine automatically searches for resources on most platforms, however...
    // HTML5 can't search because its a website. GateEngine will automatically search "ModuleName_ModuleName.resources".
    // But this module has a different name then it's package. There is no way to obtain the package name at runtime.
    // So We need to tell GateEngine the resource bundle name for this project, if you plan to deploy to HTML5.
    func customResourceLocations() -> [String] {
        return ["GateEngineDemos_3D_FirstPerson.resources"]
    }
    #endif
}

class LevelLoadingSystem: System {
    // Create a new entity. Well store it in the System so we can grab it later
    let level = Entity()
    
    // setup() is executed a single time when the System is added to the game
    override func setup(game: Game, input: HID) async {
        
        // Give the level a transform
        level.insert(Transform3Component.self)
            
        // Give the level rendering geometry
        await level.configure(RenderingGeometryComponent.self) { component in
            
            // Load the LevelRenderingGeometry from game's resources
            component.insert(Geometry(path: "Resources/LevelRenderingGeometry.obj"))
        }
        
        // Give the level a material
        await level.configure(MaterialComponent.self) { material in
            
            // Begin modifying material channel zero
            material.channel(0) { channel in
                
                // Load the texture from our game's resoruces
                channel.texture = Texture(path: "Resources/Atlas.png")
            }
        }
        
        // Give the level an OctreeComponent, which allows for 3D mesh collision
        await level.configure(OctreeComponent.self) { component in
            do {
                // Load the LevelCollisionGeometry from our game's resources
                // This is async and the OctreeComponent will only be added to the level after loading is complete
                // We'll use this to check when loading is done so the player doesn't fall through the level before it has collision loaded
                try await component.load(path: "Resources/LevelCollisionGeometry.obj", center: .zero)
            }catch{
                fatalError("\(error)")
            }
        }
        
        // Add the level to the game
        game.insertEntity(level)
    }
    
    // update() is executed every simulation tick, which may or may not be every frame
    override func update(game: Game, input: HID, withTimePassed deltaTime: Float) async {
        
        // The OctreeComponent was configured asynchronous. It's done loading when it's on the entity
        if level.hasComponent(OctreeComponent.self) {
            
            // Remove the level system as we used it for loading only
            game.removeSystem(self)
            
            // Add the PlayerControllerSystem. Implementation below
            game.insertSystem(PlayerControllerSystem.self)
        }
    }
    
    // phase determines at which point the system should be updated relative to other systems
    override class var phase: System.Phase {.updating}
}

// System subclasses are used to manipulate the simulation. They can't be used to draw content.
class PlayerControllerSystem: System {
    
    // A vertical reference angle
    var yAngle: Degrees = .zero
    
    // A horizontal reference angle
    var xAngle: Degrees = .zero
    
    // setup() is executed a single time when the System is added to the game
    override func setup(game: Game, input: HID) async {
        // Create an entity for the player
        let player = Entity(name: "Player")
                
        player.insert(Transform3Component.self)
        
        // Give the player a physics component so gravity is applied
        player.insert(Physics3DComponent.self)
        
        // Give the player a collision component so we can collide with the world
        await player.configure(Collision3DComponent.self) { component in
            // Dynamic collision is for objects that move and can be moved
            component.kind = .dynamic
            // Robust protection applies a more expensiove collision check
            // This helps reduce the chance of an entity passing through a wall
            // Use this option for entites that move with controls or move at higher speeds
            component.options = .robustProtection
            
            // The collider is the primitive shape used for collision checking
            // An ellipsoid is a sphere stretched to fit in a box.
            // This shape is great for characters becuase all sides are smooth allowing it smoothly to glide over surfaces
            component.collider = BoundingEllipsoid3D(offset: Position3(0, 0.5, 0), radius: Size3(0.25, 0.5, 0.25))
        }
        
        // Add the player to the game
        game.insertEntity(player)
        
        // Move the camera up so it's initial position is correct
        // Because the players origin is on the ground the camera is moved up so it's not in the floor
        game.cameraEntity?.position3.move(0.5, toward: .up)
    }
    
    // shouldUpdate() is executed immediatley before update(), and determines if update() is skipped
    override func shouldUpdate(game: Game, input: HID, withTimePassed deltaTime: Float) async -> Bool {
        if input.mouse.mode == .standard {
            if input.mouse.button(.button1).isPressed {
                if input.mouse.position?.y ?? 0 > game.windowManager.mainWindow?.safeAreaInsets.top ?? 0 {
                    // If the mouse is visible and the user clicked the window below the titlebar then hide the mouse.
                    input.mouse.mode = .locked
                }
            }
        }else if input.keyboard.button(.escape)!.isPressed {
            // If the mouse is hidden and the user pressed escape on the keyboard then unhide the mouse
            input.mouse.mode = .standard
        }
        
        // If the mouse is visible don't update this system
        return input.mouse.mode == .locked
    }
    
    // update() is executed every simulation tick, which may or may not be every frame
    override func update(game: Game, input: HID, withTimePassed deltaTime: Float) async {
        
        // Find the player entity
        guard let player = game.entity(named: "Player") else {return}
        
        // Unwrap the player transform
        guard let playerTransform = player.component(ofType: Transform3Component.self) else {return}

        // Update the vertical angle reference from the Mouse
        yAngle += Degrees(input.mouse.deltaPosition.y) * deltaTime * 50
        
        // Update the vertical angle reference from the gamepad
        yAngle -= Degrees(input.gamePads.any.stick.right.yAxis) * deltaTime * 150 * input.gamePads.any.stick.right.pushedAmount
        
        // Lock the vertical angle so the player can't look too far up or down
        if yAngle > 80 {
            yAngle = 80
        }else if yAngle < -80 {
            yAngle = -80
        }
        
        // Update the horizontal angle reference from the Mouse
        xAngle += Degrees(input.mouse.deltaPosition.x) * deltaTime * 40
        
        // Update the horizontal angle reference from the gamepad
        xAngle += Degrees(input.gamePads.any.stick.right.xAxis) * deltaTime * 200 * input.gamePads.any.stick.right.pushedAmount
        
        // .normalize() will lock the angle to 0..< 360 so our Quaternion can always store it
        xAngle.normalize()
        
        // Create a horizontal rotation using our reference angle around the global up axis
        let newPlayerRotation = Quaternion(-xAngle, axis: .up)
        
        // interpolate the rotation so the movement is smooth
        playerTransform.rotation.interpolate(to: newPlayerRotation, .linear(deltaTime * 100))
        
        // Update the camera so it's in the correct position and looking in the correct direction
        await game.cameraEntity?.configure(Transform3Component.self, { cameraTransform in
            
            // Rotate the players roation by our vertical rotation giving us a rotation with both
            let newCameraRotation = playerTransform.rotation * Quaternion(-self.yAngle, axis: .right)
            
            // interpolate the rotation so the movement is smooth
            cameraTransform.rotation.interpolate(to: newCameraRotation, .linear(deltaTime * 100))
            
            // Set the cameras position to 1 unit above the player
            // Becuase the player's origin is the ground and the camera is the "head"
            cameraTransform.position = playerTransform.position.addingTo(y: 1)
        })
        
        // Move the player based on keyboard presses
        if input.keyboard.button("w")!.isPressed || input.keyboard.button(.up)!.isPressed {
            playerTransform.position += Size3(playerTransform.rotation.forward) * deltaTime * 5
        }
        if input.keyboard.button("s")!.isPressed || input.keyboard.button(.down)!.isPressed {
            playerTransform.position += Size3(playerTransform.rotation.backward) * deltaTime * 5
        }
        if input.keyboard.button("a")!.isPressed || input.keyboard.button(.left)!.isPressed {
            playerTransform.position += Size3(playerTransform.rotation.left) * deltaTime * 5
        }
        if input.keyboard.button("d")!.isPressed || input.keyboard.button(.right)!.isPressed {
            playerTransform.position += Size3(playerTransform.rotation.right) * deltaTime * 5
        }
        
        // Move the player based on the gamepad left stick
        let stickRotationRelativeToPlayer = Quaternion(input.gamePads.any.stick.left.direction.angleAroundZ, axis: .up) * playerTransform.rotation
        playerTransform.position += stickRotationRelativeToPlayer.forward * deltaTime * 5 * -input.gamePads.any.stick.left.pushedAmount
    }
    
    // phase determines at which point the system should be updated relative to other systems
    override class var phase: System.Phase {.simulation}
}
