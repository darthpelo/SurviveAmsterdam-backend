//
//  SAHandlers.swift
//  SurviveAmsterdamServer
//
//  Created by Alessio Roberto on 25/06/16.
//  Copyright © 2016 Alessio Roberto. All rights reserved.
//

import PerfectLib

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

