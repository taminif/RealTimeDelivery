//
//  alertClass.swift
//  RealTimeDelivery
//
//  Created by taminif on 2018/01/25.
//  Copyright © 2018年 taminif. All rights reserved.
//

import UIKit

class alertClass {
    static func getAlertController(title: String = "", message: String = "") -> UIAlertController {
        return getAlertController(title: title, message: message, handler: nil)
    }

    static func getAlertController(title: String = "", message: String = "", handler: ((UIAlertAction) -> Void)?) -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let alertAction: UIAlertAction
        alertAction = UIAlertAction(title: "OK", style: .default, handler: handler)
        alert.addAction(alertAction)
        return alert
    }
}
