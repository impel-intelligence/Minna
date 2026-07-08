//
//  ObjC.m
//  Minna
//
//  Created by Taylor Lineman on 7/8/26.
//

// https://stackoverflow.com/a/36454808
#import "CatchException.h"

@implementation ObjC 

+ (BOOL)catchException:(void(^)(void))tryBlock error:(__autoreleasing NSError **)error {
    @try {
        tryBlock();
        return YES;
    }
    @catch (NSException *exception) {
        *error = [[NSError alloc] initWithDomain:exception.name code:0 userInfo:exception.userInfo];
        return NO;
    }
}

@end
