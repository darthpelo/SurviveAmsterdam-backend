//
//  SAHandlers.swift
//  SurviveAmsterdamServer
//
//  Created by Alessio Roberto on 25/06/16.
//  Copyright © 2016 Alessio Roberto. All rights reserved.
//

import PerfectLib

enum ResponseCode:String {
    case OK, NOK, PRS
}

struct Constants {
    struct Mustache {
        static let result = "result"
        static let count = "count"
        static let products = "products"
        static let handlerPost = "SAHandlerPost"
        static let handlerCount = "SAHandlerCount"
        static let handlerProducts = "SAHandlerProducts"
        static let handlerDelete = "SAHandlerDelete"
    }

    struct HTTP {
        static let POST = "POST"
        static let GET = "GET"
    }

    enum Columns:Int {
        case userid, name, place
    }
}

// This is the function which all Perfect Server modules must expose.
// The system will load the module and call this function.
// In here, register any handlers or perform any one-time tasks.
public func PerfectServerModuleInit() {
    // Register our handler class with the PageHandlerRegistry.
    // The name "SAHandler", which we supply here, is used within a mustache template to associate the template with the handler.
    PageHandlerRegistry.addPageHandler(Constants.Mustache.handlerPost) {
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

    PageHandlerRegistry.addPageHandler(Constants.Mustache.handlerCount) { (r:WebResponse) -> PageHandler in
        return SAHandlerCount()
    }

    PageHandlerRegistry.addPageHandler(Constants.Mustache.handlerProducts) { (r:WebResponse) -> PageHandler in
        return SAHandlerProducts()
    }

    PageHandlerRegistry.addPageHandler(Constants.Mustache.handlerDelete) { (r:WebResponse) -> PageHandler in
        return SAHandlerDelete()
    }
}

// Handler class
// When referenced in a mustache template, this class will be instantiated to handle the request
// and provide a set of values which will be used to complete the template.
// All template handlers must inherit from PageHandler
final class SAHandlerPost: PageHandler {
    // This is the function which all handlers must impliment.
    // It is called by the system to allow the handler to return the set of values which will be used when populating the template.
    // - parameter context: The MustacheEvaluationContext which provides access to the WebRequest containing all the information pertaining to the request
    // - parameter collector: The MustacheEvaluationOutputCollector which can be used to adjust the template output. For example a `defaultEncodingFunc` could be installed to change how outgoing values are encoded.
    func valuesForResponse(context: MustacheEvaluationContext, collector: MustacheEvaluationOutputCollector) throws -> MustacheEvaluationContext.MapType {
        // The dictionary which we will return
        var values = MustacheEvaluationContext.MapType()
        values = [Constants.Mustache.result: ResponseCode.NOK.rawValue]

        // Grab the WebRequest
        if let request = context.webRequest where request.requestMethod() == Constants.HTTP.POST {
            // Try to get the last tap instance from the database
            let sqlite = try SQLite(SAHandlerPost.trackerDbPath)
            defer {
                sqlite.close()
            }

            // Adding a new product instance
            if let userid = request.param("userid"),
                let name = request.param("name"),
                let place = request.param("place") {

                try sqlite.doWithTransaction {
                    var flag = false
                    try sqlite.forEachRow("SELECT userid, name FROM products WHERE userid = '\(userid)' AND name = '\(name)'") { (stmt, i) in flag = true }

                    if !flag {
                        // Insert the new row
                        try sqlite.execute("INSERT INTO products (userid, name, place, time) VALUES (?,?,?,?)", doBindings: { (stmt) in
                            try stmt.bind(1, userid)
                            try stmt.bind(2, name)
                            try stmt.bind(3, place)
                            try stmt.bind(4, ICU.getNow())

                            values = [Constants.Mustache.result: ResponseCode.OK.rawValue]
                        })
                    } else {
                        values = [Constants.Mustache.result: ResponseCode.PRS.rawValue]
                    }
                }
            }
        }

        return values
    }
}

final class SAHandlerCount:PageHandler {
    func valuesForResponse(context: MustacheEvaluationContext, collector: MustacheEvaluationOutputCollector) throws -> MustacheEvaluationContext.MapType {
        var values = MustacheEvaluationContext.MapType()

        var temp = 0

        // Grab the WebRequest
        if let request = context.webRequest where request.requestMethod() == Constants.HTTP.GET {
            let sqlite = try SQLite(SAHandlerCount.trackerDbPath)
            defer {
                sqlite.close()
            }

            try sqlite.forEachRow("SELECT * FROM products") { (stmt, i) in temp += 1 }
        }

        let timeStr = try ICU.formatDate(ICU.getNow(), format: "d-MM-yyyy hh:mm")

        values = [Constants.Mustache.count: temp, "time": timeStr]

        return values
    }
}

final class SAHandlerProducts:PageHandler {
    func valuesForResponse(context: MustacheEvaluationContext, collector: MustacheEvaluationOutputCollector) throws -> MustacheEvaluationContext.MapType {
        var values = MustacheEvaluationContext.MapType()
        var resultSets: [[String:Any]] = []

        // Grab the WebRequest
        if let request = context.webRequest where request.requestMethod() == Constants.HTTP.GET {

            // Try to get the last tap instance from the database
            let sqlite = try SQLite(SAHandlerProducts.trackerDbPath)
            defer {
                sqlite.close()
            }

            let queries = request.queryParams
            if queries.count > 0 {
                for query in queries {
                    if query.0 == "userid" {
                        try sqlite.forEachRow("SELECT * FROM products WHERE userid = '\(query.1)'") { [weak self] (stmt, i) in
                            resultSets.append(self!.appendSQLite(statement: stmt))
                        }
                    }
                }
            } else {
                try sqlite.forEachRow("SELECT * FROM products") { [weak self] (stmt, i) in
                    resultSets.append(self!.appendSQLite(statement: stmt)) }
            }
        }

        if resultSets.count > 0 {
            var lastRow = resultSets.removeLast()
            lastRow["last"] = true
            resultSets.append(lastRow)
        }

        values = [Constants.Mustache.products: resultSets]
        return values
    }

    private func appendSQLite(statement stmt: SQLiteStmt) -> [String:Any] {
        // We got a result row
        // Pull out the values and place them in the resulting values dictionary
        let userid = stmt.columnText(Constants.Columns.userid.rawValue)
        let name = stmt.columnText(2)
        let place = stmt.columnText(3)
        let time = stmt.columnDouble(4)
        return ["userid":userid, "name":name, "place":place, "time":time, "last":false]
    }
}

final class SAHandlerDelete:PageHandler {
    func valuesForResponse(context: MustacheEvaluationContext, collector: MustacheEvaluationOutputCollector) throws -> MustacheEvaluationContext.MapType {
        // The dictionary which we will return
        var values = MustacheEvaluationContext.MapType()
        values = [Constants.Mustache.result: ResponseCode.NOK.rawValue]

        // Try to get the last tap instance from the database
        let sqlite = try SQLite(SAHandlerPost.trackerDbPath)
        defer {
            sqlite.close()
        }

        // Grab the WebRequest
        if let request = context.webRequest where request.requestMethod() == Constants.HTTP.POST {
            if let userid = request.param("userid"),
                let name = request.param("name"),
                let place = request.param("place") {

                do {
                    try sqlite.execute("DELETE FROM products WHERE userid = '\(userid)' AND name = '\(name)' AND place = '\(place)'")
                    values = [Constants.Mustache.result: ResponseCode.OK.rawValue]
                } catch {
                    values = [Constants.Mustache.result: ResponseCode.NOK.rawValue]
                }
            }
        }

        return values
    }
}

extension PageHandler {
    static var trackerDbPath: String {
        // Full path to the SQLite database in which we store our tracking data.
        let dbPath = PerfectServer.staticPerfectServer.homeDir() + serverSQLiteDBs + "SurviveAmsterdamDb"
        return dbPath
    }
}
