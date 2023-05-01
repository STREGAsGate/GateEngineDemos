/*
 * Copyright © 2023 Dustin Collins (Strega's Gate)
 * All Rights Reserved.
 *
 * http://stregasgate.com
 */

// Sprite by https://gold356.itch.io/earh-rotating-32-x-32

import GateEngine

@main
final class RotatingCubeGameDelegate: GameDelegate {
    
    // didFinishLaunching() is executed immediatley after the game is ready to start
    func didFinishLaunching(game: Game, options: LaunchOptions) {

        // Add the engine provided SpriteSystem so our sprites get updated
        game.insertSystem(SpriteSystem.self)
        
        // Add our projects sytem which is implemented below
        game.insertSystem(AnimatedSpriteSystem.self)
        
        // Add the projects rendering system to the game which implementation is below
        game.insertSystem(AnimatedSpriteRenderingSystem.self)
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
class AnimatedSpriteSystem: System {
    
    // setup() is executed a single time when the System is added to the game
    override func setup(game: Game) {
        
        // Create an entity with a name so we can easily find it later
        // Ideally you would find an entity based on it's components
        // But this entity wont have uniqly identifying components, so we'll name it
        let entity = Entity(name: "Spinning Earth")
        
        // Unwrap a SpriteComponent
        entity.configure(SpriteComponent.self) { component in
            // set the size of the sprite relative to the native texture size
            component.spriteSize = Size2(width: 32, height: 32)
            
            // load the SpriteSheet from a png file
            component.spriteSheet = SpriteSheet(path: "Resources/Earth rotating 32 x 32.png")
            
            // create an animation that plays at 60fps,
            // we could also create the animation with an explicit duration
            component.animations = [SpriteAnimation(frameCount: 30, frameRate: 60)]
        }
        
        // Add the entity to the game
        game.insertEntity(entity)
    }
    
    // update() is executed every simulation tick, which may or may not be every frame
    override func update(game: Game, input: HID, layout: WindowLayout, withTimePassed deltaTime: Float) {
        
        // Get the sprite we named from the game
        if let entity = game.entity(named: "Spinning Earth") {
            
            // Unwrap a Transform2Component
            entity.configure(Transform2Component.self) { component in
                
                // the center of our custom resolution renderTarget
                let halfVerticalHeight: Float = 144 / 2
                
                // determine the horizontal position using the aspect ratio of the window
                component.position.x = halfVerticalHeight * layout.windowSize.aspectRatio
                
                // we chose the vertical resoluton so we know where vertical center is
                component.position.y = halfVerticalHeight
            }
        }
    }
    
    override class var phase: System.Phase {.simulation}
}

// RenderingSystem subclasses can draw content
// However, updating the simulation from a RenderingSystem is a programming error
// GateEngine allows for frame drops and headless execution for servers
// In these cases RenderingSystems do not get updated
class AnimatedSpriteRenderingSystem: RenderingSystem {
    
    // The window framebuffer cannot be resized, so we'll create a low resolution RenderTarget
    // and draw out sprite into that then draw that into the window
    let renderTarget = RenderTarget()
    
    // render() is called only wehn drawing needs to be done
    override func render(game: Game, framebuffer: RenderTarget, layout: WindowLayout, withTimePassed deltaTime: Float) {
        
        // We'll set the framebuffer to GameBoy resolution and use the windows aspect ratio to get an appropriate width
        renderTarget.size = Size2(144 * layout.windowSize.aspectRatio, 144)
        
        // A Canvas is a draw container for 2D renderable objects
        var canvas = Canvas()
        
        for entity in game.entities {
            // Make sure the entity has a SpriteComponent, otherwise move on
            guard let spriteComponent = entity.component(ofType: SpriteComponent.self) else {continue}
            // Make sure the entity has a Transform2Component, otherwise move on
            guard let transform2Component = entity.component(ofType: Transform2Component.self) else {continue}
            
            // Ask the spriteComponent for the current Sprite
            if let sprite = spriteComponent.sprite() {
                
                // Add the sprite to the canvas at it's transform
                canvas.insert(sprite, at: transform2Component.position)
            }
        }
        
        // Draw the canvas into our renderTarget
        renderTarget.insert(canvas)
        
        // Draw the renderTarget into the window, sampling nearest so it's not blurry
        framebuffer.insert(renderTarget, sampleFilter: .nearest)
    }
}
