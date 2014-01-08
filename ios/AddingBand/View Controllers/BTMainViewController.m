//
//  BTMainViewController.m
//  AddingBand
//
//  Created by wangpeng on 13-12-20.
//  Copyright (c) 2013年 kaka'. All rights reserved.
//

#import "BTMainViewController.h"
#import "LayoutDef.h"
#import "BTMainViewCell.h"
#import "UMSocialSnsService.h"//友盟分享
#import "UMSocial.h"
#import "NSDate+DateHelper.h"
#import "BTUtils.h"
#import "BTAlertView.h"

#import "BTKnowledgeViewController.h"
#import "MKNetworkEngine.h"
#import "MKNetworkOperation.h"
#import "BTKnowledgeModel.h"
#import "BTKnowledgeCell.h"
#import "BTWarnCell.h"
#import "BTGetData.h"
#import "BTUserSetting.h"

#import "BTRowOfSectionModel.h"
#define NAVIGATIONBAR_Y 0
#define NAVIGATIONBAR_HEIGHT 65

static int week = 0;
@interface BTMainViewController ()
@property(nonatomic,strong)UILabel *dateLabel;//3周4天
@property(nonatomic,strong)UILabel *countLabel;//预产期倒计时

@end

@implementation BTMainViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.modelArray = [NSMutableArray arrayWithCapacity:1];
        
    }
    return self;
}
#pragma mark - 视图出现  消失
- (void)viewWillAppear:(BOOL)animated
{
    
    //增加标识，用于判断是否是第一次启动应用,进入此页面
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"everAppear"]) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"firstAppear"];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"everAppear"];
        
    }
    
    
    //如果是第一次进入此页面 pop一个view
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"firstAppear"]) {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"firstAppear"];
        NSLog(@"第一次进来");
        [self popAlertView];
        
        
    }
    
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    [self updatePregnancyTime];
}


- (void)viewWillDisappear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor yellowColor];
    
    [self popAlertView];
    [self getCurrentWeekOfPregnancy];//得到今天是怀孕第几周
    [self addSubviews];
    [self addChageScrollViewToTopButton];
    [self createHeaderView];
    [self getNetworkDataWithWeekOfPregnancy:3];
	// Do any additional setup after loading the view.
}

#pragma mark - 根据预产期 的出今天处于第几周
- (int)getCurrentWeekOfPregnancy
{
    NSArray *data = [BTGetData getFromCoreDataWithPredicate:nil entityName:@"BTUserSetting" sortKey:nil];
    if (data.count > 0) {
        BTUserSetting *userData = [data objectAtIndex:0];
        int day = [self intervalSinceNow:userData.dueDate];
        self.dueDate = [userData.dueDate stringByReplacingOccurrencesOfString:@"." withString:@"-"];//把预产期取出来 存下来 避免反复操作coredata
        //根据怀孕天数 算出是第几周 第几天
        int currentWeek = (280 - day)/7 + 1;
        week = currentWeek;
        return currentWeek;
    }
    return 0;
}

#pragma mark - 更新导航栏上显示的怀孕时间
- (void)updatePregnancyTime
{
    NSArray *data = [BTGetData getFromCoreDataWithPredicate:nil entityName:@"BTUserSetting" sortKey:nil];
    if (data.count > 0) {
        BTUserSetting *userData = [data objectAtIndex:0];
        int day = [self intervalSinceNow:userData.dueDate];
        self.countLabel.text = [NSString stringWithFormat:@"预产期倒计时: %d天",day];
        
        //根据怀孕天数 算出是第几周 第几天
        int week = (280 - day)/7 + 1;
        int day1 = (280 - day)%7;
        self.dateLabel.text = [NSString stringWithFormat:@"%d周%d天",week,day1];
    }
    
}

- (int)intervalSinceNow:(NSString *)theDate
{
    
    NSDate *localdate = [NSDate localdate];
    NSNumber *year = [BTUtils getYear:localdate];
    NSNumber *month = [BTUtils getMonth:localdate];
    NSNumber *day = [BTUtils getDay:localdate];
    
    NSDate *gmtDate = [NSDate dateFromString:[NSString stringWithFormat:@"%@.%@.%@",year,month,day] withFormat:@"yyyy.MM.dd"];
    NSDate *dueDate = [NSDate dateFromString:theDate withFormat:@"yyyy.MM.dd"];
    
    NSLog(@"现在时间 %@  预产期时间 %@",gmtDate,dueDate);
    
    NSTimeInterval now = [gmtDate timeIntervalSince1970];
    NSTimeInterval due = [dueDate timeIntervalSince1970];
    NSTimeInterval cha = due - now;
    
    int day1 = cha/(24 * 60 * 60);
    
    return day1;
}

#pragma mark - 请求网络数据
- (void)getNetworkDataWithWeekOfPregnancy:(int)week
{
    
    //用MKNetworkKit进行异步网络请求
    /*GET请求 示例*/
    MKNetworkEngine *engine = [[MKNetworkEngine alloc] initWithHostName:@"addinghome.com" customHeaderFields:nil];
    MKNetworkOperation *op = [engine operationWithPath:[NSString stringWithFormat:@"/api/schedule?p=2013-12-30&W=%d+%d",week,week + 1] params:nil httpMethod:@"GET" ssl:NO];
    [op addCompletionHandler:^(MKNetworkOperation *operation) {
        NSLog(@"[operation responseData]-->>%@", [operation responseString]);
        
        [self handleDataByGetNetworkSuccessfullyWithJsonData:[operation responseData]];
        
        
        //请求数据错误
    }errorHandler:^(MKNetworkOperation *errorOp, NSError* err) {
        NSLog(@"MKNetwork request error------ : %@", [err localizedDescription]);
        [self handleDataByGetNetworkFailly];
        
    }];
    [engine enqueueOperation:op];
    
    
}
- (void)handleDataByGetNetworkSuccessfullyWithJsonData:(NSData *)data
{
    week = 3;
    NSDictionary *resultDic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
    
    NSDictionary *weekPreviousDic = [resultDic objectForKey:[NSString stringWithFormat:@"w%d",week]];
    NSArray *resultPreviousArray = [weekPreviousDic objectForKey:@"results"];
    BTRowOfSectionModel *model1 = [[BTRowOfSectionModel alloc] initWithSectionTitle:[NSString stringWithFormat:@"%d周",week] row:[resultPreviousArray count]];
    NSLog(@"resultPreviousArray==%@",resultPreviousArray);
    NSDictionary *weekCurrentDic = [resultDic objectForKey:[NSString stringWithFormat:@"w%d",week + 1]];
    NSArray *resultCurrentArray = [weekCurrentDic objectForKey:@"results"];
    
    BTRowOfSectionModel *model2 = [[BTRowOfSectionModel alloc] initWithSectionTitle:[NSString stringWithFormat:@"%d周",week + 1] row:[resultCurrentArray count]];
    
    //骚年 这里是分区数据
    NSMutableArray *section = [NSMutableArray arrayWithObjects:model1,model2, nil];
    
    for (int i = section.count - 1; i >= 0;i--) {
        
        [self.sectionArray insertObject:[section objectAtIndex:i] atIndex:0];//这是分区数据
        
    }
    
    
    //下面是每行数据
    NSMutableArray *resultArray = [NSMutableArray arrayWithArray:resultPreviousArray];
    [resultArray addObjectsFromArray:resultCurrentArray];
    
    NSLog(@"&&&&&&&&&&&&&%@",resultArray);
    
    
    for (int i = resultArray.count - 1;i >= 0;i--)
    {
        NSDictionary * dictionary = [resultArray objectAtIndex:i];
        BTKnowledgeModel * knowledge = [[BTKnowledgeModel alloc] initWithDictionary:dictionary];
        //把一个个的knowledge存入可变数组 modelArray(类初始化的时候应经开辟空间)
        [self.modelArray insertObject:knowledge atIndex:0];//这是行数据
        
        
    }
    [self finishReloadingData];//刷新完成
    [self.tableView reloadData];
    
}


- (void)handleDataByGetNetworkFailly
{
    NSDictionary * dictionary;
    for (int i = 0; i < 2; i ++) {
        if (i == 0) {
            dictionary  = [NSDictionary dictionaryWithObjectsAndKeys:@"3",@"event_id",@"103",@"event_type",@"该吃药了哈哈哈哈哈哈哈哈哈哈哈哈哈哈哈哈哈哈哈哈哈哈哈哈哈",@"title", @"",@"hash",@"丫今儿该吃苹果了",@"description",@"2014-1-2",@"date",@"2014-1-4",@"expire",@"",@"icon",nil];
        }
        if (i == 1) {
            dictionary  = [NSDictionary dictionaryWithObjectsAndKeys:@"2",@"event_id",@"103",@"event_type",@"什么是叶酸什么是叶酸什么是叶酸什么是叶酸什么是叶酸什么是叶酸什么是叶酸什么是叶酸什么是叶酸什么是叶酸什么是叶酸什么是叶酸？",@"title", @"",@"hash",@"叶酸是维生素B9的水溶形式。叶酸的名字来源于拉丁文folium。由米切尔及其同事 首次从菠菜叶中提取纯化出来，命名为叶酸。叶酸作为重要的一碳载体，在核苷酸合成，同型半胱氨酸的再甲基化等诸多重要生理代谢功能方面有重要作用。因此叶酸在快速的细胞分裂和生长过程中有尤其重要的作用。",@"description",@"2014-1-2",@"date",@"2014-1-4",@"expire",@"",@"icon",nil];
            
        }
        BTKnowledgeModel * knowledge = [[BTKnowledgeModel alloc] initWithDictionary:dictionary];
        //把一个个的shop存入可变数组 dataArray(父类中定义 并初始化)
        [self.modelArray addObject:knowledge];
        
        
    }
    
    [self finishReloadingData];//刷新完成
    [self.tableView reloadData];
    
}

#pragma mark - 加载返回第一行按钮
- (void)addChageScrollViewToTopButton
{
    self.toTopButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _toTopButton.frame = CGRectMake(10, self.view.frame.size.height - 100, 30, 30);
    [_toTopButton setBackgroundImage:[UIImage imageNamed:@"anchor_unselected"] forState:UIControlStateNormal];
    [_toTopButton setBackgroundImage:[UIImage imageNamed:@"anchor_selected"] forState:UIControlStateSelected];
    [_toTopButton setBackgroundImage:[UIImage imageNamed:@"anchor_selected"] forState:UIControlStateHighlighted];
    [_toTopButton addTarget:self action:@selector(toTop:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_toTopButton];
}
//返回到首页
- (void)toTop:(UIButton *)button
{
    [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.tableView.contentOffset = CGPointMake(0, 0);
    } completion:nil];
    
}
#pragma mark - 加载子视图
- (void)addSubviews
{
    self.navigationBgView = [[UIView alloc]init];
    if (IOS7_OR_LATER) {
        self.navigationBgView.frame = CGRectMake(0, 0, 320, 90/2 + 20);
    }
    
    else
    {
        self.navigationBgView.frame = CGRectMake(0, 0, 320, 90/2);
    }
    _navigationBgView.backgroundColor = kGlobalColor;
    [self.view addSubview:_navigationBgView];
    
    
    //navigationBgView上的子视图
    
    UIImageView *iconImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon_logo"]];
    iconImage.frame = CGRectMake(24/2, _navigationBgView.frame.size.height - 5 - 39, 39, 39);
    [_navigationBgView addSubview:iconImage];
    
    self.dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(iconImage.frame.origin.x + iconImage.frame.size.width + 10, iconImage.frame.origin.y, 100, 20)];
    _dateLabel.backgroundColor = [UIColor clearColor];
    _dateLabel.font = [UIFont systemFontOfSize:18];
    _dateLabel.textAlignment = NSTextAlignmentLeft;
    _dateLabel.textColor = [UIColor whiteColor];
    _dateLabel.text = @"3周4天";
    [_navigationBgView addSubview:_dateLabel];
    
    self.countLabel = [[UILabel alloc] initWithFrame:CGRectMake(iconImage.frame.origin.x + iconImage.frame.size.width + 10, _dateLabel.frame.origin.y + _dateLabel.frame.size.height, 200, 20)];
    _countLabel.backgroundColor = [UIColor clearColor];
    _countLabel.font = [UIFont systemFontOfSize:15];
    _countLabel.textAlignment = NSTextAlignmentLeft;
    _countLabel.textColor = [UIColor whiteColor];
    _countLabel.text = @"预产期倒计时: 255天";
    [_navigationBgView addSubview:_countLabel];
    
    UIButton *clockButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [clockButton setBackgroundImage:[UIImage imageNamed:@"appointment_bt_unselected"] forState:UIControlStateNormal];
    [clockButton setBackgroundImage:[UIImage imageNamed:@"appointment_bt_selected"] forState:UIControlStateSelected];
    [clockButton setBackgroundImage:[UIImage imageNamed:@"appointment_bt_selected"] forState:UIControlStateHighlighted];
    [clockButton addTarget:self action:@selector(inputYourPreproduction:) forControlEvents:UIControlEventTouchUpInside];
    clockButton.frame = CGRectMake(320 - 50, 10, 60/2, 60/2);
    [_navigationBgView addSubview:clockButton];
    
    //    self.tableViewBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, _navigationBgView.frame.origin.y + _navigationBgView.frame.size.height, 320, self.view.frame.size.height - NAVIGATIONBAR_HEIGHT)];
    //    _tableViewBackgroundView.backgroundColor = [UIColor redColor];
    //    [self.view addSubview:_tableViewBackgroundView];
    
    self.headView = [[UIView alloc] initWithFrame:CGRectMake(0, NAVIGATIONBAR_HEIGHT, 320, 40)];
    _headView.backgroundColor = kGlobalColor;
    //  [self.view addSubview:_headView];
    
    //加载tableview
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, _navigationBgView.frame.origin.y + _navigationBgView.frame.size.height, 320,self.view.frame.size.height - (_navigationBgView.frame.origin.y + _navigationBgView.frame.size.height) - 55)];
    _tableView.backgroundColor = [UIColor whiteColor];
    _tableView.dataSource = self;
    _tableView.delegate = self;
    [self.view addSubview:_tableView];
}

#pragma mark - popview 请输入预产期
- (void)popAlertView
{
    
    
    BTAlertView *alert = [[BTAlertView alloc] initWithTitle:@"美妈美妈" iconImage:nil contentText:@"请输入宝宝预产期" leftButtonTitle:nil rightButtonTitle:@"好的"];
    [alert show];
    alert.rightBlock = ^() {
        NSLog(@"right button clicked");
        //弹出输入预产期选择器
        if (self.actionSheetView == nil) {
            self.actionSheetView = [[BTSheetPickerview alloc] initWithPikerType:BTActionSheetPickerStyleDateAndTimePicker referView:self.view delegate:self];
        }
        
        [_actionSheetView show];
        
    };
    alert.dismissBlock = ^() {
        NSLog(@"Do something interesting after dismiss block");
    };
    
}

#pragma mark - 各种button event
//点击分区头上的按钮 进入下一页
- (void)pushNextView:(UIButton *)button
{
    NSLog(@"点击分区头，进入下一页");
}

//输入预产期
- (void)inputYourPreproduction:(UIButton *)button
{
    if (self.actionSheetView == nil) {
        self.actionSheetView = [[BTSheetPickerview alloc] initWithPikerType:BTActionSheetPickerStyleDateAndTimePicker referView:self.view delegate:self];
    }
    
    [_actionSheetView show];
    
}
#pragma mark - 输入预产期 日期选择器delegate
- (void)actionSheetPickerView:(BTSheetPickerview *)pickerView didSelectDate:(NSDate*)date
{
    
    NSDate *localDate = [NSDate localdateByDate:date];
    NSString *dateAndTime = [NSDate stringFromDate:date withFormat:@"yy-MM-dd HH:mm:ss"];
    NSNumber *year = [BTUtils getYear:localDate];
    NSNumber *month = [BTUtils getMonth:localDate];
    NSNumber *day = [BTUtils getDay:localDate];
    NSNumber *hour = [BTUtils getHour:localDate];
    NSNumber *minute = [BTUtils getMinutes:localDate];
    
    
    NSLog(@"选择的日期是。。。。。%@",dateAndTime);
    NSLog(@"选泽的年：%@,月：%@，日：%@,小时：%@,分钟：%@",year,month,day,hour,minute);
}

#pragma mark - Table view data source
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //在这里判断 用哪个cell进行展示 然后调用cell的自动调整高度的方法
    BTKnowledgeModel *model = [self.modelArray objectAtIndex:indexPath.row];
    switch ([model.eventId intValue]) {
        case 3://提醒
            return [BTWarnCell cellHeightWithMode:model];
            break;
        case 2://知识类
            return [BTKnowledgeCell cellHeightWithMode:model];
            break;
            
        default:
            break;
    }
    return 150.0;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    //return [self.sectionArray count];
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    //    BTRowOfSectionModel *model = [self.rowOfSectionArray objectAtIndex:section];
    //    return model.row;
    return [self.modelArray count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 44;
}
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *aView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 150)];
    aView.backgroundColor = [UIColor greenColor];
    
    UILabel *lable = [[UILabel alloc] initWithFrame:CGRectMake(5, 5, 60, (44 - 5*2))];
    lable.backgroundColor = [UIColor blueColor];
    lable.textAlignment = NSTextAlignmentCenter;
    lable.textColor =[UIColor whiteColor];
    
    UIButton *button  = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    button.frame = CGRectMake(320 - 100, 10,100, (44 - 10*2));
    button.tag = MAIN_BUTTON_TAG + section;
    [button setTitle:@"卵子受孕中" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(pushNextView:) forControlEvents:UIControlEventTouchUpInside];
    [aView addSubview:button];
    
    // BTRowOfSectionModel *model = [self.rowOfSectionArray objectAtIndex:section];
    if (section == 0) {
        lable.text = @"3周";
        
        //    lable.text = model.sectionTile;
    }
    [aView addSubview: lable];
    
    static int tag = 1001;
    aView.tag = tag++;
    return aView;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    static NSString *CellIdentifierWarn = @"CellWarn";
    BTKnowledgeCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    BTWarnCell *warnCell = [tableView dequeueReusableCellWithIdentifier:CellIdentifierWarn];
    
    if (cell == nil) {
        cell = [[BTKnowledgeCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    if (warnCell == nil) {
        warnCell = [[BTWarnCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifierWarn];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    warnCell.selectionStyle = UITableViewCellSelectionStyleNone;
    BTKnowledgeModel *model = [self.modelArray objectAtIndex:indexPath.row];
    //现在2是知识类  3是提醒类
    if ([model.eventId intValue] == 2) {
        cell.knowledgeModel = model;
        return cell;
        
    }
    else if([model.eventId intValue] == 3)
    {
        warnCell.knowledgeModel = model;
        return warnCell;
        
    }
    return nil;
    
}

#pragma mark - tabelview delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    BTKnowledgeViewController *knowledge = [[BTKnowledgeViewController alloc] init];
    knowledge.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:knowledge animated:YES];
    
    
}


//＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝
//初始化刷新视图
//＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝
#pragma mark - methods for creating and removing the header view

-(void)createHeaderView{
    if (_refreshHeaderView && [_refreshHeaderView superview]) {
        [_refreshHeaderView removeFromSuperview];
    }
    //	_refreshHeaderView = [[EGORefreshTableHeaderView alloc] initWithFrame:
    //                          CGRectMake(0.0f, 0.0f - self.view.bounds.size.height,
    //                                     self.view.frame.size.width, self.view.bounds.size.height) orientation:YES];
    _refreshHeaderView = [[EGORefreshTableHeaderView alloc]initWithFrame:
                          CGRectMake(0.0f, 0.0f - self.view.bounds.size.height,self.view.frame.size.width, self.view.bounds.size.height) arrowImageName:@"blueArrow.png" textColor:[UIColor whiteColor] orientation:YES];
    _refreshHeaderView.delegate = self;
   	[self.tableView addSubview:_refreshHeaderView];
    
    [_refreshHeaderView refreshLastUpdatedDate];
}

-(void)testFinishedLoadData{
	
    
    //[self setFooterView];
}
//===============
//刷新delegate
#pragma mark -
#pragma mark data reloading methods that must be overide by the subclass

-(void)beginToReloadData:(EGORefreshPos)aRefreshPos{
	
	//  should be calling your tableviews data source model to reload
	_reloading = YES;
    
    if (aRefreshPos == EGORefreshHeader)
	{
        // pull down to refresh data
        [self performSelector:@selector(refreshView) withObject:nil afterDelay:2.0];
 	}
}

//刷新调用的方法
-(void)refreshView
{
    week =  week - 2;
    if (week > 0) {
        [self getNetworkDataWithWeekOfPregnancy:week];
    }
    else
    {
        [self finishReloadingData];
        
    }
    
    
}

#pragma mark -
#pragma mark method that should be called when the refreshing is finished
- (void)finishReloadingData{
	
	//  model should call this when its done loading
	_reloading = NO;
    
	if (_refreshHeaderView) {
        [_refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:self.tableView];
    }
    
    
    
}


#pragma mark - UIScrollViewDelegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    //    if (scrollView.contentOffset.y >= 0 && scrollView.contentOffset.y <= 40) {
    //        // static CGRect rect = _headView.frame;
    //        NSLog(@"..........%f",_tableView.contentOffset.y);
    //
    //        [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
    //            _headView.frame = CGRectMake(0,NAVIGATIONBAR_HEIGHT - scrollView.contentOffset.y, 320, 40);
    //            self.tableView.frame = CGRectMake(0, NAVIGATIONBAR_HEIGHT - scrollView.contentOffset.y + 40, 320, self.view.frame.size.height);
    //
    //        } completion:nil];
    //        [self.view bringSubviewToFront:_navigationBgView];
    //    }
    //
    //
    //    else if (scrollView.contentOffset.y > 40) {
    //        [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
    //            _headView.frame = CGRectMake(0,NAVIGATIONBAR_HEIGHT - 40, 320, 40);
    //            self.tableView.frame = CGRectMake(0, NAVIGATIONBAR_HEIGHT - 40 + 40, 320, self.view.frame.size.height - 59);
    //
    //        } completion:nil];
    //
    //    }
    //
    //    else{
    //        //[UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
    //        _headView.frame = CGRectMake(0,NAVIGATIONBAR_HEIGHT, 320, 40);
    //
    //        //} completion:nil];
    //
    //    }
    //    NSLog(@"..........%f",_tableView.contentOffset.y);
    
    //刷新数据
    if (_refreshHeaderView)
	{
        [_refreshHeaderView egoRefreshScrollViewDidScroll:scrollView];
    }
    
}

//
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
	if (_refreshHeaderView)
	{
        [_refreshHeaderView egoRefreshScrollViewDidEndDragging:scrollView];
    }
	
}



#pragma mark - EGORefreshTableDelegate Methods

- (void)egoRefreshTableDidTriggerRefresh:(EGORefreshPos)aRefreshPos
{
	
	[self beginToReloadData:aRefreshPos];
	
}

- (BOOL)egoRefreshTableDataSourceIsLoading:(UIView*)view{
	
	return _reloading; // should return if data source model is reloading
	
}


// if we don't realize this method, it won't display the refresh timestamp
- (NSDate*)egoRefreshTableDataSourceLastUpdated:(UIView*)view
{
	
	return [NSDate date]; // should return date data source was last changed
	
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

