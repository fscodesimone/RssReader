//
//  MasterViewController.m
//  RssReader
//
//  Created by Francesco De Simone on 28/11/12.
//  Copyright (c) 2012 Francesco De Simone. All rights reserved.
//

#import "MasterViewController.h"
#import "DetailViewController.h"
#import "Rss.h"
#import "Config.h"
@implementation MasterViewController
@synthesize fetchedResultsController=fetchedResultsController_, managedObjectContext=managedObjectContext_;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"RssReader", @"app_name");
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            self.clearsSelectionOnViewWillAppear = NO;
            self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
        }
    }
    return self;
}


#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    
	[super viewDidLoad];
    
    UIBarButtonItem *settingsButton = [[UIBarButtonItem alloc] initWithTitle:@"Settings" style:UIBarButtonItemStyleBordered target:self action:@selector(changeUrl)];
    self.navigationItem.leftBarButtonItem = settingsButton;
    

    
    UIBarButtonItem *reloadButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(reload)];
    self.navigationItem.rightBarButtonItem = reloadButton;
    
    filteredRssEntries = [[NSMutableArray alloc ] initWithCapacity:[[self.fetchedResultsController fetchedObjects]count] ];
    
    [filteredRssEntries addObjectsFromArray:[self.fetchedResultsController fetchedObjects]];

	
}

- (void)viewWillAppear:(BOOL)animated {
  
    
    
    NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
    NSFetchRequest * config = [[NSFetchRequest alloc] init];
   [config setEntity:[NSEntityDescription entityForName:@"Config" inManagedObjectContext:context]];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Config" inManagedObjectContext:context];
    NSError * error = nil;
    NSArray * confArray = [context executeFetchRequest:config error:&error];
    
    Config *conf =nil;
    if ([confArray count]==1) {
        conf=[confArray objectAtIndex:0];
        
        NSLog(@"Last update Time %@",conf.lastUpdate);
    }
    
    
    
    
    if (conf == nil ) {
		NSString * path = @"http://xml.corriereobjects.it/rss/homepage.xml";
        NSManagedObject *configData = [NSEntityDescription insertNewObjectForEntityForName:[entity name] inManagedObjectContext:context];
		
        
        [configData setValue:[NSDate date] forKey:@"lastUpdate"];
        [configData setValue:path forKey:@"url"];
      
		
		NSError *error = nil;
		if (![context save:&error]) {
			NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		}
       
        
		[self parseXMLFileAtURL:path];
	}
}


//reload objects from url
-(void) reload{
    
    NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
    NSFetchRequest * config = [[NSFetchRequest alloc] init];
    [config setEntity:[NSEntityDescription entityForName:@"Config" inManagedObjectContext:context]];
  
    NSError * error = nil;
    NSArray * confArray = [context executeFetchRequest:config error:&error];
    
    Config *conf =nil;
    if ([confArray count]==1) {
        conf=[confArray objectAtIndex:0];
        
        conf.lastUpdate = [NSDate date];
        
        NSError *error = nil;
		if (![context save:&error]) {
			NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		}
        
     NSLog(@"url %@",conf.url);
    [self parseXMLFileAtURL:conf.url];
    }
    
}



#pragma mark -
#pragma mark Add a new object

- (void)insertNewObject {
    
    // Create a new instance of the entity managed by the fetched results controller.
    NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
    NSEntityDescription *entity = [[self.fetchedResultsController fetchRequest] entity];
    
    NSFetchRequest * oldRss = [[NSFetchRequest alloc] init];
    [oldRss setEntity:[NSEntityDescription entityForName:@"Rss" inManagedObjectContext:context]];
    [oldRss setIncludesPropertyValues:NO]; //only fetch the managedObjectID
    
    NSError * error = nil;
    NSArray * rssArray = [context executeFetchRequest:oldRss error:&error];
    
    
    for (NSManagedObject * rss in rssArray) {
        [context deleteObject:rss];
    }
    NSError *deleteError = nil;
    [context save:&deleteError];
    NSLog(@"Deleting error %@, %@", deleteError, [deleteError userInfo]);
    
    
	// Loop through array of hashes and save
	for (NSMutableDictionary *rss in rssEntries) {
		
		NSManagedObject *rssData = [NSEntityDescription insertNewObjectForEntityForName:[entity name] inManagedObjectContext:context];
		//print
    

        
        
		[rssData setValue:[rss objectForKey: @"title"] forKey:@"title"];
		[rssData setValue:[rss objectForKey: @"summary"] forKey:@"summary"];
		[rssData setValue:[rss objectForKey: @"link"] forKey:@"link"];
		[rssData setValue:[rss objectForKey: @"date"] forKey:@"date"];
		[rssData setValue:[NSDate date] forKey:@"timeStamp"];
        [rssData setValue:[rss objectForKey: @"thumbimage"] forKey:@"thumbimage"];
		
		NSError *error = nil;
		if (![context save:&error]) {
			NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		}
		
	}
	
	rssEntries = nil;
	
}

#pragma mark -
#pragma mark XML Methods

- (void)parseXMLFileAtURL:(NSString *)URL{
	
	rssEntries = [[NSMutableArray alloc] init];
	
    //you must then convert the path to a proper NSURL or it won't work
    NSURL *xmlURL = [NSURL URLWithString:URL];
	
    // here, for some reason you have to use NSClassFromString when trying to alloc NSXMLParser, otherwise you will get an object not found error
    // this may be necessary only for the toolchain
    rssParser = [[NSXMLParser alloc] initWithContentsOfURL:xmlURL];
	
    // Set self as the delegate of the parser so that it will receive the parser delegate methods callbacks.
    [rssParser setDelegate:self];
	
    // Depending on the XML document you're parsing, you may want to enable these features of NSXMLParser.
    [rssParser setShouldProcessNamespaces:NO];
    [rssParser setShouldReportNamespacePrefixes:NO];
    [rssParser setShouldResolveExternalEntities:NO];
	
    [rssParser parse];
	
}

- (void)parserDidStartDocument:(NSXMLParser *)parser{
	
	NSLog(@"found file and started parsing");
	
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
	
	NSString * errorString = [NSString stringWithFormat:@"Unable to download new objects. switch to offline mode !"];
    
	NSLog(@"error parsing XML: %@", errorString);
	
	UIAlertView * errorAlert = [[UIAlertView alloc] initWithTitle:@"Error loading content" message:errorString delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[errorAlert show];
	
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict{
    
	//NSLog(@"found this element: %@", elementName);
    
    if ([elementName isEqualToString:@"thumbimage"]) {
		NSLog(@"Found image %@", [attributeDict valueForKey:@"url"]);
        
        NSString *mediaUrl = [NSString stringWithFormat:@"%@",[attributeDict valueForKey:@"url"]];
       currentImage = [[NSData alloc]initWithContentsOfURL:[NSURL URLWithString:mediaUrl]];
	}
    
	currentElement = [elementName copy];
	if ([elementName isEqualToString:@"item"]) {
		
		// clear out our story item caches...
		item = [[NSMutableDictionary alloc] init];
		currentTitle = [[NSMutableString alloc] init];
		currentDate = [[NSMutableString alloc] init];
		currentSummary = [[NSMutableString alloc] init];
		currentLink = [[NSMutableString alloc] init];
		
	}
	
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName{
	
	if ([elementName isEqualToString:@"item"]) {
        
		// save values to an item, then store that item into the array...
		[item setObject:currentTitle forKey:@"title"];
		[item setObject:currentLink forKey:@"link"];
		[item setObject:currentSummary forKey:@"summary"];
		[item setObject:currentDate forKey:@"date"];
        if(currentImage!=nil){
           
        [item setObject:currentImage forKey:@"thumbimage"];
       
        }
		[rssEntries addObject:[item copy]];
		//NSLog(@"adding rss item: %@", currentTitle);
	}
	
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string{
	
  
	if ([currentElement isEqualToString:@"title"]) {
		[currentTitle appendString:string];
	} else if ([currentElement isEqualToString:@"link"]) {
		[currentLink appendString:string];
	} else if ([currentElement isEqualToString:@"description"]) {
		[currentSummary appendString:string];
	} else if ([currentElement isEqualToString:@"pubDate"]) {
		[currentDate appendString:string];
	}
	
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
	

	NSLog(@"all done!");
	NSLog(@"rss array has %d items", [rssEntries count]);
    
	[self insertNewObject];
    
    
    //force to reload data 
    self.fetchedResultsController = nil;
    
    filteredRssEntries = [[NSMutableArray alloc ] initWithCapacity:[[self.fetchedResultsController fetchedObjects]count] ];
    
    [filteredRssEntries addObjectsFromArray:[self.fetchedResultsController fetchedObjects]];
    
    
    
    [self.tableView reloadData];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    //id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
    //return [sectionInfo numberOfObjects];
    return [filteredRssEntries count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSLog(@"setto la cella");
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
	Rss *rss = (Rss *)[filteredRssEntries objectAtIndex:indexPath.row];
	cell.textLabel.text = rss.title;
    cell.detailTextLabel.text = rss.date;
    if(rss.thumbimage==nil){
        cell.imageView.image = [UIImage imageNamed:@"no_img.png"];
    }else{
    cell.imageView.image = [UIImage imageWithData:rss.thumbimage];
    }
    return cell;
	
	
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the managed object for the given index path
        NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
        [context deleteObject:[self.fetchedResultsController objectAtIndexPath:indexPath]];
        
        // Save the context.
        NSError *error = nil;
        if (![context save:&error]) {
          
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // The table view should not be re-orderable.
    return NO;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    //  il nib  name è il nome che dai al cazzo del file xib
	
    DetailViewController* c = [[DetailViewController alloc] initWithNibName:@"DetailViewController_iPhone" bundle:nil];
   
	Rss *rss = (Rss *)[self.fetchedResultsController objectAtIndexPath:indexPath];
	c.rss = rss;

	[self.navigationController pushViewController:c animated: YES];
    
	
}

#pragma mark -
#pragma mark Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController {
    
    if (fetchedResultsController_ != nil) {
        return fetchedResultsController_;
    }
    
    /*
     Set up the fetched results controller.
     */
    // Create the fetch request for the entity.
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Rss" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timeStamp" ascending:YES];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:@"Root"];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
    
    NSError *error = nil;
    if (![fetchedResultsController_ performFetch:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return fetchedResultsController_;
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}


- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}


-(void) changeUrl{
    
    
    NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
    NSFetchRequest * config = [[NSFetchRequest alloc] init];
    [config setEntity:[NSEntityDescription entityForName:@"Config" inManagedObjectContext:context]];
   
    NSError * error = nil;
    NSArray * confArray = [context executeFetchRequest:config error:&error];
    
    Config *conf =nil;
    if ([confArray count]==1) {
        conf=[confArray objectAtIndex:0];
         NSLog(@"url %@",conf.url);
         NSLog(@"last update %@",conf.lastUpdate);
    }
    

    
        
        UIAlertView *myAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Change Url ", @"change_url_string")
                                                              message:@"Inserisci l'url" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
        myTextField = [[UITextField alloc] initWithFrame:CGRectMake(12.0, 45.0, 260.0, 25.0)];
    
        [myTextField setBackgroundColor:[UIColor whiteColor]];
        myTextField.text=conf.url;
        //NSLog(@"url %@",conf.url);
        [myAlertView addSubview:myTextField];
        [myAlertView show];
      
    }

- (void)alertView:(UIAlertView *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
    {
       // NSLog(@"save new link=%@",myTextField.text);
        
        
        NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
        NSFetchRequest * config = [[NSFetchRequest alloc] init];
        [config setEntity:[NSEntityDescription entityForName:@"Config" inManagedObjectContext:context]];
        
        NSError * error = nil;
        NSArray * confArray = [context executeFetchRequest:config error:&error];
        
        Config *conf =nil;
        if ([confArray count]==1) {
            conf=[confArray objectAtIndex:0];
            
            conf.url = myTextField.text;
            
            NSError *error = nil;
            if (![context save:&error]) {
                NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            }
        }
        
    }



#pragma mark -
#pragma mark UISearchDisplayController Delegate Methods

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope{
    
  
	[filteredRssEntries removeAllObjects];
    NSPredicate * predicate=nil;
    NSArray *result =  nil;
    if ([searchText length] > 0) {
        predicate = [NSPredicate predicateWithFormat:@"title contains[cd] %@ OR summary contains[cd] %@", searchText ,searchText];
        
        result =  [[[self fetchedResultsController] fetchedObjects] filteredArrayUsingPredicate:predicate];
    }else{
        result =  [[self fetchedResultsController] fetchedObjects] ;
    }
    
 
   // NSLog(@"results found : %d",[result count]);
    
    filteredRssEntries = [[NSMutableArray alloc]initWithArray:result];
    
  

}


- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString{
    [self filterContentForSearchText:searchString scope:
	 [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:[self.searchDisplayController.searchBar selectedScopeButtonIndex]]];
    
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}


- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption{
	
    [self filterContentForSearchText:[self.searchDisplayController.searchBar text] scope:
     [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:searchOption]];
    
  
    return YES;
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)saearchBar {
    [filteredRssEntries removeAllObjects];
    [filteredRssEntries addObjectsFromArray: [self.fetchedResultsController fetchedObjects]];
}

@end
