import Foundation

public struct Move: Equatable, Codable, Sendable {
    public let from: Position
    public let to: Position
    public let promotion: PieceType?

    public init(from: Position, to: Position, promotion: PieceType? = nil) {
        self.from = from
        self.to = to
        self.promotion = promotion
    }
}
