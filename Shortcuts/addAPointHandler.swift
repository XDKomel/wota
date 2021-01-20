//
//  addAPointHandler.swift
//  Shortcuts
//
//  Created by Camille Khubbetdinov on 16.01.2021.
//

import Foundation
import Intents
import Firebase

struct Person: Hashable {
    var name: String
    var amount: Int
}

class FireStore {
    let coll = "water"
    let doc = "XVtkG4TAljhAgUFcBPkA"
    var data: [String:Any] = [:]
    let db = Firestore.firestore()
    
    func addTo(_ person: String) {
        let group = DispatchGroup()
        group.enter()
        DispatchQueue.main.async {
            self.db.collection(self.coll).document(self.doc).getDocument { (document, error) in
                if let document = document, document.exists {
                    self.data = document.data() ?? [:]
                    group.leave()
                    let dataDescription = document.data().map(String.init(describing:)) ?? "nil"
                    print("Document data: \(dataDescription)")
                } else {
                    print("Document does not exist")
                }
            }
        }
        
        group.notify(queue: .main, execute: {
            var newData = self.data
            print("OLD: \(newData)")
            for i in self.data {
                if i.key == person {
                    let value: Int = i.value as! Int
                    newData[person] = value+1
                } else {
                    newData[i.key] = i.value
                }
            }
            print("NEW: \(newData)")
            self.db.collection(self.coll).document(self.doc).setData(newData)
            let someDate = Date()
            let myTimeStamp = someDate.timeIntervalSince1970
            let docData: [String:Any] = [
                "name": person,
                "action": true,
                "time": myTimeStamp
            ]
            //var ref: DocumentReference? = nil
            self.db.collection(self.coll).addDocument(data: docData) { err in
                if let err = err {
                    print("Error adding document: \(err)")
                } else {
                    print("Document added")
                }
            }
        })
    }
    
    func suggest() -> String {
        var array: [Person] = []
        let group = DispatchGroup()
        group.enter()
        DispatchQueue.global().async {
            self.db.collection(self.coll).document(self.doc).getDocument { (document, error) in
                if let document = document, document.exists {
                    self.data = document.data() ?? [:]
                    group.leave()
                    let dataDescription = document.data().map(String.init(describing:)) ?? "nil"
                    print("Document data: \(dataDescription)")
                } else {
                    print("Document does not exist")
                }
            }
        }
        
        group.wait()
        print("data is \(self.data)")
        for i in self.data {
            array.append(Person(name: i.key, amount: i.value as! Int))
        }
        array.sort {$0.amount<$1.amount}
        
        print("array is \(array)")
        return array[0].name
    }
}

class AddAPointHandler: NSObject, AddIntentHandling {
    func resolveName(for intent: AddIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
        if let name = intent.name {
            //AddIntentResponse.success(result: intent.name!)
            completion(INStringResolutionResult.success(with: name))
        } else {
            completion(INStringResolutionResult.unsupported())
        }
    }
    
    func handle(intent: AddIntent, completion: @escaping (AddIntentResponse) -> Void) {
        if let name = intent.name {
            FirebaseApp.configure()
            let fs = FireStore()
            
            fs.addTo(name)
        
            
            completion(AddIntentResponse.success(result: name))
        } else {
            //completion(AddIntentResponse.fail)
        }
    }
    
    
}
