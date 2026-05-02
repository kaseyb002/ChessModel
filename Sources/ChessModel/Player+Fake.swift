import Foundation

extension Player {
    public static func fake(
        id: PlayerID = UUID().uuidString,
        name: String = "Fake Player",
        imageURL: URL? = nil,
        pieceColor: PieceColor = .white
    ) -> Self {
        Player(
            id: id,
            name: name,
            imageURL: imageURL,
            pieceColor: pieceColor
        )
    }
}
