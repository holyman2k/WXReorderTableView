//
//  WXTableViewController.m
//  WXReorderTableViewExample
//
//  Created by Charlie Wu on 7/08/2014.
//  Copyright (c) 2014 Charlie Wu. All rights reserved.
//

#import "WXTableViewController.h"
#import "WXReorderTableView.h"

@interface WXTableViewController () <WXReorderTableViewDelegate>

@property (nonatomic, strong) NSArray *list;

@property (nonatomic, strong) WXReorderTableView *tableView;

@end

@implementation WXTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.list = @[@"Buy milk", @"Buy bread", @"Buy soft drink", @"Excise", @"Have dinner with friends"];
    self.title = @"Reorder list";
}

- (void)swapObjectAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    NSMutableArray *list = [self.list mutableCopy];
    [list exchangeObjectAtIndex:fromIndexPath.row withObjectAtIndex:toIndexPath.row];
    self.list = list;

    // WXReorderTableTableViewController will re-render the cell
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.list.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];

    // if this cell is been dragged
    if (self.tableView.indexPathOfReorderingCell != nil && indexPath.row == self.tableView.indexPathOfReorderingCell.row) {
        cell.textLabel.text = nil;
        return cell;
    }

    NSString *listItem = self.list[indexPath.row];
    cell.textLabel.text = listItem;

    return cell;
}

@end
