import Foundation

// MARK: - Board helpers

extension Round {
    static func isValidPosition(_ position: Position) -> Bool {
        position.row >= 0 && position.row < boardSize
            && position.column >= 0 && position.column < boardSize
    }

    static func isSquareAttackedOnBoard(
        _ position: Position,
        by attackerColor: PieceColor,
        board: [[Piece?]]
    ) -> Bool {
        let pawnRow: Int = attackerColor == .white ? position.row + 1 : position.row - 1
        for dc in [-1, 1] {
            let pc: Int = position.column + dc
            let pos: Position = Position(row: pawnRow, column: pc)
            if isValidPosition(pos),
               let piece: Piece = board[pawnRow][pc],
               piece.color == attackerColor && piece.type == .pawn
            {
                return true
            }
        }

        let knightOffsets: [(Int, Int)] = [
            (-2, -1), (-2, 1), (-1, -2), (-1, 2),
            (1, -2), (1, 2), (2, -1), (2, 1),
        ]
        for (dr, dc) in knightOffsets {
            let pos: Position = Position(row: position.row + dr, column: position.column + dc)
            if isValidPosition(pos),
               let piece: Piece = board[pos.row][pos.column],
               piece.color == attackerColor && piece.type == .knight
            {
                return true
            }
        }

        let diagonalDirs: [(Int, Int)] = [(-1, -1), (-1, 1), (1, -1), (1, 1)]
        for (dr, dc) in diagonalDirs {
            var r: Int = position.row + dr
            var c: Int = position.column + dc
            while isValidPosition(Position(row: r, column: c)) {
                if let piece: Piece = board[r][c] {
                    if piece.color == attackerColor
                        && (piece.type == .bishop || piece.type == .queen)
                    {
                        return true
                    }
                    break
                }
                r += dr
                c += dc
            }
        }

        let straightDirs: [(Int, Int)] = [(-1, 0), (1, 0), (0, -1), (0, 1)]
        for (dr, dc) in straightDirs {
            var r: Int = position.row + dr
            var c: Int = position.column + dc
            while isValidPosition(Position(row: r, column: c)) {
                if let piece: Piece = board[r][c] {
                    if piece.color == attackerColor
                        && (piece.type == .rook || piece.type == .queen)
                    {
                        return true
                    }
                    break
                }
                r += dr
                c += dc
            }
        }

        let kingDirs: [(Int, Int)] = [
            (-1, -1), (-1, 0), (-1, 1),
            (0, -1), (0, 1),
            (1, -1), (1, 0), (1, 1),
        ]
        for (dr, dc) in kingDirs {
            let pos: Position = Position(row: position.row + dr, column: position.column + dc)
            if isValidPosition(pos),
               let piece: Piece = board[pos.row][pos.column],
               piece.color == attackerColor && piece.type == .king
            {
                return true
            }
        }

        return false
    }

    func isSquareAttacked(_ position: Position, by attackerColor: PieceColor) -> Bool {
        Self.isSquareAttackedOnBoard(position, by: attackerColor, board: board)
    }
}

// MARK: - Player helpers

extension Round {
    public func playerColor(for playerId: PlayerID) -> PieceColor {
        players.first(where: { $0.id == playerId })!.pieceColor
    }

    func opponentPlayerId(for playerId: PlayerID) -> PlayerID {
        players.first(where: { $0.id != playerId })!.id
    }

    public func player(byID id: PlayerID) -> Player? {
        players.first(where: { $0.id == id })
    }

    public func isPlayersTurn(playerID: PlayerID) -> Bool {
        switch state {
        case .waitingForPlayer(let id):
            return playerID == id
        case .complete, .draw:
            return false
        }
    }

    public var currentPlayer: Player? {
        switch state {
        case .complete, .draw:
            nil
        case .waitingForPlayer(let playerID):
            player(byID: playerID)
        }
    }
}

// MARK: - Check detection

extension Round {
    public func findKing(color: PieceColor) -> Position? {
        for row in 0..<Self.boardSize {
            for col in 0..<Self.boardSize {
                if let piece: Piece = board[row][col],
                   piece.color == color && piece.type == .king
                {
                    return Position(row: row, column: col)
                }
            }
        }
        return nil
    }

    public func isInCheck(color: PieceColor) -> Bool {
        guard let kingPos: Position = findKing(color: color) else { return false }
        return isSquareAttacked(kingPos, by: color.opposite)
    }

    func wouldBeInCheckAfterMove(_ move: Move, color: PieceColor) -> Bool {
        var testBoard: [[Piece?]] = board
        guard let piece: Piece = testBoard[move.from.row][move.from.column] else { return true }

        if piece.type == .pawn,
           let epTarget: Position = enPassantTarget,
           move.to == epTarget
        {
            testBoard[move.from.row][move.to.column] = nil
        }

        if piece.type == .king && abs(move.to.column - move.from.column) == 2 {
            let isKingside: Bool = move.to.column > move.from.column
            let rookFromCol: Int = isKingside ? 7 : 0
            let rookToCol: Int = isKingside ? 5 : 3
            testBoard[move.from.row][rookToCol] = testBoard[move.from.row][rookFromCol]
            testBoard[move.from.row][rookFromCol] = nil
        }

        testBoard[move.to.row][move.to.column] = testBoard[move.from.row][move.from.column]
        testBoard[move.from.row][move.from.column] = nil

        var kingPos: Position? = nil
        for row in 0..<Self.boardSize {
            for col in 0..<Self.boardSize {
                if let p: Piece = testBoard[row][col],
                   p.color == color && p.type == .king
                {
                    kingPos = Position(row: row, column: col)
                    break
                }
            }
            if kingPos != nil { break }
        }
        guard let kp: Position = kingPos else { return true }
        return Self.isSquareAttackedOnBoard(kp, by: color.opposite, board: testBoard)
    }
}

// MARK: - Legal moves

extension Round {
    public func legalMoves(for color: PieceColor) -> [Move] {
        let pseudo: [Move] = pseudoLegalMoves(for: color)
        return pseudo.filter { wouldBeInCheckAfterMove($0, color: color) == false }
    }

    func hasLegalMoves(for color: PieceColor) -> Bool {
        let pseudo: [Move] = pseudoLegalMoves(for: color)
        for move in pseudo {
            if wouldBeInCheckAfterMove(move, color: color) == false {
                return true
            }
        }
        return false
    }

    func pseudoLegalMoves(for color: PieceColor) -> [Move] {
        var moves: [Move] = []
        for row in 0..<Self.boardSize {
            for col in 0..<Self.boardSize {
                guard let piece: Piece = board[row][col], piece.color == color else { continue }
                let pos: Position = Position(row: row, column: col)
                switch piece.type {
                case .pawn:
                    moves.append(contentsOf: pawnMoves(from: pos, piece: piece))
                case .knight:
                    moves.append(contentsOf: knightMoves(from: pos, piece: piece))
                case .bishop:
                    moves.append(contentsOf: slidingMoves(from: pos, piece: piece, directions: Self.diagonalDirections))
                case .rook:
                    moves.append(contentsOf: slidingMoves(from: pos, piece: piece, directions: Self.straightDirections))
                case .queen:
                    moves.append(contentsOf: slidingMoves(from: pos, piece: piece, directions: Self.allDirections))
                case .king:
                    moves.append(contentsOf: kingMoves(from: pos, piece: piece))
                }
            }
        }
        return moves
    }
}

// MARK: - Move generation helpers

extension Round {
    static let diagonalDirections: [(Int, Int)] = [(-1, -1), (-1, 1), (1, -1), (1, 1)]
    static let straightDirections: [(Int, Int)] = [(-1, 0), (1, 0), (0, -1), (0, 1)]
    static let allDirections: [(Int, Int)] = diagonalDirections + straightDirections

    private func pawnMoves(from pos: Position, piece: Piece) -> [Move] {
        var moves: [Move] = []
        let direction: Int = piece.color == .white ? -1 : 1
        let startRow: Int = piece.color == .white ? 6 : 1
        let promotionRow: Int = piece.color == .white ? 0 : 7

        let oneForward: Position = Position(row: pos.row + direction, column: pos.column)
        if Self.isValidPosition(oneForward) && board[oneForward.row][oneForward.column] == nil {
            if oneForward.row == promotionRow {
                for promoType in [PieceType.queen, .rook, .bishop, .knight] {
                    moves.append(Move(from: pos, to: oneForward, promotion: promoType))
                }
            } else {
                moves.append(Move(from: pos, to: oneForward))
            }

            if pos.row == startRow {
                let twoForward: Position = Position(row: pos.row + 2 * direction, column: pos.column)
                if board[twoForward.row][twoForward.column] == nil {
                    moves.append(Move(from: pos, to: twoForward))
                }
            }
        }

        for dc in [-1, 1] {
            let capturePos: Position = Position(row: pos.row + direction, column: pos.column + dc)
            guard Self.isValidPosition(capturePos) else { continue }

            let isCapture: Bool = {
                if let target: Piece = board[capturePos.row][capturePos.column],
                   target.color != piece.color
                {
                    return true
                }
                return false
            }()

            let isEnPassant: Bool = (enPassantTarget == capturePos)

            if isCapture || isEnPassant {
                if capturePos.row == promotionRow {
                    for promoType in [PieceType.queen, .rook, .bishop, .knight] {
                        moves.append(Move(from: pos, to: capturePos, promotion: promoType))
                    }
                } else {
                    moves.append(Move(from: pos, to: capturePos))
                }
            }
        }

        return moves
    }

    private func knightMoves(from pos: Position, piece: Piece) -> [Move] {
        var moves: [Move] = []
        let offsets: [(Int, Int)] = [
            (-2, -1), (-2, 1), (-1, -2), (-1, 2),
            (1, -2), (1, 2), (2, -1), (2, 1),
        ]
        for (dr, dc) in offsets {
            let target: Position = Position(row: pos.row + dr, column: pos.column + dc)
            guard Self.isValidPosition(target) else { continue }
            if let targetPiece: Piece = board[target.row][target.column] {
                if targetPiece.color != piece.color {
                    moves.append(Move(from: pos, to: target))
                }
            } else {
                moves.append(Move(from: pos, to: target))
            }
        }
        return moves
    }

    private func slidingMoves(
        from pos: Position,
        piece: Piece,
        directions: [(Int, Int)]
    ) -> [Move] {
        var moves: [Move] = []
        for (dr, dc) in directions {
            var r: Int = pos.row + dr
            var c: Int = pos.column + dc
            while Self.isValidPosition(Position(row: r, column: c)) {
                if let targetPiece: Piece = board[r][c] {
                    if targetPiece.color != piece.color {
                        moves.append(Move(from: pos, to: Position(row: r, column: c)))
                    }
                    break
                }
                moves.append(Move(from: pos, to: Position(row: r, column: c)))
                r += dr
                c += dc
            }
        }
        return moves
    }

    private func kingMoves(from pos: Position, piece: Piece) -> [Move] {
        var moves: [Move] = []
        let offsets: [(Int, Int)] = [
            (-1, -1), (-1, 0), (-1, 1),
            (0, -1), (0, 1),
            (1, -1), (1, 0), (1, 1),
        ]
        for (dr, dc) in offsets {
            let target: Position = Position(row: pos.row + dr, column: pos.column + dc)
            guard Self.isValidPosition(target) else { continue }
            if let targetPiece: Piece = board[target.row][target.column] {
                if targetPiece.color != piece.color {
                    moves.append(Move(from: pos, to: target))
                }
            } else {
                moves.append(Move(from: pos, to: target))
            }
        }

        if piece.hasMoved == false && isInCheck(color: piece.color) == false {
            if let rook: Piece = board[pos.row][7],
               rook.type == .rook && rook.color == piece.color && rook.hasMoved == false
            {
                let pathClear: Bool = board[pos.row][5] == nil && board[pos.row][6] == nil
                if pathClear {
                    let passThrough: Position = Position(row: pos.row, column: 5)
                    let landing: Position = Position(row: pos.row, column: 6)
                    if isSquareAttacked(passThrough, by: piece.color.opposite) == false
                        && isSquareAttacked(landing, by: piece.color.opposite) == false
                    {
                        moves.append(Move(from: pos, to: landing))
                    }
                }
            }

            if let rook: Piece = board[pos.row][0],
               rook.type == .rook && rook.color == piece.color && rook.hasMoved == false
            {
                let pathClear: Bool = board[pos.row][1] == nil
                    && board[pos.row][2] == nil
                    && board[pos.row][3] == nil
                if pathClear {
                    let passThrough: Position = Position(row: pos.row, column: 3)
                    let landing: Position = Position(row: pos.row, column: 2)
                    if isSquareAttacked(passThrough, by: piece.color.opposite) == false
                        && isSquareAttacked(landing, by: piece.color.opposite) == false
                    {
                        moves.append(Move(from: pos, to: landing))
                    }
                }
            }
        }

        return moves
    }
}

// MARK: - Piece counting

extension Round {
    public func pieceCount(for color: PieceColor) -> Int {
        var count: Int = 0
        for row in board {
            for cell in row {
                if let piece: Piece = cell, piece.color == color {
                    count += 1
                }
            }
        }
        return count
    }

    public func materialValue(for color: PieceColor) -> Int {
        var value: Int = 0
        for row in board {
            for cell in row {
                if let piece: Piece = cell, piece.color == color {
                    value += piece.type.materialValue
                }
            }
        }
        return value
    }

    func isInsufficientMaterial() -> Bool {
        var whitePieces: [Piece] = []
        var blackPieces: [Piece] = []
        for row in board {
            for cell in row {
                if let piece: Piece = cell {
                    if piece.color == .white {
                        whitePieces.append(piece)
                    } else {
                        blackPieces.append(piece)
                    }
                }
            }
        }

        if whitePieces.count == 1 && blackPieces.count == 1 { return true }

        if whitePieces.count == 2 && blackPieces.count == 1 {
            if whitePieces.contains(where: { $0.type == .bishop || $0.type == .knight }) {
                return true
            }
        }
        if blackPieces.count == 2 && whitePieces.count == 1 {
            if blackPieces.contains(where: { $0.type == .bishop || $0.type == .knight }) {
                return true
            }
        }

        return false
    }
}

// MARK: - State extensions

extension Round.State {
    public var isComplete: Bool {
        switch self {
        case .complete, .draw:
            return true
        case .waitingForPlayer:
            return false
        }
    }
}
