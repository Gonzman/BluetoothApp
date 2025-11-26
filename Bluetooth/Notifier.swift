//
//  Notify.swift
//  RC-Fernsteuerung
//
//  Created by Yuki Schaefer on 26.11.25.
//

import Foundation

class Notifier: ObservableObject {
    @Published var message: String?

    static let shared = Notifier()

    private init() {}

    func notify(_ message: String) {
        self.message = message
    }
}
