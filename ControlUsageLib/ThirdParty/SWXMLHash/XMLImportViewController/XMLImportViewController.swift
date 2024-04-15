//   XMLImportViewController.swift
//   ControlUsageLib
//
//   Created by Ted on 2024/4/11
//   


import UIKit
import SnapKit
import RxSwift
import RxCocoa
import UniformTypeIdentifiers
import CoreServices
import FLEX

class XMLImportViewController: UIViewController {

    lazy var importBtn:UIButton = {
        let btn = UIButton()
        btn.setTitle("Import", for: .normal)
        btn.setTitleColor(.black, for: .normal)
        return btn
    }()
    
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        FLEXManager.shared.showExplorer()

        // Do any additional setup after loading the view.
        
        view.addSubview(importBtn)
        importBtn.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(64)
            make.width.equalTo(80)
            make.height.equalTo(32)
        }
        
        importBtn.rx.tap.subscribe(onNext:{
            [weak self] _ in guard let strongSelf = self else { return }
            strongSelf.openDocumentPicker()
        }).disposed(by: disposeBag)
    }
    
    // 通过UIDocumentPickerViewController获取设备内存或者iCould中的资源
    func openDocumentPicker() {
        let document:UIDocumentPickerViewController
        if #available(iOS 14, *) {
            let supportedTypes:[UTType] = [UTType.xml,UTType.init(importedAs: "com.example.gdtf")]
            document = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes)
        }
        else{
            let supportedTypes:[String] = [kUTTypeXML as String,
                                           "com.example.gdtf"]
            document = UIDocumentPickerViewController(documentTypes: supportedTypes, in: .import)
        }
        
        document.delegate = self
        document.allowsMultipleSelection = false
        document.modalPresentationStyle = .automatic
        present(document, animated: true)
    }
    
}

extension XMLImportViewController:UIDocumentPickerDelegate {

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if !urls.isEmpty {
            let url = urls[0]
            guard url.startAccessingSecurityScopedResource() else {
                print("禁止访问文件")
                return
            }
            
            //判断上传的是GDTF文件还是XML文件
            if url.lastPathComponent.hasSuffix(".gdtf"){
                unZipGDTFFile(url: url)
            }
            //直接上传的是xml文件
            else if url.lastPathComponent.hasSuffix(".xml"){
                parseXMLFile(url: url)
            }
            
        }
    }
    
    /// 解压GDTF压缩文件
    /// - Parameter url: 从UIDocumentPickerViewController从获取的需要解压的路径
    func unZipGDTFFile(url:URL) {
        guard let destPath = try? FileManager.default.url(for: .cachesDirectory,
                                in: .userDomainMask,
                                appropriateFor: nil,
                                create: false).appendingPathComponent("GDTF")
        else { return }
        //创建GDTF临时操作目录
        try? FileManager.default.createDirectory(atPath: destPath.path, withIntermediateDirectories: true)
        //临时存储的gdtf路径，方便之后解压
        let saveGDTFPath = destPath.appendingPathComponent("/\(url.lastPathComponent)")
        do {
            try FileManager.default.copyItem(at: url, to: saveGDTFPath)
        }
        catch let error  {
            print("复制失败，\(error)")
            return
        }
        
        //生成解压目录
        let unzipGDTFPath = destPath.appendingPathComponent("/UnZip")
        try? FileManager.default.createDirectory(atPath: unzipGDTFPath.path, withIntermediateDirectories: true)
        //开始解压
        if SSZipArchive.unzipFile(atPath: saveGDTFPath.path, toDestination: unzipGDTFPath.path) {
            let xmlPath = unzipGDTFPath.appendingPathComponent("/description.xml")
            //寻找解压后是否包含xml文件 如果存在则解析文件
            if FileManager.default.fileExists(atPath: xmlPath.path){
                parseXMLFile(url: xmlPath)
            }
        }
        
        //不论是否成功解析 都删除目录中的所有内容
        try? FileManager.default.removeItem(at: destPath)
    }
    
    /// 解析DMX相关的xml文档
    /// - Parameter url: xml文档的路径
    func parseXMLFile(url:URL) {
        if let data = try? Data(contentsOf: url) {
            if let xmlStr = String(data: data, encoding: .utf8) {
                if let fixtureType = SWXMLHashUsage().analizeGDTF(xmlStr: xmlStr) {
                    print(fixtureType)
                }
            }
        }
    }
    
}
