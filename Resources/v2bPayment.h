//
//  v2bPayment.h
//  Recorder
//
//  Created by sanjay krishnamurthy on 5/16/11.
//  Copyright 2011 Infinear Inc. All rights reserved.
//

#import <CoreData/CoreData.h>


@interface v2bPayment :  NSManagedObject  
{
}

@property (nonatomic, retain) NSDate *   PaymentDate;
@property (nonatomic, retain) NSString * PaymentType;
@property (nonatomic, retain) NSNumber * Quantity;

@end



