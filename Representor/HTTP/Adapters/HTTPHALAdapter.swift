public func deserializeHAL(json: JSON) -> Representor<HTTPTransition> {

    func parseHALLinks(json: JSON) -> [String: [HTTPTransition]] {

        var links: [String: [HTTPTransition]] = [:]

        for (link, options) in json.dictionaryValue {

            if options.isObject {

                links[link] = [HTTPTransition(uri: options["href"].stringValue)]

            }

            if options.isArray {

                var transitions: [HTTPTransition] = []

                for option in options.arrayValue {

                    transitions.append(HTTPTransition(uri: option["href"].stringValue))

                }

                links[link] = transitions

            }

        }
        
        return links
        
    }

    func parseEmbeddedHALs(embeddedHALs: JSON) -> [String: [Representor<HTTPTransition>]] {

        var representors: [String: [Representor<HTTPTransition>]] = [:]

        for (name, embedded) in embeddedHALs.dictionaryValue {

            if embedded.isArray {

                representors[name] = embedded.arrayValue.map(deserializeHAL)

            } else if embedded.isObject {
                
                representors[name] = [deserializeHAL(embedded)]
                
            }
            
        }
        
        return representors
        
    }

    let links = parseHALLinks(json["_links"])
    let representors = parseEmbeddedHALs(json["_embedded"])
    var attribues = json.dictionaryOfAnyValue

    attribues.removeValueForKey("_links")
    attribues.removeValueForKey("_embedded")

    return Representor(transitions: links, representors: representors, attributes: attribues)

}

public func serializeHAL(representor: Representor<HTTPTransition>) -> JSON {

    var representation = representor.attributes

    if representor.transitions.count > 0 {

        var links: [String: Any] = [:]

        for (relation, transitions) in representor.transitions {

            var relations: [Any] = []

            for transition in transitions {

                let href: [String: Any] = ["href": transition.uri]
                relations.append(href)


            }

            links[relation] = relations

        }

        representation["_links"] = links

    }

    if representor.representors.count > 0 {

        var embeddedHALs: [String: Any] = [:]

        for (name, representorSet) in representor.representors {

            let embeddedHAL: [Any] = representorSet.map { serializeHAL($0).dictionaryOfAnyValue }
            embeddedHALs[name] = embeddedHAL

        }
        
        representation["_embedded"] = embeddedHALs

    }

    return JSON.from(representation)

}
