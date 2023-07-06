/*
 * Copyright © 2023 Dustin Collins (Strega's Gate)
 * All Rights Reserved.
 *
 * http://stregasgate.com
 */

import GateEngine

@main
final class MultipleWindowsGameDelegate: GameDelegate {
    
    /// didFinishLaunching() is executed immediately after the game is ready to start
    func didFinishLaunching(game: Game, options: LaunchOptions) {
        game.insertSystem(SomeRenderingSystem.self)
    }
    
    /// This GameDelegate func allows you to change the options and style for the main window
    func createMainWindow(game: Game, identifier: String) throws -> Window {
        return try game.windowManager.createWindow(identifier: identifier, style: .bestForGames, options: [])
    }
    
    /// This GameDelegate func allows you to provide a window on platforms where a user can manually create one.
    func userRequestedWindow(game: Game) throws -> Window? {
        let id = userWindowNumber.generateID()
        let window = try game.windowManager.createWindow(identifier: "user\(id)")
        window.title = "User Create Window #\(id)"
        window.clearColor = .lightBlue
        return window
    }
    let userWindowNumber = IDGenerator<UInt>()
    
    
    /// This GameDelegate func allows you to provide a window to an attached display,
    /// such as an AirPlay screen when using mirroring on an iOS device.
    func screenBecomeAvailable(game: Game) throws -> Window? {
        let id = screenWindowNumber.generateID()
        let window = try game.windowManager.createWindow(identifier: "external\(id)")
        window.title = "External Window #\(id)"
        window.clearColor = .lightGreen
        return window
    }
    let screenWindowNumber = IDGenerator<UInt>()
}

// RenderingSystem subclasses can draw content
// However, updating the simulation from a RenderingSystem is a programming error
// GateEngine allows for frame drops and headless execution for servers
// In these cases RenderingSystems do not get updated
class SomeRenderingSystem: RenderingSystem {
    
    override func setup(game: Game) {
        // Windows can only be create in a `RenderingSystem` or a designated `GameDelegate` func.
        let window1 = game.windowManager.mainWindow
        window1?.title = "Main Window"
        window1?.clearColor = .lightRed
        
        do {
            let window2 = try game.windowManager.createWindow(identifier: "window2")
            window2.title = "Programmatic Window #2"
            window2.clearColor = .lightRed
            
            let window3 = try game.windowManager.createWindow(identifier: "window3")
            window3.title = "Programmatic Window #3"
            window3.clearColor = .lightRed
        }catch{
            print(error)
        }
    }
    
    // render() is called only when drawing needs to be done
    override func render(game: Game, window: Window, withTimePassed deltaTime: Float) {
        var canvas = Canvas(window: window, estimatedCommandCount: 2)
        
        // Draw something different in each window
        switch window.identifier {
        case "window2":
            canvas.insert(Rect(0, 0, 100, 100), color: .yellow, at: Position2(window.pointSafeAreaInsets.leading, window.pointSafeAreaInsets.top))
        case "window3":
            canvas.insert(Rect(0, 0, 100, 100), color: .magenta, at: Position2(window.pointSafeAreaInsets.leading, window.pointSafeAreaInsets.top))
        case "external1":
            canvas.insert(Rect(0, 0, 100, 100), color: .purple, at: Position2(window.pointSafeAreaInsets.leading, window.pointSafeAreaInsets.top))
        case "user1":
            canvas.insert(Rect(0, 0, 100, 100), color: .red, at: Position2(window.pointSafeAreaInsets.leading, window.pointSafeAreaInsets.top))
        case "user2":
            canvas.insert(Rect(0, 0, 100, 100), color: .green, at: Position2(window.pointSafeAreaInsets.leading, window.pointSafeAreaInsets.top))
        case "user3":
            canvas.insert(Rect(0, 0, 100, 100), color: .blue, at: Position2(window.pointSafeAreaInsets.leading, window.pointSafeAreaInsets.top))
        default:// Main Window and unhandled windows
            canvas.insert(Rect(0, 0, 100, 100), color: .cyan, at: Position2(window.pointSafeAreaInsets.leading, window.pointSafeAreaInsets.top))
        }
        
        window.insert(canvas)
    }
}
