import Foundation

extension Round {
    public mutating func performMove(
        _ move: Move,
        isForced: Bool = false
    ) throws {
        guard case .waitingForPlayer(let currentId) = state else {
            throw ChessError.gameAlreadyComplete
        }
        let currentColor: PieceColor = playerColor(for: currentId)
        let availableMoves: [Move] = legalMoves(for: currentColor)
        guard availableMoves.contains(move) else {
            throw ChessError.invalidMove
        }

        let result: MoveResult = executeMove(move, color: currentColor)

        let opponentColor: PieceColor = currentColor.opposite
        let opponentInCheck: Bool = isInCheck(color: opponentColor)

        log.append(
            MoveAction(
                playerId: currentId,
                from: move.from,
                to: move.to,
                capturedPosition: result.capturedPosition,
                promotion: move.promotion,
                isCastling: result.isCastling,
                isCheck: opponentInCheck,
                timestamp: .now,
                isForced: isForced
            )
        )
        trimLog()
        advanceTurn(currentPlayerId: currentId)
    }

    mutating func performMoveUnchecked(_ move: Move) {
        guard case .waitingForPlayer(let currentId) = state else { return }
        let currentColor: PieceColor = playerColor(for: currentId)
        let _: MoveResult = executeMove(move, color: currentColor)
        advanceTurn(currentPlayerId: currentId)
    }

    private mutating func executeMove(
        _ move: Move, color: PieceColor
    ) -> MoveResult {
        var capturedPosition: Position? = nil
        var isCastling: Bool = false

        guard let piece: Piece = board[move.from.row][move.from.column] else {
            return MoveResult(capturedPosition: nil, isCastling: false)
        }

        if piece.type == .pawn,
           let epTarget: Position = enPassantTarget,
           move.to == epTarget
        {
            let capturedRow: Int = move.from.row
            let capturedCol: Int = move.to.column
            board[capturedRow][capturedCol] = nil
            capturedPosition = Position(row: capturedRow, column: capturedCol)
        }

        if board[move.to.row][move.to.column] != nil {
            capturedPosition = move.to
        }

        if piece.type == .king && abs(move.to.column - move.from.column) == 2 {
            isCastling = true
            let isKingside: Bool = move.to.column > move.from.column
            let rookFromCol: Int = isKingside ? 7 : 0
            let rookToCol: Int = isKingside ? 5 : 3
            let row: Int = move.from.row
            if let rook: Piece = board[row][rookFromCol] {
                board[row][rookToCol] = rook.moved()
                board[row][rookFromCol] = nil
            }
        }

        board[move.to.row][move.to.column] = piece.moved()
        board[move.from.row][move.from.column] = nil

        if let promotionType: PieceType = move.promotion, piece.type == .pawn {
            board[move.to.row][move.to.column] = piece.promoted(to: promotionType)
        }

        if piece.type == .pawn && abs(move.to.row - move.from.row) == 2 {
            let epRow: Int = (move.from.row + move.to.row) / 2
            enPassantTarget = Position(row: epRow, column: move.from.column)
        } else {
            enPassantTarget = nil
        }

        if piece.type == .pawn || capturedPosition != nil {
            halfMoveClock = 0
        } else {
            halfMoveClock += 1
        }

        return MoveResult(capturedPosition: capturedPosition, isCastling: isCastling)
    }

    private mutating func advanceTurn(currentPlayerId: PlayerID) {
        let opponentId: PlayerID = opponentPlayerId(for: currentPlayerId)
        let opponentColor: PieceColor = playerColor(for: opponentId)

        if hasLegalMoves(for: opponentColor) == false {
            if isInCheck(color: opponentColor) {
                state = .complete(winningPlayerId: currentPlayerId)
            } else {
                state = .draw
            }
            completed = .now
        } else if halfMoveClock >= 100 {
            state = .draw
            completed = .now
        } else if isInsufficientMaterial() {
            state = .draw
            completed = .now
        } else {
            state = .waitingForPlayer(id: opponentId)
        }
    }

    private mutating func trimLog() {
        if log.count > Self.maxLogActions {
            log.removeFirst(log.count - Self.maxLogActions)
        }
    }
}

private struct MoveResult {
    let capturedPosition: Position?
    let isCastling: Bool
}
