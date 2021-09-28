import Vapor

//Customize your errors by conforming to AbortError


//Customize error logging, conform to debugableError
struct MyError: DebuggableError {
    enum Value {
        case userNotLoggedIn
        case invalidEmail(String)
    }

    var identifier: String {
        switch self.value {
        case .userNotLoggedIn:
            return "User not logged in"
        case .invalidEmail:
            return "InvalidEmail"
        }
    }

    var reason: String{
        switch self.value {
        case .userNotLoggedIn:
            return "User is not logged in."
        case .invalidEmail(let email):
            return "Email address is not valid \(email)."   
        }
    }
    var value: Value
    var source: ErrorSource?
    //capture current stack trace
    var stackTrace: StackTrace?
    
    init(
        _ value: Value,
        file: String = #file,
        function: String = #function,
        line: UInt = #line,
        column: UInt = #column,
        stackTrace: StackTrace? = .capture()
    ) {
        self.value = value
        self.source = .init(
            file: file,
            function: function,
            line: line,
            column: column
        )
        self.stackTrace = stackTrace
    }
}

extension MyError: AbortError {
    var status: HTTPStatus {
        switch self.value {
            case .userNotLoggedIn:
                return .unauthorized
            case .invalidEmail:
                return .badRequest
        }
    }
}