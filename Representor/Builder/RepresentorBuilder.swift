public class RepresentorBuilder<Transition : TransitionType> {

    private(set) public var transitions: [String: [Transition]] = [:]
    private(set) public var representors: [String: [Representor<Transition>]] = [:]
    private(set) public var attributes: [String: Any] = [:]
    private(set) public var metadata: [String: String] = [:]

    public func addAttribute(name: String, value: Any) {

        attributes[name] = value

    }

    public func addRepresentor(name: String, representor: Representor<Transition>) {

        if var representorSet = representors[name] {

            representorSet.append(representor)
            representors[name] = representorSet

        } else{

            representors[name] = [representor]

        }

    }


    public func addRepresentor(name: String, build: RepresentorBuilder<Transition> -> Void) {

        addRepresentor(name, representor: Representor<Transition>(build))

    }

    public func addTransition(name: String, _ transition: Transition) {

        if var t = transitions[name] {

            t.append(transition)
            transitions[name] = t

        } else {

            transitions[name] = [transition]

        }

    }

    public func addTransition(name: String, uri: String) {

        let transition = Transition(uri: uri, attributes: [:], parameters: [:])
        addTransition(name, transition)

    }

    public func addTransition(name: String, uri: String, build: Transition.Builder -> Void) {

        let transition = Transition(uri: uri, build)
        addTransition(name, transition)

    }

    public func addMetaData(key: String, value: String) {

        metadata[key] = value

    }
    
}
