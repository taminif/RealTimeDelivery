//
//  audienceRoomController.swift
//  RealTimeDelivery
//
//  Created by taminif on 2018/02/25.
//  Copyright © 2018年 taminif. All rights reserved.
//

import UIKit
import SkyWay
import Firebase

class audienceRoomController: UIViewController {

    var db: Firestore!
    var peer: SKWPeer?
    var remoteStream: SKWMediaStream?
    var sfuRoom: SKWSFURoom?

    @IBOutlet var video: UIView!

    var roomName: String = ""
    var ownerId: String = ""

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
            self.setSFURoom()
        })

        peer?.on(.PEER_EVENT_CLOSE, callback: {obj in
            // self.ownId = ""
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
        let roomReference = self.db.collection("rooms").document(roomName)
        self.db.runTransaction({ (transaction, errorPointer) -> Void in
            let roomDocument: DocumentSnapshot
            do {
                try roomDocument = transaction.getDocument(roomReference)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return
            }

            guard let oldAudience = roomDocument.data()["audience"] as? Int else {
                let error = NSError(
                    domain: "AppErrorDomain",
                    code: -1,
                    userInfo: [
                        NSLocalizedDescriptionKey: "Unable to retrieve population from snapshot \(roomDocument)"
                    ]
                )
                errorPointer?.pointee = error
                return
            }

            transaction.updateData(["audience": oldAudience - 1], forDocument: roomReference)
        }) { (object, error) in
        }

        remoteStream = nil
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
        let roomReference = self.db.collection("rooms").document(roomName)
        self.db.runTransaction({ (transaction, errorPointer) -> Void in
            let roomDocument: DocumentSnapshot
            do {
                try roomDocument = transaction.getDocument(roomReference)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return
            }

            guard let oldAudience = roomDocument.data()["audience"] as? Int else {
                let error = NSError(
                    domain: "AppErrorDomain",
                    code: -1,
                    userInfo: [
                        NSLocalizedDescriptionKey: "Unable to retrieve population from snapshot \(roomDocument)"
                    ]
                )
                errorPointer?.pointee = error
                return
            }

            transaction.updateData(["audience": oldAudience - 1], forDocument: roomReference)
        }) { (object, error) in
        }

        _ = self.navigationController?.popViewController(animated: true)
    }

    func setSFURoom() {
        guard let peer = peer else {
            return
        }
        // create local video
        let constraints: SKWMediaConstraints = SKWMediaConstraints.init()
        constraints.maxWidth = 0
        constraints.minWidth = 0
        constraints.maxHeight = 0
        constraints.minHeight = 0
        constraints.cameraPosition = .CAMERA_POSITION_FRONT

        SKWNavigator.initialize(self.peer!)
        let localStream = SKWNavigator.getUserMedia(constraints)

        // join SFU room
        let option = SKWRoomOption.init()
        option.mode = .ROOM_MODE_SFU
        option.stream = localStream
        option.videoBandwidth = 0
        option.audioBandwidth = 0
        guard let sfuRoom = peer.joinRoom(withName: SkyWayConfig.roomNamePrefix + roomName, options: option) as? SKWSFURoom else {
            let alert = alertClass.getAlertController(title: "error", message: "try again")
            self.present(alert, animated: true, completion: nil) // TODO: text focus
            return
        }

        // room event handling
        sfuRoom.on(.ROOM_EVENT_OPEN, callback: {obj in
        })

        // room event handling
        sfuRoom.on(.ROOM_EVENT_STREAM, callback: {obj in
            let mediaStream: SKWMediaStream = obj as! SKWMediaStream
            guard let peerId = mediaStream.peerId, peerId == self.ownerId else {
                return
            }

            let skwVideo: SKWVideo = SKWVideo.init(frame: self.video.bounds)
            self.video.addSubview(skwVideo)
            mediaStream.addVideoRenderer(skwVideo, track: 0)
        })

        sfuRoom.on(.ROOM_EVENT_PEER_LEAVE, callback: {obj in
            let peerId = obj as! String
            guard peerId == self.ownerId else {
                return
            }
            let alert = alertClass.getAlertController(title: "Distributor was leaving", message: "this room will close. if you click \"OK\" will back to page.", handler: {(_) -> Void in
                _ = self.navigationController?.popViewController(animated: true)
            })
            self.present(alert, animated: true, completion: nil) // TODO: text focus
            return
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
