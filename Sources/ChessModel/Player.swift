import Foundation

public typealias PlayerID = String

public struct Player: Equatable, Codable, Sendable, Identifiable {
    public let id: PlayerID
    public var name: String
    public var imageURL: URL?
    public let pieceColor: PieceColor

    public enum CodingKeys: String, CodingKey {
        case id
        case name
        case imageURL = "imageUrl"
        case pieceColor
    }

    public init(
        id: PlayerID,
        name: String,
        imageURL: URL?,
        pieceColor: PieceColor
    ) {
        self.id = id
        self.name = name
        self.imageURL = imageURL
        self.pieceColor = pieceColor
    }

    public func changePiece(color: PieceColor) -> Player {
        Player(
            id: id,
            name: name,
            imageURL: imageURL,
            pieceColor: color
        )
    }
}
