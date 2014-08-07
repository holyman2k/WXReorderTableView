//
//  WXTask.h
//  WXRedorderTableViewCoreDataExample
//
//  Created by Charlie Wu on 7/08/2014.
//  Copyright (c) 2014 Charlie Wu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface WXTask : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * sort;

@end
