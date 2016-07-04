# SurviveAmsterdam-backend

## Swift backend demo with Perfect.
This project it is a simply demo to show how to deploy a
REST API services using [Perfect](https://www.perfect.org) on Heroku. What is it Perfect?

 _Perfect is a web server and toolkit for developers using the Swift programming language to build applications and other REST services._

Starting from this Perfect [example](https://github.com/PerfectlySoft/Perfect-Heroku-Buildpack-Example) I decided to create very basic REST services for a my side project [SurviveAmsterdam](https://github.com/darthpelo/SurviveAmsterdam), to show you how is possible to create Backend and Mobile using only `Swift`.

The first scope of this REST APIs is very simple:
* Save Product information to the DB, only `String` properties
* Retrieve all the Products saved by a specific user
* Retrieve all the Products saved on the DB

### Disclaimer
1) I am not a backend developer, my tech background are iOS, hardware and firmware, so feel free to give me suggestions or create pull request

2) Due to the purpose of this project, I don't made any dumb of the SQLite DB before any deploy

### To Do list
- [ ] Save images on AWS S3
- [ ] Save DB before any deploys

## How to setup
[Here](http://mrchrisbarker.postach.io/post/implementing-swift-backend-server-using-perfect-on-heroku) you can found a great video tutorial about how to implementing swift backend server using perfect on Heroku. I suggest this tutorial because is based on the Perfect example that I use as inspiration.

## REST APIs
A Perfect server side project need only one source file, where you must configure the handler logics with the public function `PerfectServerModuleInit()`. In our simple case we have three handlers:
* one for the POST API
* one for the GET Products API
* the last to GET the number of all the Products saved on the DB.

```
// This is the function which all Perfect Server modules must expose.
// The system will load the module and call this function.
// In here, register any handlers or perform any one-time tasks.
public func PerfectServerModuleInit() {
    // Register our handler class with the PageHandlerRegistry.
    // The name "SAHandler", which we supply here, is used within a mustache template to associate the template with the handler.
    PageHandlerRegistry.addPageHandler("SAHandlerPost") {
        // This closure is called in order to create the handler object.
        // It is called once for each relevant request.
        // The supplied WebResponse object can be used to tailor the return value.
        // However, all request processing should take place in the `valuesForResponse` function.
        (r:WebResponse) -> PageHandler in

        // Create SQLite database.
        do {
            let sqlite = try SQLite(SAHandlerPost.trackerDbPath)
            try sqlite.execute("CREATE TABLE IF NOT EXISTS products (id INTEGER PRIMARY KEY, userid TEXT, name TEXT, place TEXT, time REAL)")
        } catch {
            print("Failure creating tracker database at " + SAHandlerPost.trackerDbPath)
        }

        return SAHandlerPost()
    }

    PageHandlerRegistry.addPageHandler("SAHandlerCount") { (r:WebResponse) -> PageHandler in
        return SAHandlerCount()
    }

    PageHandlerRegistry.addPageHandler("SAHandlerProducts") { (r:WebResponse) -> PageHandler in
        return SAHandlerProducts()
    }
}
```

For this example, instead of work on URL routing, we used the mustache template solution, to associate the handler witch the URL request and the JSON response. 
