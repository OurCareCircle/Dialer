//
//  v2bFolder.h
//  PersistentTable
//
//  Created by sanjay krishnamurthy on 12/25/10.
//  Copyright 2010 Infinear Inc. All rights reserved.
//

#import <CoreData/CoreData.h>


@interface v2bFolder :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * folderName;
@property (nonatomic, retain) NSDate * creationDate;

@end



