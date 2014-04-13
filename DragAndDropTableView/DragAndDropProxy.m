#import "DragAndDropProxy.h"
#import "DragAndDropTableView.h"

@implementation DragAndDropProxyDataSource
@synthesize movingIndexPath = _movingIndexPath;
@synthesize dataSource = _dataSource;

-(id)initWithDataSource:(id<UITableViewDataSource>)datasource
{
    if(self = [super init])
    {
        _dataSource = datasource;
        _proxyObject = datasource;
    }
    return self;
}

#pragma mark UITableViewDataSource

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // if there are no cells in section we must fake one so that is will be possible to insert a row
    NSInteger rows = [_dataSource tableView:tableView numberOfRowsInSection:section];
    return rows == 0 ? 1 : rows;
}

-(void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    NSInteger rows = [_dataSource tableView:tableView numberOfRowsInSection:destinationIndexPath.section];
    if(rows == 0)
    {
        // it's a fake cell, remove it
        [tableView beginUpdates];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:destinationIndexPath] withRowAnimation:UITableViewRowAnimationNone];
        [tableView endUpdates];
    }
    
    [_dataSource tableView:tableView moveRowAtIndexPath:sourceIndexPath toIndexPath:destinationIndexPath];
    
    // if the source section is empty after the update, a fake row must be inserted
    rows = [_dataSource tableView:tableView numberOfRowsInSection:sourceIndexPath.section];
    if(rows == 0)
    {
        [tableView beginUpdates];
        [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:sourceIndexPath] withRowAnimation:UITableViewRowAnimationNone];
        [tableView endUpdates];
    }
    
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL updated = NO;
    if(UITableViewCellEditingStyleDelete == editingStyle)
    {
        // if there source section will be empty after the update, a fake row must be inserted
        NSInteger rows = [_dataSource tableView:tableView numberOfRowsInSection:indexPath.section];
        if(rows == 1)
        {
            [tableView beginUpdates];
            [_dataSource tableView:tableView commitEditingStyle:editingStyle forRowAtIndexPath:indexPath];
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
            [tableView endUpdates];
            updated = YES;
        }
    }
    
    if(!updated)
        [_dataSource tableView:tableView commitEditingStyle:editingStyle forRowAtIndexPath:indexPath];
    
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger rows = [_dataSource tableView:tableView numberOfRowsInSection:indexPath.section];
    
    if(![indexPath isEqual:_movingIndexPath] && rows != 0)
    {
        return [_dataSource performSelector:@selector(tableView:cellForRowAtIndexPath:) withObject:tableView withObject:indexPath];
    }
    
    static NSString *CellIdentifier = @"EmptyCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if(!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.backgroundColor = [UIColor clearColor];
    }
    return cell;
}

#pragma mark -

@end

@implementation DragAndDropProxyDelegate

-(id)initWithDelegate:(id<UITableViewDelegate>)delegate
{
    if(self = [super init])
    {
        _delegate = delegate;
        _proxyObject = delegate;
    }
    return self;
}

#pragma mark UITableViewDelegate

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger count = [((DragAndDropProxyDataSource *)tableView.dataSource).dataSource tableView:tableView numberOfRowsInSection:indexPath.section];
    
    CGFloat height = 0;
    if(count > 0)
        height = [_delegate tableView:tableView heightForRowAtIndexPath:indexPath];
    else if([_delegate respondsToSelector:@selector(tableView:heightForEmptySection:)])
        height = [((NSObject<DragAndDropTableViewDelegate> *)_delegate) tableView:(DragAndDropTableView *)tableView heightForEmptySection:indexPath.section];
    else
        height = 0;
    
    return height;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger rows = [((DragAndDropProxyDataSource *)tableView.dataSource).dataSource tableView:tableView numberOfRowsInSection:indexPath.section];
    
    // you can't edit/delete the place holder cells
    if(rows == 0)
        return UITableViewCellEditingStyleNone;
    else if([_delegate respondsToSelector:@selector(tableView:editingStyleForRowAtIndexPath:)])
        return [_delegate tableView:tableView editingStyleForRowAtIndexPath:indexPath];
    else
    {
        // if the cell is in editing mode it should return UITableViewCellEditingStyleDelete (according to the docs) otherwise no style
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        return cell.editing ? UITableViewCellEditingStyleDelete : UITableViewCellEditingStyleNone;
    }
    
}

#pragma mark -

@end

@implementation DragAndDropProxy

-(void)forwardInvocation:(NSInvocation *)invocation {
	if (!_proxyObject) {
		[self doesNotRecognizeSelector: [invocation selector]];
	}
	[invocation invokeWithTarget:_proxyObject];
}

-(NSMethodSignature*)methodSignatureForSelector:(SEL)selector {
	NSMethodSignature *signature = [super methodSignatureForSelector:selector];
	if (! signature) {
		signature = [_proxyObject methodSignatureForSelector:selector];
	}
	return signature;
}

-(BOOL)respondsToSelector:(SEL)aSelector
{
    return [super respondsToSelector:aSelector] || (_proxyObject && [_proxyObject respondsToSelector:aSelector]);
}

#pragma mark -
@end