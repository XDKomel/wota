//
//  ContentView.swift
//  Wota
//
//  Created by Camille Khubbetdinov on 15.01.2021.
//

import SwiftUI
import Firebase
import Network

extension UIScreen{
   static let screenWidth = UIScreen.main.bounds.size.width
   static let screenHeight = UIScreen.main.bounds.size.height
   static let screenSize = UIScreen.main.bounds.size
}

extension UserDefaults {
    static var shared = UserDefaults(suiteName: "group.Wota.camille.com")
}

class FireStore: ObservableObject {
    let coll = "water"
    let doc = "XVtkG4TAljhAgUFcBPkA"
    let db = Firestore.firestore()
    var isConnected: Bool = false
    @Published var data: [String:Any] = [:]
    
    init() {
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                self.isConnected = true
                print("We're connected!")
            } else {
                self.isConnected = false
                print("No connection.")
            }
        }
        let queue = DispatchQueue(label: "Monitor")
        monitor.start(queue: queue)
    }
    
    func getData() {
        if UserDefaults.standard.value(forKey: "data") != nil {
            print("Cold boot data: \(UserDefaults.standard.value(forKey: "data") as! [String : Any])")
            self.data = UserDefaults.standard.value(forKey: "data") as! [String : Any]
        } else {
            print("No cold boot data")
        }
        if !isConnected {
            return
        }
        self.db.collection(self.coll).document(self.doc).getDocument { (document, error) in
            if let document = document, document.exists {
                self.data = document.data() ?? [:]
                UserDefaults.standard.setValue(self.data, forKey: "data")
                let dataDescription = document.data().map(String.init(describing:)) ?? "nil"
                print("Document data: \(dataDescription)")
            } else {
                print("Document does not exist")
            }
        }
    }
    func addTo(_ person: String) {
        if !isConnected {
            return
        }
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
        db.collection(self.coll).document(self.doc).setData(newData)
        let someDate = Date()
        let myTimeStamp = someDate.timeIntervalSince1970
        let docData: [String:Any] = [
            "name": person,
            "action": true,
            "time": myTimeStamp
        ]
        //var ref: DocumentReference? = nil
        db.collection(self.coll).addDocument(data: docData) { err in
            if let err = err {
                print("Error adding document: \(err)")
            } else {
                print("Document added")
            }
        }
    }
    func removeTo(_ person: String) {
        if !isConnected {
            return
        }
        var newData = self.data
        for i in self.data {
            if i.key == person {
                let value: Int = i.value as! Int
                newData[person] = value-1
            } else {
                newData[i.key] = i.value
            }
        }
        db.collection(self.coll).document(self.doc).setData(newData)
        let someDate = Date()
        let myTimeStamp = someDate.timeIntervalSince1970
        let docData: [String:Any] = [
            "name": person,
            "action": false,
            "time": myTimeStamp
        ]
        //var ref: DocumentReference? = nil
        db.collection(self.coll).addDocument(data: docData) { err in
            if let err = err {
                print("Error adding document: \(err)")
            } else {
                print("Document added")
            }
        }
    }
}

func getMinimal(dic: [String:Any]) -> Int {
    var newDic: [String:Int] = [:]
    for i in dic {
        newDic[i.key] = i.value as? Int
    }
    return newDic.values.min() ?? 1
}
func getMaximal(dic: [String:Any]) -> Int {
    var newDic: [String:Int] = [:]
    for i in dic {
        newDic[i.key] = i.value as? Int
    }
    return newDic.values.max() ?? 1
}

struct Score: View {
    let minValue = UIScreen.screenHeight * 0.2
    let maxValue = UIScreen.screenHeight * 0.8
    var amount: Int
    var height: CGFloat
    var name: String
    let fs: FireStore
    
    init(data: [String:Any], amount: Int, name: String, fs: FireStore) {
        self.fs = fs
        self.name = name
        self.amount = amount
        let one = (amount - getMinimal(dic: data))
        let two = (maxValue-minValue)
        var three: CGFloat = CGFloat(getMaximal(dic: data) - getMinimal(dic: data))
        if three == 0 {
            self.height = maxValue
        } else {
            three = 1/three
            self.height = CGFloat(one)*two*three + minValue
        }
        //print("\(one) \(two) \(three)")
    }
    var body: some View {
        VStack {
            ZStack {
                Rectangle()
                    .foregroundColor(.blue)
                VStack {
                    Spacer()
                    Text("\(self.amount)")
                        .foregroundColor(.white)
                        .bold()
                    Spacer()
                }
            }
            .frame(height: self.height)
            .contextMenu(ContextMenu(menuItems: {
                Button(action: {
                    withAnimation {
                        fs.addTo(self.name)
                        fs.getData()
                    }
                }, label: {
                    Text("Добавить")
                    Image(systemName: "plus")
                })
                Button(action: {
                    withAnimation {
                        fs.removeTo(self.name)
                        fs.getData()
                    }
                }, label: {
                    Text("Убрать")
                    Image(systemName: "minus")
                })
                
            }))
            Text(name).font(.caption)
        }
        //.padding(.vertical)
    }
}

struct Person: Hashable {
    var name: String
    var amount: Int
}

func setArray(_ dic: [String:Any]) -> [Person] {
    var array: [Person] = []
    for i in dic {
        array.append(Person(name: i.key, amount: i.value as! Int))
    }
    array.sort {$0.amount>$1.amount}
    return array
}

struct ContentView: View {
    @ObservedObject var fs = FireStore()
    var body: some View {
        ZStack {
            
            VStack {
                //Spacer().frame(height: 8)
                if !fs.isConnected && !fs.data.isEmpty {
                    Text("Нет подключения к интернету").font(.caption)
                }
                Spacer().frame(height: 8)
                HStack(alignment: .top, spacing: .none, content: {
                    Spacer().frame(width: 8)
                    ForEach(setArray(fs.data), id: \.self) { element in
                        Score(data: fs.data, amount: element.amount, name: element.name, fs: self.fs)
                    }
                    Spacer().frame(width: 8)
                })
                Spacer()
            }
            
        }
        .onAppear {
            fs.getData()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            fs.getData()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .previewDevice(.init(rawValue: "iPhone X"))
        ContentView()
            .previewDevice(.init(rawValue: "iPhone XS Max"))
    }
}
