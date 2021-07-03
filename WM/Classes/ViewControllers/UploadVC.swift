//
//  UploadVC.swift
//  WM
//
//  Created by mac-admin on 3/5/18.
//  Copyright © 2018 Admin. All rights reserved.
//

import UIKit
import AVFoundation
import MBProgressHUD
import FRHyperLabel
import Photos

class UploadVC: UIViewController, UIImagePickerControllerDelegate, UIPopoverControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var txtTitle: UITextField!
    @IBOutlet weak var txtDescription: UITextView!
    @IBOutlet weak var txtSubjectTags: UITextField!
    @IBOutlet weak var btnAttach: WMButton!
    @IBOutlet weak var preview: UIView!
    @IBOutlet weak var imgPreview: UIImageView!
    @IBOutlet weak var videoPreview: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    var picker: UIImagePickerController! = UIImagePickerController()
    var fileURL: URL?
    var fileData: Data?
    var mediaType: String?
    var placeholderLabel: UILabel!
    var progressHUD: MBProgressHUD?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        picker.delegate = self
        
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
        
        clearFields()
        
        // TapGestureRecognizer
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if !WMGlobal.isLoggedIn() {
            WMGlobal.showAlert(title: "Login is required", message: "You need to login to upload photo or video", target: self)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func _onUpload(_ sender: Any) {
        if !validateFields() {
            return
        }
        guard let userData = WMGlobal.getUserData() else {
            return
        }
        let identifier = (userData["screenname"] as? String ?? "") + "_" + String(format: "%d", Int(NSDate().timeIntervalSince1970))
        let s3accesskey = userData["s3accesskey"] as? String ?? ""
        let s3secretkey = userData["s3secretkey"] as? String ?? ""
        let title = txtTitle.text ?? ""
        let description = txtDescription.text ?? ""
        let subjectTags = txtSubjectTags.text ?? ""
        let filename = "\(identifier)." + (fileURL?.pathExtension ?? "jpg")
        let startTime = Date()
        self.progressHUD = MBProgressHUD.showAdded(to: self.view, animated: true)
        self.progressHUD?.label.text = "Uploading..."

        WMSAPIManager.shared.SendDataToBucket(params: [
            "identifier" : identifier,
            "title": title,
            "description": description,
            "tags": subjectTags,
            "filename" : filename,
            "mediatype" : mediaType,
            "s3accesskey" : s3accesskey,
            "s3secretkey" : s3secretkey,
            "data" : (fileData != nil) ? fileData! : (fileURL ?? "")
        ]) { (progress) in
            // pending
            if (progress.completedUnitCount == progress.totalUnitCount) {
                // finished uploading, now processing
                self.progressHUD?.label.text = "Upload Complete"
                self.progressHUD?.detailsLabel.text = "Please wait..."
            }
            else {
                self.progressHUD?.detailsLabel.text = progress.localizedAdditionalDescription
            }
        }
        completion: { (success, uploadedFileSize) in
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
                WMGlobal.showAlert(title: "Uploading Failed", message: "", target: self)
            }
        }
    }
    
    @IBAction func _onAttachFile(_ sender: Any) {
        let actionSheet = UIAlertController(title: "Attach File", message: nil, preferredStyle: .actionSheet)
        let cameraAction = UIAlertAction(title: "Camera", style: .default) { (action) in
            self.openImagePicker(type: "Camera")
        }
        let albumAction = UIAlertAction(title: "Album", style: .default) { (action) in
            self.openImagePicker(type: "Album")
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        actionSheet.addAction(cameraAction)
        actionSheet.addAction(albumAction)
        actionSheet.addAction(cancelAction)
        actionSheet.popoverPresentationController?.sourceView = self.btnAttach
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    private func openImagePicker(type: String) {
        if type == "Album" {
            picker.allowsEditing = false
            picker.sourceType = UIImagePickerController.SourceType.photoLibrary
            picker.mediaTypes = ["public.image", "public.movie"]
            self.present(picker, animated: true, completion: nil)
        } else {
            if(UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera)){
                picker.allowsEditing = false
                picker.sourceType = UIImagePickerController.SourceType.camera
                picker.mediaTypes = ["public.image", "public.movie"]
                self.present(picker, animated: true, completion: nil)
            } else {
                WMGlobal.showAlert(title: "Camera Not Found", message: "This device has no Camera", target: self)
            }
        }
    }
    
    private func validateFields() -> Bool {
        if txtTitle.text == "" {
            WMGlobal.showAlert(title: "Title is required", message: "", target: self)
            return false
        } else if txtDescription.text == "" {
            WMGlobal.showAlert(title: "Description is required", message: "", target: self)
            return false
        } else if txtSubjectTags.text == "" {
            WMGlobal.showAlert(title: "Subject Tags are required", message: "", target: self)
            return false
        } else if (fileData == nil) && (fileURL == nil) {
            // FIXME: This alert incorrectly displays after using the Camera to take photo.
            WMGlobal.showAlert(title: "Please attach a photo or video", message: "", target: self)
            return false
        }
        
        return true
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
        titleLabel.text = "Upload Successful"
        titleLabel.sizeToFit()
        titleLabel.center = CGPoint(x: customViewWidth/2, y: titleLabel.frame.size.height/2 + 17.0)
        customView.addSubview(titleLabel)

        let message = "Uploaded \(filesize) \nIn \(duration) \n\nAvailable at \(uploadedURL)"
        var txtMessageRect = CGRect(x: 13.0, y: 67, width: customViewWidth - 26, height: 200)
        
        let txtMessageContent = UITextView(frame: txtMessageRect)
        txtMessageContent.font = UIFont.systemFont(ofSize: 14.0)
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
        
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK: - UIImagePickerControllerDelegate
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

        // Local variable inserted by Swift 4.2 migrator.
        let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)

        if let type = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.mediaType)] as? String {
            if type == "public.image" {
                
                if let chosenImage = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.originalImage)] as? UIImage {
                    imgPreview.contentMode = .scaleAspectFit
                    imgPreview.image = chosenImage
                    imgPreview.isHidden = false
                    videoPreview.isHidden = true
                    mediaType = "image"
                    fileData = chosenImage.jpegData(compressionQuality: 0.5)
                }

                if #available(iOS 11.0, *) {
                    fileURL = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.imageURL)] as? URL
                } else {
                    if let refURL = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.referenceURL)] as? URL {
                        if let asset = PHAsset.fetchAssets(withALAssetURLs: [refURL], options: nil).firstObject {
                            PHImageManager.default().requestImageData(for: asset, options: nil, resultHandler: { (data, string, orientation, info) in
                                self.fileURL = info?["PHImageFileURLKey"] as? URL
                            })
                        }
                    }
                    
                }
            }
            else if type == "public.movie" {
                imgPreview.isHidden = true
                videoPreview.isHidden = false

                fileURL = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.mediaURL)] as? URL
                if let fileUrl = fileURL {
                    mediaType = "video"
                    fileData = nil
                    let videoPlayer = AVPlayer(url: fileUrl)
                    let playerLayer = AVPlayerLayer(player: videoPlayer)
                    playerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
                    videoPreview.layer.addSublayer(playerLayer)
                    playerLayer.frame = videoPreview.layer.bounds
                    videoPlayer.play()
                }
            }
        }
        
        dismiss(animated: true, completion: nil)
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
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    // Helper function inserted by Swift 4.2 migrator.
    fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
        return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
    }

    // Helper function inserted by Swift 4.2 migrator.
    fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
        return input.rawValue
    }
}

extension UploadVC: UITextViewDelegate {
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        if let webpageVC = self.storyboard?.instantiateViewController(withIdentifier: "WebPageVC") as? WebPageVC {
            webpageVC.url = URL.absoluteString
            webpageVC.modalPresentationStyle = .fullScreen
            dismiss(animated: true, completion: {
                self.present(webpageVC, animated: true, completion: nil)
            })
        }
        return false
    }
    
    func textViewDidChange(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.isEmpty
    }
}
