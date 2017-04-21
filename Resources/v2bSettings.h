//
//  v2bSettings.h
//  Recorder
//
//  Created by sanjay krishnamurthy on 5/2/11.
//  Copyright 2011 Infinear Inc. All rights reserved.
//

#import <CoreData/CoreData.h>


@interface v2bSettings :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * telNum;
@property (nonatomic, retain) NSNumber * xferSpeed;
@property (nonatomic, retain) NSString * defaultEmail;
@property (nonatomic, retain) NSNumber * balanceSeconds;
@property (nonatomic, retain) NSString * userName;
@property (nonatomic, retain) NSString * CountryCode;

+ (NSMutableArray *)getV2bXferArr;

@end



