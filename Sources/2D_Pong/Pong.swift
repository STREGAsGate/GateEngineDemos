/*
 * Copyright © 2023-2024 Dustin Collins (Strega's Gate)
 * All Rights Reserved.
 *
 * http://stregasgate.com
 */

// Pong is trademark and/or registered trademark.
// Use of the word Pong is for reference purposes only.

/*
 This example shows one of many ways this game could be created.
 
 Due to the nature and simplicity of this particular game,
 we will break the best practices for an Entity Component System.
 
 In particular we will store entites as global variables so we don't have
 to look them up constantly. For most games this would be a mistake, however since
 these entites will never be removed, and are always used, it will actually help us.
 
 Remember; there is no right or wrong way to make your games.
 */


import Foundation
import GateEngine

// The half-size of the ball
let ballRadius: Float = 8
// The half size of the player objects
let paddleRadius: Size2 = Size2(8, 96)
// The distance from the edge of the screen to place player objects
let paddleScreenEdgeMargin: Float = 16

// The ball entity
let ball    = Entity(components: [Transform2Component.self, Collision2DComponent.self, Physics2DComponent.self])
// The player entity
let paddle1 = Entity(components: [Transform2Component.self, Collision2DComponent.self, Physics2DComponent.self])
// The computer/AI entity
let paddle2 = Entity(components: [Transform2Component.self, Collision2DComponent.self, Physics2DComponent.self])

// A variable to keep track of the score
var score: [UInt] = [0, 0]

@main
final class PongGameDelegate: GameDelegate {
    
    // didFinishLaunching() is executed immediatley after the game is ready to start
    func didFinishLaunching(game: Game, options: LaunchOptions) async {
        
        // Give the ball a primitive collider
        ball[Collision2DComponent.self].collider = AxisAlignedBoundingBox2D(radius: Size2(ballRadius))
        // Add the ball to the game
        game.insertEntity(ball)
        
        // Give the player a primitive collider
        paddle1[Collision2DComponent.self].collider = AxisAlignedBoundingBox2D(radius: paddleRadius)
        // Add the player to the game
        game.insertEntity(paddle1)
        
        // Give the computer/AI a primitive collider
        paddle2[Collision2DComponent.self].collider = AxisAlignedBoundingBox2D(radius: paddleRadius)
        // Reduce how quickly the computer/AI can start moving
        paddle2[Physics2DComponent.self].acceleration = 0.8
        // Reduce how quickly the computer/AI can stop
        paddle2[Physics2DComponent.self].deceleration = 0.8
        // Add the computer/AI to the game
        game.insertEntity(paddle2)
        
        // Add a system toi manage the intermediate stage between rounds, implemented below
        game.insertSystem(PongRoundSetupSystem.self)
        
        // Add our project rendering system, implemented below
        game.insertSystem(PongRenderingSystem.self)
        
        // Add the built-in physics and collision systems for 2D
        game.insertSystem(Physics2DSystem.self)
        game.insertSystem(Collision2DSystem.self)
        
        // Set the main window's title.
        game.windowManager.mainWindow?.title = "Pong-ie: The Original Virtual Table Tennis Clone"
    }
}

final class PongRoundSetupSystem: System {
    override func setup(game: Game, input: HID) async {
        // Set the balls velocity to zero every time a round is setup
        ball[Physics2DComponent.self].velocity = .zero
    }
    
    override func update(game: Game, input: HID, withTimePassed deltaTime: Float) async {
        // Create a rectangle representing the screen area. We're using native UI scaling so we use pointSize.
        // Native UI scaling ensures the game will be scaled correctly on high density displays.
        let screenRect = Rect(size: game.windowManager.mainWindow?.pointSize ?? Size2(640, 480))
        
        // Set the player start position
        paddle1.position2.x = screenRect.minX + paddleScreenEdgeMargin
        paddle1.position2.y = screenRect.center.y
        
        // Set the computer/AI start position
        paddle2.position2.x = screenRect.maxX - paddleScreenEdgeMargin
        paddle2.position2.y = screenRect.center.y
        
        // Place the ball in the middle of the screen
        ball.position2 = screenRect.center
        
        // Wait until the player "serves" the ball by clicking or pressing space bar
        if input.keyboard.pressedButtons().isEmpty == false || input.mouse.button(.button1).isPressed {
            // Give the ball a starting velocity
            ball[Physics2DComponent.self].velocity = Size2(Direction2.up.interpolated(to: Direction2.right, .linear(0.5))) * 0.05
            // Remove this sytem for the game
            game.removeSystem(self)
            // Add our projects game logic system, implemented below
            game.insertSystem(PongGameLogicSystem.self)
        }
    }
    
    override class var phase: System.Phase { .updating }
}

final class PongGameLogicSystem: System {

    override func update(game: Game, input: HID, withTimePassed deltaTime: Float) async {
        let screenRect = Rect(size: game.windowManager.mainWindow?.pointSize ?? Size2(640, 480))
        
        // Make sure the paddles stay on their respective sides of the screen
        // If the window shape changes these will ensure the game is still layed out properly
        paddle1.position2.x = screenRect.minX + paddleScreenEdgeMargin
        paddle2.position2.x = screenRect.maxX - paddleScreenEdgeMargin
        
        // Simulate the ball, implemented below
        updateBall(screenRect: screenRect, deltaTime: deltaTime)
        // Simulate the computer/AI, implemented below
        updateAI(screenRect: screenRect, deltaTime: deltaTime)
        // Update the player based on user input, implemented below
        updatePlayer(input: input, screenRect: screenRect, deltaTime: deltaTime)
        
        // Check if the player scored
        if player1DidScore(screenRect: screenRect) {
            // Increment the players score
            score[0] += 1
            // Begine the next round, implemented below
            beginNextRound(game: game)
        }
        // Check if the compuer/AI scored
        if player2DidScore(screenRect: screenRect) {
            // Increment the computer/AIs score
            score[1] += 1
            // Begine the next round, implemented below
            beginNextRound(game: game)
        }
    }
    
    func beginNextRound(game: Game) {
        // Remove this system from the game
        game.removeSystem(self)
        // Add the round setup syetm, implemented above
        game.insertSystem(PongRoundSetupSystem.self)
    }
    
    func player1DidScore(screenRect: Rect) -> Bool {
        // If the ball move outside the screen it's a point
        // We allow the ball to move an extra 100 units to add
        // drama by allowing the user to realize a point was earned
        // before continuing to the next round
        return ball.position2.x > screenRect.maxX + 100
    }
    func player2DidScore(screenRect: Rect) -> Bool {
        // If the ball move outside the screen it's a point
        // We allow the ball to move an extra 100 units to add
        // drama by allowing the user to realize a point was earned
        // before continuing to the next round
        return ball.position2.x < screenRect.x - 100
    }
    
    func updateBall(screenRect: Rect, deltaTime: Float) {
        let ballPhysics = ball[Physics2DComponent.self]
        let direction = Direction2(ballPhysics.velocity)
        
        // If the ball is moving toward the top of the screen and passes outside the screen
        if ballPhysics.velocity.y < 0 && ball.position2.y < screenRect.y + ballRadius {
            // Bound the ball off a virtual surface pointed down
            ballPhysics.velocity = Size2(direction.reflected(off: .down))
        }
        // If the ball is moving toward the bottom of the screen and passes outside the screen
        if ballPhysics.velocity.y > 0 && ball.position2.y > screenRect.maxY - ballRadius {
            // Bound the ball off a virtual surface pointed up
            ballPhysics.velocity = Size2(direction.reflected(off: .up))
        }
        
        let ballCollider = ball[Collision2DComponent.self].collider
        
        let p1Collider = paddle1[Collision2DComponent.self].collider
        // If the ball intersects the player
        if let interpenetration = p1Collider.interpenetration(comparing: ballCollider), interpenetration.isColiding {
            // Move the ball back outside of the paddle so it never appears inside the paddle on screen
            ball.position2.move(-interpenetration.depth, toward: interpenetration.direction)
            // Bounce the ball of collision checks surface noraml, which represents the side of the paddle that was hit
            ballPhysics.velocity = Size2(direction.reflected(off: interpenetration.direction))
        }
        
        let p2Collider = paddle2[Collision2DComponent.self].collider
        // If the ball intersects the comouter/AI
        if let interpenetration = p2Collider.interpenetration(comparing: ballCollider), interpenetration.isColiding {
            // Move the ball back outside of the paddle so it never appears inside the paddle on screen
            ball.position2.move(-interpenetration.depth, toward: interpenetration.direction)
            // Bounce the ball of collision checks surface noraml, which represents the side of the paddle that was hit
            ballPhysics.velocity = Size2(direction.reflected(off: interpenetration.direction))
        }
    }
    
    func updateAI(screenRect: Rect, deltaTime: Float) {
        let aiPhysics = paddle2[Physics2DComponent.self]
        let ballPhysics = ball[Physics2DComponent.self]
        
        // If the ball is moving toward the AI/computer AND is passed mid court
        if ballPhysics.velocity.x > 0 && ball.position2.x > screenRect.center.x {
            // Make sure the computer/AI does not travel off the bottom of the screen
            if paddle2.position2.y > screenRect.maxY - paddleRadius.height {
                paddle2.position2.y = screenRect.maxY - paddleRadius.height
            }
            if paddle2.position2.y < screenRect.minY + paddleRadius.height {
                paddle2.position2.y = screenRect.minY + paddleRadius.height
            }
            
            // Move the paddle toward the ball
            if ball.position2.y - ballRadius > paddle2.position2.y - paddleRadius.width {
                aiPhysics.velocity = Size2(Direction2.up) * 0.02
            }
            if ball.position2.y + ballRadius < paddle2.position2.y + paddleRadius.width {
                aiPhysics.velocity = Size2(Direction2.down) * 0.02
            }
        }else{
            // Set the computer/AIs velocity to zero so it's no longer moving with physics
            aiPhysics.velocity = .zero
            // Slowly move the paddle to mid-court as mid-court is an optimal position between vollies
            paddle2.position2.y.interpolate(to: screenRect.center.y, .linear(deltaTime))
        }
    }
    
    func updatePlayer(input: HID, screenRect: Rect, deltaTime: Float) {
        let playerPhysics = paddle1[Physics2DComponent.self]
        
        // If a mouse cursor is present
        if let mouse = input.mouse.interfacePosition {
            
            // Move the paddle toward the mouse cursor
            if paddle1.position2.y > mouse.y {
                playerPhysics.velocity = Size2(Direction2.down) * 0.02
            }else{
                playerPhysics.velocity = Size2(Direction2.up) * 0.02
            }
        }
    }
    
    override class var phase: System.Phase { .simulation }
    override class func sortOrder() -> SystemSortOrder? { .after(Physics2DSystem.self) }
}

final class PongRenderingSystem: RenderingSystem {
    // Create some text to show scores
    let player1Score = Text(string: "0", font: .micro, pointSize: 100, color: .red, sampleFilter: .nearest)
    let player2Score = Text(string: "0", font: .micro, pointSize: 100, color: .blue, sampleFilter: .nearest)
    
    // Generate a dotted line to represent the "net"
    let midCourtLine: Points = {
        var points = RawPoints()
        for index in stride(from: 0, through: 2048, by: 16) {
            points.insert(Position2(0, Float(index)), color: .lightGreen)
        }
        return Points(points)
    }()
    
    override func render(game: Game, window: Window, withTimePassed deltaTime: Float) {
        // Update the scroe text with the scores
        player1Score.string = "\(score[0])"
        player2Score.string = "\(score[1])"
        
        // Create a canvas using the window, which give a native UI scaling canvas
        var canvas = Canvas(window: window)
        
        // Add the scores to the canvas
        canvas.insert(player1Score, at: Position2((window.pointSize.width / 2) - (player1Score.size.width / 2) - 100, paddleScreenEdgeMargin), opacity: 0.5)
        canvas.insert(player2Score, at: Position2((window.pointSize.width / 2) + 100, paddleScreenEdgeMargin), opacity: 0.5)
        
        // Add the "net" to the canvas
        canvas.insert(midCourtLine, pointSize: 8, at: Position2(window.pointSize.width / 2, 0))
        
        // Draw the players and ball last so they appear ontop of the text and "net"
        for entity in game.entities {
            
            // Grab the collider from the entity if there is one
            if let aabb = entity.component(ofType: Collision2DComponent.self)?.collider.boundingBox {
                
                // Use the colliders rect function to create a rect representing the collider
                // We add it to the canvas at zero becuase the rect already has the correct position
                canvas.insert(aabb.rect, color: .white, at: .zero)
            }
        }
        
        // Add the canvas to the window
        window.insert(canvas)
    }
}
