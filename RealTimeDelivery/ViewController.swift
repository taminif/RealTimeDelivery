//
//  ViewController.swift
//  RealTimeDelivery
//
//  Created by taminif on 2018/01/21.
//  Copyright © 2018年 taminif. All rights reserved.
//

import UIKit
import AVFoundation
import Firebase

class ViewController: UIViewController, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate {

    var db: Firestore!
    var roomNames: [String] = []
    var roomInfos: [String: [String: Any]] = [:]

    @IBOutlet var inputRoomName: UITextField!
    @IBOutlet var roomList: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        inputRoomName.delegate = self
        db = Firestore.firestore()

        db.collection("rooms").addSnapshotListener { querySnapshot, error in
            self.roomNames.removeAll()
            for document in querySnapshot!.documents {
                self.roomInfos[document.documentID] = document.data()
                self.roomNames.append(document.documentID)
            }
            self.roomList.reloadData()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // segue for myRoom
        if segue.identifier == "myRoomSegue" {
            let roomName = self.inputRoomName.text!
            let subVC: myRoomController = segue.destination as! myRoomController
            self.inputRoomName.text = ""
            db.collection("rooms").document(roomName).setData([
                "isOpen": false,
                "audience": 0
            ])
            subVC.roomName = roomName
        } else if segue.identifier == "audienceRoomSegue" {
            let roomDictionary: [String: String] = sender as! Dictionary
            guard let roomName = roomDictionary["roomName"], let ownerId = roomDictionary["ownerId"] else {
                return
            }
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

                transaction.updateData(["audience": oldAudience + 1], forDocument: roomReference)
            }) { (object, error) in
            }
            let subVC: audienceRoomController = segue.destination as! audienceRoomController
            subVC.roomName = roomName
            if !ownerId.isEmpty {
                subVC.ownerId = ownerId
            }
        }
    }

    // enter SFU room
    @IBAction func createButtonTapped(_ sender: Any) {
        let errorTitle = "input value is error"
        guard let inputRoomName = inputRoomName.text, inputRoomName != "" else {
            let alert = alertClass.getAlertController(title: errorTitle, message: "room name not input. please input room name")
            self.present(alert, animated: true, completion: { self.inputRoomName.becomeFirstResponder() })
            return
        }
        if self.roomNames.index(of: inputRoomName) != nil {
            let alert = alertClass.getAlertController(title: errorTitle, message: "room name already exists. please reinput room name")
            self.present(alert, animated: true, completion: { self.inputRoomName.becomeFirstResponder() })
            return
        }
        
        self.inputRoomName.resignFirstResponder()

        let alert = UIAlertController(title: "camera not permission",message: "please approve camera", preferredStyle: .alert)
        let alertAction: UIAlertAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(alertAction)

        let semaphore = DispatchSemaphore(value: 0)
        let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        switch cameraStatus {
        case .restricted, .notDetermined:
            AVCaptureDevice.requestAccess(for: .video, completionHandler: {(granted: Bool) in
                if !granted {
                    self.present(alert, animated: true, completion: nil)
                }
                semaphore.signal()
            })
            semaphore.wait()

        case .denied:
            self.present(alert, animated: true, completion: nil)

        default:
            break
        }
        let micStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        switch micStatus {
        case .restricted, .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio, completionHandler: {(granted: Bool) in
                if !granted {
                    self.present(alert, animated: true, completion: nil)
                }
                semaphore.signal()
            })
            semaphore.wait()

        case .denied:
            self.present(alert, animated: true, completion: nil)

        default:
            break
        }

        performSegue(withIdentifier: "myRoomSegue", sender: nil)
    }

    // allow Room Name String
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return string.isEmpty || string.range(of: "^[a-zA-Z0-9]+$", options: .regularExpression, range: nil, locale: nil) != nil || string.count >= 30
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.roomNames.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: roomListCell = tableView.dequeueReusableCell(withIdentifier: "roomListCell") as! roomListCell
        cell.roomName.text = self.roomNames[indexPath.row]
        let roomInfo: [String: Any] = self.roomInfos[self.roomNames[indexPath.row]]!
        let isOpen: Bool = roomInfo["isOpen"] as! Bool
        if !isOpen {
            cell.selectionStyle = .none
            cell.backgroundColor = UIColor.gray
        } else {
            cell.selectionStyle = .default
            cell.backgroundColor = UIColor.white
        }
        return cell
    }

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        switch indexPath.row {
        case 0:
            return indexPath;
        case 1:
            return nil;
        default:
            return indexPath;
        }
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let roomName = self.roomNames[indexPath.row]
        let roomRef = self.db.collection("rooms").document(roomName)
        let segueClosure = {(_ ownerId: String) -> () in
            self.performSegue(withIdentifier: "audienceRoomSegue", sender: ["roomName": roomName, "ownerId": ownerId])
        }

        roomRef.getDocument { (document, error) in
            if let document = document {
                let ownerId = (document.data()["ownerId"] as? String)!
                segueClosure(ownerId)
            }
        }
    }
}
