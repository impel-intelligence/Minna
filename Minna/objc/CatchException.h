//
//  CatchException.h
//  Amoeba
//
//  Created by Taylor Lineman on 1/16/25.
// https://stackoverflow.com/a/36454808

#import <Foundation/Foundation.h>

// https://stackoverflow.com/a/36454808
@interface ObjcException : NSObject

+ (BOOL)catchException:(void(^)(void))tryBlock error:(__autoreleasing NSError **)error;

@end
