//
//  PanDragAndDropTableView.m
//  
//
//  Created by Jason Chang on 4/13/14.
//
//

#import "PanableDragAndDropTableView.h"
#import "DragAndDropTableView+Private.h"

@interface PanableDragAndDropTableView () <UIGestureRecognizerDelegate>
@property (nonatomic,assign) BOOL panActivatedDragging;
@property (nonatomic,assign) BOOL giveupRecognized;
@property (nonatomic,strong) UIPanGestureRecognizer *panRightGestureRecognizer;
@end

@implementation PanableDragAndDropTableView

-(void) setup
{
    [super setup];
    // register pan gesture recognizer
    self.enablePanRightToDragAndDrop = YES;
    self.minimumPanWidthToRecognize = 60;
    self.maximumPanHeightToFailRecognize = 10;
    [self addGestureRecognizer: self.panRightGestureRecognizer];
}

- (void) setEnablePanRightToDragAndDrop:(BOOL)enablePanRightToDragAndDrop {
    self.panRightGestureRecognizer.enabled = enablePanRightToDragAndDrop;
    if(!self.panRightGestureRecognizer.enabled) {
        self.panGestureRecognizer.enabled = YES;
        self.panActivatedDragging = NO;
        self.giveupRecognized = NO;
    }
}

- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if([gestureRecognizer isKindOfClass: [UIPanGestureRecognizer class]] && [otherGestureRecognizer isKindOfClass: [UIPanGestureRecognizer class]]) {
        if(self.panActivatedDragging) {
            return NO;
        }
        return YES;
    }
    return NO;
}

- (void) onPanGestureRecognizerPan:(UIPanGestureRecognizer *)gestureRecognizer {
    
    if(UIGestureRecognizerStateBegan ==  gestureRecognizer.state) {
    } else if(UIGestureRecognizerStateChanged == gestureRecognizer.state) {
        if(self.giveupRecognized) {
            return;
        }
        if(self.panActivatedDragging) {
            [self continueDraggingWithGestureRecognizer: gestureRecognizer];
        } else {
            CGPoint translation = [gestureRecognizer translationInView: self];
            if(abs(translation.y) > self.maximumPanHeightToFailRecognize) {
                self.giveupRecognized = YES;
            } else {
                if(translation.x > self.minimumPanWidthToRecognize) {
                    self.panActivatedDragging = YES;
                    self.panGestureRecognizer.enabled = NO;
                    [self beginDraggingWithGestureRecognizer: gestureRecognizer];
                }
            }
        }
    } else if(UIGestureRecognizerStateEnded == gestureRecognizer.state) {
        self.giveupRecognized = NO;
        if(self.panActivatedDragging) {
            self.panGestureRecognizer.enabled = YES;
            [self endDraggingWithGestureRecognizer: gestureRecognizer];
            self.panActivatedDragging = NO;
        }
    }
}

- (UIPanGestureRecognizer *) panRightGestureRecognizer {
    if(!_panRightGestureRecognizer) {
        _panRightGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPanGestureRecognizerPan:)];
        _panRightGestureRecognizer.delegate = self;
    }
    return _panRightGestureRecognizer;
}

@end
