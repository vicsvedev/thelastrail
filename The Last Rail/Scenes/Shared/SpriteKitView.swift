import SpriteKit
import SwiftUI

/// Hosts an SKView in SwiftUI and swaps scenes when the controller's active scene changes.
struct SpriteKitView: UIViewRepresentable {
    let scene: SKScene

    func makeUIView(context: Context) -> SKView {
        let view = SKView()
        view.ignoresSiblingOrder = false
        view.preferredFramesPerSecond = 60
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-TLRShowFPS") {
            view.showsFPS = true
            view.showsNodeCount = true
            view.showsDrawCount = true
        }
        #endif
        view.isMultipleTouchEnabled = true
        view.backgroundColor = .black
        view.presentScene(scene)
        return view
    }

    func updateUIView(_ view: SKView, context: Context) {
        if view.scene !== scene {
            view.presentScene(scene)
        }
    }
}
