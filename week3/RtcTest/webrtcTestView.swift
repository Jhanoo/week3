//
//  webrtcTest.swift
//  week3
//
//  Created by Chanwoo on 2022/07/14.
//

import SwiftUI
import FirebaseFirestore

class EscapingViewModel: ObservableObject {
    @Published var rooms: [String]
    
    init() {
        rooms = []
    }
    
    func updateFromFire(completion: @escaping ([String]) -> Void) {
        var docArr : [String] = []
        db.collection("rooms").getDocuments() { (querySnapshot, error) in
            if let error = error {
                print("Error getting doucments: \(error)")
            }
            else {
                for document in querySnapshot!.documents{
                    print("document ID = \(document.documentID)")
                    docArr.append(document.documentID)
                }

                completion(docArr)
                print("updateFromFIre")
            }
        }
    }
    
    func doSomething() {
        self.updateFromFire(completion: { (docArr) in
            self.rooms = docArr
        })
    }
    
}

struct webrtcTestView: View {
    @StateObject var ViewModel = EscapingViewModel()
    struct roomInfo: Identifiable{
        var id = UUID()
        var roomId: String
    }
    
    @State private var selection = Set<UUID>()
    
    var webRTCClient: WebRTCClient = WebRTCClient()
    @State var myRoom: Room
    @State var roomRef: DocumentReference?
    
    
    init() {
        roomRef = nil
        //            roomRef = myR
        myRoom = Room.init()
        ViewModel.doSomething()
    }
    
    
    var body: some View {
        
        
        Button {
            roomRef = myRoom.createRoom(webRTCClient: webRTCClient)
            webRTCClient.listenCallee(roomRef: roomRef!)

        } label: {
            Text("create")
        }
        Button {
            myRoom.joinRoom(webRTCClient: webRTCClient)
        } label: {
            Text("join")
        }

        
    }
}

struct webrtcTest_Previews: PreviewProvider {
    static var previews: some View {
        webrtcTestView()
    }
}