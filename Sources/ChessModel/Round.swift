import Foundation

public struct Round: Equatable, Codable, Sendable {
    public static let boardSize: Int = 8
    public static let maxLogActions: Int = 100

    public let started: Date
    public internal(set) var completed: Date?
    public internal(set) var log: [MoveAction] = []
    public internal(set) var state: State
    public internal(set) var players: [Player]
    public internal(set) var board: [[Piece?]]
    public internal(set) var enPassantTarget: Position?
    public internal(set) var halfMoveClock: Int

    public init(players: [Player]) {
        precondition(players.count == 2, "Chess requires exactly 2 players")
        let adjustedPlayers: [Player] = [
            players[0].changePiece(color: .white),
            players[1].changePiece(color: .black),
        ]
        self.started = .now
        self.players = adjustedPlayers
        self.state = .waitingForPlayer(id: adjustedPlayers[0].id)
        self.board = Self.makeStandardBoard()
        self.enPassantTarget = nil
        self.halfMoveClock = 0
    }

    init(
        players: [Player],
        board: [[Piece?]],
        state: State,
        started: Date = .now,
        completed: Date? = nil,
        log: [MoveAction] = [],
        enPassantTarget: Position? = nil,
        halfMoveClock: Int = 0
    ) {
        self.players = players
        self.board = board
        self.state = state
        self.started = started
        self.completed = completed
        self.log = log
        self.enPassantTarget = enPassantTarget
        self.halfMoveClock = halfMoveClock
    }

    private static func makeStandardBoard() -> [[Piece?]] {
        var board: [[Piece?]] = Array(
            repeating: Array(repeating: nil, count: boardSize),
            count: boardSize
        )
        let backRank: [PieceType] = [.rook, .knight, .bishop, .queen, .king, .bishop, .knight, .rook]
        for col in 0..<boardSize {
            board[0][col] = Piece(color: .black, type: backRank[col])
            board[1][col] = Piece(color: .black, type: .pawn)
            board[6][col] = Piece(color: .white, type: .pawn)
            board[7][col] = Piece(color: .white, type: backRank[col])
        }
        return board
    }

    public enum State: Equatable, Codable, Sendable {
        case waitingForPlayer(id: PlayerID)
        case complete(winningPlayerId: PlayerID)
        case draw
    }

    public struct MoveAction: Equatable, Codable, Sendable {
        public let playerId: PlayerID
        public let from: Position
        public let to: Position
        public let capturedPosition: Position?
        public let promotion: PieceType?
        public let isCastling: Bool
        public let isCheck: Bool
        public let timestamp: Date
        public let isForced: Bool

        public init(
            playerId: PlayerID,
            from: Position,
            to: Position,
            capturedPosition: Position?,
            promotion: PieceType?,
            isCastling: Bool,
            isCheck: Bool,
            timestamp: Date,
            isForced: Bool
        ) {
            self.playerId = playerId
            self.from = from
            self.to = to
            self.capturedPosition = capturedPosition
            self.promotion = promotion
            self.isCastling = isCastling
            self.isCheck = isCheck
            self.timestamp = timestamp
            self.isForced = isForced
        }
    }
}
