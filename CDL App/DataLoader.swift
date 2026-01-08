//
//  DataLoader.swift
//  CDL App
//
//  Created by Devan Desai on 2026-01-07.
//


import Foundation
import SwiftUI
import Combine

class DataLoader: ObservableObject {
    @Published var standings: [TeamStanding] = []

    func loadData() {
        
        let baseUrl = "https://gist.githubusercontent.com/Devan-Desai/533a3630ffc404a541db9c38d1340c7f/raw/cdl_data.json"
        
        let urlString = "\(baseUrl)?v=\(UUID().uuidString)"
        
        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                if let decodedResponse = try? JSONDecoder().decode([TeamStanding].self, from: data) {
                    // Update the UI on the main thread
                    DispatchQueue.main.async {
                        self.standings = decodedResponse
                    }
                }
            }
        }.resume()
    }
}
