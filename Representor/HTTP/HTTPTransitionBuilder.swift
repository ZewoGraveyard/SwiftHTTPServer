public class HTTPTransitionBuilder : TransitionBuilderType {

    var attributes = InputProperties()
    var parameters = InputProperties()

    public var method = "POST"
    public var suggestedContentTypes: [String] = []

    init() {}

    public func addAttribute<T : Any>(
        name: String,
        title: String? = nil,
        value: T? = nil,
        defaultValue: T? = nil,
        required: Bool? = nil) {

        let property = InputProperty<Any>(
            title: title,
            value: value,
            defaultValue: defaultValue,
            required: required
        )

        attributes[name] = property

    }

    public func addAttribute(name: String, title: String? = nil, required: Bool? = nil) {

        let property = InputProperty<Any>(title: title, required: required)
        attributes[name] = property

    }

    public func addParameter(name: String) {

        let property = InputProperty<Any>(value: nil, defaultValue: nil)
        parameters[name] = property

    }

    public func addParameter<T : Any>(name: String, value: T?, defaultValue: T?, required: Bool? = nil) {

        let property = InputProperty<Any>(value: value, defaultValue: defaultValue, required: required)
        parameters[name] = property

    }

}
