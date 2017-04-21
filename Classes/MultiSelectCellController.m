//
//  MultiSelectCellController.m
//  MultiRowSelect
//
//  Created by Matt Gallagher on 11/01/09.
//  Copyright 2008 Matt Gallagher. All rights reserved.
//
//  Permission is given to use this source code file, free of charge, in any
//  project, commercial or otherwise, entirely at your risk, with the condition
//  that any redistribution (in part or whole) of source code must retain
//  this copyright and permission notice. Attribution in compiled projects is
//  appreciated but not required.
//

#import "MultiSelectCellController.h"
#import "MultiSelectTableViewCell.h"

const NSInteger SELECTION_INDICATOR_TAG = 54321;
const NSInteger TEXT_LABEL_TAG = 54322;

@implementation MultiSelectCellController

@synthesize label;

//
// init
//
// Init method for the object.
//
- (id)initWithLabel:(NSString *)newLabel
{
	self = [super init];
	if (self != nil)
	{
		label = [newLabel retain];
	}
	return self;
}

//
// dealloc
//
// Releases instance memory.
//
- (void)dealloc
{
	[label release];
	[super dealloc];
}

//
// selection
//
// Accessor for the selection
//
- (BOOL)selected
{
	return selected;
}

//
// clearSelectionForTableView:
//
// Clears the selection for the given table
//
- (void)clearSelectionForTableView:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath
{
	if (selected)
	{
		[self tableView:tableView didSelectRowAtIndexPath:indexPath];
		selected = NO;
	}
}

//
// tableView:didSelectRowAtIndexPath:
//
// Marks the current row if editing is enabled.
//
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	//mandatorily force indicators to change
	if (TRUE) {
	//if (tableView.isEditing)
	//{
		selected = !selected;
		//Flip cell indicator at selected index
		UITableViewCell *cell  = [tableView cellForRowAtIndexPath:indexPath];		
		UIImageView *indicator = (UIImageView *)[cell.contentView viewWithTag:SELECTION_INDICATOR_TAG];
		if (selected)
		{
			indicator.image = [UIImage imageNamed:@"IsSelected.png"];
			cell.backgroundView.backgroundColor = [UIColor colorWithRed:223.0/255.0 green:230.0/255.0 blue:250.0/255.0 alpha:1.0];
		}
		else
		{
			indicator.image = [UIImage imageNamed:@"NotSelected.png"];
			cell.backgroundView.backgroundColor = [UIColor whiteColor];
		}
	}
}

//
// tableView:cellForRowAtIndexPath:
//
// Constructs and configures the MultiSelectTableViewCell for this row.
//
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *cellIdentifier = @"MultiSelectCellController";
	UITableViewCell *cell =
	[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	UIImageView *indicator;
	UILabel *textLabel;
	if (!cell)
	{
        cell =
		[[[MultiSelectTableViewCell alloc]
		  initWithFrame:CGRectMake(0, 0, 320, tableView.rowHeight)
		  reuseIdentifier:cellIdentifier]
		 autorelease];
		
		
		indicator = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"NotSelected.png"]] autorelease];
		
		const NSInteger IMAGE_SIZE = 30;
		const NSInteger SIDE_PADDING = 5;
		
		indicator.tag = SELECTION_INDICATOR_TAG;
		indicator.frame =
		CGRectMake(-EDITING_HORIZONTAL_OFFSET + SIDE_PADDING, (0.5 * tableView.rowHeight) - (0.5 * IMAGE_SIZE), IMAGE_SIZE, IMAGE_SIZE);
		[cell.contentView addSubview:indicator];
		
		textLabel = [[[UILabel alloc] initWithFrame:CGRectMake(SIDE_PADDING, 0, 320, tableView.rowHeight)] autorelease];
		textLabel.tag = TEXT_LABEL_TAG;
		textLabel.textColor = [UIColor blackColor];
		textLabel.backgroundColor = [UIColor clearColor];
		textLabel.font = [UIFont boldSystemFontOfSize:[UIFont labelFontSize]];
		[cell.contentView addSubview:textLabel];
		
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		cell.backgroundView = [[[UIView alloc] init] autorelease];
	}
	else
	{
		indicator = (UIImageView *)[cell.contentView viewWithTag:SELECTION_INDICATOR_TAG];
		textLabel = (UILabel *)[cell.contentView viewWithTag:TEXT_LABEL_TAG];
	}
	
	textLabel.text = label;
	
	if (selected)
	{
		indicator.image = [UIImage imageNamed:@"IsSelected.png"];
		cell.backgroundView.backgroundColor = [UIColor colorWithRed:223.0/255.0 green:230.0/255.0 blue:250.0/255.0 alpha:1.0];
	}
	else
	{
		indicator.image = [UIImage imageNamed:@"NotSelected.png"];
		cell.backgroundView.backgroundColor = [UIColor whiteColor];
	}
	
	return cell;
}

@end
