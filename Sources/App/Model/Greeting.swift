import Vapor

struct Greeting: Content {
    var hello: String
}

struct Profile: Content {
    var name: String
    var email: String
    var image: Data //in case of file uploads, we use Data
}

//Decoding
struct Hello: Content {
    var name: String?

    //HOOKS
    //Runs after this content is decoded. 'mutating' is only required for structs, not clases.
    mutating func afterDecode() throws {
        // Name may not be passed in, but if it is, then it can't be an empty string.
        self.name = self.name?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let name = self.name, name.isEmpty {
            throw Abort(.badRequest, reason: "Name must not be empty")
        }
    }

    //Runs before this content is decoded. 'mutating' is only required for structs, not clases.
    mutating func beforeEncode() throws {
        //have to always pass a name back, and it cant be empty string.
        guard let name = self.name?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else {
            throw Abort(.badRequest, reason: "Name must not be empty")
        }
        self.name = name
    }
}