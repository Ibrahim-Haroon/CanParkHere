//
//  HolidayChecker.swift
//  CanParkHere
//
//  Created by Ibrahim Haroon on 8/24/25.
//

import Foundation

struct HolidayChecker {
    static func isHoliday(date: Date = Date(), in location: String? = nil) -> Bool {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .day, .weekday], from: date)
        
        guard let month = components.month, let day = components.day else {
            return false
        }
        
        // Major US holidays (expand based on location)
        let holidays = [
            (1, 1),   // New Year's Day
            (7, 4),   // Independence Day
            (12, 25), // Christmas
            (12, 31), // New Year's Eve
        ]
        
        // Check fixed holidays
        if holidays.contains(where: { $0.0 == month && $0.1 == day }) {
            return true
        }
        
        // Check floating holidays (simplified)
        // Memorial Day (last Monday of May)
        if month == 5 && components.weekday == 2 && day > 24 {
            return true
        }
        
        // Labor Day (first Monday of September)
        if month == 9 && components.weekday == 2 && day <= 7 {
            return true
        }
        
        // Thanksgiving (fourth Thursday of November)
        if month == 11 && components.weekday == 5 && day >= 22 && day <= 28 {
            return true
        }
        
        return false
    }
}
