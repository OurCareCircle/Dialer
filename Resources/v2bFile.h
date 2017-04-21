//
//  v2bFile.h
//  Voice2Buzz
//
//  Created by sanjay krishnamurthy on 12/29/10.
//  Copyright 2010 Infinear Inc. All rights reserved.
//

#import <CoreData/CoreData.h>


@interface v2bFile :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * fileURL;
@property (nonatomic, retain) NSString * fileName;
@property (nonatomic, retain) NSString * folderName;
@property (nonatomic, retain) NSNumber * fileLength;
@property (nonatomic, retain) NSString * emailAddrList;
@property (nonatomic, retain) NSNumber * deleted;

@end



