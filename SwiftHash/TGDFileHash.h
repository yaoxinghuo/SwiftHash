/*
 *  TGDFileHash.h
 *  TagAdA: Tagging Advanced Application
 *  
 *  Copyright © 2008-2010 The TagAdA Team. All rights reserved.
 * 
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *  
 *        http://www.apache.org/licenses/LICENSE-2.0
 *  
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *
 */

#ifndef TGDFILEHASH_H
#define TGDFILEHASH_H

//---------------------------------------------------------
// Includes
//---------------------------------------------------------

// CoreFoundation
#include <CoreFoundation/CoreFoundation.h>


//---------------------------------------------------------
// Other declarations
//---------------------------------------------------------

#pragma mark -
#pragma mark Constants and types definitions

// In bytes
#define TGDFileHashDefaultChunkSizeForReadingData 4096

// TGDHashAlgorithm
enum {
    TGDHashAlgorithmMD2 = 0, 
    TGDHashAlgorithmMD4, 
    TGDHashAlgorithmMD5, 
    TGDHashAlgorithmSHA1, 
    TGDHashAlgorithmSHA224, 
    TGDHashAlgorithmSHA256, 
    TGDHashAlgorithmSHA384, 
    TGDHashAlgorithmSHA512,
    TGDChecksumAlgorithmCRC32
};
typedef unsigned int TGDHashAlgorithm;

//---------------------------------------------------------
// Function declaration
//---------------------------------------------------------

#pragma mark -
#pragma mark Function declaration

extern CFStringRef TGDFileHashCreateWithPath(CFStringRef filePath,
                                                    size_t chunkSizeForReadingData, 
                                                    TGDHashAlgorithm hashAlgorithm);

#endif
