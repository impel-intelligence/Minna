//
//  CatchException.h
//  Amoeba
//
//  Created by Taylor Lineman on 1/16/25.
//  Edited by Claude Opus 5 (Anthropic) on 2026-08-13
//
//  Attribution: adapted from https://stackoverflow.com/a/36454808
//  Stack Overflow contributions from that period are licensed CC BY-SA 3.0 (https://creativecommons.org/licenses/by-sa/3.0/), which is why this file carries its own attribution rather than the project's Apache-2.0 header.

#import <Foundation/Foundation.h>

@interface CatchException : NSObject

+ (BOOL)catchException:(void(^)(void))tryBlock error:(__autoreleasing NSError **)error;

@end
