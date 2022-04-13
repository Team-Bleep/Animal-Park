//
//  CurrencyHandler.swift
//  AnimalPark
//
//  Created by William Chan on 2022-02-19.
//

// Handles Animal Coin based on time
struct  CurrencyHandler {
    // multiplier increases currency depending on time (in seconds)
    static let TimeCurrencyMultiplier = 1
    
    static func addCurrency(curr: Int) {
        UserDefaults.standard.set(UserDefaults.standard.integer(forKey:DefaultKeys.currency)+curr, forKey: DefaultKeys.currency)
    }
    
    // returns true on successful removal
    static func removeCurrency(curr: Int) -> Void {
        if (getCurrency() - curr) < 0 {
            return
        }
        UserDefaults.standard.set(UserDefaults.standard.integer(forKey:DefaultKeys.currency)-curr, forKey: DefaultKeys.currency)
        dateLabelTest.text = CurrencyHandler.getCurrency().description + " Animal Coins"
        return
    }
    
    static func setCurrency(curr: Int) {
        UserDefaults.standard.set(curr, forKey: DefaultKeys.currency)
    }
    
    static func getCurrency() -> Int {
        return UserDefaults.standard.integer(forKey:DefaultKeys.currency)
    }
}
