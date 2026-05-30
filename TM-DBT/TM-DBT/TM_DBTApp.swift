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
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

final class PersistenceStore {
    static let shared = PersistenceStore()

    lazy var container: ModelContainer = {
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
}
