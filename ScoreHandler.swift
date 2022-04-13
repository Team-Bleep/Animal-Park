//
//  ScoreHandler.swift
//  AnimalPark
//
//  Created by Alexis Mendiola on 2022-03-29.
//

import Foundation

struct ScoreHandler {
    static let baseScore = 1
    
    // Increase score once by base amount
    static func incrementScore() {
        let newScore = getScore() + baseScore
        UserDefaults.standard.set(newScore, forKey: DefaultKeys.score)
    }
    
    // Inrease score based on number of animals spawned
    static func setScore(numAnim: Int) {
        let newScore = getScore() + (baseScore * numAnim)
        UserDefaults.standard.set(newScore, forKey: DefaultKeys.score)
    }
    
    static func getScore() -> Int {
        return UserDefaults.standard.integer(forKey: DefaultKeys.score)
    }
}
