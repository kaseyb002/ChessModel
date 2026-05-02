import Foundation

public enum AIDifficulty: String, CaseIterable, Codable, Sendable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
}

public struct AIEngine: Sendable {
    private let difficulty: AIDifficulty
    private let maxDepth: Int

    public init(difficulty: AIDifficulty) {
        self.difficulty = difficulty
        switch difficulty {
        case .easy:
            self.maxDepth = 0
        case .medium:
            self.maxDepth = 2
        case .hard:
            self.maxDepth = 3
        }
    }

    public func getBestMove(for round: Round, playerId: PlayerID) -> Move? {
        let color: PieceColor = round.playerColor(for: playerId)
        let moves: [Move] = round.legalMoves(for: color)
        guard moves.isEmpty == false else { return nil }

        switch difficulty {
        case .easy:
            return getEasyMove(moves: moves, round: round)
        case .medium, .hard:
            return getSmartMove(round: round, moves: moves, playerId: playerId, color: color)
        }
    }

    // MARK: - Easy: random with slight preference for captures

    private func getEasyMove(moves: [Move], round: Round) -> Move {
        let captures: [Move] = moves.filter { round.board[$0.to.row][$0.to.column] != nil }
        if captures.isEmpty == false && Double.random(in: 0...1) < 0.6 {
            return captures.randomElement()!
        }
        return moves.randomElement()!
    }

    // MARK: - Medium / Hard: minimax with alpha-beta pruning

    private func getSmartMove(
        round: Round, moves: [Move], playerId: PlayerID, color: PieceColor
    ) -> Move {
        var bestScore: Double = -.infinity
        var bestMove: Move = moves[0]

        for move in moves {
            var testRound: Round = round
            testRound.performMoveUnchecked(move)
            let score: Double = minimax(
                round: testRound,
                depth: maxDepth - 1,
                alpha: -.infinity,
                beta: .infinity,
                isMaximizing: false,
                playerColor: color
            )
            if score > bestScore {
                bestScore = score
                bestMove = move
            }
        }
        return bestMove
    }

    private func minimax(
        round: Round,
        depth: Int,
        alpha: Double,
        beta: Double,
        isMaximizing: Bool,
        playerColor: PieceColor
    ) -> Double {
        if case .complete(let winnerId) = round.state {
            let winnerColor: PieceColor = round.playerColor(for: winnerId)
            if winnerColor == playerColor {
                return 1000.0 + Double(depth)
            } else {
                return -1000.0 - Double(depth)
            }
        }

        if case .draw = round.state {
            return 0.0
        }

        if depth == 0 {
            return evaluateBoard(round: round, playerColor: playerColor)
        }

        let currentColor: PieceColor = isMaximizing ? playerColor : playerColor.opposite
        let moves: [Move] = round.legalMoves(for: currentColor)
        if moves.isEmpty {
            return isMaximizing ? -1000.0 - Double(depth) : 1000.0 + Double(depth)
        }

        if isMaximizing {
            var maxScore: Double = -.infinity
            var alpha: Double = alpha
            for move in moves {
                var testRound: Round = round
                testRound.performMoveUnchecked(move)
                let score: Double = minimax(
                    round: testRound, depth: depth - 1,
                    alpha: alpha, beta: beta,
                    isMaximizing: false, playerColor: playerColor
                )
                maxScore = max(maxScore, score)
                alpha = max(alpha, score)
                if beta <= alpha { break }
            }
            return maxScore
        } else {
            var minScore: Double = .infinity
            var beta: Double = beta
            for move in moves {
                var testRound: Round = round
                testRound.performMoveUnchecked(move)
                let score: Double = minimax(
                    round: testRound, depth: depth - 1,
                    alpha: alpha, beta: beta,
                    isMaximizing: true, playerColor: playerColor
                )
                minScore = min(minScore, score)
                beta = min(beta, score)
                if beta <= alpha { break }
            }
            return minScore
        }
    }

    // MARK: - Board evaluation

    private func evaluateBoard(round: Round, playerColor: PieceColor) -> Double {
        var score: Double = 0.0
        let opponentColor: PieceColor = playerColor.opposite

        for row in 0..<Round.boardSize {
            for col in 0..<Round.boardSize {
                guard let piece: Piece = round.board[row][col] else { continue }
                let pieceValue: Double = Double(piece.type.materialValue)
                let positional: Double = positionalBonus(row: row, col: col, piece: piece)
                if piece.color == playerColor {
                    score += pieceValue + positional
                } else if piece.color == opponentColor {
                    score -= pieceValue + positional
                }
            }
        }
        return score
    }

    private func positionalBonus(row: Int, col: Int, piece: Piece) -> Double {
        var bonus: Double = 0.0

        let centerDistance: Double = abs(Double(row) - 3.5) + abs(Double(col) - 3.5)
        bonus += (4.0 - centerDistance) * 0.05

        if piece.type == .pawn {
            let advancement: Double
            switch piece.color {
            case .white:
                advancement = Double(6 - row) / 6.0
            case .black:
                advancement = Double(row - 1) / 6.0
            }
            bonus += advancement * 0.2
        }

        if piece.type == .king {
            let backRow: Int = piece.color == .white ? 7 : 0
            if row == backRow {
                bonus += 0.3
            }
        }

        return bonus
    }
}

// MARK: - Round convenience for AI moves

extension Round {
    public mutating func makeAIMove(difficulty: AIDifficulty, playerId: PlayerID) throws {
        let ai: AIEngine = AIEngine(difficulty: difficulty)
        guard let bestMove: Move = ai.getBestMove(for: self, playerId: playerId) else {
            throw ChessError.invalidMove
        }
        try performMove(bestMove, isForced: true)
    }
}
