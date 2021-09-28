import Vapor

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    
    

    // register routes
    try routes(app)

    app.http.server.configuration.hostname = "192.168.1.182"
    app.http.server.configuration.port = 8989
    
    //OVERRIDE GLOBAL DECODERS & ENCODERS
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .secondsSince1970
    ContentConfiguration.global.use(encoder: encoder, for: .json)

    //Always capture stack traces, regardless of log level
    StackTrace.isCaptureEnabled = true

    //set your own middleware Error handler
    //remove existing middleware
    //app.middleware = .init()
    //set new custom middleware
    //app.middleware.user(MyErrorMiddleware())

}
