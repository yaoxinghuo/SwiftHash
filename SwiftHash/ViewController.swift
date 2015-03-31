//
//  ViewController.swift
//  SwiftHash
//
//  Created by Terry on 2015-3-30.
//  Copyright (c) 2015 MengyangSoft. All rights reserved.
//

import Cocoa
import CryptoSwift

class ViewController: NSViewController, NSTextFieldDelegate, NSTabViewDelegate, FileDropViewDelegate {
    
    let SELECT_ALGORITHM_MD5 = 0;
    let SELECT_ALGORITHM_SHA1 = 1;
    let SELECT_ALGORITHM_SHA224 = 2;
    let SELECT_ALGORITHM_SHA256 = 3;
    let SELECT_ALGORITHM_SHA384 = 4;
    let SELECT_ALGORITHM_SHA512 = 5;
    let SELECT_ALGORITHM_CRC32 = 6;
    
    let RESULT_ERROR = "ERROR";
    
    let DEFALUT_SELECTED_ALGORITHM_INDEX_KEY = "selectedAlgorithmIndex"
    let DEFAULT_OUTPUT_FORMAT_INDEX_KEY = "outputFormatIndex" //0 lowercase 1upcase
    let DEFAULT_TAB_INDEX_KEY = "tabIndex";

    @IBOutlet weak var fileDropView: FileDropView!
    @IBOutlet weak var hashAlgorithmComboBox: NSComboBoxCell!
    
    @IBOutlet weak var progressView: NSProgressIndicator!
    @IBOutlet weak var fileView: NSTextField!
    @IBOutlet weak var tabView: NSTabView!
    @IBOutlet weak var outputFormatRadio: NSMatrix!
    @IBOutlet weak var compareResultView: NSTextField!
    @IBOutlet weak var copyResultButton: NSButton!
    @IBOutlet weak var compareView: NSTextField!
    @IBOutlet weak var resultView: NSTextField!
    @IBOutlet weak var sourceStringView: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad();
        
        sourceStringView.delegate = self;
        tabView.delegate = self;
        fileDropView.delegate = self;
        showProgress(false);
        loadDefault();
        checkCopyButtonVisibility();
    }
    
    func loadDefault() {
        let defaults = NSUserDefaults.standardUserDefaults()
        let seletedAlgorithmIndex = defaults.integerForKey(DEFALUT_SELECTED_ALGORITHM_INDEX_KEY)
        hashAlgorithmComboBox.selectItemAtIndex(seletedAlgorithmIndex)
        let outputFormatIndex = defaults.integerForKey(DEFAULT_OUTPUT_FORMAT_INDEX_KEY);
        outputFormatRadio.selectCellAtRow(outputFormatIndex, column: 0);
        let tabIndex = defaults.integerForKey(DEFAULT_TAB_INDEX_KEY);
        tabView.selectTabViewItemAtIndex(tabIndex);
    }

    override var representedObject: AnyObject? {
        didSet {
        }
    }
    
    func checkCopyButtonVisibility() {
        let resultString = resultView.stringValue;
        var hidden : Bool = false;
        if(resultString == "" || resultString == RESULT_ERROR){
            hidden = true;
        }
        copyResultButton.hidden = hidden;
    }
    
    @IBAction func hashAlgorithmComboBoxSelected(sender: NSComboBox) {
        calcHash();
        let defaults = NSUserDefaults.standardUserDefaults();
        defaults.setInteger(hashAlgorithmComboBox.indexOfSelectedItem, forKey: DEFALUT_SELECTED_ALGORITHM_INDEX_KEY);
    }
    
    override func controlTextDidChange(obj: NSNotification) {
        calcHash();
    }
    
    func calcHash() {
        let identify:String = tabView.selectedTabViewItem!.identifier as String;
        let tabIndex:Int = identify == "1" ? 0 : 1;
        if(tabIndex == 0) {
            let filePath = fileView.stringValue;
            if(filePath == "" || filePath == "No file") {
                //Ignore
            } else {
                showProgress(true);
                Async.background({
                    self.hashFile(filePath);
                });
            }
            return;
        }
        
        showProgress(true);
        let sourceString = sourceStringView.stringValue;
        var result:String? = "";
        if(sourceString == "") {
            
        } else {
            switch(hashAlgorithmComboBox.indexOfSelectedItem) {
            case SELECT_ALGORITHM_MD5:
                result = sourceString.md5();
            case SELECT_ALGORITHM_SHA1:
                result = sourceString.sha1();
            case SELECT_ALGORITHM_SHA224:
                result = sourceString.sha224();
            case SELECT_ALGORITHM_SHA256:
                result = sourceString.sha256();
            case SELECT_ALGORITHM_SHA384:
                result = sourceString.sha384();
            case SELECT_ALGORITHM_SHA512:
                result = sourceString.sha512();
            case SELECT_ALGORITHM_CRC32:
                result = sourceString.crc32();
            default:
                result = RESULT_ERROR;
            }
            if(result == nil) {
                result = RESULT_ERROR;
            }
        }
        resultView.stringValue = result!;
        checkCopyButtonVisibility();
        showProgress(false);
    }
    
    @IBAction func copyResultButtonClicked(sender: NSButton) {
        var pasteBoard = NSPasteboard.generalPasteboard()
        pasteBoard.clearContents();
        var str = resultView.stringValue;
        // now read write our String and an Array with 1 item at index 0
        pasteBoard.writeObjects([str]);
    }
    
    @IBAction func outputFormatClicked(sender: NSMatrix) {
        calcHash();
        let defaults = NSUserDefaults.standardUserDefaults();
        defaults.setInteger(outputFormatRadio.selectedRow, forKey: DEFAULT_OUTPUT_FORMAT_INDEX_KEY);
    }
    
    func tabView(tabView: NSTabView, didSelectTabViewItem tabViewItem: NSTabViewItem?){
        let identify:String = tabViewItem!.identifier as String;
        let defaults = NSUserDefaults.standardUserDefaults();
        let tabIndex:Int = identify == "1" ? 0 : 1;
        defaults.setInteger(tabIndex, forKey: DEFAULT_TAB_INDEX_KEY);
    }
    
    func fileDropView(didDroppedFile filePath: String) {
        var isDir:ObjCBool = false;
        if(NSFileManager.defaultManager().fileExistsAtPath(filePath, isDirectory: &isDir) && !isDir) {
            fileView.stringValue = filePath;
            calcHash();
        } else {
            //not a file or is directory
        }
    }
    
    //Hash文件的时候，不能用CryptoSwift，因为如果一次性读入一个大文件的话，需要很多内存
    func hashFile(filePath:String) {
        var alg:TGDHashAlgorithm;
        switch(hashAlgorithmComboBox.indexOfSelectedItem) {
        case SELECT_ALGORITHM_MD5:
            alg = TGDHashAlgorithm(TGDHashAlgorithmMD5);
        case SELECT_ALGORITHM_SHA1:
            alg = TGDHashAlgorithm(TGDHashAlgorithmSHA1);
        case SELECT_ALGORITHM_SHA224:
            alg = TGDHashAlgorithm(TGDHashAlgorithmSHA224);
        case SELECT_ALGORITHM_SHA256:
            alg = TGDHashAlgorithm(TGDHashAlgorithmSHA256);
        case SELECT_ALGORITHM_SHA384:
            alg = TGDHashAlgorithm(TGDHashAlgorithmSHA384);
        case SELECT_ALGORITHM_SHA512:
            alg = TGDHashAlgorithm(TGDHashAlgorithmSHA512);
        case SELECT_ALGORITHM_CRC32:
            alg = TGDHashAlgorithm(TGDChecksumAlgorithmCRC32);
        default:
            alg = TGDHashAlgorithm(TGDHashAlgorithmMD5);
        }
       
        
        var result = convertCfTypeToString(TGDFileHashCreateWithPath(filePath, 4096, alg));
        
        resultView.stringValue = result!;
        checkCopyButtonVisibility();
        showProgress(false);
    }
    
    func convertCfTypeToString(cfValue:Unmanaged<CFString>!) ->String? {
        let value = Unmanaged<CFStringRef>.fromOpaque(cfValue.toOpaque()).takeUnretainedValue() as CFStringRef;
        if CFGetTypeID(value) == CFStringGetTypeID() {
            return value as String;
        } else {
            return nil;
        }
    }
    
    func showProgress(show:Bool){
        if(show) {
            progressView.startAnimation(self);
            progressView.hidden = false;
        } else {
            progressView.stopAnimation(self);
            progressView.hidden = true;
        }
    }
}
