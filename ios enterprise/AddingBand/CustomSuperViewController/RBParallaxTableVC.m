//
//  RBParallaxTableVC.m
//  RBParallaxTableViewController
//
//  Created by @RheeseyB on 01/02/2012.
//  Copyright (c) 2012 Rheese Burgess. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of
//  this software and associated documentation files (the "Software"), to deal in
//  the Software without restriction, including without limitation the rights to
//  use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
//  of the Software, and to permit persons to whom the Software is furnished to do
//  so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

#import "RBParallaxTableVC.h"
#import "SRRefreshView.h"

#define HEAD_TITILE_LEFT 5
#define HEAD_TITILE_TOP 110
#define HEAD_TITILE_WIDTH 50
#define HEAD_TITILE_HEIGHT 30
@implementation RBParallaxTableVC

static CGFloat WindowHeight = 200.0;
static CGFloat ImageHeight  = 300.0;

- (id)initWithImage:(UIImage *)image {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {        
        _imageScroller  = [[UIScrollView alloc] initWithFrame:CGRectZero];
        NSLog(@"底下的scrollview的大小是%@",NSStringFromCGRect(_imageScroller.frame));
        _imageScroller.backgroundColor                  = [UIColor whiteColor];
        _imageScroller.showsHorizontalScrollIndicator   = NO;
        _imageScroller.showsVerticalScrollIndicator     = NO;
        
        _imageView = [[UIImageView alloc] initWithImage:image];
        [_imageScroller addSubview:_imageView];
        
        _tableView = [[UITableView alloc] init];
        _tableView.backgroundColor              = [UIColor clearColor];
        _tableView.dataSource                   = self;
        _tableView.delegate                     = self;
       // _tableView.separatorStyle               = UITableViewCellSeparatorStyleNone;//分割线
        _tableView.showsVerticalScrollIndicator = NO;
        [self.view addSubview:_imageScroller];
        [self.view addSubview:_tableView];
        
//        //创建自定义分区头
//        self.headTitle = [[UILabel alloc]initWithFrame:CGRectMake(HEAD_TITILE_LEFT, HEAD_TITILE_TOP, HEAD_TITILE_WIDTH, HEAD_TITILE_HEIGHT)];
//        _headTitle.backgroundColor = [UIColor redColor];
//        [self.tableView addSubview:_headTitle];

    }
    return self;
}

#pragma mark - Parallax effect

- (void)updateOffsets {
    CGFloat yOffset   = _tableView.contentOffset.y;
    CGFloat threshold = ImageHeight - WindowHeight;
    
    if (yOffset > -threshold && yOffset < 0) {
        _imageScroller.contentOffset = CGPointMake(0.0, floorf(yOffset / 2.0));
    } else if (yOffset < 0) {
        _imageScroller.contentOffset = CGPointMake(0.0, yOffset + floorf(threshold / 2.0));
    } else {
        _imageScroller.contentOffset = CGPointMake(0.0, yOffset);
    }
}

#pragma mark - View Layout
- (void)layoutImage {
    CGFloat imageWidth   = _imageScroller.frame.size.width;
    CGFloat imageYOffset = floorf((WindowHeight  - ImageHeight) / 2.0);
    CGFloat imageXOffset = 0.0;
    
    _imageView.frame             = CGRectMake(imageXOffset, imageYOffset, imageWidth, ImageHeight);
    _imageScroller.contentSize   = CGSizeMake(imageWidth, self.view.bounds.size.height);
    _imageScroller.contentOffset = CGPointMake(0.0, 0.0);
}

#pragma mark - View lifecycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    CGRect bounds = self.view.bounds;
    
    _imageScroller.frame        = CGRectMake(0.0, 0.0, bounds.size.width, bounds.size.height);
    _tableView.backgroundView   = nil;
 //   _tableView.frame            = bounds;
      _tableView.frame            = CGRectMake(0, 0, bounds.size.width, bounds.size.height);
    
    //以下 添加小圆圈刷新
    /*SRRefreshView是背后 背景图*/
    _slimeView = [[SRRefreshView alloc] init];
    // _slimeView.backgroundColor = [UIColor redColor];
    _slimeView.delegate = self;
    _slimeView.upInset = 44;
    _slimeView.slimeMissWhenGoingBack = YES;
    _slimeView.slime.bodyColor = [UIColor grayColor];//圆圈水滴填充颜色
    _slimeView.slime.skinColor = [UIColor whiteColor];//外边勾勒颜色
    _slimeView.slime.lineWith = 3;//外边勾勒宽度
    //  _slimeView.slime.shadowBlur = 4;//阴影宽度
    //  _slimeView.slime.shadowColor = [UIColor blackColor];
    [_tableView addSubview:_slimeView];

    [self layoutImage];
    [self updateOffsets];
}

#pragma mark - Table View Datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) { return 1;  }
    else              { return 26; }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) { return WindowHeight; }
    else                        { return 10.0;         }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellReuseIdentifier   = @"RBParallaxTableViewCell";
    static NSString *windowReuseIdentifier = @"RBParallaxTableViewWindow";
    
    UITableViewCell *cell = nil;
    
    if (indexPath.section == 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:windowReuseIdentifier];
        if (!cell) {
            
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:windowReuseIdentifier];
            cell.backgroundColor             = [UIColor clearColor];
            cell.contentView.backgroundColor = [UIColor clearColor];
            cell.selectionStyle              = UITableViewCellSelectionStyleNone;
        }
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:cellReuseIdentifier];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellReuseIdentifier];
            cell.backgroundColor             = [UIColor grayColor];

            //cell.contentView.backgroundColor = [UIColor grayColor];
            cell.alpha = 0.0;//改变透明度
            cell.selectionStyle              = UITableViewCellSelectionStyleNone;

        }
    }
    
    return cell;
}

#pragma mark - Table View Delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self updateOffsets];
    
    [_slimeView scrollViewDidScroll];//小雨滴刷新的代理方法

    //调整title 的位置 保持不动
    self.headTitle.frame = CGRectMake(HEAD_TITILE_LEFT, HEAD_TITILE_TOP + self.tableView.contentOffset.y, HEAD_TITILE_WIDTH, HEAD_TITILE_HEIGHT);

}
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    [_slimeView scrollViewDidEndDraging];//小雨滴刷新的代理方法
}
#pragma mark - slimeRefresh delegate

- (void)slimeRefreshStartRefresh:(SRRefreshView *)refreshView
{
    
    NSLog(@"拉断了");
    //更新数据在这个方法里面写
    //更新完了之后 调用endRefresh方法停止菊花转动
    [_slimeView performSelector:@selector(endRefresh)
                     withObject:nil afterDelay:2
                        inModes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
}



@end
