import Foundation

public struct Position: Hashable, Codable, Sendable {
    public let row: Int
    public let column: Int

    public init(row: Int, column: Int) {
        self.row = row
        self.column = column
    }

    public var isDarkSquare: Bool {
        (row + column) % 2 == 1
    }

    public var algebraicNotation: String {
        let file: Character = Character(UnicodeScalar(97 + column)!)
        let rank: Int = 8 - row
        return "\(file)\(rank)"
    }
}
