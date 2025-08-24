//
//  Agent.swift
//  CanParkHere
//
//  Created by Ibrahim Haroon on 8/24/25.
//

import Foundation

protocol Agent {
    associatedtype Context
    associatedtype Result
    
    func execute(_ context: Context) async throws -> Result
}

