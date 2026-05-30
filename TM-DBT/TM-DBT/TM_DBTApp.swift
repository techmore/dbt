//
//  TM_DBTApp.swift
//  TM-DBT
//
//  Created by techmore on 5/29/26.
//

import SwiftUI
import SwiftData

@main
struct TM_DBTApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            PracticeEntry.self,
            ChainReview.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
