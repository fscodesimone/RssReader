//
//  DetailViewController.m
//  RssReader
//
//  Created by Francesco De Simone on 28/11/12.
//  Copyright (c) 2012 Francesco De Simone. All rights reserved.
//

#import "DetailViewController.h"

@interface DetailViewController ()
@property (strong, nonatomic) UIPopoverController *masterPopoverController;
- (void)configureView;
@end

@implementation DetailViewController
@synthesize rss,descLabel,titoloLabel,image;
#pragma mark - Managing the detail item



- (void)configureView
{
    // Update the user interface for the detail item.
    
    titoloLabel.text =rss.title;
    descLabel.text = rss.summary;
    image.image = [UIImage imageWithData:rss.thumbimage];
   
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [self configureView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"Dettaglio Notizia", @"detail");
    }
    return self;
}
							
#pragma mark - Split view

- (void)splitViewController:(UISplitViewController *)splitController willHideViewController:(UIViewController *)viewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popoverController
{
    barButtonItem.title = NSLocalizedString(@"Back", @"back");
    [self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
    self.masterPopoverController = popoverController;
}

- (void)splitViewController:(UISplitViewController *)splitController willShowViewController:(UIViewController *)viewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    // Called when the view is shown again in the split view, invalidating the button and popover controller.
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    self.masterPopoverController = nil;
}


-(IBAction)openInSafari:(id)sender{
    
    NSURL *url = [NSURL URLWithString:rss.link];
    
    if (![[UIApplication sharedApplication] openURL:url])
    NSLog(@"%@%@",@"Failed to open url:",[url description]);
    
}

@end
