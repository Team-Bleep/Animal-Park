//
//  CurrencyHandler.swift
//  AnimalPark
//
//  Created by William Chan on 2022-02-19.
//

struct  CurrencyHandler {
    // multiplier increases currency depending on time (in seconds)
    static let TimeCurrencyMultiplier = 5
    
    static func addCurrency(curr: Int) {
        UserDefaults.standard.set(UserDefaults.standard.integer(forKey:DefaultKeys.currency)+curr, forKey: DefaultKeys.currency)
    }
    
    // returns true on successful removal
    static func removeCurrency(curr: Int) -> Bool {
        if (getCurrency() - curr) < 0 {
            return false
        }
        UserDefaults.standard.set(UserDefaults.standard.integer(forKey:DefaultKeys.currency)-curr, forKey: DefaultKeys.currency)
        return true
    }
    
    static func setCurrency(curr: Int) {
        UserDefaults.standard.set(curr, forKey: DefaultKeys.currency)
    }
    
    static func getCurrency() -> Int {
        return UserDefaults.standard.integer(forKey:DefaultKeys.currency)
    }
}
