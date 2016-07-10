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
- [x] Delete function
- [ ] Save images on AWS S3
- [ ] Save DB before any deploys

## How to setup
[Here](http://mrchrisbarker.postach.io/post/implementing-swift-backend-server-using-perfect-on-heroku) you can found a great video tutorial about how to implementing swift backend server using perfect on Heroku. I suggest this tutorial because is based on the Perfect example that I use as inspiration.

For this example, instead of work on [URL routing](https://github.com/PerfectlySoft/PerfectExample-URLRouting), we used the mustache template solution, to associate the handler witch the URL request and the JSON response. Every

## Server Operations
A Perfect server side project need only one source file `SAHandler.swift`, where you must configure the handler logics with the public function `PerfectServerModuleInit()` and some class which implement the `PageHandler` protocol. In this simple case there are three classes:
* one for the POST API *SAHandlerPost*
* one for the GET Products API *SAHandlerCount*
* the last to GET the number of all the Products saved on the DB *SAHandlerProducts*

```
public func PerfectServerModuleInit() {
    PageHandlerRegistry.addPageHandler("SAHandlerPost") { (r:WebResponse) -> PageHandler in
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

    PageHandlerRegistry.addPageHandler(Constants.Mustache.handlerDelete) { (r:WebResponse) -> PageHandler in
        return SAHandlerDelete()
    }
}
```

### Mustache template

A mustache template represents the response (a JSON file) to a GET/PUT request from the client.

This is the `products.mustache` file:
```
{{% handler:SAHandlerProducts}}
{
  "products":[{{#products}}{"userid":"{{userid}}","name":"{{name}}","place":"{{place}}","time":{{time}}}{{^last}},{{/last}}{{/products}}]
}
```
In this example:
- the first line `{{% handler:SAHandlerProducts}}` indicates the handler class that manages the specific API
- the second part between the curly brackets is the template of the JSON response. In this specific case, the value of the *products* key is an array of products.

The object that represent this response in swift is an array of dictionaries `[[String:Any]]`:
`["userid":userid, "name":name, "place":place, "time":time, "last":false]`.

### Makefile
In the video tutorial is missed how to configure properly the `makefile` but based on to the Perfect example, it is very easy to understand how to:
- in the `install` section insert all the mustache & html files
- in the `target` section insert the correct path of the file with the `PerfectServerModuleInit()` implementation.
```
# Makefile for Perfect Server

TARGET = SurviveAmsterdamServer
OS = $(shell uname)
PERFECT_ROOT = /app/.delta/usr/src/perfect/PerfectLib
DEBUG = -g -Onone -Xcc -DDEBUG=1
SWIFTC = swift
SWIFTC_FLAGS = -frontend -c $(DEBUG) -module-cache-path $(MODULE_CACHE_PATH) -emit-module -I /app/.delta/usr/local/lib -I /app/.delta/usr/include -I /app/.delta/usr/include/x86_64-linux-gnu -I $(PERFECT_ROOT)/linked/LibEvent \
	-I $(PERFECT_ROOT)/linked/OpenSSL_Linux -I $(PERFECT_ROOT)/linked/ICU -I $(PERFECT_ROOT)/linked/SQLite3 -I $(PERFECT_ROOT)/linked/LinuxBridge -I $(PERFECT_ROOT)/linked/cURL_Linux
MODULE_CACHE_PATH = /tmp/modulecache
Linux_SHLIB_PATH = $(shell dirname $(shell dirname $(shell which swiftc)))/lib/swift/linux
SHLIB_PATH = -L$($(OS)_SHLIB_PATH)
LFLAGS = $(SHLIB_PATH) -luuid -lswiftCore -lswiftGlibc /app/.delta/usr/local/lib/PerfectLib.so -Xlinker -rpath -Xlinker $($(OS)_SHLIB_PATH) -shared

all: $(TARGET)

install:
	mv $(TARGET).so ../PerfectLibraries
	cp save.mustache ../webroot
	cp products.mustache ../webroot
	cp count.mustache ../webroot
	cp delete.mustache ../webroot
	cp index.html ../webroot
modulecache:
	@mkdir -p $(MODULE_CACHE_PATH)

$(TARGET): modulecache
	$(SWIFTC) $(SWIFTC_FLAGS) "SurviveAmsterdamServer/SurviveAmsterdamServer/SAHandler.swift" -o $@.o -module-name $@ -emit-module-path $@.swiftmodule
	clang++ $(LFLAGS) $@.o -o $@.so

clean:
	@rm *.o
```
