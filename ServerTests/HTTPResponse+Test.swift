extension HTTPResponse {

    var isJSON: Bool {

        guard let contentType = headers["content-type"] else {

            return false

        }

        return contentType == "application/json"

    }

    func equalsJSON(candidateJSON: JSON) -> Bool {

        if !isJSON {

            return false

        }

        guard let responseJSON = try? JSONParser.parse(body) else {

            return false

        }
        
        return candidateJSON == responseJSON

    }

}