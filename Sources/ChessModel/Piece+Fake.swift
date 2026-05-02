import Foundation

extension Piece {
    public static func fake(
        color: PieceColor = .white,
        type: PieceType = .pawn,
        hasMoved: Bool = false
    ) -> Self {
        Piece(color: color, type: type, hasMoved: hasMoved)
    }
}
