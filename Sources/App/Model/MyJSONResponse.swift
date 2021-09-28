import Vapor

struct MyJSONResponse: Content {
    var slideshow: Slideshow
}

struct Slideshow: Content {
    var author: String
    var date: String
    var slides: [Slide]
    var title: String
}

struct Slide: Content {
    var title: String
    var type: String
    var items: [String]?
}
