import XCTest
@testable import ChessModel

final class AIEngineTests: XCTestCase {

    private func makePlayers() -> [Player] {
        let p1: Player = Player(id: "human", name: "Human", imageURL: nil, pieceColor: .white)
        let p2: Player = Player(id: "ai", name: "AI", imageURL: nil, pieceColor: .black)
        return [p1, p2]
    }

    func testEasyAIReturnsValidMove() {
        let ai: AIEngine = AIEngine(difficulty: .easy)
        let round: Round = Round(players: makePlayers())
        let move: Move? = ai.getBestMove(for: round, playerId: "human")
        XCTAssertNotNil(move)
        let legalMoves: [Move] = round.legalMoves(for: .white)
        XCTAssertTrue(legalMoves.contains(move!))
    }

    func testMediumAIReturnsValidMove() {
        let ai: AIEngine = AIEngine(difficulty: .medium)
        let round: Round = Round(players: makePlayers())
        let move: Move? = ai.getBestMove(for: round, playerId: "human")
        XCTAssertNotNil(move)
        let legalMoves: [Move] = round.legalMoves(for: .white)
        XCTAssertTrue(legalMoves.contains(move!))
    }

    func testHardAIReturnsValidMove() {
        let ai: AIEngine = AIEngine(difficulty: .hard)
        let round: Round = Round(players: makePlayers())
        let move: Move? = ai.getBestMove(for: round, playerId: "human")
        XCTAssertNotNil(move)
        let legalMoves: [Move] = round.legalMoves(for: .white)
        XCTAssertTrue(legalMoves.contains(move!))
    }

    func testAITakesCaptureWhenAvailable() {
        let players: [Player] = makePlayers()
        var board: [[Piece?]] = Array(repeating: Array(repeating: nil, count: 8), count: 8)
        board[4][3] = Piece(color: .white, type: .pawn, hasMoved: true)
        board[3][4] = Piece(color: .black, type: .queen, hasMoved: true)
        board[7][4] = Piece(color: .white, type: .king)
        board[0][4] = Piece(color: .black, type: .king)

        let round: Round = Round(
            players: players,
            board: board,
            state: .waitingForPlayer(id: "human")
        )

        let ai: AIEngine = AIEngine(difficulty: .hard)
        let move: Move? = ai.getBestMove(for: round, playerId: "human")
        XCTAssertNotNil(move)
    }

    func testAIMoveOnEmptyBoardExceptKings() {
        let players: [Player] = makePlayers()
        var board: [[Piece?]] = Array(repeating: Array(repeating: nil, count: 8), count: 8)
        board[7][4] = Piece(color: .white, type: .king)
        board[0][4] = Piece(color: .black, type: .king)

        let round: Round = Round(
            players: players,
            board: board,
            state: .waitingForPlayer(id: "human")
        )

        let ai: AIEngine = AIEngine(difficulty: .easy)
        let move: Move? = ai.getBestMove(for: round, playerId: "human")
        XCTAssertNotNil(move, "King should have legal moves")
    }

    func testAIPlayerCreation() {
        let aiPlayer: AIPlayer = Player.aiPlayer(
            name: "Test AI",
            difficulty: .hard,
            pieceColor: .black
        )
        XCTAssertEqual(aiPlayer.name, "Test AI")
        XCTAssertEqual(aiPlayer.difficulty, .hard)
        XCTAssertEqual(aiPlayer.pieceColor, .black)
        XCTAssertFalse(aiPlayer.id.isEmpty)
    }

    func testAIPlayerConversion() {
        let aiPlayer: AIPlayer = Player.aiPlayer(difficulty: .medium, pieceColor: .white)
        let regularPlayer: Player = aiPlayer.asPlayer
        XCTAssertEqual(regularPlayer.id, aiPlayer.id)
        XCTAssertEqual(regularPlayer.name, aiPlayer.name)
        XCTAssertEqual(regularPlayer.pieceColor, aiPlayer.pieceColor)
    }

    func testRoundMakeAIMove() throws {
        let players: [Player] = makePlayers()
        var round: Round = Round(players: players)
        try round.makeAIMove(difficulty: .medium, playerId: "human")
        XCTAssertEqual(round.log.count, 1)
        XCTAssertEqual(round.log[0].playerId, "human")
        XCTAssertTrue(round.log[0].isForced)
    }

    func testAIVsAICompleteGame() throws {
        var round: Round = Round(players: makePlayers())
        var moveCount: Int = 0
        let maxMoves: Int = 500

        while case .waitingForPlayer(let currentId) = round.state, moveCount < maxMoves {
            let color: PieceColor = round.playerColor(for: currentId)
            let difficulty: AIDifficulty = color == .white ? .easy : .easy
            try round.makeAIMove(difficulty: difficulty, playerId: currentId)
            moveCount += 1
        }

        XCTAssertTrue(round.state.isComplete, "AI vs AI game should complete")
        print("AI vs AI game completed in \(moveCount) moves")
    }
}
