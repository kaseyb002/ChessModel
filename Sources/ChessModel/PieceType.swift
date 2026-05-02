import Foundation

public enum PieceType: String, Equatable, Codable, Sendable, CaseIterable {
    case king
    case queen
    case rook
    case bishop
    case knight
    case pawn

    public var displayableName: String {
        switch self {
        case .king: "King"
        case .queen: "Queen"
        case .rook: "Rook"
        case .bishop: "Bishop"
        case .knight: "Knight"
        case .pawn: "Pawn"
        }
    }

    public var materialValue: Int {
        switch self {
        case .king: 0
        case .queen: 9
        case .rook: 5
        case .bishop: 3
        case .knight: 3
        case .pawn: 1
        }
    }
}
