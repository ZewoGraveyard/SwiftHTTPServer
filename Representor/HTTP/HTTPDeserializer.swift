public struct HTTPDeserializer {

    public typealias Deserialize = HTTPResponse -> Representor<HTTPTransition>?

    public static func jsonDeserializer(deserialize: JSON -> Representor<HTTPTransition>?) -> (HTTPResponse -> Representor<HTTPTransition>?) {

        return { response in

            if let json = try? JSONParser.parse(response.body) {

                return deserialize(json)
                
            }
            
            return nil
        }
        
    }

    public static var deserializers: [String: Deserialize] = [

        "application/hal+json": HTTPDeserializer.jsonDeserializer { json in

            return deserializeHAL(json)

        },

//        "application/vnd.siren+json": HTTPDeserializer.jsonDeserializer { json in
//
//            return deserializeSiren(json)
//
//        },

    ]

    public static var preferredContentTypes: [String] = [
        "application/vnd.siren+json",
        "application/hal+json",
    ]

    public static func deserialize(response: HTTPResponse) -> Representor<HTTPTransition>? {

        if let contentType = response.contentType {

            if let deserialize = HTTPDeserializer.deserializers[contentType] {

                return deserialize(response)

            }

        }
        
        return nil

    }

}
