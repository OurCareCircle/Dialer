//
//  MultiSelectCellController.h
//  Voice2Buzz
//
//  Created by sanjay krishnamurthy on 1/2/11.
//  Copyright 2011 Infinear Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CellController.h"

@interface MultiSelectCellController : NSObject <CellController>
{
	NSString *label;
	BOOL      selected;
}

@property (nonatomic, retain) NSString *label;

- (id)initWithLabel:(NSString *)newLabel;
- (void)clearSelectionForTableView:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath;
- (BOOL)selected;

@end
