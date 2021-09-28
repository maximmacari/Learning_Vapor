import Vapor


func routes(_ app: Application) throws {
    app.get { req in
        return "It works!"
    }

    app.get("hello") { req -> String in
        return "Hello, world! Amigo, Cómo estas?"
    }

    app.get("hello", "vapor") { req in
        return "Hello vapor"
    }

    app.on(.GET, "hello", "on", "vapor") { req in
        return "Hello vapor"
    }

    //parameters
    app.get("hello", ":name"){ req -> String in
        let name = req.parameters.get("name")!
        return "Hello \(name)"
    }.description("Say hello")

    app.get("foo"){ req -> String in
        return "Generic return"
    }
    
    //accepts http method as an input parameter
    app.on(.OPTIONS, "foo", "bar") { req in
        return "responds to OPTIONS /foo/bar"
    }

    //PATH COMPONENT
    /*
        - Constant(foo)
        - Parameter(:foo)
        - Anything(*)
        - Catchall(**)
    */

    //Constant
    app.get("foo", "bar", "baz"){ req in
        return "requests to an excatly matching string"
    }

    //parameter
    app.get("foo", ":bar", ":baz"){ req -> String in
        let bar = req.parameters.get("bar")!
        let baz = req.parameters.get("baz")!
        return "requests to an excatly matching string, that ends in \(bar)/\(baz)"
    }
    //Anything(*), same as before but the parameter is not accesible.
    app.get("foo", "*", "baz"){ req in
        return "request *"
    }
    //Catchall(**) will match one or more components.
    app.get("foo", "**"){ req -> String in
        //the req.parameters will be stored as [String]
        let ruteComponenets = req.parameters.getCatchall().joined(separator: "/")
        return "request Catchall(**), url components: \(ruteComponenets)"
    }

    //Save parameter unwraping, 
    app.get("number", ":x"){ req -> String in
        guard let number = req.parameters.get("x", as: Int.self) else {
            throw Abort(.badRequest)
        }
        return "\(number) is a great number"
    }


    //Increasing the streaming body collection limit to 500kb, default is 16kb
    app.routes.defaultMaxBodySize = "500kb"

    app.on(.POST, "listings", body: .collect(maxSize: "1mb")) { req -> String in
        return ""
    }

    //to prevent the request body from being collected, use the stream strategy
    app.on(.POST, "upload", body: .stream) { req -> String in
        //let bodyData = req.body.data! this would be nil
        //let bodyData = req.body.drain
        return ""
    }.description("to prevent the request body from being collected, use the stream strategy")

    //handle componenets case-sensitive and case-preserving
    app.routes.caseInsensitive = true
    
    // List all routes command
    // <vapor run routes>
    app.get("help", "routes"){ req -> String in 
        "routes: " + app.routes.all.description
    }
    
    //Route GROUPS
    let users = app.grouped("users")

    users.get { req -> String in
        return "Main users index"
    }

    users.post { req -> String in
        ""
    }

    users.get(":id") { req -> String in
        let id = req.parameters.get("id")!
        return "user's id: \(id)"
    }

    // nesting and closure-based

    app.group("users") { users in
            users.get { req -> String in
            return "Main users index"
        }

        users.post { req -> String in
            ""
        }

        users.group(":id"){ user in
            user.get { req -> String in
                return ""
            }

            user.patch { req -> String in
                return ""
            }

            user.put { req -> String in
                return ""
            }
        }
    }

    //MIDDLEWARE
    //usefull when protecting a subset of routes with different authentication middleware
    /*
    app.group(RateLimitMiddleware(requestsPerMinute: 5)){ rateLimited in
        rateLimited.get("slow-thing") { req -> String in
            return ""
        }
    }
    */

    //REDIRECITONS
    //For redirecting an unauthorized user
    app.get("redirection") { req in
        req.redirect(to:"hello/, you seem to be lost")
    }

    app.get("redirectionPermanent") { req in
        req.redirect(to:"hello/permanentLost", type: .permanent)
    }

    /*
        TYPES
        1 - .permanent: returns a 301 Permanent redirection
        2 - .normal: returns a 303 see other redirect. This is the default
        3 - .temporary: returns a 307 Temporary redirect. This tells the client to preserve the HTTP method ised in the request.

    */

    //CONTENT
    //post call sending an object as JSON
    app.post("greeting") { req -> HTTPResponseStatus in 
        let greeting = try req.content.decode(Greeting.self)
        print(greeting.hello)
        return HTTPStatus.ok
    }

    //decoding
    app.get("DecodedHello"){ req -> String in
        //fetching single values from the query string using subscripts
        //let name: String? = req.query["name"]
        let hello = try req.query.decode(Hello.self)
        return "Hello, \(hello.name ?? "Anonymous")"
    }

    //OVERRIDE DECODERS & ENCODERS

    //One-off, use a specific decoder
    //let decoder = JSONDecoder()
    //decoder.dateDecodingStrategy = .secondsSince1970
    //let hello = try req.content.decode(Hello.self, using: decoder)

    //CUSTOM CODERS
    //use html as a response
    app.get("html") { _ in
        HTML(value: """
            <html>
                <body>
                    <h1 class="font-thin" >Hello, world!!</h1>
                </body>
            </html>
        """)
    }

    //Client - Third party APIs
    app.client // Client

    app.get("client", "get") { req in
        req.client.get("https://httpbin.org/status/200").map { res in
            return res.description
        }
    }

    app.get("client", "get1") { req in
        req.client.post("https://httpbin.org/status/200") { req in
            //encode query string to the request URL
            //try req.query.enconde(["q": "test"])

            //Encode JSON to the request body
            try req.content.encode(["hello": "world"])

            //Add auth header to the request
            let auth = BasicAuthorization(username: "something", password: "somethingelse")
            req.headers.basicAuthorization = auth
        }.flatMapThrowing { res -> MyJSONResponse in
            let slideshow = try res.content.decode(MyJSONResponse.self)
            print(slideshow)
            return slideshow
        }
    }

    app.get("client", "getjson") { req in
        req.client.get("https://httpbin.org/json").flatMapThrowing { res -> MyJSONResponse in
            let slideshow = try res.content.decode(MyJSONResponse.self)
            print(slideshow)
            return slideshow
        }
    }    

    //VALIDATION: Validate incoming request before using the Content
    //Human-readable errors

    //as x-www-form-urlencoded
    app.post("validating") { req -> CreateUser in
        try CreateUser.validate(content: req)
        let user = try req.content.decode(CreateUser.self)
        return user
    }

    //parameters
    app.post("validating") { req -> CreateUser in
        try CreateUser.validate(query: req)
        let user = try req.query.decode(CreateUser.self)
        return user
    }

    //ASYNC
    //Promises create futures

    //asume we  get a future string from some API
    // let futureString: EventLoopFuture<String> = 

    // //map the future string to an integer
    // var futureInt = futureString.map { string -> Int in
    //     print(string)
    //     return Int(string) ?? 0
    // }

    // print(futureInt) // EventLoopFuture<Int>

    // //flatMapThrowing transforms to another value or throw an error
    // futureInt = futureString.flatMapThrowing { string in
    //     print(string)
    //     guard let num = Int(string) else {
    //         throw Abort(.notFound)
    //     }
    //     return num
    // }

    // print(futureInt)
    ////FlatMap transormas generic future value to another future value
    ///Assume we have created an HTTP client
    // let client: CLient = ...

    // //flatMap the future string to a future response
    // let futureResponse = futureString.flatmap { string in
            // let url: URL
            // do {
            //     url = try convertToURL(string)
            // } catch error {
            //     return eventLoop.makeFailedFuture(error)
            // }
    //     return client.get(string) //EventLoopFuture<ClientResponse>
    // }

    // //We now have a future response
    // print(futureResponse)

    //Promise
    // let eventLoop: EventLoop

    // let promiseString = eventLoop.makePromise(of: String.self)
    // print("EventLoopPromise<String>: \(promiseString)")
    // print("EventLoopFuture<String>: \(promiseString.futureResult)")

    // promiseString.succeed("Hello")
    //promiseString.fail(error: ...)

    //Accress current event loop
    //req.ecentLoop.makePromise(of: )
    //Get one of the available event loops
    //app.eventLoopGroup.next().makePromise(of:)

    //BLOCKING
    app.get("blocking"){ req -> EventLoopFuture<String> in
        return req.application.threadPool.runIfActive(eventLoop: req.eventLoop) {
            //puts the background thread to sleep
            //this will not affect any of the event loops
            sleep(5)

            //when the blocking work has completed, return the result
            return "Hello world"
        }
    }

    //Logging
    app.get("log") { req -> String in
        req.logger.info("Hello, logs!")
        return "Hello, world!"
    }

    //for app configuration
    app.logger.info("Setting up migations...")

    //Custom logger
    app.get("customLog") { req -> String in
        let myLogger = Logger(label: "dev.logger.my")
        myLogger.info("custom logger")
        return "customlogg"
    }

    /**
    LEVELS
    - trace 
    - debug
    - info
    - notice 
    - warning
    - error
    - critical
    */

    //Environment
    switch app.environment {//access current environment
    case .production:
        //app.database.use()    
        print("We are in prod")
    default:
        //app.database.use()
        print("We are in everting but prod")
    }
    //Changing environment <vapor run serve --env production>
    /**Available environments
        - production | prod | Deployed to your users
        - development | dev | Local development
        - testing | test | For unit testing
    */
    //process variables
    let inputVariable = Environment.get("FOO")
    if let foo = inputVariable as? String {
        print(foo) // String?    
    }
    

    //Environment.process.FOO
    //print(inputVariable) // String?

    //Set variable in the termional when launching your app
    //Or, in xcode, editing the Run Scheme
    //export FOO=BAR
    //vapor run serve

    //Also you can generate a .env file with a list of key:value 
    //pairs to be automatically loaded into the environment
    /* FILES Hierarchy
        .env  Default values
        .env.delopment | .env.production | .env.testing
    */
    // DO NOT commit .env with sensitive information as passwords and keys

    //Custom environment
    /*
    extension Environment {
        static var staging: Environment {
            .custom(name: "staging")
        }
    }
    */

    //ERRORS
    //Route handlers can either throw an error or return a failed EventLoopFuture
    //The handling is done by ErrorMiddleware.

    //Abort, conforms to AbortError and DebuggableError
    //throw Abort(.notFound) // 403, deafult "Not found", reson used
    // 401, deafult "Not found", custom reason
    //throw Abort(.unauthorized, reason: "Invalid Credentials") 
    
    //async situations
    /*
    guard let user = user else {
        req.eventLoop.makeFailedFuture(Abort(.notFound))
    }
    return user.save()
    */

   

}
