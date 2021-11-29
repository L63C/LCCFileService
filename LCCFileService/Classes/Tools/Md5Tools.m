//
//  Md5Tools.m
//  S3Demo
//
//  Created by L63 on 2021/9/28.
//

#import "Md5Tools.h"
#import <CommonCrypto/CommonDigest.h>

@implementation Md5Tools
+ (NSString *)fileMD5WithData:(NSData *)data {
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(data.bytes, (int)data.length, result);   // This is the md5 call
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
    ];
}

+ (NSString *)fileMD5WithPath:(NSString *)path {
    NSFileHandle *handle = [NSFileHandle fileHandleForReadingAtPath:path];
    if (handle == nil) return @"ERROR GETTING FILE MD5"; // file didnt exist
    CC_MD5_CTX md5;
    CC_MD5_Init(&md5);
    BOOL done = NO;
    while (!done) {
        @autoreleasepool {
            NSData *fileData = [handle readDataOfLength:1 << 21];
            CC_MD5_Update(&md5, [fileData bytes], (uint32_t)[fileData length]);
            if ([fileData length] == 0) done = YES;
        }
    }
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5_Final(digest, &md5);
    NSString *s = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                   digest[0], digest[1],
                   digest[2], digest[3],
                   digest[4], digest[5],
                   digest[6], digest[7],
                   digest[8], digest[9],
                   digest[10], digest[11],
                   digest[12], digest[13],
                   digest[14], digest[15]];
    return s;
}

#define FileHashDefaultChunkSizeForReadingData 1024 * 8

+ (NSString *)getFileMD5WithPath:(NSString *)path

{
    return (__bridge_transfer NSString *)FileMD5HashCreateWithPath((__bridge CFStringRef)path, FileHashDefaultChunkSizeForReadingData);
}

CFStringRef FileMD5HashCreateWithPath(CFStringRef filePath, size_t chunkSizeForReadingData) {
    // Declare needed variables

    CFStringRef result = NULL;

    CFReadStreamRef readStream = NULL;

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

    CC_MD5_CTX hashObject;

    CC_MD5_Init(&hashObject);

    // Make sure chunkSizeForReadingData is valid

    if (!chunkSizeForReadingData) {
        chunkSizeForReadingData = FileHashDefaultChunkSizeForReadingData;
    }

    // Feed the data to the hash object

    bool hasMoreData = true;

    while (hasMoreData) {
        uint8_t buffer[chunkSizeForReadingData];

        CFIndex readBytesCount = CFReadStreamRead(readStream, (UInt8 *)buffer, (CFIndex)sizeof(buffer));

        if (readBytesCount == -1) break;

        if (readBytesCount == 0) {
            hasMoreData = false;

            continue;
        }

        CC_MD5_Update(&hashObject, (const void *)buffer, (CC_LONG)readBytesCount);
    }

    // Check if the read operation succeeded

    didSucceed = !hasMoreData;

    // Compute the hash digest

    unsigned char digest[CC_MD5_DIGEST_LENGTH];

    CC_MD5_Final(digest, &hashObject);

    // Abort if the read operation failed

    if (!didSucceed) goto done;

    // Compute the string result

    char hash[2 * sizeof(digest) + 1];

    for (size_t i = 0; i < sizeof(digest); ++i) {
        snprintf(hash + (2 * i), 3, "%02x", (int)(digest[i]));
    }

    result = CFStringCreateWithCString(kCFAllocatorDefault, (const char *)hash, kCFStringEncodingUTF8);

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

@end
