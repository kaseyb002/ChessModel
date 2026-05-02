import Foundation

public enum ChessError: Error, Sendable {
    case gameAlreadyComplete
    case invalidMove
}
