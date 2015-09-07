//
//
//
//
//
//
//private func sirenFieldToAttribute(builder: HTTPTransitionBuilder)(field: [String: Any]) {
//
//    if let name = field["name"] as? String {
//
//        let title = field["title"] as? String
//        let value: Any? = field["value"]
//
//        builder.addAttribute(name, title: title, value: value, defaultValue: nil)
//
//    }
//
//}
//
//private func sirenActionToTransition(action:[String: Any]) -> (name: String, transition: HTTPTransition)? {
//
//    if let name = action["name"] as? String,
//        href = action["href"] as? String {
//
//            let transition = HTTPTransition(uri: href) { builder in
//
//                if let method = action["method"] as? String {
//
//                    builder.method = method
//
//                }
//
//                if let contentType = action["type"] as? String {
//
//                    builder.suggestedContentTypes = [contentType]
//
//                }
//
//                if let fields = action["fields"] as? [[String: Any]] {
//
//                    fields.forEach(sirenFieldToAttribute(builder))
//
//                }
//
//            }
//
//            return (name, transition)
//
//    }
//
//    return nil
//
//}
//
//private func inputPropertyToSirenField(name: String, inputProperty: InputProperty<Any>) -> [String: Any] {
//
//    var field: [String: Any] = [
//        "name": name
//    ]
//
//    if let value: Any = inputProperty.value {
//
//        field["value"] = "\(value)"
//
//    }
//
//    if let title = inputProperty.title {
//
//        field["title"] = title
//
//    }
//
//    return field
//
//}
//
//private func transitionToSirenAction(relation: String, transition: HTTPTransition) -> [String: Any] {
//
//    var action:[String: Any] = [
//        "href": transition.uri,
//        "name": relation,
//        "method": transition.method
//    ]
//
//    if let contentType = transition.suggestedContentTypes.first {
//
//        action["type"] = contentType
//
//    }
//
//    if transition.attributes.count > 0 {
//
//        action["fields"] = transition.attributes.map(inputPropertyToSirenField)
//
//    }
//
//    return action
//
//}
//
//public func deserializeSiren(siren: JSON) -> Representor<HTTPTransition> {
//
//    var representors: [String: [Representor<HTTPTransition>]] = [:]
//    var transitions: [String: HTTPTransition] = [:]
//    var attributes: [String: Any] = [:]
//
//    if let sirenLinks = siren["links"] as? [[String: Any]] {
//
//        for link in sirenLinks {
//
//            if let href = link["href"] as? String,
//                relations = link["rel"] as? [String] {
//
//                    for relation in relations {
//
//                        transitions[relation] = HTTPTransition(uri: href)
//
//                    }
//
//            }
//
//        }
//
//    }
//
//    if let entities = siren["entities"] as? [[String: Any]] {
//
//        for entity in entities {
//
//            let representor = deserializeSiren(entity)
//
//            if let relations = entity["rel"] as? [String] {
//
//                for relation in relations {
//
//                    if var reps = representors[relation] {
//
//                        reps.append(representor)
//                        representors[relation] = reps
//
//                    } else {
//
//                        representors[relation] = [representor]
//
//                    }
//
//                }
//
//            }
//
//        }
//
//    }
//
//    if let actions = siren["actions"] as? [[String: Any]] {
//
//        for action in actions {
//
//            if let (name, transition) = sirenActionToTransition(action) {
//
//                transitions[name] = transition
//
//            }
//
//        }
//
//    }
//
//    if let properties = siren["properties"] as? [String: Any] {
//
//        attributes = properties
//
//    }
//
//    return Representor<HTTPTransition>(transitions: transitions, representors: representors, attributes: attributes, metadata: [:])
//
//}
//
//public func serializeSiren(representor: Representor<HTTPTransition>) -> [String: Any] {
//
//    var representation: [String: Any] = [:]
//
//    if representor.representors.count > 0 {
//
//        var entities: [[String: Any]] = [[:]]
//
//        for (relation, representorSet) in representor.representors {
//
//            for representor in representorSet {
//
//                var representation = serializeSiren(representor)
//                representation["rel"] = [relation]
//                entities.append(representation)
//
//            }
//
//        }
//        
//        representation["entities"] = entities
//
//    }
//    
//    if representor.attributes.count > 0 {
//
//        representation["properties"] = representor.attributes
//
//    }
//    
//    let links = representor.transitions.filter { $1.method == "GET" }
//    let actions = representor.transitions.filter { $1.method != "GET" }
//    
//    if links.count > 0 {
//
//        var linkRepresentations: [[String: Any]] = [[:]]
//
//        for link in links {
//
//            let linkRepresentation: [String: Any] = [
//                "rel": [link.0],
//                "href": link.1.uri
//            ]
//
//            linkRepresentations.append(linkRepresentation)
//
//        }
//
//        representation["links"] = linkRepresentations
//
//    }
//    
//    if actions.count > 0 {
//
//        representation["actions"] = actions.map(transitionToSirenAction)
//
//    }
//    
//    return representation
//
//}
