//
//  CountryViewController.h
//  Dialer
//
//  Created by sanjay krishnamurthy on 7/4/12.
//  Copyright (c) 2012 Infinear Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CountryViewController : UITableViewController <UISearchDisplayDelegate, UISearchBarDelegate>
{
	NSArray		       *listContent;			// The master content.
	NSMutableArray	   *filteredListContent;	// The content filtered as a result of a search.
    NSArray             *sectionedListContent;  // The content filtered into alphabetical sections.
	
	// The saved state of the search UI if a memory warning removed the view.
    NSString		     *savedSearchTerm;
    NSInteger	 	      savedScopeButtonIndex;
    BOOL	  		      searchWasActive;
    
    // Remember which country was picked
    NSString             *chosenCountry;

}

@property (nonatomic, retain) NSArray              *listContent;
@property (nonatomic, retain) NSMutableArray       *filteredListContent;
@property (nonatomic, retain, readonly) NSArray    *sectionedListContent;
@property (nonatomic, retain) NSString             *chosenCountry;

@property (nonatomic, copy) NSString               *savedSearchTerm;
@property (nonatomic) NSInteger                     savedScopeButtonIndex;
@property (nonatomic) BOOL                          searchWasActive;

@end