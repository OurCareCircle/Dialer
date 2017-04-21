//
//  V2bDialed.h
//  Dialer
//
//  Created by sanjay krishnamurthy on 7/11/12.
//  Copyright (c) 2012 Infinear Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface V2bDialed : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * number;
@property (nonatomic, retain) NSString * country;
@property (nonatomic, retain) NSDate * dialedTime;

@end
