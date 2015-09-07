public struct HTTPTransition : TransitionType {

    public typealias Builder = HTTPTransitionBuilder

    public let uri: String
    public let method: String
    public let suggestedContentTypes: [String]
    public let attributes: InputProperties
    public let parameters: InputProperties

    public init(uri: String, attributes: InputProperties? = nil, parameters: InputProperties? = nil) {

        self.uri = uri
        self.attributes = attributes ?? [:]
        self.parameters = parameters ?? [:]
        self.method = "GET"
        self.suggestedContentTypes = []

    }

    public init(uri: String, _ build: Builder -> Void) {

        let builder = Builder()

        build(builder)

        self.uri = uri
        self.attributes = builder.attributes
        self.parameters = builder.parameters
        self.method = builder.method
        self.suggestedContentTypes = builder.suggestedContentTypes

    }

}