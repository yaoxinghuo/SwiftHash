/*
 *  TGDFileHash.c
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

//---------------------------------------------------------
// Includes
//---------------------------------------------------------

// Header file
#include "TGDFileHash.h"

// Standard library
#include <stdint.h>
#include <stdio.h>

// Cryptography
#include <CommonCrypto/CommonDigest.h>


//---------------------------------------------------------
// Other declarations
//---------------------------------------------------------

#pragma mark -
#pragma mark Private types definitions

// Function pointer types for functions used in the computation 
// of a cryptographic hash.
typedef int (*TGDHashInitFunction)   (uint8_t *hashObjectPointer[]);
typedef int (*TGDHashUpdateFunction) (uint8_t *hashObjectPointer[], 
                                      const void *data, 
                                      CC_LONG len);
typedef int (*TGDHashFinalFunction)  (unsigned char *md, 
                                      uint8_t *hashObjectPointer[]);

// Structure used to describe a hash computation context.
typedef struct _TGDHashComputationContext {
    TGDHashInitFunction initFunction;
    TGDHashUpdateFunction updateFunction;
    TGDHashFinalFunction finalFunction;
    size_t digestLength;
    uint8_t **hashObjectPointer;
} TGDHashComputationContext;

#pragma mark -
#pragma mark Private functions declarations

static CFStringRef _TGDFileHashCreateWithPath(CFStringRef filePath, 
                                              size_t chunkSizeForReadingData, 
                                              TGDHashComputationContext *context);

typedef struct {
    CC_LONG crc;
} CC_CRC32_CTX;

static int CC_CRC32_Init(CC_CRC32_CTX *c);
static int CC_CRC32_Update(CC_CRC32_CTX *c, const uint8_t *data, CC_LONG len);
static int CC_CRC32_Final(unsigned char *md, CC_CRC32_CTX *c);

#define CC_CRC32_DIGEST_LENGTH 4

#pragma mark -
#pragma mark Handy preprocessor macros

// From <CommonCrypto/CommonDigest.h>:
//     - same context struct is used for SHA224 and SHA256;
//     - same context struct is used for SHA384 and SHA512.
#define CC_SHA224_CTX CC_SHA256_CTX
#define CC_SHA384_CTX CC_SHA512_CTX


// Macro to easily setup a TGDHashComputationContext given 
// a hash algorithm name.
#define TGDHashComputationContextDeclare(context, hashAlgorithmName)        \
    CC_##hashAlgorithmName##_CTX hashObjectFor##hashAlgorithmName;          \
    TGDHashComputationContext context = {                                   \
        (TGDHashInitFunction)&CC_##hashAlgorithmName##_Init,                \
        (TGDHashUpdateFunction)&CC_##hashAlgorithmName##_Update,            \
        (TGDHashFinalFunction)&CC_##hashAlgorithmName##_Final,              \
        CC_##hashAlgorithmName##_DIGEST_LENGTH,                             \
        (uint8_t **)&hashObjectFor##hashAlgorithmName                       \
    }


// Macro used in TGDFileHashCreateWithPath to easily add more cases 
// to the switch block with just the hash algorithm name.
#define TGDFileHashCreateWithPath_CaseHashAlgorithmBranch(                  \
            hashAlgorithmName                                               \
        )                                                                   \
                                                                            \
        case TGDHashAlgorithm##hashAlgorithmName:                           \
            do {                                                            \
                TGDHashComputationContextDeclare(hashComputationContext,    \
                                                 hashAlgorithmName);        \
                return _TGDFileHashCreateWithPath(filePath,                 \
                                                  chunkSizeForReadingData,  \
                                                  &hashComputationContext); \
            } while(false)


// Macro used in TGDFileHashCreateWithPath to easily add more cases
// to the switch block with just the hash algorithm name.
#define TGDFileChecksumCreateWithPath_CaseChecksumAlgorithmBranch(              \
                hashAlgorithmName                                               \
            )                                                                   \
                                                                                \
            case TGDChecksumAlgorithm##hashAlgorithmName:                       \
                do {                                                            \
                    TGDHashComputationContextDeclare(hashComputationContext,    \
                                                     hashAlgorithmName);        \
                    return _TGDFileHashCreateWithPath(filePath,                 \
                                                      chunkSizeForReadingData,  \
                                                      &hashComputationContext); \
            } while(false)

//---------------------------------------------------------
// Functions definitions
//---------------------------------------------------------

#pragma mark -
#pragma mark Functions definitions

CFStringRef TGDFileHashCreateWithPath(CFStringRef filePath,
                                      size_t chunkSizeForReadingData,
                                      TGDHashAlgorithm hashAlgorithm) {
    
    switch (hashAlgorithm) {
        TGDFileHashCreateWithPath_CaseHashAlgorithmBranch(MD2);
        TGDFileHashCreateWithPath_CaseHashAlgorithmBranch(MD4);
        TGDFileHashCreateWithPath_CaseHashAlgorithmBranch(MD5);
        TGDFileHashCreateWithPath_CaseHashAlgorithmBranch(SHA1);
        TGDFileHashCreateWithPath_CaseHashAlgorithmBranch(SHA224);
        TGDFileHashCreateWithPath_CaseHashAlgorithmBranch(SHA256);
        TGDFileHashCreateWithPath_CaseHashAlgorithmBranch(SHA384);
        TGDFileHashCreateWithPath_CaseHashAlgorithmBranch(SHA512);
        TGDFileChecksumCreateWithPath_CaseChecksumAlgorithmBranch(CRC32);
        default:
            break;
    }
    return NULL;
}

static CFStringRef _TGDFileHashCreateWithPath(CFStringRef filePath, 
                                              size_t chunkSizeForReadingData, 
                                              TGDHashComputationContext *context) {
    
    // Declare needed variables and buffers
    CFStringRef result = NULL;
    CFReadStreamRef readStream = NULL;
    unsigned char digest[context->digestLength];
    char hash[2 * context->digestLength + 1];
    
    // Get the file URL
    CFURLRef fileURL = 
        CFURLCreateWithFileSystemPath(kCFAllocatorDefault, 
                                      (CFStringRef)filePath, 
                                      kCFURLPOSIXPathStyle, 
                                      (Boolean)false);
    if (!fileURL) goto done;
    
    // Create and open the read stream
    readStream = CFReadStreamCreateWithFile(kCFAllocatorDefault, 
                                            (CFURLRef)fileURL);
    if (!readStream) goto done;
    bool didSucceed = (bool)CFReadStreamOpen(readStream);
    if (!didSucceed) goto done;
    
    // Initialize the hash object
    (*context->initFunction)(context->hashObjectPointer);
    
    // Make sure chunkSizeForReadingData is valid
    if (!chunkSizeForReadingData) {
        chunkSizeForReadingData = TGDFileHashDefaultChunkSizeForReadingData;
    }
    
    // Feed the data to the hash object
    bool hasMoreData = true;
    while (hasMoreData) {
        uint8_t buffer[chunkSizeForReadingData];
        CFIndex readBytesCount = CFReadStreamRead(readStream, 
                                                  (UInt8 *)buffer, 
                                                  (CFIndex)sizeof(buffer));
        if (readBytesCount == -1) break;
        if (readBytesCount == 0) {
            hasMoreData = false;
            continue;
        }
        (*context->updateFunction)(context->hashObjectPointer, 
                                   (const void *)buffer, 
                                   (CC_LONG)readBytesCount);
    }
    
    // Check if the read operation succeeded
    didSucceed = !hasMoreData;
    
    // Compute the hash digest
    (*context->finalFunction)(digest, context->hashObjectPointer);
    
    // Abort if the read operation failed
    if (!didSucceed) goto done;
    
    // Compute the string result
    for (size_t i = 0; i < context->digestLength; ++i) {
        snprintf(hash + (2 * i), 3, "%02x", (int)(digest[i]));
    }
    result = CFStringCreateWithCString(kCFAllocatorDefault, 
                                       (const char *)hash, 
                                       kCFStringEncodingUTF8);
    
done:
    
    if (readStream) {
        CFReadStreamClose(readStream);
        CFRelease(readStream);
    }
    if (fileURL) {
        CFRelease(fileURL);
    }
    return result;
    
}

static CC_LONG crc32_tbl[256] =
{
    0x00000000L, 0x77073096L, 0xEE0E612CL, 0x990951BAL, 0x076DC419L,
    0x706AF48FL, 0xE963A535L, 0x9E6495A3L, 0x0EDB8832L, 0x79DCB8A4L,
    0xE0D5E91EL, 0x97D2D988L, 0x09B64C2BL, 0x7EB17CBDL, 0xE7B82D07L,
    0x90BF1D91L, 0x1DB71064L, 0x6AB020F2L, 0xF3B97148L, 0x84BE41DEL,
    0x1ADAD47DL, 0x6DDDE4EBL, 0xF4D4B551L, 0x83D385C7L, 0x136C9856L,
    0x646BA8C0L, 0xFD62F97AL, 0x8A65C9ECL, 0x14015C4FL, 0x63066CD9L,
    0xFA0F3D63L, 0x8D080DF5L, 0x3B6E20C8L, 0x4C69105EL, 0xD56041E4L,
    0xA2677172L, 0x3C03E4D1L, 0x4B04D447L, 0xD20D85FDL, 0xA50AB56BL,
    0x35B5A8FAL, 0x42B2986CL, 0xDBBBC9D6L, 0xACBCF940L, 0x32D86CE3L,
    0x45DF5C75L, 0xDCD60DCFL, 0xABD13D59L, 0x26D930ACL, 0x51DE003AL,
    0xC8D75180L, 0xBFD06116L, 0x21B4F4B5L, 0x56B3C423L, 0xCFBA9599L,
    0xB8BDA50FL, 0x2802B89EL, 0x5F058808L, 0xC60CD9B2L, 0xB10BE924L,
    0x2F6F7C87L, 0x58684C11L, 0xC1611DABL, 0xB6662D3DL, 0x76DC4190L,
    0x01DB7106L, 0x98D220BCL, 0xEFD5102AL, 0x71B18589L, 0x06B6B51FL,
    0x9FBFE4A5L, 0xE8B8D433L, 0x7807C9A2L, 0x0F00F934L, 0x9609A88EL,
    0xE10E9818L, 0x7F6A0DBBL, 0x086D3D2DL, 0x91646C97L, 0xE6635C01L,
    0x6B6B51F4L, 0x1C6C6162L, 0x856530D8L, 0xF262004EL, 0x6C0695EDL,
    0x1B01A57BL, 0x8208F4C1L, 0xF50FC457L, 0x65B0D9C6L, 0x12B7E950L,
    0x8BBEB8EAL, 0xFCB9887CL, 0x62DD1DDFL, 0x15DA2D49L, 0x8CD37CF3L,
    0xFBD44C65L, 0x4DB26158L, 0x3AB551CEL, 0xA3BC0074L, 0xD4BB30E2L,
    0x4ADFA541L, 0x3DD895D7L, 0xA4D1C46DL, 0xD3D6F4FBL, 0x4369E96AL,
    0x346ED9FCL, 0xAD678846L, 0xDA60B8D0L, 0x44042D73L, 0x33031DE5L,
    0xAA0A4C5FL, 0xDD0D7CC9L, 0x5005713CL, 0x270241AAL, 0xBE0B1010L,
    0xC90C2086L, 0x5768B525L, 0x206F85B3L, 0xB966D409L, 0xCE61E49FL,
    0x5EDEF90EL, 0x29D9C998L, 0xB0D09822L, 0xC7D7A8B4L, 0x59B33D17L,
    0x2EB40D81L, 0xB7BD5C3BL, 0xC0BA6CADL, 0xEDB88320L, 0x9ABFB3B6L,
    0x03B6E20CL, 0x74B1D29AL, 0xEAD54739L, 0x9DD277AFL, 0x04DB2615L,
    0x73DC1683L, 0xE3630B12L, 0x94643B84L, 0x0D6D6A3EL, 0x7A6A5AA8L,
    0xE40ECF0BL, 0x9309FF9DL, 0x0A00AE27L, 0x7D079EB1L, 0xF00F9344L,
    0x8708A3D2L, 0x1E01F268L, 0x6906C2FEL, 0xF762575DL, 0x806567CBL,
    0x196C3671L, 0x6E6B06E7L, 0xFED41B76L, 0x89D32BE0L, 0x10DA7A5AL,
    0x67DD4ACCL, 0xF9B9DF6FL, 0x8EBEEFF9L, 0x17B7BE43L, 0x60B08ED5L,
    0xD6D6A3E8L, 0xA1D1937EL, 0x38D8C2C4L, 0x4FDFF252L, 0xD1BB67F1L,
    0xA6BC5767L, 0x3FB506DDL, 0x48B2364BL, 0xD80D2BDAL, 0xAF0A1B4CL,
    0x36034AF6L, 0x41047A60L, 0xDF60EFC3L, 0xA867DF55L, 0x316E8EEFL,
    0x4669BE79L, 0xCB61B38CL, 0xBC66831AL, 0x256FD2A0L, 0x5268E236L,
    0xCC0C7795L, 0xBB0B4703L, 0x220216B9L, 0x5505262FL, 0xC5BA3BBEL,
    0xB2BD0B28L, 0x2BB45A92L, 0x5CB36A04L, 0xC2D7FFA7L, 0xB5D0CF31L,
    0x2CD99E8BL, 0x5BDEAE1DL, 0x9B64C2B0L, 0xEC63F226L, 0x756AA39CL,
    0x026D930AL, 0x9C0906A9L, 0xEB0E363FL, 0x72076785L, 0x05005713L,
    0x95BF4A82L, 0xE2B87A14L, 0x7BB12BAEL, 0x0CB61B38L, 0x92D28E9BL,
    0xE5D5BE0DL, 0x7CDCEFB7L, 0x0BDBDF21L, 0x86D3D2D4L, 0xF1D4E242L,
    0x68DDB3F8L, 0x1FDA836EL, 0x81BE16CDL, 0xF6B9265BL, 0x6FB077E1L,
    0x18B74777L, 0x88085AE6L, 0xFF0F6A70L, 0x66063BCAL, 0x11010B5CL,
    0x8F659EFFL, 0xF862AE69L, 0x616BFFD3L, 0x166CCF45L, 0xA00AE278L,
    0xD70DD2EEL, 0x4E048354L, 0x3903B3C2L, 0xA7672661L, 0xD06016F7L,
    0x4969474DL, 0x3E6E77DBL, 0xAED16A4AL, 0xD9D65ADCL, 0x40DF0B66L,
    0x37D83BF0L, 0xA9BCAE53L, 0xDEBB9EC5L, 0x47B2CF7FL, 0x30B5FFE9L,
    0xBDBDF21CL, 0xCABAC28AL, 0x53B39330L, 0x24B4A3A6L, 0xBAD03605L,
    0xCDD70693L, 0x54DE5729L, 0x23D967BFL, 0xB3667A2EL, 0xC4614AB8L,
    0x5D681B02L, 0x2A6F2B94L, 0xB40BBE37L, 0xC30C8EA1L, 0x5A05DF1BL,
    0x2D02EF8DL
};

int CC_CRC32_Init(CC_CRC32_CTX *c) {
    c->crc =  0xFFFFFFFFL;
    return 0;
}

int CC_CRC32_Update(CC_CRC32_CTX *c, const uint8_t *data, CC_LONG len) {
    CC_LONG crc = c->crc;
    
    for(CC_LONG i=0; i<len;i++) {
        crc = (crc>>8) ^ crc32_tbl[(crc&0xFF) ^ *data++];
    }
    
    c->crc = crc;
    
    return 0;
}

int CC_CRC32_Final(unsigned char *md, CC_CRC32_CTX *c) {
    CC_LONG crc = c->crc;
    
    crc = crc ^ 0xFFFFFFFFL;
    
    md[0] = (crc & 0xff000000UL) >> 24;
    md[1] = (crc & 0x00ff0000UL) >> 16;
    md[2] = (crc & 0x0000ff00UL) >>  8;
    md[3] = (crc & 0x000000ffUL)      ;
    
    return 0;
}