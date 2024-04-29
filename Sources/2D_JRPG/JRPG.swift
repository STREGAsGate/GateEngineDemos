/*
 * Copyright © 2023 Dustin Collins (Strega's Gate)
 * All Rights Reserved.
 *
 * http://stregasgate.com
 */

// Sprites and Tiles inspired by Final Fantasy III (NES). Used for educational purposes only.

import Foundation
import GateEngine

@main
final class JRPGGameDelegate: GameDelegate {
    
    // didFinishLaunching() is executed immediatley after the game is ready to start
    func didFinishLaunching(game: Game, options: LaunchOptions) async {
        // Create and add an entity for the player.
        // We name it so we can look it up by name later.
        let player = Entity(name: "Player")
        // Give the player a transform so it can have a location in the world
        player.insert(Transform2Component.self)
        // Give the player a physics component for movement
        player.insert(Physics2DComponent.self)
        // Give the player a state machine so we can control it
        player.insert(StateMachineComponent(
            // Give the state machine a default state, implemented below
            initialState: Player.IdleState.self
        ))
        // Give the player a sprite so we have something to look at
        player.insert(SpriteComponent(
            // the size of a single frame on the sprite sheet
            spriteSize: Size2(16, 16),
            // the sprite sheet to use
            spriteSheet: SpriteSheet(path: "Resources/SpriteSheet.png"),
            // the default animation from the list below (1 is facing down)
            activeAnimationIndex: 1,
            // Give the sprite some animations
            animations: [
                // First row (up)
                SpriteAnimation(startRow: 0, frameCount: 2, duration: 0.25, repeats: true),
                // Second row (down)
                SpriteAnimation(startRow: 1, frameCount: 2, duration: 0.25, repeats: true),
                // Third row (left)
                SpriteAnimation(startRow: 2, frameCount: 2, duration: 0.25, repeats: true),
                // Fourth row (right)
                SpriteAnimation(startRow: 3, frameCount: 2, duration: 0.25, repeats: true),
            ]
        ))
        // Add the player to the game
        game.insertEntity(player)
        // Add the systems used to update the components we just gave the player
        game.insertSystem(SpriteSystem.self)
        game.insertSystem(Physics2DSystem.self)
        game.insertSystem(StateMachineSystem.self)
        
        // Add a tile map system to update the room's tileMap we'll be adding later
        game.insertSystem(TileMapSystem.self)
        // Add our room loading system, implemented below
        game.insertSystem(RoomLoadingSystem(
            area: "AltarCave",
            room: "Room1",
            spawnCoordinate: TileMap.Layer.Coordinate(column: 15, row: 26),
            activeAnimationIndex: 2
        ))
        // Add our custom collision system, implemented below
        game.insertSystem(JRPGCollisionSystem.self)
        // Add our custom rendering system, implemented below
        game.insertSystem(JRPGRenderingSystem.self)
       
        // Set the main window's title.
        game.windowManager.mainWindow?.title = "JRPG"
    }
}

// A component to store triggers. 
// Triggers are things the player steps on.
final class RoomTriggerComponent: Component {
    // Locations for the triggers
    private(set) var coordinates: [TileMap.Layer.Coordinate] = []
    // Actions to run when the trigger is stepped on
    private(set) var actions: [GravityClosure] = []
    
    // A var to store the current player coordinate. We'll use this so we don't
    // repeatedly call the action while the player is standing on the trigger
    var currentPlayerCoordinate: TileMap.Layer.Coordinate = TileMap.Layer.Coordinate(column: -1, row: -1)
    
    // A function to add the trigger and action
    // By using a function we ensure the triggers and actions arrays will always have equal counts
    func appendTrigger(at coordiante: TileMap.Layer.Coordinate, action: GravityClosure) {
        self.coordinates.append(coordiante)
        self.actions.append(action)
    }
    
    static let componentID: ComponentID = ComponentID()
}

// A component to store interactions.
// Interactions are things the player presses the action button in front of.
final class RoomInteractionComponent: Component {
    // Locations for the interaction
    private(set) var coordinates: [TileMap.Layer.Coordinate] = []
    // Actions to run when the player presses a button in front of the interaction
    private(set) var actions: [GravityClosure] = []
    
    // A function to add the interaction location and it's action
    // By using a function we ensure the interactions and actions arrays will always have equal counts
    func appendInteraction(at coordiante: TileMap.Layer.Coordinate, action: GravityClosure) {
        self.coordinates.append(coordiante)
        self.actions.append(action)
    }
    
    static let componentID: ComponentID = ComponentID()
}

// A system to handle trnasitions between rooms
final class RoomLoadingSystem: System {
    // The area being loaded
    let area: String
    // The room being loaded
    let room: String
    // The location to place the player after loading
    let spawnCoordinate: TileMap.Layer.Coordinate
    // The animation to give the player after loading
    // This will change the direction the player is facing
    let activeAnimationIndex: Int
    
    // A variable to track the back curtain the closes of the screen when zoning
    var curtainClosedProgress: Float = 0
    
    // The phases for our loading process
    enum Phase {
        case curtainClosing
        case swapRooms
        case waitForRoomToLoad
        case curtainOpening
        case finished
    }
    // The current phase
    var phase: Phase = .curtainClosing
    
    override func setup(game: Game, input: HID) async {
        // Lookup the player entity by it's name
        let player = game.entity(named: "Player")!
        
        // Remove the StateMachine so the player cannot be controlled while loading
        player.remove(StateMachineComponent.self)
        
        // Stop player animations
        player[SpriteComponent.self].playbackState = .stop
        // Stop player movement
        player[Physics2DComponent.self].velocity = .zero
    }
    
    override func update(game: Game, input: HID, withTimePassed deltaTime: Float) async {
        switch phase {
        case .curtainClosing:
            // Animate the curtain closing
            curtainClosedProgress += deltaTime * 1.5
            if curtainClosedProgress > 1 {
                // When the curtain is closed make sure it's exactly closed
                curtainClosedProgress = 1
                // Switch to the next loading phase
                phase = .swapRooms
            }
        case .swapRooms:
            // Remove the RoomSystem.
            // This will unload the room by calling it's teardown func.
            game.removeSystem(RoomSystem.self)
            // Add a new RoomSystem for the room being loaded
            // Note: Only 1 System of any type can exist in the game at a time.
            game.insertSystem(RoomSystem(area: area, room: room))
            // Look up the player by it's name
            if let player = game.entity(named: "Player") {
                // Move the player to the spawn location
                player.position2 = Position2(
                    x: Float((spawnCoordinate.column * 16) + 8),
                    y: Float((spawnCoordinate.row * 16) + 4)
                )
                // Give the player the spawn animation index
                // This will change which direction the player is facing
                player[SpriteComponent.self].activeAnimationIndex = activeAnimationIndex
            }
            // Move to the next loading phase
            phase = .waitForRoomToLoad
        case .waitForRoomToLoad:
            // Get the room system
            let roomSystem = game.system(ofType: RoomSystem.self)
            // If the RoomSystem is done loading
            if roomSystem.isLoading == false {
                if let player = game.entity(named: "Player") {
                    // Add a new StateMachine so the player can be controlled again
                    // Doing this now will allow the player to move while the curtain is raising
                    player.insert(StateMachineComponent(initialState: Player.IdleState.self))
                }
                phase = .curtainOpening
            }
        case .curtainOpening:
            // Animate the curtain raising
            curtainClosedProgress -= deltaTime * 1.5
            if curtainClosedProgress < 0 {
                // When the curtain is raised ensure it didn't over raise
                // This is mostly done to keep things clean. It won't be used again.
                // But if we ever change anything it will work as expected.
                curtainClosedProgress = 0
                // Move to the next loading phase
                phase = .finished
            }
        case .finished:
            // Remove this system form the game
            game.removeSystem(self)
        }
    }
    
    // A custom initializer with the required information
    init(area: String, room: String, spawnCoordinate: TileMap.Layer.Coordinate, activeAnimationIndex: Int) {
        self.area = area
        self.room = room
        self.spawnCoordinate = spawnCoordinate
        self.activeAnimationIndex = activeAnimationIndex
    }
    
    // Make sure using a blank system init will crash, as we must use our custom init above
    required init() {
        fatalError("init() has not been implemented")
    }

    // Give our system a phase to be sorted into.
    // The updating phase is performed before the simulation making it a good choice for loading.
    override class var phase: System.Phase { .updating }
}

// A system to manage the room
final class RoomSystem: System {
    // The area of this room.
    // Areas are folders in our Resources/Areas/
    let area: String
    // The room.
    // Rooms are folders in our Resources/Areas/[self.area]/
    let room: String
    
    // A scripting instance.
    // This allows us to load and use .gravity scripting files
    let gravity: Gravity = Gravity()
    
    // An entity for this room
    // We'll store it here for easy accesss
    let entity: Entity = Entity()
    
    // A property to prevent the room form doing things before
    // everything is ready to be used
    var isLoading: Bool = true
    
    // A property to remmeber if the gravity script has been run yet
    var didRunScript: Bool = false

    // A custom init to ensure we have the information we need to load the room
    init(area: String, room: String) {
        self.area = area
        self.room = room
    }
    // Crash if we aren't using our custom init above
    required init() {
        fatalError("init() has not been implemented")
    }
    
    override func setup(game: Game, input: HID) async {
        entity.insert(
            // Give the room entity a tileMap
            TileMapComponent(
                // use the area property to load the TileSet
                tileSetPath: "Resources/Areas/\(area)/TileSet.tsj",
                // use the area and room properties to load the TileMap
                tileMapPath: "Resources/Areas/\(area)/\(room)/TileMap.tmj"
            )
        )
        // Give the room our trigger component, implemented above
        entity.insert(RoomTriggerComponent.self)
        // Give the room our interaction component, implemented above
        entity.insert(RoomInteractionComponent.self)
        // Add the room entity to the game
        game.insertEntity(entity)
        
        do {
            // Use the area and room to load and compile the room's script
            try await gravity.compile(file: "Resources/Areas/\(area)/\(room)/Script.gravity")
            
            // Add a Swift closure to our gravity instance.
            // This allows the script to call a function `getPlayerCoordinate()`
            // This function returns a GravityValue
            // In our script we expect the return value to be a List with our coordinates
            // List is like an Array in gravity.
            // In Swift a Array<GravityValue> will be converted to a List
            gravity.setFunc("getPlayerCoordinate") { gravity, args -> GravityValue in
                if let player = game.entity(named: "Player") {
                    return [
                        GravityValue(Int(player.position2.x / 16)),
                        GravityValue(Int(player.position2.y / 16))
                    ]
                }
                return [-1, -1]
            }
            
            // Add a Swift closure to our gravity instance.
            // This allows the script to call a function `setPlayerCoordinate()`
            // This function returns nothing, so we use Void in the Swift closure.
            // `args` contains a List of arguments passed to the function in the script.
            gravity.setFunc("setPlayerCoordinate") { gravity, args -> Void in
                if let player = game.entity(named: "Player") {
                    // Grab the first argument which we expect tobe a List
                    // Convert the list to a Swift.Array<Float>
                    let list = args[0].getList()!.map({$0.asFloat()})
                    // Set the players x position by multiplying the column by the tile size
                    // Add 8 to move the player to the middle of the tile
                    player[Transform2Component.self].position.x = (list[0] * 16) + 8
                    // Set the players y position by multiplying the rom by the tile size
                    // Add 4 to move the player 4 units below the center of the tile
                    // This will make the forced perspective seem more attractive
                    player[Transform2Component.self].position.y = (list[1] * 16) + 4
                }
            }
            
            // Add a Swift closure to our gravity instance.
            // This allows the script to call a function `setPlayerAnimation()`
            // This function returns nothing, so we use Void in the Swift closure.
            // `args` contains a List of arguments passed to the function in the script.
            gravity.setFunc("setPlayerAnimation") { gravity, args -> Void in
                if let player = game.entity(named: "Player") {
                    // Get the first argument which we expect to be a Swift.Int
                    // Set the Int as the players active animation
                    // This will change the direction the player is facing
                    player[SpriteComponent.self].activeAnimationIndex = args[0].getInt()
                }
            }
            
            // Add a Swift closure to our gravity instance.
            // This allows the script to call a function `setPlayerAnimation()`
            // This function returns nothing, so we use Void in the Swift closure.
            // `args` contains a List of arguments passed to the function in the script.
            gravity.setFunc("load") { gravity, args -> Void in
                // We exppect the argument 0 to be the area name
                let area = args[0].asString()
                // We exppect the argument 1 to be the room name
                let room = args[1].asString()
                // We exppect the argument 2 to be a List of Ints
                // Make it a swift array of Ints
                let list = args[2].getList()!.map({$0.asInt()})
                // Create a coordinate from the swift array
                let coordinate = TileMap.Layer.Coordinate(column: list[0], row: list[1])
                // We exppect the argument 3 to be an Int
                let animationIndex = args[3].asInt()
                game.insertSystem(
                    // Add the room loading system which will kick off the loading process
                    RoomLoadingSystem(
                        area: area,
                        room: room,
                        spawnCoordinate: coordinate,
                        activeAnimationIndex: animationIndex
                    )
                )
            }
            
            // Add a Swift closure to our gravity instance.
            // This allows the script to call a function `setPlayerAnimation()`
            // This function returns nothing, so we use Void in the Swift closure.
            // `args` contains a List of arguments passed to the function in the script.
            gravity.setFunc("setTrigger") { gravity, args -> Void in
                // We exppect the argument 0 to be a List of Ints
                // Make it a swift array of Ints
                let list = args[0].getList()!.map({$0.asInt()})
                // Create a coordinate from the swift array
                let coordinate = TileMap.Layer.Coordinate(column: list[0], row: list[1])
                // We exppect the argument 1 to be a GravityClosure
                // This is like a function pointer to the gravity closure
                // We'll give it our gravity instance, and it has no sender
                let closure = args[1].getClosure(gravity: gravity, sender: nil)!
                // Add the trigger to our room's trigger component
                self.entity[RoomTriggerComponent.self].appendTrigger(at: coordinate, action: closure)
            }
            
            // Add a Swift closure to our gravity instance.
            // This allows the script to call a function `setPlayerAnimation()`
            // This function returns nothing, so we use Void in the Swift closure.
            // `args` contains a List of arguments passed to the function in the script.
            gravity.setFunc("setInteraction") { gravity, args -> Void in
                // We exppect the argument 0 to be a List of Ints
                // Make it a swift array of Ints
                let list = args[0].getList()!.map({$0.asInt()})
                // Create a coordinate from the swift array
                let coordinate = TileMap.Layer.Coordinate(column: list[0], row: list[1])
                // We exppect the argument 1 to be a GravityClosure
                // This is like a function pointer to the gravity closure
                // We'll give it our gravity instance, and it has no sender
                let closure = args[1].getClosure(gravity: gravity, sender: nil)!
                // Add the trigger to our room's interaction component
                self.entity[RoomInteractionComponent.self].appendInteraction(at: coordinate, action: closure)
            }
            
            // Add a Swift closure to our gravity instance.
            // This allows the script to call a function `setPlayerAnimation()`
            // This function returns nothing, so we use Void in the Swift closure.
            // `args` contains a List of arguments passed to the function in the script.
            gravity.setFunc("setTile") { gravity, args -> Void in
                // We exppect the argument 0 to be a List of Ints
                // Make it a swift array of Ints
                let list = args[0].getList()!.map({$0.asInt()})
                // Create a coordinate from the swift array
                let coordinate = TileMap.Layer.Coordinate(column: list[0], row: list[1])
                // We exppect the argument 1 to be a Int
                let layer = args[1].asInt()
                // We exppect the argument 2 to be a Int
                let tileID = args[2].asInt()
                // Create a Tile from our ID
                let tile = TileMap.Tile(id: tileID, options: [])
                // Change the TileMap's tile to our new tile
                self.entity[TileMapComponent.self].layers[layer].setTile(tile, at: coordinate)
            }
            
            // Add a Swift closure to our gravity instance.
            // This allows the script to call a function `setPlayerAnimation()`
            // This function returns nothing, so we use Void in the Swift closure.
            // `args` contains a List of arguments passed to the function in the script.
            gravity.setFunc("setTileAnimation") { gravity, args -> Void in
                // We exppect the argument 0 to be a List of Ints
                // Make it a swift array of Ints
                let coordinateList = args[0].getList()!.map({$0.asInt()})
                // Create a coordinate from the swift array
                let coordinate = TileMap.Layer.Coordinate(column: coordinateList[0],
                                                          row: coordinateList[1])
                // We exppect the argument 1 to be a Int
                let layer = args[1].asInt()
                // We exppect the argument 2 to be a List of Ints
                // We'll convert it to a swift array of tilemap tiles
                let tiles = args[2].getList()!.map({
                    TileMap.Tile(id: $0.asInt(), options: [])
                })
                // We exppect the argument 3 to be a Double
                let duration = args[3].asFloat()
                
                // Add the tilemap animation to the rooms tilemap
                self.entity[TileMapComponent.self].layers[layer].animations.append(
                    TileMapComponent.Layer.TileAnimation(
                        coordinate: coordinate,
                        frames: tiles,
                        duration: duration
                    )
                )
            }
        }catch{
            // If there is a Gravity script compile error, print it
            print(error)
        }
    }
    
    override func update(game: Game, input: HID, withTimePassed deltaTime: Float) async {
        // If the room is still loading, check each element until they are all ready
        if self.isLoading {
            guard entity[TileMapComponent.self].tileSet.state == .ready else {return}
            guard entity[TileMapComponent.self].tileSet.texture.state == .ready else {return}
            guard entity[TileMapComponent.self].tileMap.state == .ready else {return}
            self.isLoading = false
            return
        }
        // Our room is done loading, run the script if we need to
        if didRunScript == false {
            didRunScript = true
            do {
                // Every Gravity script has a main function
                // We must run the main function before interacting with any memory in the gravity instance
                // We'll run main now, which occured after TileMapComponenet is fully loaded.
                // This is important because the script might attempt to edit the TileMap
                try gravity.runMain()
            }catch{
                // If execution of the script failed, print the error
                print(error)
            }
        }
        
        // Check to see if the player has stepped on a trigger
        if let tileMap = entity[TileMapComponent.self].tileMap {
            if let player = game.entity(named: "Player") {
                let triggers = entity[RoomTriggerComponent.self]
                if let playerCoordinate = tileMap.layers.first?.coordinate(at: player.position2) {
                    if triggers.currentPlayerCoordinate != playerCoordinate {
                        triggers.currentPlayerCoordinate = playerCoordinate
                        if let index = triggers.coordinates.firstIndex(where: {$0 == playerCoordinate}) {
                            do {
                                // If the player stepped on the trigger, execute the action GravityClosure.
                                // This will run the closure within the gravity script prvided to a call to `setTrigger()`
                                try triggers.actions[index].run()
                            }catch{
                                print(error)
                            }
                        }
                    }
                }
            }
        }
    }

    override func teardown(game: Game) {
        // Remove the room entity from the game
        game.removeEntity(entity)
    }
    
    override class var phase: System.Phase { .simulation }
}

// Create an empty enum to give the player states a namespace
// This will allow us to use `Player.IdleState` which is helpful if you have multiple character states
enum Player {
    // A state for when the character is doing nothing
    final class IdleState: State {
        // apply() is called when the state becomes current
        // This is similar to `setup()` for a System
        func apply(to entity: Entity, previousState: some State, game: Game, input: HID) {
            // Stop animations
            entity[SpriteComponent.self].playbackState = .stop
            // Stop movement
            entity[Physics2DComponent.self].velocity = .zero
        }
        
        func update(for entity: Entity, inGame game: Game, input: HID, withTimePassed deltaTime: Float) {
            // A variable to store if any action input was pressed
            var actionWasPressed = false
            
            // If a keyboard key was pressed change out variable to true
            if input.keyboard.anyKeyIsPressed(in: [.return, .space, "e", .enter(.numberPad)]) {
                actionWasPressed = true
            }
            // If a gamepad button was pressed change out variable to true
            // `confirmButton` is a special button that changes bassed on the gamepad
            // On Xbox controllers it is "A". On playstation it is "X".
            if input.gamePads.any.button.confirmButton.isPressed {
                actionWasPressed = true
            }
            
            if actionWasPressed {
                let room = game.system(ofType: RoomSystem.self).entity
                guard let floorLayer = room[TileMapComponent.self].tileMap?.layers.first else {return}
                guard var coordinate = floorLayer.coordinate(at: entity.position2) else {return}
                switch entity[SpriteComponent.self].activeAnimationIndex {
                case 0:
                    coordinate.row -= 1
                case 1:
                    coordinate.row += 1
                case 2:
                    coordinate.column -= 1
                default:
                    coordinate.column += 1
                }
                // Find an interaction for the tile in front of the player
                if let index = room[RoomInteractionComponent.self].coordinates.firstIndex(where: {$0 == coordinate}) {
                    do {
                        // If an interaction exists, then run it's action GravityClosure.
                        // This will run the closure within the gravity script prvided to a call to `setInteraction()`
                        try room[RoomInteractionComponent.self].actions[index].run()
                    }catch{
                        print(error)
                    }
                }
            }
        }
        
        // possibleNextStates() should return, in order, the states that this state could transition to
        // Each of the retenued states will be asked, in order, if they can become the current state.
        // The first state that canBecomeCurrent() will be transitioned to.
        func possibleNextStates(for entity: Entity, game: Game, input: HID) -> [State.Type] {
            return [WalkState.self]
        }
    }
    
    // A state for when the character is moving
    final class WalkState: State {
        // A variable to reduce the amount of work needed to see if moving to the next state should happen
        var canMoveToNextState = false
        
        // apply() is called when the state becomes current
        // This is similar to `setup()` for a System
        func apply(to entity: Entity, previousState: some State, game: Game, input: HID) {
            // Begin playing animation
            entity[SpriteComponent.self].playbackState = .play
            // Start the animation half way through
            // This will ensure the sharacter immediatley picks up his foot
            // when movement starts
            entity[SpriteComponent.self].activeAnimation?.progress = 0.5
        }
        
        func update(for entity: Entity, inGame game: Game, input: HID, withTimePassed deltaTime: Float) {
            // Check for inputs and move the character in the approproite direction
            if input.keyboard.anyKeyIsPressed(in: ["a", .left]) || input.gamePads.any.dpad.left.isPressed {
                // Use the left facing animation
                entity[SpriteComponent.self].activeAnimationIndex = 2
                // Move the character left
                entity[Physics2DComponent.self].velocity = Size2(Direction2.left) * 0.01
            }else if input.keyboard.anyKeyIsPressed(in: ["d", .right]) || input.gamePads.any.dpad.right.isPressed {
                // Use the right facing animation
                entity[SpriteComponent.self].activeAnimationIndex = 3
                // Move the character right
                entity[Physics2DComponent.self].velocity = Size2(Direction2.right) * 0.01
            }else if input.keyboard.anyKeyIsPressed(in: ["w", .up]) || input.gamePads.any.dpad.up.isPressed {
                // Use the up facing animation
                entity[SpriteComponent.self].activeAnimationIndex = 0
                // Move the character up.
                // We negate the value becuse the top of the screen is the origin, so subtracting will go up.
                entity[Physics2DComponent.self].velocity = Size2(-Direction2.up) * 0.01
            }else if input.keyboard.anyKeyIsPressed(in: ["s", .down]) || input.gamePads.any.dpad.down.isPressed {
                // Use the down facing animation
                entity[SpriteComponent.self].activeAnimationIndex = 1
                // We negate the value becuse the top of the screen is the origin, so subtracting will go down.
                entity[Physics2DComponent.self].velocity = Size2(-Direction2.down) * 0.01
            }else{
                // If no input occured we can move back to the idle state
                canMoveToNextState = true
            }
        }
        
        // canBecomeCurrentState() determines if this state is able to become the current state
        static func canBecomeCurrentState(for entity: Entity, from currentState: some State, game: Game, input: HID) -> Bool {
            // If any input is pressed we can become the current State
            return input.keyboard.anyKeyIsPressed(in: ["w", "s", "a", "d", .up, .down, .left, .right])
            || input.gamePads.any.dpad.isPressed
        }
        
        // canMoveToNextState() determines if this state is ready to be transitioned to the next state
        func canMoveToNextState(for entity: Entity, game: Game, input: HID) -> Bool {
            // If no input occured we can move back to the idle state
            return canMoveToNextState
        }
        
        // possibleNextStates() should return, in order, the states that this state could transition to
        // Each of the retenued states will be asked, in order, if they can become the current state.
        // The first state that canBecomeCurrent() will be transitioned to.
        func possibleNextStates(for entity: Entity, game: Game, input: HID) -> [State.Type] {
            return [IdleState.self]
        }
    }
}

// A custom collision system for our game
final class JRPGCollisionSystem: System {
    // A finite amount of colliders we'll use to check if we're hitting any tiles
    // Well change these each time we want to check for collisions.
    var tileColliders: [AxisAlignedBoundingBox2D] = Array(repeating: AxisAlignedBoundingBox2D(radius: Size2(8)), count: 6)
    // A collider to use for any character. We'll change this each time we want to check for a collision.
    var playerCollider: BoundingEllipsoid2D = BoundingEllipsoid2D(offset: Position2(0,4), radius: Size2(8, 4))
    // A collection of points we'll put around the character to find tiles we might collide with
    var tileLocators: [Position2] = []
    
    override func update(game: Game, input: HID, withTimePassed deltaTime: Float) async {
        // Look up the rooms TileMapComponent. There's only ever 1 so weill grab the first one we find.
        guard let tileMapComponent = game.firstEntity(withComponent: TileMapComponent.self)?[TileMapComponent.self] else {return}
        // Make sure the tile map is ready to be used
        guard tileMapComponent.tileMap.state == .ready else {return}
        // Grab the first layer of our tile map. This is the floor layer and the only one we can collide with.
        guard let floorLayer = tileMapComponent.layers.first else {return}
        // Look up our player by name
        guard let player = game.entity(named: "Player") else {return}
        
        // Move the players collider to where the player currently is
        playerCollider.center = player.position2
        
        // Loop through ever tileCollider
        for index in tileColliders.indices {
            // Move the collider off the map
            // This will prevent stale colliders from being in the wrong location
            tileColliders[index].center = Position2(-32, -32)
        }

        // Use the playerCollider to create piints moved 2 units outward.
        // This creates positions at each corner of the box, but moved away from it's center by 2 units
        let points = playerCollider.boundingBox.points(insetBy: -Size2(2))
        // Store the tile locators so we can use them in rendering later
        tileLocators = [
            // Add the point generated by the collider
            points[0],
            // Add an adiditional point between the top 2 positions
            // This is necessary because the points are more then a tile width apart
            // If we don't do this then a tile could exist between these points and not be found
            (points[0] + points[1]) / 2,
            // Add the point generated by the collider
            points[1],
            // Add the point generated by the collider
            points[2],
            // Add an adiditional point between the bottom 2 positions
            // This is necessary because the points are more then a tile width apart
            // If we don't do this then a tile could exist between these points and not be found
            (points[2] + points[3]) / 2,
            // Add the point generated by the collider
            points[3],
        ]

        // A variable to store the tiles we have already located
        var usedCoordinates: Set<TileMap.Layer.Coordinate> = []
        usedCoordinates.reserveCapacity(6)
        
        // Loop through all our tile locator positions
        for index in tileLocators.indices {
            // Get the tile coordinate at the current tile locator's position
            guard let tileCoordinate = floorLayer.coordinate(at: tileLocators[index]) else {continue}
            // If we've already located this tile, skip it
            guard usedCoordinates.contains(tileCoordinate) == false else {continue}
            // Get the tile identifier, this is 0 based so it's also an index
            let tileIndex = floorLayer.tileAtCoordinate(tileCoordinate).id
            // Make sure a tile exists. A -1 tile id is an empty tile
            guard tileIndex > -1 else {continue}
            // Check the tile map for a solid property that is true
            // We added these properties when creating the TileSet using the open source Tiled.app
            if tileMapComponent.tileSet.tiles[tileIndex].properties["solid"] == "true" {
                // Get the rectangle for the tile
                let rect = floorLayer.rectForTileAt(tileCoordinate)
                // Update our tileCollider for this tile to have the correct location
                tileColliders[usedCoordinates.count].center = rect.center
                // Update our tileCollider for this tile to have the correct radius
                tileColliders[usedCoordinates.count].radius = rect.size * 0.5
                // Add this tile to our usedCoordinates so we don't check it again
                usedCoordinates.insert(tileCoordinate)
            }
        }
        
        // Loop through all our tileColliders
        for tileCollider in tileColliders {
            // Check if the tile collider is intersecting the player
            if let interpenetration = playerCollider.interpenetration(comparing: tileCollider), interpenetration.isColiding {
                // Move the playerCollider out of the tileCollider
                // The interpenetration.depth is a value indicating how far into tileCollider the playerCollider is
                // We'll negate it to move the playerCollider away from the tileCollider
                // The interpenetration.direction is the direction playerCollider would naturally move to get out of the tileCollider
                playerCollider.center.move(-interpenetration.depth, toward: interpenetration.direction)
                // Update the player location to match the collision changes we just did
                player.position2.move(-interpenetration.depth, toward: interpenetration.direction)
            }
        }
    }
    
    override class var phase: System.Phase { .simulation }
    override nonisolated class func sortOrder() -> SystemSortOrder? {
        // Update this system after physics have updated.
        // The player moves with physics so this will allow collision to update after.
        // This will prevent the renderer from drawing the player inside of a block for a
        // frame before pushing it back out
        return .after(Physics2DSystem.self)
    }
}

final class JRPGRenderingSystem: RenderingSystem {
    // A render target that will allow us to draw at a specific resolution
    lazy var renderTarget = RenderTarget()
    
    override func render(game: Game, window: Window, withTimePassed deltaTime: Float) {
        // Resize the render target to be 240 high and with a width to match the windows's aspect ratio
        var width = 240 * window.size.aspectRatio
        width -= width.truncatingRemainder(dividingBy: 2)
        renderTarget.size = Size2(width: width, height: 240)
        
        // Get the room entity
        guard let room = game.firstEntity(withComponent: TileMapComponent.self) else {return}
        // Get the room's tile map compoenent
        guard let tileMapComponent = room.component(ofType: TileMapComponent.self) else {return}
        // make sure the tileSet is ready
        guard tileMapComponent.tileSet.state == .ready else {return}
        // make sure the tileMap is ready
        guard tileMapComponent.tileMap.state == .ready else {return}
        
        // Create a canvas
        var canvas = Canvas(estimatedCommandCount: 15)
        
        // Set the canvas's view origin.
        // This will move the "camera" of the canvas
        canvas.setViewOrigin({
            guard let player = game.entity(named: "Player") else {return .zero}
            var position = player.position2 - (renderTarget.size / 2)
            let tileMapPixelSize = tileMapComponent.tileMap.size * tileMapComponent.tileSet.tileSize
            
            // Prevent the camera from moving off the map
            if position.y < 0 { position.y = 0 }
            if position.x < 0 { position.x = 0 }
            if position.x + renderTarget.size.width > tileMapPixelSize.width {
                position.x = tileMapPixelSize.width - renderTarget.size.width
            }
            if position.y + renderTarget.size.height > tileMapPixelSize.height {
                position.y = tileMapPixelSize.height - renderTarget.size.height
            }
            
            // Center the map on screen if it's smaller then the screen
            if renderTarget.size.width > tileMapPixelSize.width {
                position.x = -(renderTarget.size.width - tileMapPixelSize.width) / 2
            }
            if renderTarget.size.height > tileMapPixelSize.height {
                position.y = -(renderTarget.size.height - tileMapPixelSize.height) / 2
            }
            
            // Make sure the camera is always on a pixel edge
            return floor(position)
        }())
        
        // A variable to make drawing multiple layers more efficiency
        var roomIsMultiLayer = false
        
        // Create a material for the tileMap
        let material = Material(texture: tileMapComponent.tileSet.texture)
        if let layer = tileMapComponent.layers.first {
            // Add the layers geometry to the canvas
            canvas.insert(layer.geometry, withMaterial: material, at: .zero)
            if tileMapComponent.layers.count > 1 {
                // make a note of additional layers
                roomIsMultiLayer = true
            }
        }
        
        // Loop through all the entites in the game
        for entity in game.entities {
            // if the entity has a transform
            if let transform = entity.component(ofType: Transform2Component.self) {
                // if the entity has a sprite
                if let spriteComponent = entity.component(ofType: SpriteComponent.self) {
                    // get the current sprite
                    if let sprite = spriteComponent.sprite() {
                        // Add the sprite to the canvas at the entites position
                        canvas.insert(sprite, at: transform.position, depth: spriteComponent.depth)
                    }
                }
                
                // When debugging, draw the colliders
                #if DEBUG
                // Get the collision system
                let collisionSystem = game.system(ofType: JRPGCollisionSystem.self)
                // Loop through each tile collider
                for tileCollider in collisionSystem.tileColliders {
                    // Add a rect to the canvas representing the tile collider
                    canvas.insert(
                        tileCollider.rect,
                        color: .lightRed,
                        at: .zero,
                        opacity: 0.6
                    )
                }
                // Get the player collider
                let playerCollider = collisionSystem.playerCollider.boundingBox
                // Add a rect to the canvas representing the player collider
                canvas.insert(
                    playerCollider.rect,
                    color: .white,
                    at: .zero,
                    opacity: 0.5
                )
                // Loop through each tile locator
                for tileLocator in collisionSystem.tileLocators {
                    canvas.insert(
                        Rect(size: Size2(2), center: tileLocator),
                        color: .green,
                        at: .zero
                    )
                }
                #endif
            }
        }
        
        // If we need to draw additional tilemap layers
        if roomIsMultiLayer {
            // Loop through any additional layers
            // We exclude the floor which we already added to the canvas
            for layer in tileMapComponent.layers[1...] {
                // Add the layers geometry to the canvas
                canvas.insert(layer.geometry, withMaterial: material, at: .zero)
            }
        }
        
        // Add the canvas to the render target
        renderTarget.insert(canvas)
        // Add the render target to the window
        window.insert(renderTarget)
        
        // If the game has a RoomLoadingSystem, then we must be loading a room
        if game.hasSystem(ofType: RoomLoadingSystem.self) {
            // Create a new interface scaled canvas with the window
            var canvas = Canvas(window: window)
            // Get the curtain animation progress
            let curtainProgress = game.system(ofType: RoomLoadingSystem.self).curtainClosedProgress
            // Create a rect for half the curtain
            let rect = Rect(position: .zero, size: Size2(window.pointSize.width, (window.pointSize.height / 2) * curtainProgress))

            // A the curtain rect to the canvas at the top of the screen
            canvas.insert(rect, color: .black, at: .zero)
            // A the curtain rect to the canvas at the bottom of the screen
            canvas.insert(rect, color: .black, at: Position2(0, window.pointSize.height - rect.height))
            // Add the canvas to the window
            window.insert(canvas)
        }
    }
}
