//
//  entrypoint.swift
//  CDLServer
//
//  Where the server starts (Vapor's standard opening). `@main` marks the starting
//  point, like CDL_AppApp is the app's. The interesting parts are in configure.swift.
//

import Vapor

@main
enum Entrypoint {
    static func main() async throws {
        var env = try Environment.detect()            // "development" unless told otherwise
        try LoggingSystem.bootstrap(from: &env)
        let app = try await Application.make(env)

        do {
            try await configure(app)
            try await app.execute()                    // runs until you press Ctrl-C
        } catch {
            app.logger.report(error: error)
            try? await app.asyncShutdown()
            throw error
        }
        try await app.asyncShutdown()
    }
}
