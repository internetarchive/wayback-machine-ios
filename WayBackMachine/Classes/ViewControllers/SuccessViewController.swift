//
//  SuccessViewController.swift
//  WM
//
//  Created by Admin on 05/02/17.
//  Copyright © 2017 Admin. All rights reserved.
//

import UIKit

class SuccessViewController: UIViewController {

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var imageViewSuccess: UIImageView!
    @IBOutlet weak var btnShare: UIButton!
    @IBOutlet weak var btnDone: UIButton!
    
    var url:String? = nil;
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        containerView.layer.cornerRadius = 10
        
        imageViewSuccess.layer.cornerRadius = imageViewSuccess.frame.width / 2
        imageViewSuccess.layer.masksToBounds = true
        
        btnShare.layer.cornerRadius = 10
        btnDone.layer.cornerRadius = 10

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - Actions
    @IBAction func _onShare(_ sender: Any) {
        if (url?.isEmpty)! {
            return
        }
        
        self.displayShareSheet(url: url!)
    }

    @IBAction func _onDone(_ sender: Any) {
        self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        exit(0)
    }
    
    func displayShareSheet(url: String) {
        let activityViewController = UIActivityViewController(activityItems: [url as NSString], applicationActivities: nil)
        activityViewController.completionWithItemsHandler = {
            (activityType, completed, returnedItems, err) -> Void in
            
            if (completed) {
                print("completed")
            } else {
                print("user cancelled")
            }
            
            if (err != nil) {
                print("error occured")
            }
        }
        
        self.present(activityViewController, animated: true, completion: {})
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
