//
//  Rss.h
//  RssReader
//
//  Created by Francesco De Simone on 28/11/12.
//  Copyright (c) 2012 Francesco De Simone. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Rss : NSManagedObject

@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSDate * timeStamp;
@property (nonatomic, retain) NSString * summary;
@property (nonatomic, retain) NSString * link;
@property (nonatomic, retain) NSData * thumbimage;
@property (nonatomic, retain) NSString * date;

@end
