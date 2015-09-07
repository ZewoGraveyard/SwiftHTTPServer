public struct Representor<Transition : TransitionType> {

    public typealias Builder = RepresentorBuilder<Transition>

    public let transitions: [String: [Transition]]
    public let representors: [String: [Representor]]
    public let metadata: [String: String]
    public let attributes: [String: Any]

    public init(
        transitions: [String: [Transition]] = [:],
        representors: [String: [Representor]] = [:],
        attributes: [String: Any] = [:],
        metadata: [String: String] = [:]) {

            self.transitions = transitions
            self.representors = representors
            self.attributes = attributes
            self.metadata = metadata

    }

    public init(_ build: Builder -> Void) {

        let builder = Builder()

        build(builder)

        self.transitions = builder.transitions
        self.representors = builder.representors
        self.attributes = builder.attributes
        self.metadata = builder.metadata

    }

}
