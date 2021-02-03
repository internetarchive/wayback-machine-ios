//
//  ArchiveVC.swift
//  WayBackMachine
//
//  Created by Admin on 31/01/17.
//  Copyright © 2017 Admin. All rights reserved.
//

import UIKit
import AVFoundation
import Social
import MobileCoreServices
import MBProgressHUD
import FRHyperLabel

class ArchiveVC: UIViewController, UIImagePickerControllerDelegate, UIPopoverControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate{

    @IBOutlet weak var shareView: UIView!
    @IBOutlet weak var urlTextField: UITextField!
    @IBOutlet weak var btnCancel: UIButton!
    @IBOutlet weak var btnSave: UIButton!
    
    @IBOutlet weak var uploadView: UIView!
    @IBOutlet weak var innerView: UIView!
    @IBOutlet weak var txtTitle: UITextField!
    @IBOutlet weak var txtDescription: UITextView!
    @IBOutlet weak var txtSubjectTags: UITextField!
    @IBOutlet weak var preview: UIView!
    @IBOutlet weak var imgPreview: UIImageView!
    @IBOutlet weak var videoPreview: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    var fileURL: URL?
    var fileData: Data?
    var mediaType: String?
    var placeholderLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // ------UI------
        shareView.layer.cornerRadius = 10
        urlTextField.isUserInteractionEnabled = false
        urlTextField.textAlignment = .center
        urlTextField.layer.borderWidth = 0.5
        urlTextField.layer.borderColor = UIColor.lightGray.cgColor
        txtTitle.layer.borderWidth = 0.5
        txtTitle.layer.borderColor = UIColor.lightGray.cgColor
        txtSubjectTags.layer.borderWidth = 0.5
        txtSubjectTags.layer.borderColor = UIColor.lightGray.cgColor
        btnSave.layer.cornerRadius = 10
        btnCancel.layer.cornerRadius = 10
        
        uploadView.layer.cornerRadius = 10
        innerView.layer.cornerRadius = 10
        
        txtDescription.layer.borderWidth = 0.5
        txtDescription.layer.cornerRadius = 5
        txtDescription.layer.borderColor = UIColor.lightGray.cgColor
        txtDescription.backgroundColor = UIColor.white
        txtDescription.delegate = self
        placeholderLabel = UILabel()
        placeholderLabel.text = "Description"
        placeholderLabel.sizeToFit()
        placeholderLabel.font = placeholderLabel.font.withSize(14)
        txtDescription.addSubview(placeholderLabel)
        placeholderLabel.frame.origin = CGPoint(x:5, y: (txtDescription.font?.pointSize)! / 2)
        placeholderLabel.textColor = UIColor.lightGray
        placeholderLabel.isHidden = !txtDescription.text.isEmpty
        
        preview.layer.borderWidth = 0.5
        preview.layer.cornerRadius = 5
        preview.layer.borderColor = UIColor.lightGray.cgColor
        
        videoPreview.layer.cornerRadius = 5
        
        shareView.isHidden = true
        uploadView.isHidden = true
        
        if let inputItem = self.extensionContext?.inputItems.first as? NSExtensionItem,
            let attachmentsKeys = inputItem.userInfo?[NSExtensionItemAttachmentsKey] as? [NSItemProvider] {
            var itemProvider: NSItemProvider?
            var contentType: String = ""
            
            for item in attachmentsKeys {
                itemProvider = item
                if item.hasItemConformingToTypeIdentifier(kUTTypeURL as String) {
                    contentType = kUTTypeURL as String
                    break
                } else if item.hasItemConformingToTypeIdentifier(kUTTypeImage as String) {
                    contentType = kUTTypeImage as String
                    break
                } else if item.hasItemConformingToTypeIdentifier(kUTTypeMovie as String) {
                    contentType = kUTTypeMovie as String
                    break
                }
            }
            
            if itemProvider == nil {
                return;
            }
            
            itemProvider?.loadItem(forTypeIdentifier: contentType, options: nil, completionHandler: {(result, error) in
                if let result = result, error == nil {
                    self.performSelector(onMainThread: #selector(self.processResult(_:)), with: ["data": result, "contentType": contentType], waitUntilDone: false)
                } else {
                    let errorAlert = UIAlertController(title: "", message: "Error occured when grab url.", preferredStyle: .alert)
                    errorAlert.addAction(UIAlertAction(title: "OK", style: .default) {action in
                        
                    })
                    self.present(errorAlert, animated: true)
                }
            })
        }
        
        // TapGestureRecognizer
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
    }

    @objc func processResult(_ result: Any) -> Void {

      if let result = result as? [String: Any],
         let data = result["data"],
         let contentType = result["contentType"] as? String,
         let url = data as? URL
      {
        DispatchQueue.main.async {
            if contentType == kUTTypeURL as String {
                self.shareView.isHidden = false
                self.urlTextField.text = url.absoluteString
            } else if contentType == kUTTypeImage as String {
                self.uploadView.isHidden = false
                self.imgPreview.isHidden = false
                self.videoPreview.isHidden = true
                do {
                    let fileData = try Data(contentsOf: url)
                    self.fileURL = url
                    self.mediaType = "image"
                    self.imgPreview.image = UIImage(data: fileData)
                    self.imgPreview.contentMode = .scaleAspectFit
                } catch (let error) {
                    print("error print", error.localizedDescription)
                }
            } else if contentType == kUTTypeMovie as String {
                self.uploadView.isHidden = false
                self.imgPreview.isHidden = true
                self.videoPreview.isHidden = false
                
                self.fileURL = url
                self.mediaType = "video"
                let videoPlayer = AVPlayer(url: url as URL)
                let playerLayer = AVPlayerLayer(player: videoPlayer)
                playerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
                self.videoPreview.layer.addSublayer(playerLayer)
                playerLayer.frame = self.videoPreview.layer.bounds
                videoPlayer.play()
            }
        }
      }
    }
    
    private func clearFields() -> Void {
        txtTitle.text = ""
        txtDescription.text = ""
        placeholderLabel.isHidden = !txtDescription.text.isEmpty
        txtSubjectTags.text = ""
        fileURL = nil
        fileData = nil
        imgPreview.image = nil
        imgPreview.isHidden = true
        videoPreview.isHidden = true
    }
    
    private func validateFields() -> Bool {
        if txtTitle.text == "" {
            WMGlobal.showAlert(title: "Title is required", message: "", target: self)
            return false
        } else if txtDescription.text == "" {
            WMGlobal.showAlert(title: "Description is required", message: "", target: self)
            return false
        } else if txtSubjectTags.text == "" {
            WMGlobal.showAlert(title: "Subject Tags is required", message: "", target: self)
            return false
        } else if fileURL == nil {
            WMGlobal.showAlert(title: "You need to attach photo or video", message: "", target: self)
            return false
        }
        
        return true
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    //- MARK: Actions
    @IBAction func _onOK(_ sender: Any) {
        let userData = WMGlobal.getUserData()
        if let userData = userData,
           let userProps = userData["logged-in-user"] as? [HTTPCookiePropertyKey : Any],
           let sigProps = userData["logged-in-sig"] as? [HTTPCookiePropertyKey : Any],
           let loggedInUser = HTTPCookie.init(properties: userProps),
           let loggedInSig = HTTPCookie.init(properties: sigProps)
        {
            let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
            WMAPIManager.sharedManager.checkURLBlocked(url: self.urlTextField.text!, completion: { (isBlocked) in
                if isBlocked {
                    MBProgressHUD.hide(for: self.view, animated: true)
                    WMGlobal.showAlert(title: "Error", message: "That site's robots.txt policy requests we not archive it.", target: self)
                } else {
                    hud.label.text = "Archiving..."
                    hud.detailsLabel.text = "May take a while."
                    WMAPIManager.sharedManager.request_capture(url: self.urlTextField.text!, logged_in_user: loggedInUser, logged_in_sig: loggedInSig, completion: { (job_id) in
                        if job_id == nil {
                            MBProgressHUD.hide(for: self.view, animated: true)
                        } else {
                            WMAPIManager.sharedManager.request_capture_status(job_id: job_id!, logged_in_user: loggedInUser, logged_in_sig: loggedInSig, completion: { (url, error) in
                                MBProgressHUD.hide(for: self.view, animated: true)
                                if url == nil {
                                    WMGlobal.showAlert(title: "Error", message: (error ?? ""), target: self)
                                } else {
                                    let storyBoard = UIStoryboard(name: "Main", bundle: nil)
                                    if let shareVC = storyBoard.instantiateViewController(withIdentifier: "ShareVC") as? ShareVC {
                                        shareVC.modalPresentationStyle = .fullScreen
                                        shareVC.url = url ?? ""
                                        DispatchQueue.main.async {
                                            self.present(shareVC, animated: true, completion: nil)
                                        }
                                    }
                                }
                            })
                        }
                    })
                }
            })
        } else {
            WMGlobal.showAlert(title: "", message: "You need to login through Wayback Machine app.", target: self)
        }
    }
    
    @IBAction func _onCancel(_ sender: Any) {
        exit(0)
    }
    
    @IBAction func _onUpload(_ sender: Any) {
        if !validateFields() {
            return
        }
        guard let userData = WMGlobal.getUserData(), let fileUrl = fileURL else {
            return
        }
        let identifier = (userData["screenname"] as? String ?? "") + "_" + String(format: "%d", Int(NSDate().timeIntervalSince1970))
        let s3accesskey = userData["s3accesskey"] as? String ?? ""
        let s3secretkey = userData["s3secretkey"] as? String ?? ""
        let title = txtTitle.text ?? ""
        let description = txtDescription.text ?? ""
        let subjectTags = txtSubjectTags.text ?? ""
        let filename = "\(identifier).\(fileUrl.pathExtension)"
        let startTime = Date()
        MBProgressHUD.showAdded(to: self.view, animated: true)
        
        WMAPIManager.sharedManager.SendDataToBucket(params: [
            "identifier" : identifier,
            "title": title,
            "description": description,
            "tags": subjectTags,
            "filename" : filename,
            "mediatype" : mediaType,
            "s3accesskey" : s3accesskey,
            "s3secretkey" : s3secretkey,
            "data" : (fileData != nil) ? fileData! : fileUrl
        ]) { (success, uploadedFileSize) in
            let endTime = Date()
            let interval = endTime.timeIntervalSince(startTime)
            
            let dcf = DateComponentsFormatter()
            dcf.allowedUnits = [.minute, .second]
            dcf.unitsStyle = .brief
            let duration = dcf.string(from: TimeInterval(interval)) ?? ""
            
            let bcf = ByteCountFormatter()
            bcf.allowedUnits = [.useMB]
            bcf.countStyle = .file
            let filesize = bcf.string(fromByteCount: uploadedFileSize)
            
            self.clearFields()
            MBProgressHUD.hide(for: self.view, animated: true)
            
            if success {
                self.showSuccessAlert(filesize: filesize, duration: duration, uploadedURL: "https://archive.org/details/\(identifier)")
            } else {
                let alertController = UIAlertController(title: "Uploading failed", message: "", preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "OK", style: .default) {action in
                    exit(0)
                })
                self.present(alertController, animated: true)
            }
        }
    }
    
    func showSuccessAlert(filesize: String, duration: String, uploadedURL: String) -> Void {
        let alert = UIAlertController(title: "\n\n\n\n\n\n", message: nil, preferredStyle: .alert)
        let customViewWidth: CGFloat = 270
        let viewRect = CGRect(x:0, y:0, width: customViewWidth, height: 250)
        let customView = UIView(frame: viewRect)
        customView.layer.cornerRadius = 20.0
        customView.clipsToBounds = true
        
        let titleRect = CGRect(x: 13.0, y: 17.0, width: customViewWidth - 26, height: 40)
        let titleLabel = UILabel(frame: titleRect)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.font = UIFont.boldSystemFont(ofSize: 17.0)
        titleLabel.text = "Upload successful"
        titleLabel.sizeToFit()
        titleLabel.center = CGPoint(x: customViewWidth/2, y: titleLabel.frame.size.height/2 + 17.0)
        customView.addSubview(titleLabel)
        
        let message = "Uploaded \(filesize) \nIn \(duration) \n\nAvailable here \(uploadedURL)"
        var txtMessageRect = CGRect(x: 13.0, y: 67, width: customViewWidth - 26, height: 200)
        
        let txtMessageContent = UITextView(frame: txtMessageRect)
        txtMessageContent.font = UIFont.systemFont(ofSize: 15.0)
        txtMessageContent.textAlignment = .center
        txtMessageContent.isEditable = false
        txtMessageContent.dataDetectorTypes = [
            .address,
            .link,
            .phoneNumber
        ]
        
        txtMessageContent.delegate = self
        txtMessageContent.text = message
        txtMessageContent.sizeToFit()
        txtMessageRect.size.height = txtMessageContent.frame.height
        txtMessageContent.frame = txtMessageRect
        txtMessageContent.backgroundColor = UIColor.clear
        
        customView.addSubview(txtMessageContent)
        customView.frame.size.height = txtMessageRect.maxY + 20
        
        alert.view.addSubview(customView)
        
        alert.addAction(UIAlertAction(title: "OK", style: .default) {action in
            exit(0)
        })
        
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if scrollView.contentInset.bottom == 0 {
                scrollView.contentInset.bottom = keyboardSize.height
                scrollView.contentOffset.y = keyboardSize.height
            }
            
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        if scrollView.contentInset.bottom > 0 {
            scrollView.contentInset.bottom = 0
            scrollView.contentOffset.y = 0
        }
    }
}

extension ArchiveVC: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        if let webPageVC = self.storyboard?.instantiateViewController(withIdentifier: "WebPageVC") as? WebPageVC {
            webPageVC.url = URL.absoluteString
            webPageVC.modalPresentationStyle = .fullScreen
            dismiss(animated: true, completion: {
                self.present(webPageVC, animated: true, completion: nil)
            })
        }
        return false
    }
    
    func textViewDidChange(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.isEmpty
    }
}
