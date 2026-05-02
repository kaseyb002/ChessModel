import Foundation

public enum PieceColor: String, Equatable, Codable, Sendable, CaseIterable {
    case white
    case black

    public var opposite: PieceColor {
        switch self {
        case .white: .black
        case .black: .white
        }
    }

    public var displayableName: String {
        switch self {
        case .white: "White"
        case .black: "Black"
        }
    }

    public var emoji: String {
        switch self {
        case .white: "⬜"
        case .black: "⬛"
        }
    }
}
