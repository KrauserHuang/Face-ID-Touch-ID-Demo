//
//  ViewController.swift
//  Face ID Touch ID Demo
//
//  Created by Tai Chin Huang on 2022/8/13.
//

import UIKit
import LocalAuthentication

class ViewController: UIViewController {
    
    @IBOutlet weak var stateView: UIView!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var faceIDLabel: UILabel!
    
    /// An authentication context stored at class scope so it's available for use during UI updates.
    var context = LAContext()
    
    var buttonTitle = String()
    
    /// The available states of being logged in or not.
    enum AuthenticationState {
        case loggedin, loggedout
    }
    
    /// The current authentication state.
    @MainActor
    var state = AuthenticationState.loggedout {
        // update the UI on a change
        didSet {
            loginButton.isHighlighted = state == .loggedin // The button text changes on highlight
            stateView.backgroundColor = state == .loggedin ? .green : .red
            
            buttonTitle = (state == .loggedin) ? "Log Out" : "Log In"
            loginButton.setTitle(buttonTitle, for: .normal)
            
            // FaceID runs right away on evaluation, so you might want to warn the user.
            //  In this app, show a special Face ID prompt if the user is logged out, but
            //  only if the device supports that kind of authentication.
            //當裝置支援FaceID，然後是登出狀態才會顯示
            faceIDLabel.isHidden = (state == .loggedin) || (context.biometryType != .faceID)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // The biometryType, which affects this app's UI when state changes, is only meaningful
        //  after running canEvaluatePolicy. But make sure not to run this test from inside a
        //  policy evaluation callback (for example, don't put next line in the state's didSet
        //  method, which is triggered as a result of the state change made in the callback),
        //  because that might result in deadlock.
        /*
         LAPolicy是enum
         
         只支援FaceID/TouchID
         deviceOwnerAuthenticationWithBiometrics = 1
         
         支援FaceID/TouchID/Passcode(使用者密碼)
         deviceOwnerAuthentication
         */
        context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
        
        // Set the initial app state. This impacts the initial state of the UI as well.
        state = .loggedout
    }
    
    @IBAction func tapButton(_ sender: UIButton) {
        if state == .loggedin {
            
            // Log out immediately.
            state = .loggedout
        } else {
            
            // Get a fresh context for each login. If you use the same context on multiple attempts
            //  (by commenting out the next line), then a previously successful authentication
            //  causes the next policy evaluation to succeed without testing biometry again.
            //  That's usually not what you want.
            context = LAContext() //需要在可以重新登入處執行context = LAContext()，因為移除的話他會認定你已經確認過biometry而直接登入(但我們需要每次都執行)
            
            context.localizedCancelTitle = "Enter Username/Password" //當FaceID認證失敗時，cancel欄位所顯示的內容
            context.localizedFallbackTitle = "你是去整形了嗎？" //當FaceID認證失敗多次(第二次就跳了)，cancel欄位所顯示的內容，在點他會變成需要輸入使用者密碼
            
            // First check if we have the needed hardware support.
            var error: NSError?
            //確認支援FaceID/TouchID/Passcode
            guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
                print(error?.localizedDescription ?? "Can't evaluate policy")
                
                // Fall back to a asking for username and password.
                // ...
                return
            }
            //可以驗證情形下驗證失敗後切到passcode後顯示字眼
            let reason = "選用輸入帳密方式或取消登入"
//            let reason = "Log in to your account"
            Task {
                do {
                    try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
                    state = .loggedin
                } catch let error {
                    print(error.localizedDescription)
                    print("出事拉阿北")
                    // Fall back to a asking for username and password.
                    // ...
                }
            }
        }
    }
}

