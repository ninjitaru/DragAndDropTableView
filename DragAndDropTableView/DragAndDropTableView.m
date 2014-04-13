//
//  DragAndDropTableView.m
//  DragAndDropTableView
//
//  Created by Erik Johansson on 4/1/13.
//  Copyright (c) 2013 Erik Johansson. All rights reserved.
//

#import "DragAndDropTableView.h"
#import "DragAndDropProxy.h"
#import "DragAndDropTableView+Private.h"

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

#pragma mark Actions

-(void)onLongPressGestureRecognizerTap:(UILongPressGestureRecognizer *)gestureRecognizer
{
    if(UIGestureRecognizerStateBegan ==  gestureRecognizer.state)
    {
        [self beginDraggingWithGestureRecognizer: gestureRecognizer];
    }
    else if(UIGestureRecognizerStateChanged == gestureRecognizer.state)
    {
        [self continueDraggingWithGestureRecognizer: gestureRecognizer];
    }
    else if(UIGestureRecognizerStateEnded == gestureRecognizer.state)
    {
        [self endDraggingWithGestureRecognizer: gestureRecognizer];
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

@end
