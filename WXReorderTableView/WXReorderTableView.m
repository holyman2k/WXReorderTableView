//
//  WXReorderTableView.m
//  WXReorderTableViewExample
//
//  Created by Charlie Wu on 8/08/2014.
//  Copyright (c) 2014 Charlie Wu. All rights reserved.
//

#import "WXReorderTableView.h"

@interface WXReorderTableView()

@property (nonatomic, strong) UIView *snapshot;
@property (nonatomic, strong) NSIndexPath *indexPathOfReorderingCell;
@property (nonatomic, strong) UILongPressGestureRecognizer *longPressGestureRecognizer;

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
//            self.snapshot = [cell snapshotViewAfterScreenUpdates:NO];
//            [self.snapshot setTransform:CGAffineTransformMakeScale(1.00, 1.00)];

            self.snapshot = [self snapshotViewForCell:cell];
            CGRect frame = self.snapshot.frame;
            frame.origin.y = point.y - frame.size.height / 2;
            self.snapshot.frame = frame;
            [self addSubview:self.snapshot];
            [self reloadRowsAtIndexPaths:@[self.indexPathOfReorderingCell] withRowAnimation:NO];

            break;
        }
        case UIGestureRecognizerStateChanged: { // when cell is dragging

            CGPoint point = [gesture locationInView:self];
            // move sorted cell
            CGRect frame = self.snapshot.frame;
            frame.origin.y = point.y - frame.size.height / 2;
            self.snapshot.frame = frame;

            NSIndexPath *fromIndexPath = self.indexPathOfReorderingCell;
            NSIndexPath *toIndexPath = [self indexPathForRowAtPoint:point];
            if (!toIndexPath) toIndexPath = [self indexPathOfLastRowInSection:0];

            // check if table view requires to swap cell
            if (toIndexPath.row != fromIndexPath.row) {
                [self.delegate swapObjectAtIndexPath:fromIndexPath toIndexPath:toIndexPath];
                self.indexPathOfReorderingCell = toIndexPath;
                UITableViewRowAnimation animation = fromIndexPath.row < toIndexPath.row ? UITableViewRowAnimationTop : UITableViewRowAnimationBottom;
                [self reloadRowsAtIndexPaths:@[fromIndexPath] withRowAnimation:animation];
                [self reloadRowsAtIndexPaths:@[toIndexPath] withRowAnimation:UITableViewRowAnimationNone];
            }
            break;
        }
        case UIGestureRecognizerStateEnded: {

            NSTimeInterval animationDuration = .2;

            CGPoint point = [gesture locationInView:self];
            NSIndexPath *indexPath = [self indexPathForRowAtPoint:point];
            if (!indexPath) indexPath = [self indexPathOfLastRowInSection:0];

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
    NSInteger lastRow = [self.dataSource tableView:self numberOfRowsInSection:section] - 1;
    return [NSIndexPath indexPathForRow:lastRow inSection:0];
    
}

- (UIImageView *)snapshotViewForCell:(UITableViewCell *)cell
{
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
