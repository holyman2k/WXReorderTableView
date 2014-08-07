//
//  WXSortableTableViewController.m
//  SortableTableView
//
//  Created by Charlie Wu on 7/08/2014.
//  Copyright (c) 2014 Charlie Wu. All rights reserved.
//

#import "WXReorderTableTableViewController.h"

@interface WXReorderTableTableViewController ()

@property (nonatomic, strong) UIView *snapshot;
@property (nonatomic, strong) NSIndexPath *indexPathOfReorderingCell;
@property (nonatomic, strong) UILongPressGestureRecognizer *longPressGestureRecognizer;
@end

@implementation WXReorderTableTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // setup re order gesture
    self.longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGestureHandler:)];
    self.longPressGestureRecognizer.minimumPressDuration = .5;
    self.longPressGestureRecognizer.allowableMovement = YES;
    [self.tableView addGestureRecognizer:self.longPressGestureRecognizer];
}

- (void)disableReorder
{
    if (self.longPressGestureRecognizer) [self.tableView removeGestureRecognizer:self.longPressGestureRecognizer];
}

- (void)longPressGestureHandler:(UILongPressGestureRecognizer *)gesture
{
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan: {   // start dragging
            // get sorting cell
            CGPoint point = [gesture locationInView:self.tableView];
            self.indexPathOfReorderingCell = [self.tableView indexPathForRowAtPoint:point];
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:self.indexPathOfReorderingCell];

            // create cell snap shot for dragging
            self.snapshot = [cell snapshotViewAfterScreenUpdates:NO];
            [self.snapshot setTransform:CGAffineTransformMakeScale(1.00, 1.00)];
            CGRect frame = self.snapshot.frame;
            frame.origin.y = point.y - frame.size.height / 2;
            self.snapshot.frame = frame;
            [self.view addSubview:self.snapshot];
            [self.tableView reloadRowsAtIndexPaths:@[self.indexPathOfReorderingCell] withRowAnimation:NO];

            break;
        }
        case UIGestureRecognizerStateChanged: { // when cell is dragging

            CGPoint point = [gesture locationInView:self.tableView];
            // move sorted cell
            CGRect frame = self.snapshot.frame;
            frame.origin.y = point.y - frame.size.height / 2;
            self.snapshot.frame = frame;

            NSIndexPath *fromIndexPath = self.indexPathOfReorderingCell;
            NSIndexPath *toIndexPath = [self.tableView indexPathForRowAtPoint:point];            
            if (!toIndexPath) toIndexPath = [self indexPathOfLastRowInSection:0];

            // check if table view requires to swap cell
            if (toIndexPath.row != fromIndexPath.row) {
                [self.reorderDelegate swapCellAtIndexPath:fromIndexPath toIndexPath:toIndexPath];
                self.indexPathOfReorderingCell = toIndexPath;
                UITableViewRowAnimation animation = fromIndexPath.row < toIndexPath.row ? UITableViewRowAnimationTop : UITableViewRowAnimationBottom;
                [self.tableView reloadRowsAtIndexPaths:@[fromIndexPath] withRowAnimation:animation];
                [self.tableView reloadRowsAtIndexPaths:@[toIndexPath] withRowAnimation:UITableViewRowAnimationNone];
            }
            break;
        }
        case UIGestureRecognizerStateEnded: {

            NSTimeInterval animationDuration = .2;

            CGPoint point = [gesture locationInView:self.tableView];
            NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:point];            
            if (!indexPath) indexPath = [self indexPathOfLastRowInSection:0];

            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
            CGRect frame = cell.frame;

            [UIView animateWithDuration:animationDuration delay:.1 options:UIViewAnimationOptionCurveEaseOut animations:^{
                self.snapshot.frame = frame;
            } completion:^(BOOL finished) {
                if (finished) {
                    [self.snapshot removeFromSuperview];
                    self.indexPathOfReorderingCell = nil;
                    self.snapshot = nil;
                    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                }
            }];
            break;
        }
        case UIGestureRecognizerStatePossible: {
            break;
        }
        case UIGestureRecognizerStateCancelled: {
            break;
        }
        case UIGestureRecognizerStateFailed: {
            break;
        }
        default:
            break;
    }
}

- (NSIndexPath *)indexPathOfLastRowInSection:(NSInteger)section
{
    NSInteger lastRow = [self.tableView.dataSource tableView:self.tableView numberOfRowsInSection:section] - 1;
    return [NSIndexPath indexPathForRow:lastRow inSection:0];

}
@end
