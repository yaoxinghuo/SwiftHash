//
//  ConvertUtil.swift
//  SwiftHash
//
//  @author Terry E-mail: yaoxinghuo at 126 dot com
//  @date 2015-3-31 11:51
//  @description 
//

import Foundation

//type 0 dec2hex
//type 1 hex2dec
//type 2 string2base64
//type 3 base642string
func convert(_ source:String, type:Int) -> String? {
    var result:String?;
    switch(type){
    case 0:
        result = convertDecToHex(source);
    case 1:
        result = convertHexToDec(source);
    case 2:
        result = convertStringToBase64(source);
    case 3:
        result = convertBase64ToString(source);
    case 4:
        result = convertTimeMillisToDate(source);
    case 5:
        result = convertDateToTimeMillis(source);
        
    default:
        result = nil;
    }
    return result;
}

func convertDecToHex(_ source:String) -> String? {
    let numberOfString = Int(source);
    if(numberOfString == nil) {
        return nil;
    }
    return String(NSString(format:"%2X", numberOfString!));
}

func convertHexToDec(_ source:String) -> String? {
    let scanner = Scanner(string: source);
    var result : UInt64 = 0;
    if scanner.scanHexInt64(&result) {
        return String(result);
    } else {
        return nil;
    }
}

func convertStringToBase64(_ source:String) -> String? {
    let plainData = (source as NSString).data(using: String.Encoding.utf8.rawValue);
    if(plainData == nil) {
        return nil;
    }
    let base64String = plainData!.base64EncodedString(options: NSData.Base64EncodingOptions.lineLength64Characters);
    return base64String;
}

func convertBase64ToString(_ source:String) -> String? {
    let decodedData = Data(base64Encoded: source, options:NSData.Base64DecodingOptions.ignoreUnknownCharacters);
    if(decodedData == nil) {
        return nil;
    }
    let decodedString = NSString(data: decodedData!, encoding: String.Encoding.utf8.rawValue)
    if(decodedString == nil) {
        return nil;
    }
    return String(decodedString!);
}

func convertTimeMillisToDate(_ source:String) -> String? {
    var timeMillis:Double? = nil;
    if(!source.isEmpty){
        let temp =  Double(source);
        if let t = temp {
            timeMillis = t;
        }
    }
    if(source == "now"){
        timeMillis = Date().timeIntervalSince1970;
    }
    if(timeMillis == nil){
        return nil;
    }
    if(timeMillis! > 10000000000){
        timeMillis = timeMillis! / 1000;
    }
    
    let date = Date(timeIntervalSince1970: TimeInterval(timeMillis!));
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss";
    return dateFormatter.string(from: date);
}

func convertDateToTimeMillis(_ source:String) -> String? {
    if(source == "now"){
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 0;
        return formatter.string(from: NSNumber(value: Date().timeIntervalSince1970));
    }
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss";
    
    let date = dateFormatter.date(from: source.characters.count == 16 ? (source+":00") : source);
    if let trueDate = date {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 0;
        return formatter.string(from: NSNumber(value: trueDate.timeIntervalSince1970));
    }
    return nil;
}
