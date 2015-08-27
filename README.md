HTTP Server / Web Framework
===

This project is still very unstable. That's why it still doesn't have a name and it can't be really defined as an HTTP Server or a Web Framework. Actually It does a lot of things which we haven't splited into different projects yet, because everything changes a lot. But the goal is to have all components needed for a web framework.

Actually, the reason this project has so many components is because **it doesn't depend on Foundation at all**. This constraint was defined because we want this framework to run on every platform **Swift 2** will support (specially **Linux**). Another reason everything is packed together is that we don't know how swift frameworks will work on **Linux**, so all dependencies are imported directly from the source. As we don't depend on **Foundation**, all the low level routines are accessed through **C** library wrappers. Specially **Grand Central Dispatch** and **Socket**.

What we have until now:

- **No Foundation dependency** (has everything needed to run on Linux)
- FastCGI support (you can use Nginx or Apache through mod_fastcgi)
- Native server with Async I/O through Joyent's libuv 
- HTTP parsing with Nginx/Joyent's http_parser 
- URI parsing 
- Functional based routing and middleware architecture
- JSON parsing
- PostgreSQL database
- Mustache templates

There's a *lot* of things happening behind the curtains, but to be brief I will explain only the essential.

## `HTTPRequest`

`HTTPRequest` is basically formed by theses properties.

```swift
struct HTTPRequest {

    let method: HTTPMethod
    let uri: URI
    let version: String
    var headers: [String: String]
    let body: Data
    
    var parameters: [String: String]
    var data: [String: Any]
    
    ...
    
}
```

That's quite self explanatory. What's not standard HTTP request information is the properties `parameters` and `data`. These properties are used to pass information between the middlewares and the respond functions, which will be explained later. `parameters` is used when the information is just a string, `data` is used when you want to pass forward any other value.

## `HTTPResponse`

`HTTPResponse` is pretty much mapped from a standard HTTP response.

```swift
struct HTTPResponse {

    let status: HTTPStatus
    let version: String
    var headers: [String: String]
    let body: Data
    
    ...
    
}
```

## `HTTPServer`

A simplistic view of an HTTP Server is that it receives HTTP requests and sends HTTP responses. That's actually what's needed to create an `HTTPServer`. A function that receives an `HTTPRequest` and returns an `HTTPResponse`. We call this function the `respond` function.

```swift
init(respond: (request: HTTPRequest) throws -> HTTPResponse)
```

## `HTTPRequestMiddleware`

An `HTTPRequestMiddleware` is a typealias for a function that receives an `HTTPRequest` and returns either another `HTTPRequest` or an `HTTPResponse` through the enum `HTTPRequestMiddlewareResult`.

```swift
enum HTTPRequestMiddlewareResult {

    case Request(HTTPRequest)
    case Response(HTTPResponse)

}

typealias HTTPRequestMiddleware = HTTPRequest throws -> HTTPRequestMiddlewareResult
```

## `HTTPResponseMiddleware`

An `HTTPResponseMiddleware` is a typealias for a function that receives an `HTTPResponse` and returns another `HTTPResponse`.

```swift
typealias HTTPResponseMiddleware = HTTPResponse throws -> HTTPResponse
```

## The `>>>` Operator

Now that we have our middlewares we need a way to apply them to a respond function. We do that using the `>>>` operator. This is the operator implementation for request middleware and respond operands.

```swift
typealias HTTPRespond = HTTPRequest throws -> HTTPResponse

func >>>(middleware: HTTPRequestMiddleware, respond: HTTPRespond) -> HTTPRespond {

    return { request in

        switch try middleware(request) {
        
        case .Response(let response):
            return response

        case .Request(let request):
            return try respond(request)

        }

    }

}
```

Basically if the middleware returns a response, that response is passed forward. If the middleware returns a request that request is applied to the respond function and passed forward.

The `>>>` operator for the response middleware is the most trivial one. It is actually just a generic function composition operator.

```swift
func >>> <A, B, C>(f: (A throws -> B), g: (B throws -> C)) -> (A throws -> C) {

    return { x in try g(f(x)) }

}
```

Actually most things in the framework are generic, but I explained with concrete examples to be briefer. The `>>>` is used for almost any composition in the framework. For example, error handling and routing is also employed by `>>>`.

## `HTTPRouter`

An `HTTPRouter` routes an `HTTPRequest` to a respond function based on it's `URI` path and it's `HTTPMethod`. To create an `HTTPRouter` you have to use its builder like so:

```swift
let simpleRouter = HTTPRouter { router in

	router.post("/foo", someRespondFunction)	
	
	router.get("/baz/:id") { request in
	
		let id = request.parameter["id"]
		return HTTPResponse()
		
	}

}
```

`router` is an instance of `HTTPRouterBuilder` which has a lot of methods that associate an HTTP method and an URI path to a respond function. For example `router.post("/foo", someRespondFunction)` will associate a request with the POST method and the "/foo" URI path to the respond function called `someRespondFunction`. `HTTPRouterBuilder` also has the `resource` and `resources` functions which work kinda like `rails` routing, but we won't go in detail about it now.

If you define a route with a `:placeholder` in the path, the router will match any text and save it in the `parameters` dictionary of the request with `placeholder` as a key. Using the route defined above and the request below: 

```
GET /baz/1969 HTTP/1.1
```

The router will set `parameter["id"] = "1969"` to the `HTTPRequest` and send it to the function defined by the literal closure above.


You can use request middlewares before and response middlewares after the router like:

```swift
middlewareA >>> middlewareB >>> router >>> middlewareC
```

Routes can have middlewares associated only to them as well:

```swift
let simpleRouter = HTTPRouter { router in

	router.get("/foo", middlewareA >>> respond >>> middlewareB)

}
```

Mixing everything:

```swift
let respond = middlewareA >>> middlewareB >>> HTTPRouter { router in

	router.get("/foo", middlewareC >>> respondA >>> middlewareD)
	router.put("/baz", middlewareE >>> respondB >>> middlewareF)

} >>> middlewareG >>> middlewareH
```


## `Middleware` and `Responder`

Most of the middlewares availabe are static functions of the `Middleware` struct defined in `Middleware` extensions. Some respond functions like `redirect` are also available as static functions of the `Responder` struct. A responder is just a struct or a class that has a respond function.

This decision has two reasons.

1. By putting all middleware functions as static functions under `Middleware` we don't clutter the global namespace.
2. By having middlewares under `Middleware`, using auto-complete gives us all options of middlewares we have available to us.

The same apply to standards respond functions. The donwside of that is that the respond chains become longer. But this can be overcomed by simply putting every element in the chain in it's own line.

```swift
let longChain = Middleware.middlewareA >>>
	Middleware.middlewareB >>>
	Middleware.middlewareC >>>
	Middleware.middlewareD >>>
	respond >>>
	Middleware.middlewareE >>>
	Middleware.middlewareF >>>
	Middleware.middlewareG
```

It's not that pretty but it's still readable and understandable.

## Usage

To start the server you define a respond function composed of the middlewares, the router and it's respond functions, pass it to the `HTTPServer` and call the `start()` method.

```swift
let respond = Middleware.logRequest >>> Middleware.parseURLEncoded >>> HTTPRouter { router in

	router.get("/login", LoginResponder.show)
	router.post("/login", LoginResponder.authenticate)
	router.get("/json", JSONResponder.get)
	router.post("/json", Middleware.parseJSON >>> JSONResponder.post)
	router.get("/redirect", Responder.redirect("http://www.google.com"))
	router.all("/parameters/:id/", ParametersResponder.respond)

} >>> Middleware.logResponse

let server = HTTPServer(respond: respond)
server.start()    
```

## `HTTPParser`

The `HTTPParser` used by the `HTTPServer` is a wrapper over the **C** library [`http_parser`](https://github.com/joyent/http-parser) which is used by **Node.js**. I've made some simple benchmarks, and when compiled in release mode we were able to get faster results than the `http` module from **Node.js**.
