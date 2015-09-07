public struct InputProperty<T : Any> {

    public let title: String?
    public let defaultValue: T?
    public let value: T?
    public let required: Bool?

    public init(title: String? = nil, value: T? = nil, defaultValue: T? = nil, required: Bool? = nil) {

        self.title = title
        self.value = value
        self.defaultValue = defaultValue
        self.required = required

    }

}

public typealias InputProperties = [String: InputProperty<Any>]

public protocol TransitionType {

    typealias Builder = TransitionBuilderType

    init(uri: String, attributes: InputProperties?, parameters: InputProperties?)
    init(uri: String, _ build: Builder -> Void)

    var uri: String { get }

    var attributes: InputProperties { get }
    var parameters: InputProperties { get }

}
