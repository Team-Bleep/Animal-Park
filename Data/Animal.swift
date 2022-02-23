//
//  Animal.swift
//  AnimalPark
//
//  Created by Gloria Ngo on 2022-02-22.
//

import Foundation

struct Animal {
    /// Rarity of the animal spawning
    let rarity: Int
    /// Amount of value in exp that the animal will grant the player
    let value: Int
    /// Position of the animal
    var position: (Double, Double)
    /// Whether an animal is currently playing with a toy at the moment
    var playing: Bool
    /// If the animal is playing with a toy, toy object the animal is playing with
    var toy: Toy?
    
    init(rarity: Int, value: Int, position: (Double, Double)) {
        self.rarity = rarity
        self.value = value
        self.position = position
        self.playing = false
        self.toy = nil
    }
}
