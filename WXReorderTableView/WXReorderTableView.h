//
//  WXReorderTableView.h
//  WXReorderTableViewExample
//
//  Created by Charlie Wu on 8/08/2014.
//  Copyright (c) 2014 Charlie Wu. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol WXReorderTableViewDelegate <NSObject>

- (void)swapObjectAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath;

@end

@interface WXReorderTableView : UITableView

@property (nonatomic, readonly) NSIndexPath *indexPathOfReorderingCell;

@property (nonatomic, weak) id<WXReorderTableViewDelegate> reorderDelegate;

- (void)disableReorder;

@end
