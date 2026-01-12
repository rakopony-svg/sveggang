import Foundation

enum ConfigRetrievalState: Equatable {
    case completed
    case failed(Error)
    case pending
    case rateLimited
    
    static func == (lhs: ConfigRetrievalState, rhs: ConfigRetrievalState) -> Bool {
        switch (lhs, rhs) {
        case (.completed, .completed),
            (.pending, .pending),
            (.rateLimited, .rateLimited):
            return true
        case (.failed(let leftError), .failed(let rightError)):
            return (leftError as NSError) == (rightError as NSError)
        default:
            return false
        }
    }
}
