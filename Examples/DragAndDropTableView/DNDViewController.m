//
//  DNDViewController.m
//  DragAndDropTableView
//
//  Created by Erik Johansson on 4/1/13.
//  Copyright (c) 2013 Erik Johansson. All rights reserved.
//

#import "DNDViewController.h"
#import <QuartzCore/QuartzCore.h>

static NSString *const tableViewCellName = @"TableViewCell";

@interface DNDViewController ()

@end

@implementation DNDViewController

-(id)init
{
    if(self = [super init])
    {
        _datasource = [NSMutableArray arrayWithObject: [NSMutableArray array]];
        NSMutableArray *section1Data = [_datasource objectAtIndex: 0];
        for(NSInteger i = 0; i < 100; i++) {
            [section1Data addObject: [NSString stringWithFormat:@"Book %li",i+1]];
        }
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
	_tableView = [[PanableDragAndDropTableView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:_tableView];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier: tableViewCellName];
//    if([self respondsToSelector: @selector(topLayoutGuide)]) {
//        _tableView.contentInset = UIEdgeInsetsMake(self.topLayoutGuide.length, 0, 0, 0);
//    }
}

- (void) viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    if([self respondsToSelector: @selector(topLayoutGuide)]) {
    _tableView.frame = (CGRect) {0,self.topLayoutGuide.length,CGRectGetWidth(self.view.bounds),CGRectGetHeight(self.view.bounds)-self.topLayoutGuide.length};
    } else {
        _tableView.frame = self.view.bounds;
    }
}

#pragma mark -

#pragma mark UITableViewDataSource

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _datasource.count;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[_datasource objectAtIndex:section] count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:tableViewCellName forIndexPath: indexPath];
    cell.textLabel.text = [[_datasource objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    return cell;
}

-(BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

-(void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    NSObject *o = [[_datasource objectAtIndex:sourceIndexPath.section] objectAtIndex:sourceIndexPath.row];
    [[_datasource objectAtIndex:sourceIndexPath.section] removeObjectAtIndex:sourceIndexPath.row];
    [[_datasource objectAtIndex:destinationIndexPath.section] insertObject:o atIndex:destinationIndexPath.row];
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(UITableViewCellEditingStyleInsert == editingStyle)
    {
        // inserts are always done at the end
        
        [tableView beginUpdates];
        [_datasource addObject:[NSMutableArray array]];
        [tableView insertSections:[NSIndexSet indexSetWithIndex:[_datasource count]-1] withRowAnimation:UITableViewRowAnimationAutomatic];
        [tableView endUpdates];
        
    }
    else if(UITableViewCellEditingStyleDelete == editingStyle)
    {
        // check if we are going to delete a row or a section
        [tableView beginUpdates];
        if([[_datasource objectAtIndex:indexPath.section] count] == 0)
        {
            [tableView deleteSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationAutomatic];
            [_datasource removeObjectAtIndex:indexPath.section];
        }
        else
        {
            // Delete the row from the table view.
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            // Delete the row from the data source.
            [[_datasource objectAtIndex:indexPath.section] removeObjectAtIndex:indexPath.row];
        }
        [tableView endUpdates];
    }
}

#pragma mark -

#pragma mark UITableViewDelegate

-(UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 37;
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 10;
}

#pragma mark -

#pragma mark DragAndDropTableViewDataSource

-(BOOL)canCreateNewSection:(NSInteger)section
{
    return YES;
}

#pragma mark -

#pragma mark DragAndDropTableViewDelegate

-(void)tableView:(UITableView *)tableView willBeginDraggingCellAtIndexPath:(NSIndexPath *)indexPath placeholderImageView:(UIImageView *)placeHolderImageView
{
    // this is the place to edit the snapshot of the moving cell
    // add a shadow 
    placeHolderImageView.layer.shadowOpacity = .3;
    placeHolderImageView.layer.shadowRadius = 1;
    

}

-(void)tableView:(DragAndDropTableView *)tableView didEndDraggingCellToIndexPath:(NSIndexPath *)indexPath placeHolderView:(UIImageView *)placeholderImageView
{
    // The cell has been dropped. Remove all empty sections (if you want to)
    NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
    for(int i = 0; i < _datasource.count; i++)
    {
        NSArray *ary = [_datasource objectAtIndex:i];
        if(ary.count == 0)
            [indexSet addIndex:i];
    }
    
    [tableView beginUpdates];
    [tableView deleteSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
    [_datasource removeObjectsAtIndexes:indexSet];
    [tableView endUpdates];
}

-(CGFloat)tableView:tableView heightForEmptySection:(NSInteger)section
{
    return 10;
}

#pragma mark -


@end
