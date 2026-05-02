import Foundation

extension Player {
    public static func aiPlayer(
        id: PlayerID = UUID().uuidString,
        name: String = "AI Player",
        difficulty: AIDifficulty,
        pieceColor: PieceColor
    ) -> AIPlayer {
        AIPlayer(
            id: id,
            name: name,
            imageURL: nil,
            pieceColor: pieceColor,
            difficulty: difficulty
        )
    }
}

public struct AIPlayer: Equatable, Codable, Sendable, Identifiable {
    public let id: PlayerID
    public var name: String
    public var imageURL: URL?
    public let pieceColor: PieceColor
    public let difficulty: AIDifficulty

    public enum CodingKeys: String, CodingKey {
        case id
        case name
        case imageURL = "imageUrl"
        case pieceColor
        case difficulty
    }

    public init(
        id: PlayerID,
        name: String,
        imageURL: URL?,
        pieceColor: PieceColor,
        difficulty: AIDifficulty
    ) {
        self.id = id
        self.name = name
        self.imageURL = imageURL
        self.pieceColor = pieceColor
        self.difficulty = difficulty
    }

    public func changePiece(color: PieceColor) -> AIPlayer {
        AIPlayer(
            id: id,
            name: name,
            imageURL: imageURL,
            pieceColor: color,
            difficulty: difficulty
        )
    }

    public func makeMove(in round: Round) -> Move? {
        let ai: AIEngine = AIEngine(difficulty: difficulty)
        return ai.getBestMove(for: round, playerId: id)
    }
}

extension AIPlayer {
    public var asPlayer: Player {
        Player(
            id: id,
            name: name,
            imageURL: imageURL,
            pieceColor: pieceColor
        )
    }
}
