import Foundation

public struct Piece: Equatable, Codable, Sendable {
    public let color: PieceColor
    public let type: PieceType
    public let hasMoved: Bool

    public init(color: PieceColor, type: PieceType, hasMoved: Bool = false) {
        self.color = color
        self.type = type
        self.hasMoved = hasMoved
    }

    public func moved() -> Piece {
        Piece(color: color, type: type, hasMoved: true)
    }

    public func promoted(to newType: PieceType) -> Piece {
        Piece(color: color, type: newType, hasMoved: true)
    }

    public var emoji: String {
        switch (color, type) {
        case (.white, .king): "♔"
        case (.white, .queen): "♕"
        case (.white, .rook): "♖"
        case (.white, .bishop): "♗"
        case (.white, .knight): "♘"
        case (.white, .pawn): "♙"
        case (.black, .king): "♚"
        case (.black, .queen): "♛"
        case (.black, .rook): "♜"
        case (.black, .bishop): "♝"
        case (.black, .knight): "♞"
        case (.black, .pawn): "♟"
        }
    }
}
