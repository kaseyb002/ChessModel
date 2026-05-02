import Foundation
import Testing
@testable import ChessModel

// MARK: - Test helpers

private func makePlayers() -> [Player] {
    let p1: Player = Player(id: "alice", name: "Alice", imageURL: nil, pieceColor: .white)
    let p2: Player = Player(id: "bob", name: "Bob", imageURL: nil, pieceColor: .black)
    return [p1, p2]
}

private func winnerID(_ round: Round) -> PlayerID? {
    if case .complete(let winningPlayerId) = round.state { return winningPlayerId }
    return nil
}

private func currentPlayerId(_ round: Round) -> PlayerID? {
    if case .waitingForPlayer(let id) = round.state { return id }
    return nil
}

private func emptyBoard() -> [[Piece?]] {
    Array(repeating: Array(repeating: nil, count: 8), count: 8)
}

// MARK: - Board setup tests

@Test
func initialBoardHas16PiecesPerPlayer() {
    let round: Round = Round(players: makePlayers())
    #expect(round.pieceCount(for: .white) == 16)
    #expect(round.pieceCount(for: .black) == 16)
}

@Test
func initialBoardBackRankSetup() {
    let round: Round = Round(players: makePlayers())
    let expectedTypes: [PieceType] = [.rook, .knight, .bishop, .queen, .king, .bishop, .knight, .rook]
    for col in 0..<8 {
        #expect(round.board[0][col]?.type == expectedTypes[col])
        #expect(round.board[0][col]?.color == .black)
        #expect(round.board[7][col]?.type == expectedTypes[col])
        #expect(round.board[7][col]?.color == .white)
    }
}

@Test
func initialBoardPawnSetup() {
    let round: Round = Round(players: makePlayers())
    for col in 0..<8 {
        #expect(round.board[1][col]?.type == .pawn)
        #expect(round.board[1][col]?.color == .black)
        #expect(round.board[6][col]?.type == .pawn)
        #expect(round.board[6][col]?.color == .white)
    }
}

@Test
func initialBoardMiddleRowsEmpty() {
    let round: Round = Round(players: makePlayers())
    for row in 2..<6 {
        for col in 0..<8 {
            #expect(round.board[row][col] == nil)
        }
    }
}

@Test
func whiteMovesFirst() {
    let round: Round = Round(players: makePlayers())
    #expect(currentPlayerId(round) == "alice")
    #expect(round.players[0].pieceColor == .white)
}

@Test
func secondPlayerForcedToBlack() {
    let p1: Player = Player(id: "a", name: "A", imageURL: nil, pieceColor: .black)
    let p2: Player = Player(id: "b", name: "B", imageURL: nil, pieceColor: .black)
    let round: Round = Round(players: [p1, p2])
    #expect(round.players[0].pieceColor == .white)
    #expect(round.players[1].pieceColor == .black)
}

@Test
func noPiecesHaveMovedOnInitialBoard() {
    let round: Round = Round(players: makePlayers())
    for row in round.board {
        for cell in row {
            if let piece: Piece = cell {
                #expect(piece.hasMoved == false)
            }
        }
    }
}

// MARK: - Simple move tests

@Test
func pawnForwardOneSquare() throws {
    var round: Round = Round(players: makePlayers())
    let from: Position = Position(row: 6, column: 4)
    let to: Position = Position(row: 5, column: 4)
    try round.performMove(Move(from: from, to: to))
    #expect(round.board[6][4] == nil)
    #expect(round.board[5][4]?.type == .pawn)
    #expect(round.board[5][4]?.color == .white)
    #expect(currentPlayerId(round) == "bob")
    #expect(round.log.count == 1)
}

@Test
func pawnForwardTwoSquaresFromStart() throws {
    var round: Round = Round(players: makePlayers())
    try round.performMove(Move(from: Position(row: 6, column: 4), to: Position(row: 4, column: 4)))
    #expect(round.board[4][4]?.type == .pawn)
    #expect(round.board[4][4]?.color == .white)
    #expect(round.enPassantTarget == Position(row: 5, column: 4))
}

@Test
func moveAlternatesTurns() throws {
    var round: Round = Round(players: makePlayers())
    try round.performMove(Move(from: Position(row: 6, column: 4), to: Position(row: 4, column: 4)))
    #expect(currentPlayerId(round) == "bob")
    try round.performMove(Move(from: Position(row: 1, column: 4), to: Position(row: 3, column: 4)))
    #expect(currentPlayerId(round) == "alice")
}

@Test
func invalidMoveThrows() {
    var round: Round = Round(players: makePlayers())
    #expect(throws: ChessError.invalidMove) {
        try round.performMove(Move(from: Position(row: 6, column: 4), to: Position(row: 3, column: 4)))
    }
}

@Test
func knightMoveFromStart() throws {
    var round: Round = Round(players: makePlayers())
    try round.performMove(Move(from: Position(row: 7, column: 1), to: Position(row: 5, column: 2)))
    #expect(round.board[5][2]?.type == .knight)
    #expect(round.board[5][2]?.color == .white)
    #expect(round.board[7][1] == nil)
}

// MARK: - Capture tests

@Test
func pawnCapture() throws {
    let players: [Player] = makePlayers()
    var board: [[Piece?]] = emptyBoard()
    board[4][3] = Piece(color: .white, type: .pawn, hasMoved: true)
    board[3][4] = Piece(color: .black, type: .pawn, hasMoved: true)
    board[0][4] = Piece(color: .black, type: .king)
    board[7][4] = Piece(color: .white, type: .king)

    var round: Round = Round(
        players: players,
        board: board,
        state: .waitingForPlayer(id: "alice")
    )
    try round.performMove(Move(from: Position(row: 4, column: 3), to: Position(row: 3, column: 4)))
    #expect(round.board[3][4]?.color == .white)
    #expect(round.board[3][4]?.type == .pawn)
    #expect(round.log[0].capturedPosition == Position(row: 3, column: 4))
}

@Test
func enPassantCapture() throws {
    let players: [Player] = makePlayers()
    var board: [[Piece?]] = emptyBoard()
    board[3][4] = Piece(color: .white, type: .pawn, hasMoved: true)
    board[3][3] = Piece(color: .black, type: .pawn, hasMoved: true)
    board[0][0] = Piece(color: .black, type: .king)
    board[7][4] = Piece(color: .white, type: .king)

    var round: Round = Round(
        players: players,
        board: board,
        state: .waitingForPlayer(id: "alice"),
        enPassantTarget: Position(row: 2, column: 3)
    )

    try round.performMove(Move(from: Position(row: 3, column: 4), to: Position(row: 2, column: 3)))
    #expect(round.board[2][3]?.color == .white)
    #expect(round.board[3][3] == nil, "En passant captured pawn should be removed")
}

// MARK: - Castling tests

@Test
func kingsideCastling() throws {
    let players: [Player] = makePlayers()
    var board: [[Piece?]] = emptyBoard()
    board[7][4] = Piece(color: .white, type: .king)
    board[7][7] = Piece(color: .white, type: .rook)
    board[0][4] = Piece(color: .black, type: .king)

    var round: Round = Round(
        players: players,
        board: board,
        state: .waitingForPlayer(id: "alice")
    )

    try round.performMove(Move(from: Position(row: 7, column: 4), to: Position(row: 7, column: 6)))
    #expect(round.board[7][6]?.type == .king)
    #expect(round.board[7][5]?.type == .rook)
    #expect(round.board[7][4] == nil)
    #expect(round.board[7][7] == nil)
    #expect(round.log[0].isCastling == true)
}

@Test
func queensideCastling() throws {
    let players: [Player] = makePlayers()
    var board: [[Piece?]] = emptyBoard()
    board[7][4] = Piece(color: .white, type: .king)
    board[7][0] = Piece(color: .white, type: .rook)
    board[0][4] = Piece(color: .black, type: .king)

    var round: Round = Round(
        players: players,
        board: board,
        state: .waitingForPlayer(id: "alice")
    )

    try round.performMove(Move(from: Position(row: 7, column: 4), to: Position(row: 7, column: 2)))
    #expect(round.board[7][2]?.type == .king)
    #expect(round.board[7][3]?.type == .rook)
    #expect(round.board[7][4] == nil)
    #expect(round.board[7][0] == nil)
    #expect(round.log[0].isCastling == true)
}

@Test
func castlingBlockedByPiece() {
    let players: [Player] = makePlayers()
    var board: [[Piece?]] = emptyBoard()
    board[7][4] = Piece(color: .white, type: .king)
    board[7][5] = Piece(color: .white, type: .bishop)
    board[7][7] = Piece(color: .white, type: .rook)
    board[0][4] = Piece(color: .black, type: .king)

    var round: Round = Round(
        players: players,
        board: board,
        state: .waitingForPlayer(id: "alice")
    )

    #expect(throws: ChessError.invalidMove) {
        try round.performMove(Move(from: Position(row: 7, column: 4), to: Position(row: 7, column: 6)))
    }
}

@Test
func castlingBlockedByCheck() {
    let players: [Player] = makePlayers()
    var board: [[Piece?]] = emptyBoard()
    board[7][4] = Piece(color: .white, type: .king)
    board[7][7] = Piece(color: .white, type: .rook)
    board[0][4] = Piece(color: .black, type: .rook)
    board[0][0] = Piece(color: .black, type: .king)

    var round: Round = Round(
        players: players,
        board: board,
        state: .waitingForPlayer(id: "alice")
    )

    #expect(throws: ChessError.invalidMove) {
        try round.performMove(Move(from: Position(row: 7, column: 4), to: Position(row: 7, column: 6)))
    }
}

@Test
func castlingBlockedAfterKingMoved() {
    let players: [Player] = makePlayers()
    var board: [[Piece?]] = emptyBoard()
    board[7][4] = Piece(color: .white, type: .king, hasMoved: true)
    board[7][7] = Piece(color: .white, type: .rook)
    board[0][4] = Piece(color: .black, type: .king)

    var round: Round = Round(
        players: players,
        board: board,
        state: .waitingForPlayer(id: "alice")
    )

    #expect(throws: ChessError.invalidMove) {
        try round.performMove(Move(from: Position(row: 7, column: 4), to: Position(row: 7, column: 6)))
    }
}

// MARK: - Promotion tests

@Test
func pawnPromotion() throws {
    let players: [Player] = makePlayers()
    var board: [[Piece?]] = emptyBoard()
    board[1][0] = Piece(color: .white, type: .pawn, hasMoved: true)
    board[7][4] = Piece(color: .white, type: .king)
    board[0][4] = Piece(color: .black, type: .king)

    var round: Round = Round(
        players: players,
        board: board,
        state: .waitingForPlayer(id: "alice")
    )

    try round.performMove(Move(from: Position(row: 1, column: 0), to: Position(row: 0, column: 0), promotion: .queen))
    #expect(round.board[0][0]?.type == .queen)
    #expect(round.board[0][0]?.color == .white)
    #expect(round.log[0].promotion == .queen)
}

@Test
func pawnPromotionToKnight() throws {
    let players: [Player] = makePlayers()
    var board: [[Piece?]] = emptyBoard()
    board[1][0] = Piece(color: .white, type: .pawn, hasMoved: true)
    board[7][4] = Piece(color: .white, type: .king)
    board[0][4] = Piece(color: .black, type: .king)

    var round: Round = Round(
        players: players,
        board: board,
        state: .waitingForPlayer(id: "alice")
    )

    try round.performMove(Move(from: Position(row: 1, column: 0), to: Position(row: 0, column: 0), promotion: .knight))
    #expect(round.board[0][0]?.type == .knight)
    #expect(round.board[0][0]?.color == .white)
}

// MARK: - Check and checkmate tests

@Test
func detectCheck() throws {
    let players: [Player] = makePlayers()
    var board: [[Piece?]] = emptyBoard()
    board[7][4] = Piece(color: .white, type: .king)
    board[0][4] = Piece(color: .black, type: .king)
    board[6][3] = Piece(color: .white, type: .queen)

    var round: Round = Round(
        players: players,
        board: board,
        state: .waitingForPlayer(id: "alice")
    )

    try round.performMove(Move(from: Position(row: 6, column: 3), to: Position(row: 1, column: 3)))
    #expect(round.log[0].isCheck == true)
}

@Test
func scholarsMateCheckmate() throws {
    var round: Round = Round(players: makePlayers())

    // 1. e4
    try round.performMove(Move(from: Position(row: 6, column: 4), to: Position(row: 4, column: 4)))
    // 1... e5
    try round.performMove(Move(from: Position(row: 1, column: 4), to: Position(row: 3, column: 4)))
    // 2. Bc4
    try round.performMove(Move(from: Position(row: 7, column: 5), to: Position(row: 4, column: 2)))
    // 2... Nc6
    try round.performMove(Move(from: Position(row: 0, column: 1), to: Position(row: 2, column: 2)))
    // 3. Qh5
    try round.performMove(Move(from: Position(row: 7, column: 3), to: Position(row: 3, column: 7)))
    // 3... Nf6
    try round.performMove(Move(from: Position(row: 0, column: 6), to: Position(row: 2, column: 5)))
    // 4. Qxf7#
    try round.performMove(Move(from: Position(row: 3, column: 7), to: Position(row: 1, column: 5)))

    #expect(round.state == .complete(winningPlayerId: "alice"))
    #expect(round.completed != nil)
}

@Test
func stalemateResultsInDraw() throws {
    let players: [Player] = makePlayers()
    var board: [[Piece?]] = emptyBoard()
    board[0][0] = Piece(color: .black, type: .king, hasMoved: true)
    board[2][1] = Piece(color: .white, type: .queen, hasMoved: true)
    board[7][4] = Piece(color: .white, type: .king)

    var round: Round = Round(
        players: players,
        board: board,
        state: .waitingForPlayer(id: "alice")
    )

    try round.performMove(Move(from: Position(row: 2, column: 1), to: Position(row: 1, column: 2)))
    #expect(round.state == .draw)
    #expect(round.completed != nil)
}

// MARK: - Game state tests

@Test
func cannotMoveAfterGameComplete() throws {
    var round: Round = Round(players: makePlayers())
    // Scholar's mate
    try round.performMove(Move(from: Position(row: 6, column: 4), to: Position(row: 4, column: 4)))
    try round.performMove(Move(from: Position(row: 1, column: 4), to: Position(row: 3, column: 4)))
    try round.performMove(Move(from: Position(row: 7, column: 5), to: Position(row: 4, column: 2)))
    try round.performMove(Move(from: Position(row: 0, column: 1), to: Position(row: 2, column: 2)))
    try round.performMove(Move(from: Position(row: 7, column: 3), to: Position(row: 3, column: 7)))
    try round.performMove(Move(from: Position(row: 0, column: 6), to: Position(row: 2, column: 5)))
    try round.performMove(Move(from: Position(row: 3, column: 7), to: Position(row: 1, column: 5)))
    #expect(round.state.isComplete)

    #expect(throws: ChessError.gameAlreadyComplete) {
        try round.performMove(Move(from: Position(row: 0, column: 0), to: Position(row: 1, column: 0)))
    }
}

@Test
func logTrimsToMaxActions() throws {
    var round: Round = Round(players: makePlayers())
    var moveCount: Int = 0
    while round.state.isComplete == false && moveCount < 120 {
        guard case .waitingForPlayer(let currentId) = round.state else { break }
        try round.makeAIMove(difficulty: .easy, playerId: currentId)
        moveCount += 1
    }
    #expect(round.log.count <= Round.maxLogActions)
}

// MARK: - Legal moves tests

@Test
func legalMovesFromInitialPosition() {
    let round: Round = Round(players: makePlayers())
    let moves: [Move] = round.legalMoves(for: .white)
    #expect(moves.count == 20)
}

@Test
func noLegalMovesWhenCheckmated() {
    let players: [Player] = makePlayers()
    var board: [[Piece?]] = emptyBoard()
    board[0][0] = Piece(color: .black, type: .king, hasMoved: true)
    board[0][7] = Piece(color: .white, type: .rook, hasMoved: true)
    board[1][7] = Piece(color: .white, type: .rook, hasMoved: true)
    board[7][4] = Piece(color: .white, type: .king)

    let round: Round = Round(
        players: players,
        board: board,
        state: .waitingForPlayer(id: "bob")
    )
    let moves: [Move] = round.legalMoves(for: .black)
    #expect(moves.isEmpty)
}

@Test
func kingCannotMoveIntoCheck() {
    let players: [Player] = makePlayers()
    var board: [[Piece?]] = emptyBoard()
    board[0][4] = Piece(color: .black, type: .king)
    board[7][4] = Piece(color: .white, type: .king)
    board[7][3] = Piece(color: .white, type: .rook, hasMoved: true)

    let round: Round = Round(
        players: players,
        board: board,
        state: .waitingForPlayer(id: "bob")
    )

    let blackMoves: [Move] = round.legalMoves(for: .black)
    let movesToD8: [Move] = blackMoves.filter { $0.to == Position(row: 0, column: 3) }
    #expect(movesToD8.isEmpty, "King should not be able to move into rook's attack line")
}

// MARK: - Fake tests

@Test
func playerFakeHasDefaults() {
    let player: Player = Player.fake()
    #expect(player.name == "Fake Player")
    #expect(player.id.isEmpty == false)
}

@Test
func roundFakeCreatesValidGame() {
    let round: Round = Round.fake()
    #expect(round.players.count == 2)
    #expect(round.pieceCount(for: .white) == 16)
    #expect(round.pieceCount(for: .black) == 16)
    #expect(round.state.isComplete == false)
}

@Test
func pieceFakeHasDefaults() {
    let piece: Piece = Piece.fake()
    #expect(piece.color == .white)
    #expect(piece.type == .pawn)
    #expect(piece.hasMoved == false)
}

@Test
func moveActionFakeHasDefaults() {
    let action: Round.MoveAction = Round.MoveAction.fake()
    #expect(action.playerId == "fakePlayer")
    #expect(action.capturedPosition == nil)
    #expect(action.isCastling == false)
}

// MARK: - Codable tests

@Test
func roundEncodesAndDecodes() throws {
    let round: Round = Round(players: makePlayers())
    let encoder: JSONEncoder = .init()
    let decoder: JSONDecoder = .init()
    decoder.keyDecodingStrategy = .convertFromSnakeCase

    let data: Data = try encoder.encode(round)
    let decoded: Round = try decoder.decode(Round.self, from: data)
    #expect(decoded == round)
}

@Test
func playerEncodesAndDecodes() throws {
    let player: Player = Player(
        id: "test", name: "Test", imageURL: URL(string: "https://example.com/img.png"),
        pieceColor: .white
    )
    let encoder: JSONEncoder = .init()
    let decoder: JSONDecoder = .init()

    let data: Data = try encoder.encode(player)
    let decoded: Player = try decoder.decode(Player.self, from: data)
    #expect(decoded == player)
}

// MARK: - Full game playthrough

@Test
func fullGamePlaythrough() throws {
    var round: Round = Round(players: makePlayers())
    var moveCount: Int = 0
    let maxMoves: Int = 500

    while round.state.isComplete == false && moveCount < maxMoves {
        guard case .waitingForPlayer(let currentId) = round.state else { break }
        try round.makeAIMove(difficulty: .easy, playerId: currentId)
        moveCount += 1
    }

    #expect(round.state.isComplete, "Game should complete within \(maxMoves) moves")
    print("Full game completed in \(moveCount) moves")
}

@Test
func fullGameWithDeterministicMoves() throws {
    var round: Round = Round(players: makePlayers())
    var moveCount: Int = 0
    let maxMoves: Int = 500

    while round.state.isComplete == false && moveCount < maxMoves {
        let color: PieceColor = round.currentPlayer!.pieceColor
        let moves: [Move] = round.legalMoves(for: color)
        guard moves.isEmpty == false else { break }
        let move: Move = moves[0]
        try round.performMove(move)
        moveCount += 1
    }

    #expect(round.state.isComplete, "Game should complete within \(maxMoves) moves")
    print("Deterministic game completed in \(moveCount) moves")
}
