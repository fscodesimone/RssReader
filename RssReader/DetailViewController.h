//
//  DetailViewController.h
//  RssReader
//
//  Created by Francesco De Simone on 28/11/12.
//  Copyright (c) 2012 Francesco De Simone. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Rss.h"

@interface DetailViewController : UIViewController <UISplitViewControllerDelegate>{
    
    Rss *rss;
}

@property (strong, nonatomic) Rss  *rss;

@property (weak, nonatomic) IBOutlet UILabel *titoloLabel;
@property (weak, nonatomic) IBOutlet UILabel *descLabel;
@property (weak, nonatomic) IBOutlet UIImageView *image;

- (IBAction)openInSafari:(id)sender;
@end
