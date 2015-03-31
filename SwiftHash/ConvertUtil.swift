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
func convert(source:String, type:Int) -> String? {
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
    default:
        result = nil;
    }
    return result;
}

func convertDecToHex(source:String) -> String? {
    let numberOfString = source.toInt();
    if(numberOfString == nil) {
        return nil;
    }
    return String(NSString(format:"%2X", numberOfString!));
}

func convertHexToDec(source:String) -> String? {
    let scanner = NSScanner(string: source);
    var result : UInt64 = 0;
    if scanner.scanHexLongLong(&result) {
        return String(result);
    } else {
        return nil;
    }
}

func convertStringToBase64(source:String) -> String? {
    let plainData = (source as NSString).dataUsingEncoding(NSUTF8StringEncoding);
    if(plainData == nil) {
        return nil;
    }
    let base64String = plainData!.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.Encoding64CharacterLineLength);
    return base64String;
}

func convertBase64ToString(source:String) -> String? {
    let decodedData = NSData(base64EncodedString: source, options:NSDataBase64DecodingOptions.IgnoreUnknownCharacters);
    if(decodedData == nil) {
        return nil;
    }
    let decodedString = NSString(data: decodedData!, encoding: NSUTF8StringEncoding)
    if(decodedString == nil) {
        return nil;
    }
    return String(decodedString!);
}