//
//  Math24.h
// 
//
//  Created by olami on 2017/4/20.
//  Copyright © 2017年 VIA Techologies, Inc. &OLAMI Team All rights reserved.
//  http://olami.ai

#import <Foundation/Foundation.h>

@interface Math24 : NSObject
+ (Math24*)shareInstance;
- (NSString*)calculate:(NSArray*)nums;
@end
