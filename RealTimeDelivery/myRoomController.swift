//
//  myRoomController.swift
//  RealTimeDelivery
//
//  Created by taminif on 2018/01/21.
//  Copyright © 2018年 taminif. All rights reserved.
//

import UIKit
import SkyWay
import Firebase

class myRoomController: UIViewController {

    var ownId: String = "" {
        didSet {
            if self.roomName.isEmpty {
                return
            }
            let roomReference = self.db.collection("rooms").document(self.roomName)
            self.db.runTransaction({ (transaction, errorPointer) -> Void in
                transaction.updateData(["ownerId": self.ownId], forDocument: roomReference)
            }) { (object, error) in
            }
        }
    }

    var db: Firestore!
    var peer: SKWPeer?
    var localStream: SKWMediaStream?
    var sfuRoom: SKWSFURoom?

    @IBOutlet var myVideo: UIView!

    var roomName: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        db = Firestore.firestore()
        self.navigationItem.title = roomName
        let newBackButton = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(self.closeMyRoom))
        self.navigationItem.setLeftBarButton(newBackButton, animated: true)

        // peer connection
        let options: SKWPeerOption = SKWPeerOption.init()
        options.key = SkyWayConfig.apiKey
        options.domain = SkyWayConfig.domain
        // options.debug = .DEBUG_LEVEL_ALL_LOGS
        peer = SKWPeer.init(options: options)

        // peer event handling
        peer?.on(.PEER_EVENT_OPEN, callback: {obj in
            self.ownId = obj as! String

            // create local video
            let constraints: SKWMediaConstraints = SKWMediaConstraints.init()
            constraints.maxWidth = 640
            constraints.minWidth = 640
            constraints.maxHeight = 480
            constraints.minHeight = 480
            constraints.cameraPosition = .CAMERA_POSITION_FRONT

            SKWNavigator.initialize(self.peer!)
            self.localStream = SKWNavigator.getUserMedia(constraints)
            let video: SKWVideo = SKWVideo.init(frame: self.myVideo.bounds)
            self.myVideo.addSubview(video)
            self.localStream?.addVideoRenderer(video, track: 0)

            self.setSFURoom()
        })

        peer?.on(.PEER_EVENT_CLOSE, callback: {obj in
            SKWNavigator.terminate()
            self.peer = nil
        })

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.isIdleTimerDisabled = true
    }

    override func viewDidDisappear(_ animated: Bool) {
        UIApplication.shared.isIdleTimerDisabled = false
        super.viewDidDisappear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    deinit {
        db.collection("rooms").document(roomName).delete()

        localStream = nil
        sfuRoom = nil
        peer = nil
    }

    @objc func closeMyRoom() {
        guard let sfuRoom = self.sfuRoom else {
            return
        }
        // leave SFU room
        sfuRoom.close()
        // remove FireStore room
        db.collection("rooms").document(roomName).delete()
        _ = self.navigationController?.popViewController(animated: true)
    }

    func setSFURoom() {
        guard let peer = peer else {
            return
        }
        // join SFU room
        let option = SKWRoomOption.init()
        option.mode = .ROOM_MODE_SFU
        option.stream = self.localStream
        guard let sfuRoom = peer.joinRoom(withName: SkyWayConfig.roomNamePrefix + roomName, options: option) as? SKWSFURoom else {
            let alert = alertClass.getAlertController(title: "error", message: "try again")
            self.present(alert, animated: true, completion: nil) // TODO: text focus
            return
        }

        // room event handling
        sfuRoom.on(.ROOM_EVENT_OPEN, callback: {obj in
            // set room on firestore
            let roomReference = self.db.collection("rooms").document(self.roomName)
            self.db.runTransaction({ (transaction, errorPointer) -> Void in
                transaction.updateData(["isOpen": true], forDocument: roomReference)
            }) { (object, error) in
            }
        })

        sfuRoom.on(.ROOM_EVENT_CLOSE, callback: {obj in
            // leave SFU room
            if let sfuRoom = self.sfuRoom {
                sfuRoom.offAll()
                self.sfuRoom = nil
            }
        })
        self.sfuRoom = sfuRoom
    }
}
