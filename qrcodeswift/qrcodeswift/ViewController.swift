import UIKit
import AVFoundation
import QRCodeReader
import ContactsUI
import MessageUI

class ViewController: UIViewController, QRCodeReaderViewControllerDelegate, CNContactPickerDelegate, MFMessageComposeViewControllerDelegate {

    
    lazy var readerVC: QRCodeReaderViewController = {
        let builder = QRCodeReaderViewControllerBuilder {
            $0.reader = QRCodeReader(metadataObjectTypes: [.qr], captureDevicePosition: .back)
            $0.showTorchButton = true
            $0.cancelButtonTitle = "Vazgeç"
        }
        return QRCodeReaderViewController(builder: builder)
    }()


    @IBAction func startscanning(_ sender: UIButton) {
        
        readerVC.delegate = self
        readerVC.modalPresentationStyle = .fullScreen 
        present(readerVC, animated: true)
    }
    
    private var scannedText: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        
    }

    
    @objc func startScanning() {
        readerVC.delegate = self
        readerVC.modalPresentationStyle = .fullScreen // Tam ekran yapıyoruz
        present(readerVC, animated: true)
    }

    func reader(_ reader: QRCodeReaderViewController, didScanResult result: QRCodeReaderResult) {
        scannedText = result.value
        reader.stopScanning()
        reader.dismiss(animated: true) {
            self.pickContact()
        }
    }

    func readerDidCancel(_ reader: QRCodeReaderViewController) {
        reader.stopScanning()
        reader.dismiss(animated: true, completion: nil)
    }

   
    func pickContact() {
        let picker = CNContactPickerViewController()
        picker.delegate = self
        picker.displayedPropertyKeys = [CNContactPhoneNumbersKey]
        present(picker, animated: true)
    }

    func contactPicker(_ picker: CNContactPickerViewController, didSelect contactProperty: CNContactProperty) {
        picker.dismiss(animated: true)
        guard let phoneValue = contactProperty.value as? CNPhoneNumber,
              let message = scannedText else { return }
        sendSMS(to: phoneValue.stringValue, body: message)
    }

    
    func sendSMS(to phone: String, body: String) {
        guard MFMessageComposeViewController.canSendText() else {
            let alert = UIAlertController(title: "Hata", message: "Bu cihaz SMS gönderemez.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Tamam", style: .default, handler: nil))
            present(alert, animated: true)
            return
        }

        let composer = MFMessageComposeViewController()
        composer.messageComposeDelegate = self
        composer.recipients = [phone]
        composer.body = body
        present(composer, animated: true)
    }

    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true)
        let alert: UIAlertController
        switch result {
        case .cancelled:
            alert = UIAlertController(title: "İptal Edildi", message: "SMS gönderimi iptal edildi.", preferredStyle: .alert)
        case .sent:
            alert = UIAlertController(title: "Gönderildi", message: "SMS başarıyla gönderildi.", preferredStyle: .alert)
        case .failed:
            alert = UIAlertController(title: "Başarısız", message: "SMS gönderimi başarısız oldu.", preferredStyle: .alert)
        @unknown default:
            alert = UIAlertController(title: "Hata", message: "Bilinmeyen bir durum oluştu.", preferredStyle: .alert)
        }
        alert.addAction(UIAlertAction(title: "Tamam", style: .default, handler: nil))
        present(alert, animated: true)
    }
}
