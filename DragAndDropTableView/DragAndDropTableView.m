//
//  DragAndDropTableView.m
//  DragAndDropTableView
//
//  Created by Erik Johansson on 4/1/13.
//  Copyright (c) 2013 Erik Johansson. All rights reserved.
//

#import "DragAndDropTableView.h"
#import <QuartzCore/QuartzCore.h>
#import "DragAndDropProxy.h"
#import "UIView+Snapshot.h"

const static CGFloat kAutoScrollingThreshold = 60;

@implementation DragAndDropTableView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self setup];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Initialization code
        [self setup];
    }
    return self;
}

-(void)setup
{
    // register gesture recognizer
    _dndLongPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onLongPressGestureRecognizerTap:)];
    [self addGestureRecognizer:_dndLongPressGestureRecognizer];
    
}

#pragma mark Actions

-(void)onLongPressGestureRecognizerTap:(UILongPressGestureRecognizer *)gestureRecognizer
{
    if(UIGestureRecognizerStateBegan ==  gestureRecognizer.state)
    {
        _latestTouchPoint = [gestureRecognizer locationInView:self];
        
        // get index path of position
        _movingIndexPath = _originIndexPath = [self indexPathForRowAtPoint:_latestTouchPoint];

        BOOL validMove = YES;
        // Check if we are allowed to move it
        if (![self.delegate respondsToSelector:@selector(tableView:canMoveRowAtIndexPath:)])
            validMove = NO;
        
        if (validMove && ![self.dataSource tableView:self canMoveRowAtIndexPath:_movingIndexPath])
            validMove = NO;
        
        // Check for a valid index path, otherwise cancel the touch
        if (validMove && (!_originIndexPath || [_originIndexPath section] == NSNotFound || [_originIndexPath row] == NSNotFound))
            validMove = NO;
        
        if(!validMove)
        {
            gestureRecognizer.enabled = !(gestureRecognizer.enabled = NO);
            return;
        }
        
        // Get the touched cell and reset it's selection state
        UITableViewCell *cell = [self cellForRowAtIndexPath:_movingIndexPath];
        
        // Compute the touch offset from the cell's center
        _touchOffset = CGPointMake([cell center].x - _latestTouchPoint.x, [cell center].y - _latestTouchPoint.y);
        
        // let the fake datasource know which indexpath is moving
        _proxyDataSource.movingIndexPath = _movingIndexPath;
        
        // create a snapshot of the cell we are about to move
        _cellSnapShotImageView = [[UIImageView alloc] initWithImage:[cell snapshotImage]];
        _cellSnapShotImageView.alpha = .6;
        [self addSubview:_cellSnapShotImageView];
        _cellSnapShotImageView.center = CGPointMake(_cellSnapShotImageView.center.x, _latestTouchPoint.y + _touchOffset.y);

        if([self.delegate respondsToSelector:@selector(tableView:willBeginDraggingCellAtIndexPath:placeholderImageView:)])
            [((NSObject<DragAndDropTableViewDelegate> *)self.delegate) tableView:self willBeginDraggingCellAtIndexPath:_movingIndexPath placeholderImageView:_cellSnapShotImageView];
        
        [self reloadRowsAtIndexPaths:[NSArray arrayWithObject:_movingIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        
    }
    else if(UIGestureRecognizerStateChanged == gestureRecognizer.state)
    {
        _latestTouchPoint = [gestureRecognizer locationInView:self];

        // check if we've moved close enough to an edge to autoscroll, or far enough away to stop autoscrolling
        [self maybeAutoscrollForSnapshot:_cellSnapShotImageView];
        
        // Update the snap shot's position
        _cellSnapShotImageView.center = CGPointMake(_cellSnapShotImageView.center.x, _latestTouchPoint.y + _touchOffset.y);
        
        NSIndexPath *newIndexPath = [self indexPathForRowAtPoint:_latestTouchPoint];
        if(newIndexPath)
        {
            _lastIndexPathValid = YES;
            if(![newIndexPath isEqual:_movingIndexPath])
            {
                // ask the delegate to show a new location for the move
                if([self.delegate respondsToSelector:@selector(tableView:targetIndexPathForMoveFromRowAtIndexPath:toProposedIndexPath:)])
                    newIndexPath = [self.delegate tableView:self targetIndexPathForMoveFromRowAtIndexPath:_movingIndexPath toProposedIndexPath:newIndexPath];
                
                
                [self beginUpdates];
                [self moveRowAtIndexPath:_movingIndexPath toIndexPath:newIndexPath];
                // inform datasource
                if ([self.dataSource respondsToSelector:@selector(tableView:moveRowAtIndexPath:toIndexPath:)])
                    [self.dataSource tableView:self moveRowAtIndexPath:_movingIndexPath toIndexPath:newIndexPath];
                [self endUpdates];
                
                [self bringSubviewToFront:_cellSnapShotImageView];
                
                _movingIndexPath = newIndexPath;
            }
            
            // remove the temp section if it exists and we are not proposing a move to it
            
            if(_tempNewSectionIndexPath && newIndexPath.section != _tempNewSectionIndexPath.section)
            {

                [self.dataSource tableView:self commitEditingStyle:UITableViewCellEditingStyleDelete forRowAtIndexPath:_tempNewSectionIndexPath];
                _tempNewSectionIndexPath = nil;
            }
                
        }
        else if(_lastIndexPathValid && !_tempNewSectionIndexPath)
        {
            // check if we are above or below the "valid" table and propose a new section if supported by the delegate
            NSInteger maxSection = [self.dataSource numberOfSectionsInTableView:self];
            NSIndexPath *proposedIndexPath = nil;
            if(_latestTouchPoint.y > [self rectForFooterInSection:maxSection-1].origin.y) //CGRectGetMaxY([self rectForFooterInSection:maxSection-1]))
            {
                proposedIndexPath = [NSIndexPath indexPathForRow:0 inSection:maxSection];
            }
            else if (_latestTouchPoint.y < self.frame.origin.y)
            {
                proposedIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
            }
            
            if(proposedIndexPath)
            {
                _lastIndexPathValid = NO;
                
                // check if we are allowed to create a new section
                // creating new sections "above" the table is not supported (yet).
                if(proposedIndexPath.section > 0 &&
                   [self.dataSource respondsToSelector:@selector(canCreateNewSection:)] &&
                   [self.dataSource performSelector:@selector(canCreateNewSection:) withObject:[NSNumber numberWithInteger:proposedIndexPath.section]])
                {
                    [self.dataSource tableView:self commitEditingStyle:UITableViewCellEditingStyleInsert forRowAtIndexPath:proposedIndexPath];

                    _tempNewSectionIndexPath = proposedIndexPath;
                    _lastIndexPathValid = YES;
                    
                    [self scrollToRowAtIndexPath:proposedIndexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
                    
                    [self bringSubviewToFront:_cellSnapShotImageView];
                }
            }
        }
        
    }
    else if(UIGestureRecognizerStateEnded == gestureRecognizer.state)
    {
        if(_autoscrollTimer)
        {
            [_autoscrollTimer invalidate]; _autoscrollTimer = nil;
        }

        // since anything can happen with the table structure in the following delegate call we use the cell as reference rather than the indexpath to it
        UITableViewCell *cell = [self cellForRowAtIndexPath:_movingIndexPath];

        if([self.delegate respondsToSelector:@selector(tableView:didEndDraggingCellToIndexPath:placeHolderView:)])
            [((NSObject<DragAndDropTableViewDelegate> *)self.delegate) tableView:self didEndDraggingCellToIndexPath:_movingIndexPath placeHolderView:_cellSnapShotImageView];
        
        // remove image
        [UIView animateWithDuration:.3 animations:^{
            NSIndexPath *ipx = [self indexPathForCell:cell];
            if(ipx)
                _cellSnapShotImageView.frame = [self rectForRowAtIndexPath:ipx];
        } completion:^(BOOL finished) {
            [_cellSnapShotImageView removeFromSuperview]; _cellSnapShotImageView = nil;
            [self reloadData];
        }];
         
        _proxyDataSource.movingIndexPath = nil;
        _tempNewSectionIndexPath = nil;
    }
}

#pragma mark -

#pragma mark Overrides

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_proxyDataSource tableView:tableView numberOfRowsInSection:section];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [_proxyDataSource tableView:tableView cellForRowAtIndexPath:indexPath];
}

-(void)setDataSource:(id<UITableViewDataSource>)dataSource
{
    _proxyDataSource = dataSource ? [[DragAndDropProxyDataSource alloc] initWithDataSource:dataSource] : nil;
    
    [super setDataSource:_proxyDataSource];
}

-(void)setDelegate:(id<UITableViewDelegate>)delegate
{
    _proxyDelegate = delegate ? [[DragAndDropProxyDelegate alloc] initWithDelegate:delegate] : nil;
        
    [super setDelegate:_proxyDelegate];
} 

#pragma mark -

#pragma mark Autoscrolling methods

- (void)maybeAutoscrollForSnapshot:(UIImageView *)snapshot
{

    _autoscrollDistance = 0;
    
    if (CGRectGetMaxY(snapshot.frame) < self.contentSize.height )
    {
        // only autoscroll if the content is larger than the view
        if (self.contentSize.height > self.frame.size.height)
        {
            // only autoscroll if the thumb is overlapping the thumbScrollView
            if (CGRectIntersectsRect([snapshot frame], [self bounds]))
            {
                float distanceFromTop = _latestTouchPoint.y - CGRectGetMinY(self.bounds);
                float distanceFromBottom = CGRectGetMaxY(self.bounds) - _latestTouchPoint.y;
                
                if (distanceFromTop < kAutoScrollingThreshold) {
                    _autoscrollDistance = [self autoscrollDistanceForProximityToEdge:distanceFromTop] * -1; // if scrolling up, distance is negative
                } else if (distanceFromBottom < kAutoScrollingThreshold) {
                    _autoscrollDistance = [self autoscrollDistanceForProximityToEdge:distanceFromBottom];
                }
            }
        }
    }
        
    // if no autoscrolling, stop and clear timer
    if (_autoscrollDistance == 0) {
        [_autoscrollTimer invalidate];
        _autoscrollTimer = nil;
    }
    // otherwise create and start timer (if we don't already have a timer going)
    else if (_autoscrollTimer == nil) {
        _autoscrollTimer = [NSTimer scheduledTimerWithTimeInterval:(1.0 / 60.0)
                                                           target:self
                                                         selector:@selector(autoscrollTimerFired:)
                                                         userInfo:snapshot
                                                          repeats:YES];
    }
}

- (float)autoscrollDistanceForProximityToEdge:(float)proximity {
    // the scroll distance grows as the proximity to the edge decreases, so that moving the thumb
    // further over results in faster scrolling.
    return ceilf((kAutoScrollingThreshold - proximity) / 5.0);
}

- (void)legalizeAutoscrollDistance {
    // makes sure the autoscroll distance won't result in scrolling past the content of the scroll view
    float minimumLegalDistance = [self contentOffset].y * -1;
    float maximumLegalDistance = [self contentSize].height - ([self frame].size.height + [self contentOffset].y);
    _autoscrollDistance = MAX(_autoscrollDistance, minimumLegalDistance);
    _autoscrollDistance = MIN(_autoscrollDistance, maximumLegalDistance);
}

- (void)autoscrollTimerFired:(NSTimer*)timer {
//    NSLog(@"autoscrolling: %.2f",_autoscrollDistance);
    [self legalizeAutoscrollDistance];
    // autoscroll by changing content offset
    CGPoint contentOffset = [self contentOffset];
    contentOffset.y += _autoscrollDistance;
    [self setContentOffset:contentOffset];
    
    // adjust thumb position so it appears to stay still
    UIImageView *snapshot = (UIImageView *)[timer userInfo];
    snapshot.center = CGPointMake(snapshot.center.x, snapshot.center.y + _autoscrollDistance);
//    [snapshot moveByOffset:CGPointMake(_autoscrollDistance, 0)];
}

#pragma mark -

@end
