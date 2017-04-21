// 
//  v2bSettings.m
//  Recorder
//
//  Created by sanjay krishnamurthy on 5/2/11.
//  Copyright 2011 Infinear Inc. All rights reserved.
//

#import "v2bSettings.h"


@implementation v2bSettings 

@dynamic telNum;
@dynamic xferSpeed;
@dynamic defaultEmail;
@dynamic balanceSeconds;
@dynamic userName;
@dynamic CountryCode;

//moved from .h file on 091011
//Use this to index the array of xfer speeds; the user selects 0..2 index
static const float xferArr[] = {16000.0, 32000.0, 41100.0};

+ (NSMutableArray *)getV2bXferArr {
	NSMutableArray *v2bXferArr = [[NSMutableArray alloc] init];
	NSNumber *num = [NSNumber numberWithFloat:xferArr[0]];
	[v2bXferArr insertObject:num atIndex:0];
	num = [NSNumber numberWithFloat:xferArr[1]];
	[v2bXferArr insertObject:num atIndex:1];
	num = [NSNumber numberWithFloat:xferArr[2]];
	[v2bXferArr insertObject:num atIndex:2];
	
	return v2bXferArr;
}

@end
