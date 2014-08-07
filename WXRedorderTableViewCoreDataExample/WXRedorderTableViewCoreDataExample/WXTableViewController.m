//
//  WXTableViewController.m
//  WXReorderTableViewExample
//
//  Created by Charlie Wu on 7/08/2014.
//  Copyright (c) 2014 Charlie Wu. All rights reserved.
//

#import "WXTableViewController.h"
#import "WXAppDelegate.h"
#import "WXTask.h"

@interface WXTableViewController () <WXReorderTableViewDelegate, NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

@end

@implementation WXTableViewController

- (NSManagedObjectContext *)managedObjectContext
{
    WXAppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    return appDelegate.managedObjectContext;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Task"];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"sort" ascending:YES]];

    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:[self managedObjectContext]
                                                                          sectionNameKeyPath:nil
                                                                                   cacheName:nil];
    [self.fetchedResultsController performFetch:nil];
    self.fetchedResultsController.delegate = self;
    self.title = @"Task list";

    self.reorderDelegate = self;
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView reloadData];
}

- (void)swapCellAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    WXTask *fromTask = [self.fetchedResultsController objectAtIndexPath:fromIndexPath];
    WXTask *toTask = [self.fetchedResultsController objectAtIndexPath:toIndexPath];

    NSNumber *fromTaskSort = fromTask.sort;

    fromTask.sort = toTask.sort;
    toTask.sort = fromTaskSort;

    [[self managedObjectContext] save:nil];

    // WXReorderTableTableViewController will re-render the cell
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.fetchedResultsController.sections[0] numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];

    // if this cell is been dragged
    if (self.indexPathOfReorderingCell != nil && indexPath.row == self.indexPathOfReorderingCell.row) {
        cell.textLabel.text = nil;
        return cell;
    }

    WXTask *task = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.textLabel.text = task.name;

    return cell;
}

@end
