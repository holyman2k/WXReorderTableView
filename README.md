WXReorderTableView
==================

WXReorderTableView is a sub class of UITableViewController that implements hold-drag re ordering of table view cells. 
This library works with list backed table view as well as NSFetchedResultsController.

There are other library on github such as [BVReorderTableView]https://github.com/bvogelzang/BVReorderTableView you can
also have a look

Installation
------------

Download and add the following classes

    WXReorderTableView/WXReorderTableView.h  
    WXReorderTableView/WXReorderTableView.m
  
Implement Reordering
--------------------

Sub class WXReorderTableView set sub class and set your table view controller as the reorder delegate

    - (void)viewDidLoad
    {
        [super viewDidLoad];
        self.reorderDelegate = self;
    }
  
Implement delegate method

    - (void)swapObjectAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
  
when rendering cell, check the re ordering cell and set it to blank

    UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
    {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    
        // if cell is been dragged
        if (self.indexPathOfReorderingCell != nil && indexPath.row == self.indexPathOfReorderingCell.row) {
            
            // config cell that is been dragged
            return cell;
        }
    
        // config cell
        
        return cell;
    }
  
  
Examples
--------

* WXReorderTableViewExample - List backed table view
* WXRedorderTableViewCoreDataExample - Core Data, NSFetchedResultController backed table viewDidLoad


