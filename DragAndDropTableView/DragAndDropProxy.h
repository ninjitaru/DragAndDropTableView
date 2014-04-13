#import <UIKit/UIKit.h>

@interface DragAndDropProxy : NSObject
{
    NSObject *_proxyObject;
}

@end

@interface DragAndDropProxyDataSource : DragAndDropProxy<UITableViewDataSource>

@property (nonatomic) NSObject<UITableViewDataSource> *dataSource;
@property (nonatomic) NSIndexPath *movingIndexPath;

-(id)initWithDataSource:(id<UITableViewDataSource>)datasource;

@end

@interface DragAndDropProxyDelegate : DragAndDropProxy<UITableViewDelegate>
{
    NSObject<UITableViewDelegate> *_delegate;
}


-(id)initWithDelegate:(id<UITableViewDelegate>)delegate;

@end

