//
//  LCFileTagM.m
//  S3Demo
//
//  Created by L63 on 2021/9/29.
//

#import "LCFileTagM.h"

@implementation LCFileTagM
- (NSString *)tagId{
    if(!_tag){
        _tag = [NSString stringWithFormat:@"%@_%@",_tag,_group];
    }
    return _tag;
}
@end
