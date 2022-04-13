//
//  FoodHandler.swift
//  AnimalPark
//
//  Created by William Chan on 2022-03-26.
//

struct  FoodHandler {
    static let FoodCost = 2;
    static let MaxFood = 100;
    
    static func fillFood() {
        let curr = CurrencyHandler.getCurrency();
        let foodSpace = MaxFood-getFood(); // amount of food able to fill in dish
        let foodBuyable = curr/FoodCost; // amount of food able to purchase

        if (foodBuyable >= foodSpace) {
            // overfill or perfect amount
            CurrencyHandler.removeCurrency(curr: (foodSpace * FoodCost)); // subtract money
            setFood(fd: 100); // add food
        }
        else {
            // can only afford some
            CurrencyHandler.removeCurrency(curr: (foodBuyable * FoodCost)) // subtract money
            setFood(fd: getFood() + foodBuyable); // add food
        }
        foodLeftText.text = FoodHandler.getFood().description + "% Food Remaining"
    }
    
    // returns true on successful removal
    static func removeFood(fd: Int) -> Bool {
        if (getFood() - fd) < 0 {
            return false
        }
        UserDefaults.standard.set(UserDefaults.standard.integer(forKey:DefaultKeys.food)-fd, forKey: DefaultKeys.food)
        foodLeftText.text = FoodHandler.getFood().description + "% Food Remaining"
        return true
    }
    
    static func setFood(fd: Int) {
        UserDefaults.standard.set(fd, forKey: DefaultKeys.food)
    }
    
    static func getFood() -> Int {
        return UserDefaults.standard.integer(forKey:DefaultKeys.food)
    }
}
