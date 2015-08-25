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
@property (nonatomic, strong) CADisplayLink *scrollDisplayLink;
@property (nonatomic) CGFloat scrollRate;

@end

#define DefaultScrollRate 1
#define MaxScrollRate 8
#define ScrollRateIncreaseRate .07


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

            self.scrollRate = DefaultScrollRate;
            self.scrollDisplayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(autoScrollTableView:)];
            [self.scrollDisplayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];

            break;
        }
        case UIGestureRecognizerStateChanged: { // when cell is dragging

            // move sorted cell

            [UIView animateWithDuration:0 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                [self updateSnapshotLocation];
            } completion:nil];

            [self updateTableCell:YES];
            break;
        }
        case UIGestureRecognizerStateEnded: {
            NSLog(@"ended");

            [self.scrollDisplayLink invalidate];
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

- (void)updateTableCell:(BOOL)animated;
{
    CGPoint point = [self.longPressGestureRecognizer locationInView:self];
    NSIndexPath *fromIndexPath = self.indexPathOfReorderingCell;
    NSIndexPath *toIndexPath = [self indexPathForRowAtPoint:point];

    // check if table view requires to swap cell
    if (toIndexPath.row != fromIndexPath.row
        && labs(toIndexPath.row - fromIndexPath.row) == 1) {

        [self.reorderDelegate swapObjectAtIndexPath:fromIndexPath toIndexPath:toIndexPath];
        self.indexPathOfReorderingCell = toIndexPath;
//        UITableViewRowAnimation animation = fromIndexPath.row < toIndexPath.row ? UITableViewRowAnimationTop : UITableViewRowAnimationBottom;
        UITableViewRowAnimation animation = animated ? UITableViewRowAnimationFade : UITableViewRowAnimationNone;
        [self reloadRowsAtIndexPaths:@[fromIndexPath] withRowAnimation:animation];
        [self reloadRowsAtIndexPaths:@[toIndexPath] withRowAnimation:UITableViewRowAnimationNone];
    }
}

- (void)updateSnapshotLocation
{
    CGPoint point = [self.longPressGestureRecognizer locationInView:self];
    CGRect frame = self.snapshot.frame;
    frame.origin.y = point.y - frame.size.height / 2;
    self.snapshot.frame = frame;
}

- (void)autoScrollTableView:(NSTimer *)timer
{
    CGPoint point = [self.longPressGestureRecognizer locationInView:self];
    NSIndexPath *indexPath = [self indexPathForRowAtPoint:point];
    UITableViewCell *cell = [self cellForRowAtIndexPath:indexPath];
    if (!cell) return;

    NSInteger upperBound = point.y - cell.frame.size.height / 2 - self.contentOffset.y;
    NSInteger lowerBound = point.y + cell.frame.size.height / 2 - self.contentOffset.y;
    NSInteger totalRow = [self.dataSource tableView:self numberOfRowsInSection:0];

    CGRect visibleRect = CGRectIntersection(self.frame, self.superview.frame);

    CGFloat scrollSize = self.scrollRate; //cell.frame.size.height;

    if (upperBound < 0 && indexPath.row > 0) {
        // auto scroll up

        [UIView animateWithDuration:.6 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            CGPoint offset = self.contentOffset;
            offset.y -= scrollSize;
            [self setContentOffset:offset animated:NO];
            [self updateSnapshotLocation];
            [self updateTableCell:NO];
            self.scrollRate += self.scrollRate < MaxScrollRate ? ScrollRateIncreaseRate : 0;
        } completion:^(BOOL finished) {

        }];

    } else if (lowerBound > visibleRect.size.height && indexPath.row < totalRow) {
        // auto scroll down

        [UIView animateWithDuration:.6 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            CGPoint offset = self.contentOffset;
            offset.y += scrollSize;
            [self setContentOffset:offset animated:NO];
            [self updateTableCell:NO];
            [self updateSnapshotLocation];
            self.scrollRate += self.scrollRate < MaxScrollRate ? ScrollRateIncreaseRate : 0;
        } completion:^(BOOL finished) {

        }];
    } else {
        self.scrollRate = DefaultScrollRate;
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
