//
//  WXReorderTableView.m
//  WXReorderTableViewExample
//
//  Created by Charlie Wu on 8/08/2014.
//  Copyright (c) 2014 Charlie Wu. All rights reserved.
//

#import "WXReorderTableView.h"

@interface WXReorderTableView() <UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIView *snapshot;
@property (nonatomic, strong) NSIndexPath *indexPathOfReorderingCell;
@property (nonatomic, strong) UILongPressGestureRecognizer *longPressGestureRecognizer;
@property (nonatomic, strong) NSTimer *autoScrollTimer;


@end

@implementation WXReorderTableView

- (void)layoutSubviews
{
    [super layoutSubviews];
    // setup re order gesture
    if (!self.longPressGestureRecognizer) {
        self.longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGestureHandler:)];
        self.longPressGestureRecognizer.minimumPressDuration = .5;
        self.longPressGestureRecognizer.allowableMovement = YES;
        self.longPressGestureRecognizer.delegate = self;
        [self addGestureRecognizer:self.longPressGestureRecognizer];
    }
}

- (void)disableReorder
{
    if (self.longPressGestureRecognizer) [self removeGestureRecognizer:self.longPressGestureRecognizer];
}

- (void)longPressGestureHandler:(UILongPressGestureRecognizer *)gesture
{
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan: {   // start dragging
            // get sorting cell
            CGPoint point = [gesture locationInView:self];
            self.indexPathOfReorderingCell = [self indexPathForRowAtPoint:point];
            UITableViewCell *cell = [self cellForRowAtIndexPath:self.indexPathOfReorderingCell];

            // create cell snap shot for dragging
            self.snapshot = [self snapshotViewForCell:cell];
            [self updateSnapshotLocation];
            [self addSubview:self.snapshot];
            [self reloadRowsAtIndexPaths:@[self.indexPathOfReorderingCell] withRowAnimation:NO];

            break;
        }
        case UIGestureRecognizerStateChanged: { // when cell is dragging

            // move sorted cell
            [self updateSnapshotLocation];
            [self updateTableCell];
            break;
        }
        case UIGestureRecognizerStateEnded: {
            NSLog(@"ended");

            NSTimeInterval animationDuration = .2;

            CGPoint point = [gesture locationInView:self];
            NSIndexPath *indexPath = [self indexPathForRowAtPoint:point];
            if (!indexPath) indexPath = point.y > 0 ? [self indexPathOfLastRowInSection:0] : [NSIndexPath indexPathForRow:0 inSection:0];


            UITableViewCell *cell = [self cellForRowAtIndexPath:indexPath];
            CGRect frame = cell.frame;

            [UIView animateWithDuration:animationDuration delay:.1 options:UIViewAnimationOptionCurveEaseOut animations:^{
                self.snapshot.frame = frame;
            } completion:^(BOOL finished) {
                if (finished) {
                    [self.snapshot removeFromSuperview];
                    self.indexPathOfReorderingCell = nil;
                    self.snapshot = nil;
                    [self reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                }
            }];
            break;
        }
        case UIGestureRecognizerStatePossible: {
            NSLog(@"possible");
            break;
        }
        case UIGestureRecognizerStateCancelled: {
            NSLog(@"cancelled");
            break;
        }
        case UIGestureRecognizerStateFailed: {
            NSLog(@"failed");
            break;
        }
        default:
            break;
    }
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer == self.longPressGestureRecognizer) {
        CGPoint point = [gestureRecognizer locationInView:self];
        self.indexPathOfReorderingCell = [self indexPathForRowAtPoint:point];
        UITableViewCell *cell = [self cellForRowAtIndexPath:self.indexPathOfReorderingCell];
        return cell != nil;
    }
    return YES;
}

- (void)updateTableCell
{
    CGPoint point = [self.longPressGestureRecognizer locationInView:self];
    NSIndexPath *fromIndexPath = self.indexPathOfReorderingCell;
    NSIndexPath *toIndexPath = [self indexPathForRowAtPoint:point];

    if (!toIndexPath) toIndexPath = [self indexPathOfLastRowInSection:0];

    // check if table view requires to swap cell
    if (toIndexPath.row != fromIndexPath.row
        && labs(toIndexPath.row - fromIndexPath.row) == 1) {
        // check if need to scroll table view
        NSLog(@"to %@, from %@", @(toIndexPath.row), @(fromIndexPath.row));

        [self.delegate swapObjectAtIndexPath:fromIndexPath toIndexPath:toIndexPath];
        self.indexPathOfReorderingCell = toIndexPath;
        UITableViewRowAnimation animation = fromIndexPath.row < toIndexPath.row ? UITableViewRowAnimationTop : UITableViewRowAnimationBottom;
        [self reloadRowsAtIndexPaths:@[fromIndexPath] withRowAnimation:animation];
        [self reloadRowsAtIndexPaths:@[toIndexPath] withRowAnimation:UITableViewRowAnimationNone];

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self autoScrollTableView];
        });

    }
}

- (void)updateSnapshotLocation
{
    CGPoint point = [self.longPressGestureRecognizer locationInView:self];
    CGRect frame = self.snapshot.frame;
    frame.origin.y = point.y - frame.size.height / 2;
    self.snapshot.frame = frame;
}

- (void)autoScrollTableView
{
//    CGPoint point = [self.longPressGestureRecognizer locationInView:self];
//    NSIndexPath *toIndexPath = [self indexPathForRowAtPoint:point];
//    UITableViewCell *firstCell = self.visibleCells[1];
//    UITableViewCell *lastCell = self.visibleCells.lastObject;
//    UITableViewCell *currentCell = [self cellForRowAtIndexPath:toIndexPath];
//    if (currentCell == lastCell) {
//
//        NSLog(@"auto scroll");
//        NSInteger rows = [self.dataSource tableView:self numberOfRowsInSection:0];
//        if (toIndexPath.row < rows - 1) {
//            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:toIndexPath.row + 1 inSection:0];
//
//            CGFloat height = [self.delegate tableView:self heightForRowAtIndexPath:indexPath];
//            CGPoint offset = self.contentOffset;
//            offset.y += height;
//            [UIView animateWithDuration:.6 animations:^{
//                self.contentOffset = offset;
//                [self updateSnapshotLocation];
//            } completion:^(BOOL finished) {
//                [self updateTableCell];
//            }];
//        }
//    } else if (currentCell == firstCell) {
//        if (toIndexPath.row > 0) {
//            NSLog(@"auto scroll up");
//            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:toIndexPath.row - 1 inSection:0];
//
//            CGFloat height = [self.delegate tableView:self heightForRowAtIndexPath:indexPath];
//            CGPoint offset = self.contentOffset;
//            offset.y -= height;
//            [UIView animateWithDuration:.6 animations:^{
//                self.contentOffset = offset;
//                [self updateSnapshotLocation];
//            } completion:^(BOOL finished) {
//                [self updateTableCell];
//            }];
//        }
//    }

//    CGPoint currentOffset = self.contentOffset;
//    CGPoint newOffset = CGPointMake(currentOffset.x, currentOffset.y + 55);
//
//    if (newOffset.y < -self.contentInset.top) {
//        newOffset.y = -self.contentInset.top;
//    } else if (self.contentSize.height + self.contentInset.bottom < self.frame.size.height) {
//        newOffset = currentOffset;
//    } else if (newOffset.y > (self.contentSize.height + self.contentInset.bottom) - self.frame.size.height) {
//        newOffset.y = (self.contentSize.height + self.contentInset.bottom) - self.frame.size.height;
//    }

    CGPoint point = [self.longPressGestureRecognizer locationInView:self];
    NSLog(@"pint %@", NSStringFromCGPoint(point));


}

- (NSIndexPath *)indexPathOfLastRowInSection:(NSInteger)section
{
    NSInteger lastRow = [self.dataSource tableView:self numberOfRowsInSection:section] - 1;
    return [NSIndexPath indexPathForRow:lastRow inSection:0];
    
}

- (UIImageView *)snapshotViewForCell:(UITableViewCell *)cell
{

//    self.snapshot = [cell snapshotViewAfterScreenUpdates:NO];
//    [self.snapshot setTransform:CGAffineTransformMakeScale(1.00, 1.00)];
    UIView *subView = cell;
    UIGraphicsBeginImageContextWithOptions(subView.bounds.size, YES, 0.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [subView.layer renderInContext:context];
    UIImage *snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    UIImageView *imageView = [[UIImageView alloc] initWithFrame:cell.frame];
    imageView.image = snapshotImage;

    return imageView;
}
@end
