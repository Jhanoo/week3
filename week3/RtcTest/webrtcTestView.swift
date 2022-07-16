//
//  webrtcTest.swift
//  week3
//
//  Created by Chanwoo on 2022/07/14.
//

import AVFoundation
import SwiftUI
import FirebaseFirestore
import WebRTC

let bounds: CGRect = UIScreen.main.bounds
var centerX: CGFloat = bounds.width / 2
var videoWidth: CGFloat = centerX
var videoHeight: CGFloat = centerX

let localRenderer = RTCMTLVideoView()
let remoteRenderer = RTCMTLVideoView()


class EscapingViewModel: ObservableObject {
    @Published var rooms: [String]
    var webRTCClient: WebRTCClient = WebRTCClient()
    
    init() {
        rooms = []
        doSomething()
        self.webRTCClient.delegate = self
    }
    
    func updateFromFire(completion: @escaping ([String]) -> Void) {
        db.collection("rooms").addSnapshotListener{ [self] snapshot, error in
            print("rooms refresh")
            guard snapshot != nil else {
                print("Error fetching document: \(error!)")
                return
            }
            
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
    @State var myRoom: Room
    @State var roomRef: DocumentReference?
    
    
    init() {
        roomRef = nil
        myRoom = Room.init()
    }
    
    
    var body: some View {
        List(ViewModel.rooms, id: \.self){roomID in
            Button(action: {
                myRoom.roomId = roomID
                ViewModel.webRTCClient.roomId = roomID
                myRoom.joinRoom(webRTCClient: ViewModel.webRTCClient)
            }) {
                Text(roomID)
            }
        }
        
        Button {
            roomRef = myRoom.createRoom(webRTCClient: ViewModel.webRTCClient)
            ViewModel.webRTCClient.roomId = myRoom.roomId
            ViewModel.webRTCClient.listenCallee(roomRef: roomRef!)

        } label: {
            Text("create")
        }
        
        HStack {
            localVideoView()
                .frame(width: videoWidth, height: videoHeight)
            Spacer()
            remoteVideoView()
                .frame(width: videoWidth, height: videoHeight)
        }
    }
}

struct webrtcTest_Previews: PreviewProvider {
    static var previews: some View {
        webrtcTestView()
    }
}

struct localVideoView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        return localRenderer
    }
    
    func updateUIView(_ view: UIView, context: Context) {
    }
}

struct remoteVideoView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        return remoteRenderer
    }
    
    func updateUIView(_ view: UIView, context: Context) {
    }
}


extension EscapingViewModel: WebRTCClientDelegate {
    func webRTCClient(_ client: WebRTCClient, didDiscoverLocalCandidate candidate: RTCIceCandidate) {
        print("did discover local candidate")
        client.sendCandidate(candidate: candidate)
    }
    
    func webRTCClient(_ client: WebRTCClient, didCreateLocalCapturer capturer: RTCCameraVideoCapturer) {
        print("local cam created")
    }
    
    func webRTCClient(_ client: WebRTCClient, didChangeSignaling stateChanged: RTCSignalingState) {
        DispatchQueue.main.async { [self] in
            if stateChanged.rawValue == 1 || stateChanged.rawValue == 3 { //  have local/remote offer
                print("signaling have offer -> local render")
                localRenderer.videoContentMode = .scaleAspectFill
                client.startCaptureLocalVideo(renderer: localRenderer, front: true)
            }
        }
    }
    
    func webRTCClient(_ client: WebRTCClient, didChangeIceConnection newState: RTCIceConnectionState) {
        DispatchQueue.main.async { [self] in
            if newState.rawValue == 2 { // connected
                print("ice connection connected -> remote render")
                remoteRenderer.videoContentMode = .scaleAspectFill
                client.renderRemoteVideo(to: remoteRenderer)
            }
            
            else if newState.rawValue == 4 || newState.rawValue == 5 || newState.rawValue == 6 { // failed, disconnected, closed
//                initVideoView()
                print("카메라 꺼")
//                let r = myAvatar?.position[0]
//                let c = myAvatar?.position[1]
//
//                 미팅 안 없어졌으면 hangup
//                for i in 0...3 {
//                    let m = myVillage?.meetingRooms[i]
//                    if (m?.caller?.position[0] == r && m?.caller?.position[1] == c) || (m?.callee?.position[0] == r && m?.callee?.position[1] == c) {
//                        if m?.isRoomOpened == true {
//                            m?.hangUp(webRTCClient: self.webRTCClient)
//                        }
//                        break
//                    }
//                }

//                micButton.isEnabled = false
//                cameraButton.isEnabled = false
            }
        }
        
    }
    
    func webRTCClient(_ client: WebRTCClient, didAdd stream: RTCMediaStream) {
        print("Add stream")
//        DispatchQueue.main.async {
//            print("did add stream -> remote render")
//            let remoteRenderer = RTCMTLVideoView(frame: CGRect(x: 0, y: 0, width: self.remoteVideoView.frame.width, height: self.remoteVideoView.frame.height))
//            remoteRenderer.videoContentMode = .scaleAspectFill
//            client.renderRemoteVideo(to: remoteRenderer)
//            self.remoteVideoView.addSubview(remoteRenderer)
//            self.remoteVideoView.layoutIfNeeded()
//        }
    }
    
}
