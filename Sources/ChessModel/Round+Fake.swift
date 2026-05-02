import Foundation

extension Round {
    public static func fake(
        players: [Player] = [Player.fake(), Player.fake()]
    ) -> Self {
        Round(players: players)
    }
}

extension Round.MoveAction {
    public static func fake(
        playerId: PlayerID = "fakePlayer",
        from: Position = Position(row: 6, column: 4),
        to: Position = Position(row: 4, column: 4),
        capturedPosition: Position? = nil,
        promotion: PieceType? = nil,
        isCastling: Bool = false,
        isCheck: Bool = false,
        timestamp: Date = .now,
        isForced: Bool = false
    ) -> Self {
        Round.MoveAction(
            playerId: playerId,
            from: from,
            to: to,
            capturedPosition: capturedPosition,
            promotion: promotion,
            isCastling: isCastling,
            isCheck: isCheck,
            timestamp: timestamp,
            isForced: isForced
        )
    }
}
