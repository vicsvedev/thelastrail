import SpriteKit

enum Facing: Int {
    case down, up, left, right
}

/// The player character, authored as ASCII pixel art (16×16).
enum CharacterSprites {
    private static let headDown = [
        "................",
        "......kkkk......",
        ".....knnnnk.....",
        "....knnnnnnk....",
        "....knssssnk....",
        "....ksksskSk....",
        "....kssssssk....",
        ".....kyyyyk.....",
    ]
    private static let headUp = [
        "................",
        "......kkkk......",
        ".....knnnnk.....",
        "....knnnnnnk....",
        "....knnnnnnk....",
        "....knNnnNnk....",
        "....kNnnnnNk....",
        ".....kyyyyk.....",
    ]
    private static let headSide = [
        "................",
        "......kkkk......",
        ".....knnnnk.....",
        "....knnnnnnk....",
        "....knnnsssk....",
        "....knnsskSk....",
        ".....kssssk.....",
        ".....kyyyk......",
    ]
    private static let bodyFront = [
        "....krryyrrk....",
        "...krrrrrrrRk...",
        "...ksrrrrrrRsk..",
        "...kskRrrrRksk..",
        "....kBBBBBBk....",
    ]
    private static let bodyBack = [
        "....krrrrrrk....",
        "...krrRrrRrrk...",
        "...ksrrrrrrrsk..",
        "...kskRrrrRksk..",
        "....kBBBBBBk....",
    ]
    private static let bodySide = [
        ".....krrrrk.....",
        "....krrrrrRk....",
        "....krrrsrRk....",
        "....kRrrskRk....",
        ".....kBBBBk.....",
    ]
    private static let legsFront: [[String]] = [
        ["....kBBkkBBk....", "....kBk..kBk....", "....kNk..kNk...."],
        ["....kBBkkBBk....", "....kBk..kNk....", "....kNk.........."],
        ["....kBBkkBBk....", "....kNk..kBk....", ".........kNk...."],
    ]
    private static let legsSide: [[String]] = [
        [".....kBBBk......", ".....kBkBk......", ".....kNkNk......"],
        [".....kBBBk......", "....kBk.kBk.....", "....kNk..kNk...."],
        [".....kBBBk......", ".....kBBk.......", ".....kNNk......."],
    ]

    private static var cache: [String: SKTexture] = [:]

    static func texture(_ facing: Facing, frame: Int) -> SKTexture {
        let f = frame % 3
        let key = "\(facing.rawValue)-\(f)"
        if let t = cache[key] { return t }
        let c = PixelCanvas(16, 16)
        switch facing {
        case .down:
            c.stamp(headDown); c.stamp(bodyFront, at: 0, 8); c.stamp(legsFront[f], at: 0, 13)
        case .up:
            c.stamp(headUp); c.stamp(bodyBack, at: 0, 8); c.stamp(legsFront[f], at: 0, 13)
        case .left, .right:
            let flip = facing == .left
            c.stamp(headSide, flipX: flip); c.stamp(bodySide, at: 0, 8, flipX: flip); c.stamp(legsSide[f], at: 0, 13, flipX: flip)
        }
        let t = c.texture()
        cache[key] = t
        return t
    }

    /// Bigger portrait-style figure for the side-view train scene (8×14 silhouette with lantern glow).
    static func smallSide() -> SKTexture {
        if let t = cache["small"] { return t }
        let c = PixelCanvas(8, 14)
        c.stamp([
            "..kkk...",
            ".knnnk..",
            ".kssSk..",
            "..kyk...",
            ".krrrk..",
            "krrrrrk.",
            "ksrrrsk.",
            ".kRrRk..",
            ".kBBBk..",
            ".kBkBk..",
            ".kBkBk..",
            ".kBkBk..",
            ".kNkNk..",
            "........",
        ])
        let t = c.texture()
        cache["small"] = t
        return t
    }
}
