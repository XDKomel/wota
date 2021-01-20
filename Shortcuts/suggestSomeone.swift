//
//  suggestSomeone.swift
//  Shortcuts
//
//  Created by Camille Khubbetdinov on 17.01.2021.
//

import Foundation
import Intents
import Firebase

class SuggestIntentHandler: NSObject, SuggestIntentHandling {
    func handle(intent: SuggestIntent, completion: @escaping (SuggestIntentResponse) -> Void) {
        FirebaseApp.configure()
        let fs = FireStore()
        let name = fs.suggest()
        completion(SuggestIntentResponse.success(name: name))
    }
    
    
}
