HTTP Server / Web Framework
===

This project is still very unstable. That's why it still doesn't have a name and it can't be really defined as an HTTP Server or a Web Framework. Actually It does a lot of things which we haven't splited into different projects yet, because everything changes a lot. But the goal is to have all components needed for a web framework.

Actually, the reason this project has so many components is because **it doesn't depend on Foundation at all**. This constraint was defined because we want this framework to run on every platform **Swift 2** will support (specially **Linux**). Another reason everything is packed together is that we don't know how swift frameworks will work on **Linux**, so all dependencies are imported directly from the source. As we don't depend on **Foundation**, all the low level routines are accessed through **C** library wrappers. Specially **Grand Central Dispatch** and **Socket**.

There's a lot of things happening behind the curtains, but to be brief I will explain only the essential.

## HTTPRequest

```
struct HTTPRequest {

    let method: HTTPMethod
    let uri: URI
    let version: String
    var headers: [String: String]
    let body: Data
    var parameters: [String: String]
    var data: [String: Any]
    
}
```
