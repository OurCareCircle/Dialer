//
//  v2bEmail.h
//  Voice2Buzz
//
//  Created by sanjay krishnamurthy on 1/2/11.
//  Copyright 2011 Infinear Inc. All rights reserved.
//

#import <CoreData/CoreData.h>


@interface v2bEmail :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * nickName;
@property (nonatomic, retain) NSString * emailAddress;

@end



