#import "DragAndDropTableView.h"

const static CGFloat kAutoScrollingThreshold = 60;

@interface DragAndDropTableView (Private)

- (void)maybeAutoscrollForSnapshot:(UIImageView *)snapshot;
- (CGFloat)autoscrollDistanceForProximityToEdge:(CGFloat)proximity;
- (void)legalizeAutoscrollDistance;
- (void)autoscrollTimerFired:(NSTimer*)timer;
- (void) beginDraggingWithGestureRecognizer:(UIGestureRecognizer *)gestuerRecognizer;
- (void) continueDraggingWithGestureRecognizer:(UIGestureRecognizer *)gestuerRecognizer;
- (void) endDraggingWithGestureRecognizer:(UIGestureRecognizer *)gestuerRecognizer;
@end
