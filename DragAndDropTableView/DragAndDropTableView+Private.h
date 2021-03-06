#import "DragAndDropTableView.h"

const static CGFloat kAutoScrollingThreshold = 60;

@interface DragAndDropTableView (Private)

- (void) setup;
- (void)maybeAutoscrollForSnapshot:(UIImageView *)snapshot;
- (CGFloat)autoscrollDistanceForProximityToEdge:(CGFloat)proximity;
- (void)legalizeAutoscrollDistance;
- (void)autoscrollTimerFired:(NSTimer*)timer;
- (void) beginDraggingWithGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer;
- (void) continueDraggingWithGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer;
- (void) endDraggingWithGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer;
@end
