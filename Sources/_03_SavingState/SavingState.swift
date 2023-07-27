/*
 * Copyright © 2023 Dustin Collins (Strega's Gate)
 * All Rights Reserved.
 *
 * http://stregasgate.com
 */

import GateEngine

/**
 This example allows a user to change the window color by clicking anywhere in the window.
 The color is saved and will be restored after quitting and launching the example again.
 */

@main
final class SavingStateGameDelegate: GameDelegate {
    
    /// didFinishLaunching() is executed immediatley after the game is ready to start
    func didFinishLaunching(game: Game, options: LaunchOptions) {
        
        /// Add our system to process changes, implemented below
        game.insertSystem(ChangeBackgroundColorSystem.self)
        
        /// Add the engine provided StandardRenderingSystem
        game.insertSystem(StandardRenderingSystem.self)
        
        /// Set the main window's title
        game.windowManager.mainWindow?.title = "Saving State"
    }
}

/// System subclasses are used to manipulate the simulation. They can't be used to draw content.
class ChangeBackgroundColorSystem: System {
    
    /// This value stores Input states and is used to check when an input has changed
    var receipts = InputReceipts()
    
    /// setup() is executed a single time when the System is added to the game
    override func setup(game: Game, input: HID) async {
        do {
            /// Get the color that was saved previously if it exists
            if let restoredColor = try game.state.decode(Color.self, forKey: "mainWindowColor") {
                
                /// Give the window the restored color
                game.windowManager.mainWindow?.clearColor = restoredColor
            }
        }catch{
            /// Handle state restore failures
            print(error)
        }
    }
    
    /// update() is executed every simulation tick, which may or may not be every frame
    override func update(game: Game, input: HID, withTimePassed deltaTime: Float) async {
        
        /// A function to generate a different color then the one we are using
        func newColor() -> Color {
            let possibleColors: [Color] = [.red, .lightRed, .green, .lightGreen, .blue, .lightBlue, .orange, .yellow, .magenta]
            var newColor: Color = possibleColors.randomElement()!
            while newColor == game.windowManager.mainWindow?.clearColor {
                /// The color is the same as what ewe're using, so select a different color
                newColor = possibleColors.randomElement()!
            }
            return newColor
        }
        
        /// When the user clicks the window change it's color and save it
        input.mouse.button(.primary).whenPressed(ifDifferent: &receipts) { button in
            /// Get a new color
            let color = newColor()
            
            /// Set the window background to the new color
            game.windowManager.mainWindow?.clearColor = color
            
            do {
                /// Add the new color to the state
                try game.state.encode(color, forKey: "mainWindowColor")
                
                Task {
                    do {
                        /// Save the state so it's available when we next launch
                        try await game.state.save()
                    }catch{
                        print(error)
                    }
                }
            }catch{
                /// Handle state save failures
                print(error)
            }
        }
    }
}
