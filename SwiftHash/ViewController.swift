//
//  ViewController.swift
//  SwiftHash
//
//  Created by Terry on 2015-3-30.
//  Copyright (c) 2017 Terry. All rights reserved.
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
    let SELECT_ALGORITHM_CRC16 = 6;
    let SELECT_ALGORITHM_CRC32 = 7;
    let LAST_ALGORITHM_TYPE_INDEX = 7;

    let RESULT_ERROR = "ERROR";

    let DEFALUT_SELECTED_ALGORITHM_INDEX_KEY = "selectedAlgorithmIndex"
    let DEFAULT_OUTPUT_FORMAT_INDEX_KEY = "outputFormatIndex"
    //0 lowercase 1upcase
    let DEFAULT_TAB_INDEX_KEY = "tabIndex";

    @IBOutlet weak var dropHintView: NSTextField!
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
        compareView.delegate = self;
        tabView.delegate = self;
        fileDropView.delegate = self;

        showProgress(false);
        loadDefault();
        checkCopyButtonVisibility();
    }

    func loadDefault() {
        let defaults = UserDefaults.standard;
        let outputFormatIndex = defaults.integer(forKey: DEFAULT_OUTPUT_FORMAT_INDEX_KEY);
        outputFormatRadio.selectCell(atRow: outputFormatIndex, column: 0);
        let tabIndex = defaults.integer(forKey: DEFAULT_TAB_INDEX_KEY);
        tabView.selectTabViewItem(at: tabIndex);

        refreshAlgorithmComboBox(tabIndex);

        var seletedAlgorithmIndex = defaults.integer(forKey: DEFALUT_SELECTED_ALGORITHM_INDEX_KEY);
        if (seletedAlgorithmIndex >= hashAlgorithmComboBox.numberOfItems || seletedAlgorithmIndex < 0) {
            seletedAlgorithmIndex = 0;
        }
        hashAlgorithmComboBox.selectItem(at: seletedAlgorithmIndex);
    }

    func checkCopyButtonVisibility() {
        let resultString = resultView.stringValue;
        var hidden: Bool = false;
        if (resultString == "" || resultString == RESULT_ERROR) {
            hidden = true;
        }
        copyResultButton.isHidden = hidden;
    }

    @IBAction func hashAlgorithmComboBoxSelected(_ sender: NSComboBox) {
        calcHash();
        let defaults = UserDefaults.standard;
        defaults.set(hashAlgorithmComboBox.indexOfSelectedItem, forKey: DEFALUT_SELECTED_ALGORITHM_INDEX_KEY);
    }

    override func controlTextDidChange(_ obj: Notification) {
        let textField: NSTextField = obj.object as! NSTextField;
        if (textField == sourceStringView) {
            calcHash();
        } else {
            compareResult();
        }

    }

    func calcHash() {
        var algorithmIndex = hashAlgorithmComboBox.indexOfSelectedItem;
        if (algorithmIndex < 0) {
            algorithmIndex = 0;
        }
        let identify: String = tabView.selectedTabViewItem!.identifier as! String;
        let tabIndex: Int = identify == "1" ? 0 : 1;
        if (tabIndex == 0) {
            let filePath = fileView.stringValue;
            if (filePath == "" || filePath == "No file") {
                //Ignore
            } else {
                showProgress(true);
                Async.background {
                    self.hashFile(filePath);
                };
            }
            return;
        }

        showProgress(true);
        let sourceString = sourceStringView.stringValue;
        var result: String? = "";
        if (sourceString == "") {

        } else {
            if (algorithmIndex > LAST_ALGORITHM_TYPE_INDEX) {
                result = convert(sourceString, type: algorithmIndex - LAST_ALGORITHM_TYPE_INDEX - 1);
            } else {
                switch (algorithmIndex) {
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
                case SELECT_ALGORITHM_CRC16:
                    result = sourceString.crc16();
                case SELECT_ALGORITHM_CRC32:
                    result = sourceString.crc32();
                default:
                    result = RESULT_ERROR;
                }
            }

            if (result == nil) {
                result = RESULT_ERROR;
            }
        }
        showResult(result!);
        checkCopyButtonVisibility();
        showProgress(false);
    }

    @IBAction func copyResultButtonClicked(_ sender: NSButton) {
        let pasteBoard = NSPasteboard.general()
        pasteBoard.clearContents();
        let str = resultView.stringValue;
        // now read write our String and an Array with 1 item at index 0
        pasteBoard.writeObjects([str as NSPasteboardWriting]);
    }

    @IBAction func outputFormatClicked(_ sender: NSMatrix) {
        showResult(nil);
        let defaults = UserDefaults.standard;
        defaults.set(outputFormatRadio.selectedRow, forKey: DEFAULT_OUTPUT_FORMAT_INDEX_KEY);
    }

    func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
        let identify: String = tabViewItem!.identifier as! String;
        let defaults = UserDefaults.standard;
        let tabIndex: Int = identify == "1" ? 0 : 1;
        defaults.set(tabIndex, forKey: DEFAULT_TAB_INDEX_KEY);
        refreshAlgorithmComboBox(tabIndex);
    }

    func refreshAlgorithmComboBox(_ tab: Int) {
        hashAlgorithmComboBox.removeAllItems();
        hashAlgorithmComboBox.addItems(withObjectValues: ["MD5", "SHA1", "SHA224", "SHA256", "SHA384", "SHA512", "CRC16", "CRC32"]);
        if (tab == 1) {
            hashAlgorithmComboBox.addItems(withObjectValues: ["Dec->Hex(0x)", "Hex(0x)->Dec", "String->Base64", "Base64->String", "TimeSeconds->Date", "Date->TimeSeconds"]);
        }
    }

    func fileDropView(didDroppedFile filePath: String) {
        //if a file is processing, do not accept new file
        if (progressView.isHidden == false) {
            return;
        }
        var isDir: ObjCBool = false;
        if (FileManager.default.fileExists(atPath: filePath, isDirectory: &isDir) && !isDir.boolValue) {
            fileView.stringValue = filePath;
            calcHash();
        } else {
            //not a file or is directory
        }
    }

    //Hash文件的时候，不能用CryptoSwift，因为如果一次性读入一个大文件的话，需要很多内存
    func hashFile(_ filePath: String) {
        var alg: TGDHashAlgorithm;
        switch (hashAlgorithmComboBox.indexOfSelectedItem) {
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
        case SELECT_ALGORITHM_CRC16:
            alg = TGDHashAlgorithm(TGDChecksumAlgorithmCRC16);
        case SELECT_ALGORITHM_CRC32:
            alg = TGDHashAlgorithm(TGDChecksumAlgorithmCRC32);
        default:
            alg = TGDHashAlgorithm(TGDHashAlgorithmMD5);
        }


        let result = convertCfTypeToString(TGDFileHashCreateWithPath(filePath as CFString!, 4096, alg));

        showResult(result!);
        checkCopyButtonVisibility();
        showProgress(false);
    }

    func convertCfTypeToString(_ cfValue: Unmanaged<CFString>!) -> String? {
        let value = Unmanaged < CFString>.fromOpaque(cfValue.toOpaque()).takeUnretainedValue() as CFString;
        if CFGetTypeID(value) == CFStringGetTypeID() {
            return value as String;
        } else {
            return nil;
        }
    }

    func showResult(_ result: String?) {
        let lowercase = outputFormatRadio.selectedRow == 0;
        var string: String;
        if (result == nil) {
            string = resultView.stringValue;
        } else {
            string = result!;
        }
        if (hashAlgorithmComboBox.indexOfSelectedItem > LAST_ALGORITHM_TYPE_INDEX + 2) {
            resultView.stringValue = string;
        } else {
            resultView.stringValue = lowercase ? string.lowercased() : string.uppercased();
        }

        compareResult();
    }

    func showProgress(_ show: Bool) {
        if (show) {
            dropHintView.stringValue = "Please wait...";
            progressView.startAnimation(self);
            progressView.isHidden = false;
        } else {
            dropHintView.stringValue = "Drop File Here";
            progressView.stopAnimation(self);
            progressView.isHidden = true;
        }
    }

    func compareResult() {
        let resultString = resultView.stringValue;
        let compareString = compareView.stringValue;
        var compareResultString: String = "";
        if (resultString != "" && compareString != "") {
            if (resultString.lowercased() == compareString.lowercased()) {
                compareResultString = "Equals";
                compareResultView.textColor = NSColor.blue;
            } else {
                compareResultView.textColor = NSColor.red;
                compareResultString = "Not Equals";
            }
        }
        compareResultView.stringValue = compareResultString;
    }
}

