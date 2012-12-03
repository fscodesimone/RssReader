//
//  MasterViewController.h
//  RssReader
//
//  Created by Francesco De Simone on 28/11/12.
//  Copyright (c) 2012 Francesco De Simone. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"
@class DetailViewController;

#import <CoreData/CoreData.h>

@interface MasterViewController : UITableViewController <NSFetchedResultsControllerDelegate,NSXMLParserDelegate>{
    

    IBOutlet UITableView * newsTable;
	NSXMLParser * rssParser;
	NSMutableArray * rssEntries;
    NSMutableArray * filteredRssEntries;
	NSMutableDictionary * item;
	NSString * currentElement;
	NSMutableString * currentTitle, * currentDate, * currentSummary, * currentLink;
    NSData *currentImage;
    UITextField *myTextField;
    MBProgressHUD *HUD;
	
@private
    NSFetchedResultsController *fetchedResultsController_;
    NSManagedObjectContext *managedObjectContext_;

    
    
}

- (void)parseXMLFileAtURL:(NSString *)URL;


@property (strong, nonatomic) DetailViewController *detailViewController;

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end
