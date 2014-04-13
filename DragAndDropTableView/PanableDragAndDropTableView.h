//
//  PanDragAndDropTableView.h
//  
//
//  Created by Jason Chang on 4/13/14.
//
//

#import "DragAndDropTableView.h"

@interface PanableDragAndDropTableView : DragAndDropTableView

@property (nonatomic,assign) BOOL enablePanRightToDragAndDrop;
@property (nonatomic,assign) CGFloat minimumPanWidthToRecognize;
@property (nonatomic,assign) CGFloat maximumPanHeightToFailRecognize;

@end
