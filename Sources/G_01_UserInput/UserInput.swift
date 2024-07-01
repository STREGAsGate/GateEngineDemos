/*
 * Copyright © 2023-2024 Dustin Collins (Strega's Gate)
 * All Rights Reserved.
 *
 * http://stregasgate.com
 */

import GateEngine

@main
final class UserInputGameDelegate: GameDelegate {
    
    // didFinishLaunching() is executed immediatley after the game is ready to start
    func didFinishLaunching(game: Game, options: LaunchOptions) {
        
        // Add our projects sytem which is implemented below
        game.insertSystem(UserInputSystem.self)
        
        // Add the projects rendering system to the game which implementation is below
        game.insertSystem(TextRenderingSystem.self)
        
        // Set the main window's title
        game.windowManager.mainWindow?.title = "User Input"
    }
}

// We need a component to store some text to draw
// Creating Text is an async process, and it wont necessarily be renderable instantly
// We must store it in a component so the Text has a chance to load.
// Passing it directly to Canvas will likely cause it to deallocate before it is ever shown on screen
final class TextComponent: Component {
    
    // Text is a renderable object that hold a string and associated meta like font, pointSize, and color
    @MainActor
    let text = Text(string: "Press Something...", pointSize: 64, color: .white)
    
    // All components require a componentID. For performance reasons make it a let.
    // ComponentID has single init() so we'll always just create a new one with no options.
    static let componentID: ComponentID = ComponentID()
}

// System subclasses are used to manipulate the simulation. They can't be used to draw content.
class UserInputSystem: System {
    
    // This value stores Input states and is used to check when an input has changed
    var inputReceipts = InputReceipts()
    
    // setup() is executed a single time when the System is added to the game
    override func setup(game: Game, input: HID) async {
        
        // Create an entity
        let entity = Entity()
        
        // Give the entity the TextComponent we made
        entity.insert(TextComponent.self)
        
        // Add the entity to the game
        game.insertEntity(entity)
    }
    
    // update() is executed every simulation tick, which may or may not be every frame
    override func update(game: Game, input: HID, withTimePassed deltaTime: Float) async {
        
        // Get the entity from the game
        if let entity = game.firstEntity(withComponent: TextComponent.self) {
            
            // Unwrap the TextComponent
            entity.modify(TextComponent.self) { [self] component in
                
                // MARK: - Gamepads
                
                // The "any" gamepad will return the most recently used gamepad.
                // Use this for single user games so the user can swap controllers seamlessly.
                // isPressed(ifDifferent:) will return true if the button is currently down but was previously up
                input.gamePads.any.button.north.whenPressed(ifDifferent: &inputReceipts) { button in
                    
                    // the symbol property will return the platform button for the physical gamepad
                    // For example on DualShock south is .cross, and on Xbox south is .A
                    // Symbols for console gamepads are guaranteed, otherwise GateEngine will guess
                    // based on the host OS and the physical gampad's manufacturer name
                    component.text.string += "\n\(button.symbol) pressed!"
                }
                input.gamePads.any.button.south.whenPressed(ifDifferent: &inputReceipts) { button in
                    component.text.string += "\n\(button.symbol) pressed!"
                }
                input.gamePads.any.button.east.whenPressed(ifDifferent: &inputReceipts) { button in
                    component.text.string += "\n\(button.symbol) pressed!"
                }
                input.gamePads.any.button.west.whenPressed(ifDifferent: &inputReceipts) { button in
                    component.text.string += "\n\(button.symbol) pressed!"
                }
                
                if input.gamePads.any.stick.right.isPushed {
                    component.text.string += String(format: "\nR-Stick Pushed x: %.3f, y: %.3f", input.gamePads.any.stick.right.xAxis, input.gamePads.any.stick.right.yAxis)
                }
                if input.gamePads.any.stick.left.isPushed {
                    component.text.string += String(format: "\nL-Stick Pushed x: %.3f, y: %.3f", input.gamePads.any.stick.left.xAxis, input.gamePads.any.stick.left.yAxis)
                }

                if input.gamePads.any.trigger.left.isPressed {
                    component.text.string += String(format: "\nL-Trigger Pressed %.3f", input.gamePads.any.trigger.left.value)
                }
                if input.gamePads.any.trigger.right.isPressed {
                    component.text.string += String(format: "\nR-Trigger Pressed %.3f", input.gamePads.any.trigger.right.value)
                }
                
                // MARK: - Keyboard
                
                // Keyboard checks work similar to gamepad buttons, see above
                if input.keyboard.button(.azerty("z")).isPressed(ifDifferent: &inputReceipts) {
                    component.text.string += "\nW pressed!"
                }else if input.keyboard.button("s").isPressed(ifDifferent: &inputReceipts) {
                    component.text.string += "\nS pressed!"
                }else if input.keyboard.button("a").isPressed(ifDifferent: &inputReceipts) {
                    component.text.string += "\nA pressed!"
                }else if input.keyboard.button("d").isPressed(ifDifferent: &inputReceipts) {
                    component.text.string += "\nD pressed!"
                }else if let button = input.keyboard.pressedButtons().first?.button {
                    button.whenPressed(ifDifferent: &inputReceipts) { button in
                        component.text.string += "\n\(button) pressed!"
                    }
                }
                
                // MARK: - Mouse
                
                // Mouse buttons work similar to gamepad buttons, see above
                input.mouse.button(.button1).whenPressed(ifDifferent: &inputReceipts) { button in
                    component.text.string += String(format: "\nPrimary Click (%i) at x: %.0f, y: %.0f", button.pressCount,
                                                                                                        input.mouse.position!.x,
                                                                                                        input.mouse.position!.y)
                }
                input.mouse.button(.button2).whenPressed(ifDifferent: &inputReceipts) { button in
                    component.text.string += String(format: "\nSecondary Click (%i) at x: %.0f, y: %.0f", button.pressCount,
                                                                                                          input.mouse.position!.x,
                                                                                                          input.mouse.position!.y)
                }
                input.mouse.button(.button3).whenPressed(ifDifferent: &inputReceipts) { button in
                    component.text.string += String(format: "\nMiddle Click (%i) at x: %.0f, y: %.0f", button.pressCount,
                                                                                                       input.mouse.position!.x,
                                                                                                       input.mouse.position!.y)
                }
                input.mouse.button(.button4).whenPressed(ifDifferent: &inputReceipts) { button in
                    component.text.string += String(format: "\nButton 4 Click (%i) at x: %.0f, y: %.0f", button.pressCount,
                                                                                                         input.mouse.position!.x,
                                                                                                         input.mouse.position!.y)
                }
                input.mouse.button(.button5).whenPressed(ifDifferent: &inputReceipts) { button in
                    component.text.string += String(format: "\nButton 5 Click (%i) at x: %.0f, y: %.0f", button.pressCount,
                                                                                                         input.mouse.position!.x,
                                                                                                         input.mouse.position!.y)
                }
                
                input.mouse.scroller(.horizontal).whenScrolled(ifDifferent: &inputReceipts) { scroller in
                    let direction = (scroller.direction == .positive) ? "Right" : "Left"
                    component.text.string += String(format: "\nScrolled %i (%@) Delta: %.3f, UI Delta: %.3f", scroller.ticks, direction, scroller.delta, scroller.uiDelta)
                }
                input.mouse.scroller(.vertical).whenScrolled(ifDifferent: &inputReceipts) { scroller in
                    let direction = (scroller.direction == .positive) ? "Up" : "Down"
                    component.text.string += String(format: "\nScrolled %i (%@) Delta: %.3f, UI Delta: %.3f", scroller.ticks, direction, scroller.delta, scroller.uiDelta)
                }
                
                // MARK: - Touch
                
                // Touches can be on screen, indirect such as a trackpad or gamepad. Use the Touch.kind property to ensure you treat the touch appropriatley
                // as the user will expect certain things like screens to be pixel perfect and trackpads to be relative.
                // A Touch.phase is valid for this update only. The .up phase is available exactly once before the Touch is removed, so be sure to check the phase every frame.
                if let touch = input.screen.touches.first(where: {$0.phase == .up}) {
                    component.text.string += String(format: "\nScreen Touch Up at x: %.3f, y: %.3f", touch.position.x, touch.position.y)
                }
                
                if let touch = input.surfaces.any?.touches.first(where: {$0.phase == .up}) {
                    component.text.string += String(format: "\nSurface Touch Up at x: %.3f, y: %.3f", touch.position.x, touch.position.y)
                }
                
                var components = component.text.string.components(separatedBy: "\n")
                while components.count > 5 {
                    components.remove(at: 0)
                }
                component.text.string = components.joined(separator: "\n")
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
class TextRenderingSystem: RenderingSystem {

    // render() is called only when drawing needs to be done
    override func render(game: Game, window: Window, withTimePassed deltaTime: Float) {
        
        // A Canvas is a drawing container for 2D objects
        // Canvas is light weight and you're meant to create a new one every frame
        var canvas = Canvas()
        
        // Loop through all entites in the game
        for entity in game.entities {
            
            // Make sure the entity has a TextComponent, otherwise move on
            guard let text = entity.component(ofType: TextComponent.self)?.text else {continue}
            
            // Create a Rect the size of the window and get it's center
            let windowCenter = Rect(size: window.size).center
            
            // Half of the rendered text size
            let halfTextSize = text.size / 2
            
            // Subtract half the text size from the window center
            // to get a position that will center the text
            let position = windowCenter - halfTextSize
            
            // Add the text to the canvas at our centerd position
            canvas.insert(text, at: position)
        }
        
        // Add the canvas to the framebuffer to be drawn
        window.insert(canvas)
    }
}
