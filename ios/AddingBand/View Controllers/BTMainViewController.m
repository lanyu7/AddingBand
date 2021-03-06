//
//  BTMainViewController.m
//  AddingBand
//
//  Created by wangpeng on 13-12-20.
//  Copyright (c) 2013年 kaka'. All rights reserved.
//

#import "BTMainViewController.h"
#import "LayoutDef.h"
#import "NSDate+DateHelper.h"
#import "BTUtils.h"
#import "BTAlertView.h"

#import "MKNetworkEngine.h"
#import "MKNetworkOperation.h"
#import "BTKnowledgeModel.h"
#import "BTKnowledgeCell.h"
#import "BTWarnCell.h"
#import "BTGetData.h"
#import "BTUserSetting.h"

#import "BTRowOfSectionModel.h"
#import "BTPersonalDataView.h"
#import "BTBlogDetailViewController.h"
#import "BTDateCell.h"
#define NAVIGATIONBAR_Y 0
#define NAVIGATIONBAR_HEIGHT 65

static int currentWeek = 0;
static int pastWeek = 100;//初始值
static int nextWeek = 0;
@interface BTMainViewController ()
@property(nonatomic,strong)UILabel *dateLabel;//3周4天
@property(nonatomic,strong)UILabel *countLabel;//预产期倒计时
@property(nonatomic,strong)NSString *menstruation;
@property(nonatomic,strong)NSString *today;
@property(nonatomic,assign)BOOL isCodeRefresh;
@property(nonatomic,assign)BOOL isLoadPastSuccessfully;
@property(nonatomic,assign)BOOL isLoadNextSuccessfully;
@end

@implementation BTMainViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.modelArray = [NSMutableArray arrayWithCapacity:1];
        self.sectionArray = [NSMutableArray arrayWithCapacity:1];
        self.isLoadPastSuccessfully = YES;
        self.isLoadNextSuccessfully = YES;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getNetworkData:) name:FIRSTENTERNOTICE object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshloadDataByModifyMenstruation:) name:MODIFYMENSTRUATIONDATENOTICE object:nil];
        
    }
    return self;
}
#pragma mark - 视图出现  消失
- (void)viewWillAppear:(BOOL)animated
{

    //如果是第一次进入此页面 pop一个view
    if ([[NSUserDefaults standardUserDefaults] boolForKey:FIRST_APPEAR]) {
        
        [self presentPersonnalDataView];
        //[self popAlertView];
        
    }
    
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    //[self updatePregnancyTime];
    
    
}
- (void)presentPersonnalDataView
{
    BTPersonalDataView *personnalDataView =[[BTPersonalDataView alloc] init];
    [self presentViewController:personnalDataView animated:YES completion:nil];
    
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    NSLog(@"视图加载了........");
    self.view.backgroundColor = [UIColor whiteColor];
    NSLog(@"*********当前周  %d",currentWeek);
    [self addSubviews];
    [self addChageScrollViewToTopButton];
    
    //[self getNetworkDataWithWeekOfPregnancy:3];
    
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:FIRST_APPEAR]) {
        [self getMenstruationAndTodayDate];//得到末次月经 和 今天日期
        currentWeek =[self getCurrentWeekOfPregnancyWithMenstruation:nil];//得到今天是怀孕第几周
        [self showRefreshHeader:YES];//代码触发刷新
        
    }
   	// Do any additional setup after loading the view.
}
#pragma mark - 收到通知 请求数据
- (void)getNetworkData:(NSNotification *)notification
{
    NSDictionary *userInfoDic = notification.userInfo;
    
    self.menstruation = [userInfoDic objectForKey:FIRSTENTERNOTICE_MENSTRUAL_KEY];
    self.today = [userInfoDic objectForKey:FIRSTENTERNOTICE_TODAY_KEY];
    NSString *menstruationString = [self.menstruation stringByReplacingOccurrencesOfString:@"-" withString:@"."];
    currentWeek = [self getCurrentWeekOfPregnancyWithMenstruation:menstruationString];
    
    [self showRefreshHeader:YES];//代码触发刷新
}
//修改完预产期后 首页更新数据
- (void)refreshloadDataByModifyMenstruation:(NSNotification *)notification
{
    NSDate *localdate = [NSDate localdate];
    NSNumber *year = [BTUtils getYear:localdate];
    NSNumber *month = [BTUtils getMonth:localdate];
    NSNumber *dayLocal = [BTUtils getDay:localdate];
    self.today = [NSString stringWithFormat:@"%@-%@-%@",year,month,dayLocal];

    NSDictionary *userInfoDic = notification.userInfo;
    self.menstruation = [userInfoDic objectForKey:MODIFY_MENSTRUATION_KEY];
    currentWeek = [self getCurrentWeekOfPregnancyWithMenstruation:self.menstruation];
    //model数组要清零 各日期也要重置
    [self.sectionArray removeAllObjects];
    [self.modelArray removeAllObjects];
    [self.tableView reloadData];
    pastWeek = 100;
    nextWeek = 0;
    _isLoadNextSuccessfully = YES;
    _isLoadPastSuccessfully = YES;
    [self showRefreshHeader:YES];//代码触发刷新

}
#pragma mark - 得到末次月经 和 今天日期
- (void)getMenstruationAndTodayDate
{
    NSArray *data = [BTGetData getFromCoreDataWithPredicate:nil entityName:@"BTUserSetting" sortKey:nil];
    if (data.count > 0) {
        BTUserSetting *userData = [data objectAtIndex:0];
        NSString *str1 = userData.menstruation;
        
        self.menstruation = [str1 stringByReplacingOccurrencesOfString:@"." withString:@"-"];
    }
    NSDate *localdate = [NSDate localdate];
    NSNumber *year = [BTUtils getYear:localdate];
    NSNumber *month = [BTUtils getMonth:localdate];
    NSNumber *dayLocal = [BTUtils getDay:localdate];
    self.today = [NSString stringWithFormat:@"%@-%@-%@",year,month,dayLocal];
    
}
#pragma mark - 代码触发下拉刷新
-(void)showRefreshHeader:(BOOL)animated
{
    self.isCodeRefresh = YES;
    if (animated)
    {
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:0.3];
        self.tableView.contentInset = UIEdgeInsetsMake(65.0f, 0.0f, 0.0f, 0.0f);
        [self.tableView scrollRectToVisible:CGRectMake(0, 0.0f, 1, 1) animated:NO];
        [UIView commitAnimations];
    }
    else
    {
        self.tableView.contentInset = UIEdgeInsetsMake(65.0f, 0.0f, 0.0f, 0.0f);
        [self.tableView scrollRectToVisible:CGRectMake(0, 0.0f, 1, 1) animated:NO];
    }
    
    [_refreshHeaderView setState:EGOOPullRefreshLoading];
    [_refreshHeaderView egoRefreshScrollViewDidEndDragging:self.tableView];
    
}

#pragma mark - 根据末次月经日期 算出今天处于第几周
/**
 *  根据末次月经日期 算出今天处于第几周
 *
 *  @param menstruation menstruation格式 为2014.12.23
 *
 *  @return 当前为怀孕第几周
 */
- (int)getCurrentWeekOfPregnancyWithMenstruation:(NSString *)menstruation
{
    NSDate *localdate = [NSDate localdate];
    NSNumber *year = [BTUtils getYear:localdate];
    NSNumber *month = [BTUtils getMonth:localdate];
    NSNumber *dayLocal = [BTUtils getDay:localdate];
    int day = 0;
    if (menstruation) {
        NSDate *gmtDate = [NSDate dateFromString:[NSString stringWithFormat:@"%@.%@.%@",year,month,dayLocal] withFormat:@"yyyy.MM.dd"];
        NSDate *menstruationDate = [NSDate dateFromString:menstruation withFormat:@"yyyy.MM.dd"];//duedate为00：00：00
        NSTimeInterval menstruation = [menstruationDate timeIntervalSince1970];
        NSTimeInterval now = [gmtDate timeIntervalSince1970];
        NSTimeInterval cha = now - menstruation;
        day = cha/(24 * 60 * 60);
        
    }
    else{
        NSDate *gmtDate = [NSDate dateFromString:[NSString stringWithFormat:@"%@.%@.%@",year,month,dayLocal] withFormat:@"yyyy.MM.dd"];
        day = [BTGetData getPregnancyDaysWithDate:gmtDate];
        
    }
    //根据怀孕天数 算出是第几周 第几天
    int week = day/7 + 1;
    if (day%7 == 0) {
        week = week - 1;
    }
    return week;
    
}

#pragma mark - 更新导航栏上显示的怀孕时间
- (void)updatePregnancyTime
{
    NSDate *localdate = [NSDate localdate];
    NSNumber *year = [BTUtils getYear:localdate];
    NSNumber *month = [BTUtils getMonth:localdate];
    NSNumber *dayLocal = [BTUtils getDay:localdate];
    NSDate *gmtDate = [NSDate dateFromString:[NSString stringWithFormat:@"%@.%@.%@",year,month,dayLocal] withFormat:@"yyyy.MM.dd"];
    int day = [BTGetData getPregnancyDaysWithDate:gmtDate];
    //根据怀孕天数 算出是第几周 第几天
    int week = day/7 + 1;
    int day1 = day%7;
    
    if (day%7 == 0) {
        week = week - 1;
        day1 = 7;
    }
    self.countLabel.text = [NSString stringWithFormat:@"预产期倒计时: %d天",(280 - day)];
    self.dateLabel.text = [NSString stringWithFormat:@"%d周%d天",week,day1];
    
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
- (void)getNetworkDataOfPastTimeWithWeekOfPregnancy:(int)week
{
    self.engine = [[MKNetworkEngine alloc] initWithHostName:HTTP_HOSTNAME customHeaderFields:nil];
    [self.engine useCache];//使用缓存
    
    MKNetworkOperation *op = [self.engine operationWithPath:[NSString stringWithFormat:@"/api/schedule_new?p=%@&t=%@&w=%d",self.menstruation,self.today,week] params:nil httpMethod:@"GET" ssl:NO];
    
    [op addCompletionHandler:^(MKNetworkOperation *operation) {
        NSLog(@"[operation responseData]-->>%@", [operation responseString]);
        
        //请求成功
        _isLoadPastSuccessfully = YES;
        NSDictionary *resultDic = [NSJSONSerialization JSONObjectWithData:[operation responseData] options:NSJSONReadingAllowFragments error:nil];
        //保证有数据的时候在进行数据处理 没有数据就直接跳过
        if ([resultDic count] > 0) {
            
       [self handlePastDataByGetNetworkSuccessfullyWithJsonData:[operation responseData] week:week];
            
        }
        
        else{
            [self finishReloadingData];
        }
        
        //请求数据错误
    }errorHandler:^(MKNetworkOperation *errorOp, NSError* err) {
        NSLog(@"MKNetwork request error------ : %@", [err localizedDescription]);
        //请求失败
        _isLoadPastSuccessfully = NO;
        [self handleDataByGetNetworkFailly];
        
    }];
    [self.engine enqueueOperation:op];
    
    
    
}

- (void)getNetworkDataWithWeekOfPregnancy:(int)week
{
    
    //用MKNetworkKit进行异步网络请求
    /*GET请求 示例*/
    
    self.engine = [[MKNetworkEngine alloc] initWithHostName:HTTP_HOSTNAME customHeaderFields:nil];
    [self.engine useCache];//使用缓存
    
    MKNetworkOperation *op = [self.engine operationWithPath:[NSString stringWithFormat:@"/api/schedule_new?p=%@&t=%@&w=%d+%d",self.menstruation,self.today,week,week + 1] params:nil httpMethod:@"GET" ssl:NO];
    
    
    
    
    
    
    [op addCompletionHandler:^(MKNetworkOperation *operation) {
        NSLog(@"[operation responseData]-->>%@", [operation responseString]);
        
        NSDictionary *resultDic = [NSJSONSerialization JSONObjectWithData:[operation responseData] options:NSJSONReadingAllowFragments error:nil];
        //保证有数据的时候在进行数据处理 没有数据就直接跳过
        if ([resultDic count] > 0) {
            
            //加载成功之后 才将 _isCodeRefresh置为no,否则还是要加载当周的数据
             _isCodeRefresh = NO;
            
            if (_isLoadNextData) {
                NSLog(@"week 是----%d",week);
                //请求成功
                _isLoadNextSuccessfully = YES;
                [self handleNextDataByGetNetworkSuccessfullyWithJsonData:[operation responseData] week:week];
                
            }
            else{
                _isLoadPastSuccessfully = YES;
                [self handlePastDataByGetNetworkSuccessfullyWithJsonData:[operation responseData] week:week];
                
            }
            
        }
        
        else{
            [self finishReloadingData];
        }
        
        _isCodeRefresh = NO;//代码触发刷新置为 NO
        //请求数据错误
    }errorHandler:^(MKNetworkOperation *errorOp, NSError* err) {
        NSLog(@"MKNetwork request error------ : %@", [err localizedDescription]);
        //请求失败
        _isLoadNextSuccessfully = NO;
        _isLoadPastSuccessfully = NO;
        [self handleDataByGetNetworkFailly];
        
    }];
    [self.engine enqueueOperation:op];
    
    
}
- (void)handlePastDataByGetNetworkSuccessfullyWithJsonData:(NSData *)data week:(int)week
{
    
    NSMutableArray *section = [NSMutableArray arrayWithCapacity:1];
    // currentWeek = 3;
    NSDictionary *resultDic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
    
    NSDictionary *weekPreviousDic = [resultDic objectForKey:[NSString stringWithFormat:@"w%d",week]];
    NSArray *resultPreviousArray = [weekPreviousDic objectForKey:@"results"];
    //判断是否有数据，有的话再做处理
    BTRowOfSectionModel *model1 = nil;
    if ([resultPreviousArray count] > 0) {
        model1 = [[BTRowOfSectionModel alloc] initWithSectionTitle:[NSString stringWithFormat:@"%d周",week] row:[resultPreviousArray count]];
        [section addObject:model1];
    }
    NSLog(@"resultPreviousArray==%@",resultPreviousArray);
    NSLog(@"_____%@",model1);
    NSDictionary *weekCurrentDic = [resultDic objectForKey:[NSString stringWithFormat:@"w%d",week + 1]];
    NSArray *resultCurrentArray = [weekCurrentDic objectForKey:@"results"];
    NSLog(@"resultCurrentArray====%@",resultCurrentArray);
    BTRowOfSectionModel *model2 = nil;
    if ([resultCurrentArray count] > 0) {
        model2 = [[BTRowOfSectionModel alloc] initWithSectionTitle:[NSString stringWithFormat:@"%d周",week + 1] row:[resultCurrentArray count]];
        [section addObject:model2];
    }
    
    //骚年 这里是分区数据
    
    for (int i = section.count - 1; i >= 0;i--) {
        
        [self.sectionArray insertObject:[section objectAtIndex:i] atIndex:0];//这是分区数据
        
    }
    
    
    //下面是每行数据
    NSMutableArray *array1 = [NSMutableArray arrayWithCapacity:1];
    NSMutableArray *array2 = [NSMutableArray arrayWithCapacity:1];
    NSMutableArray *resultArray = [NSMutableArray arrayWithCapacity:1];
    
    if ([resultPreviousArray count] > 0) {
        for (int i = 0; i < [resultPreviousArray count]; i ++) {
            NSDictionary * dictionary = [resultPreviousArray objectAtIndex:i];
            BTKnowledgeModel * knowledge = [[BTKnowledgeModel alloc] initWithDictionary:dictionary];
            //加入判断条件
            if (([knowledge.remind intValue] == 1) && [self shouldRemoveWithWarnid:[NSNumber numberWithInt:[knowledge.warnId intValue]] date:knowledge.date]) {
                NSLog(@"哈哈哈哈哈哈哈哈哈哈哈哈");
                continue;
            }
            else{
                [array1 addObject:knowledge];
            }
            
        }
        
        NSLog(@"dadadadada %@",array1);
        [resultArray addObject:array1];
        
    }
    
    if ([resultCurrentArray count] > 0) {
        for (int i = 0; i < [resultCurrentArray count]; i ++) {
            NSDictionary * dictionary = [resultCurrentArray objectAtIndex:i];
            BTKnowledgeModel * knowledge = [[BTKnowledgeModel alloc] initWithDictionary:dictionary];
            [array2 addObject:knowledge];
        }
        
        [resultArray addObject:array2];
        
    }
    
    
    for (int i = resultArray.count - 1;i >= 0;i--)
    {
        NSArray * array = [resultArray objectAtIndex:i];
        //把一个个的knowledge存入可变数组 modelArray(类初始化的时候应开辟空间)
        [self.modelArray insertObject:array atIndex:0];//这是行数据
    }
    NSLog(@"请求结果是.......%@",self.modelArray);
    
    
    
    [self.tableView reloadData];
    [self finishReloadingData];//刷新完成
}

- (void)handleNextDataByGetNetworkSuccessfullyWithJsonData:(NSData *)data week:(int)week
{
    NSMutableArray *section = [NSMutableArray arrayWithCapacity:1];
    
    // currentWeek = 3;
    NSDictionary *resultDic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
    
    
    NSDictionary *weekPreviousDic = [resultDic objectForKey:[NSString stringWithFormat:@"w%d",week]];
    NSArray *resultPreviousArray = [weekPreviousDic objectForKey:@"results"];
    //判断是否有数据，有的话再做处理
    BTRowOfSectionModel *model1 = nil;
    if ([resultPreviousArray count] > 0) {
        model1 = [[BTRowOfSectionModel alloc] initWithSectionTitle:[NSString stringWithFormat:@"%d周",week] row:[resultPreviousArray count]];
        [section addObject:model1];
    }
    NSLog(@"resultPreviousArray==%@",resultPreviousArray);
    NSLog(@"_____%@",model1);
    NSDictionary *weekCurrentDic = [resultDic objectForKey:[NSString stringWithFormat:@"w%d",week + 1]];
    NSArray *resultCurrentArray = [weekCurrentDic objectForKey:@"results"];
    NSLog(@"resultCurrentArray====%@",resultCurrentArray);
    BTRowOfSectionModel *model2 = nil;
    if ([resultCurrentArray count] > 0) {
        model2 = [[BTRowOfSectionModel alloc] initWithSectionTitle:[NSString stringWithFormat:@"%d周",week + 1] row:[resultCurrentArray count]];
        [section addObject:model2];
    }
    
    //骚年 这里是分区数据
    
    for (int i = 0; i < [section count];i++) {
        
        [self.sectionArray addObject:[section objectAtIndex:i]];//这是分区数据
        
    }
    
    
    
    
    
    //下面是每行数据
    NSMutableArray *array1 = [NSMutableArray arrayWithCapacity:1];
    NSMutableArray *array2 = [NSMutableArray arrayWithCapacity:1];
    NSMutableArray *resultArray = [NSMutableArray arrayWithCapacity:1];
    
    if ([resultPreviousArray count] > 0) {
        for (int i = 0; i < [resultPreviousArray count]; i ++) {
            NSDictionary * dictionary = [resultPreviousArray objectAtIndex:i];
            NSLog(@"zidianshi %@",dictionary);
            BTKnowledgeModel * knowledge = [[BTKnowledgeModel alloc] initWithDictionary:dictionary];
            [array1 addObject:knowledge];
        }
        [resultArray addObject:array1];
        
    }
    
    if ([resultCurrentArray count] > 0) {
        for (int i = 0; i < [resultCurrentArray count]; i ++) {
            NSDictionary * dictionary = [resultCurrentArray objectAtIndex:i];
            BTKnowledgeModel * knowledge = [[BTKnowledgeModel alloc] initWithDictionary:dictionary];
            [array2 addObject:knowledge];
        }
        
        [resultArray addObject:array2];
        
    }
    
    
    for (int i = 0;i < [resultArray count];i++)
    {
        NSArray * array = [resultArray objectAtIndex:i];
        //把一个个的knowledge存入可变数组 modelArray(类初始化的时候应经开辟空间)
        [self.modelArray addObject:array];//这是行数据
    }
    NSLog(@"请求结果是.......%@",self.modelArray);
    
    [self.tableView reloadData];
    [self finishReloadingData];//刷新完成
}


- (void)handleDataByGetNetworkFailly
{
    //    NSDictionary * dictionary;
    //    for (int i = 0; i < 2; i ++) {
    //        if (i == 0) {
    //            dictionary  = [NSDictionary dictionaryWithObjectsAndKeys:@"3",@"event_id",@"103",@"event_type",@"该吃药了哈哈哈哈哈哈哈哈哈哈哈哈哈哈哈哈哈哈哈哈哈哈哈哈哈",@"title", @"",@"hash",@"丫今儿该吃苹果了",@"description",@"2014-1-2",@"date",@"2014-1-4",@"expire",@"",@"icon",nil];
    //        }
    //        if (i == 1) {
    //            dictionary  = [NSDictionary dictionaryWithObjectsAndKeys:@"2",@"event_id",@"103",@"event_type",@"什么是叶酸什么是叶酸什么是叶酸什么是叶酸什么是叶酸什么是叶酸什么是叶酸什么是叶酸什么是叶酸什么是叶酸什么是叶酸什么是叶酸？",@"title", @"",@"hash",@"叶酸是维生素B9的水溶形式。叶酸的名字来源于拉丁文folium。由米切尔及其同事 首次从菠菜叶中提取纯化出来，命名为叶酸。叶酸作为重要的一碳载体，在核苷酸合成，同型半胱氨酸的再甲基化等诸多重要生理代谢功能方面有重要作用。因此叶酸在快速的细胞分裂和生长过程中有尤其重要的作用。",@"description",@"2014-1-2",@"date",@"2014-1-4",@"expire",@"",@"icon",nil];
    //
    //        }
    //        BTKnowledgeModel * knowledge = [[BTKnowledgeModel alloc] initWithDictionary:dictionary];
    //        //把一个个的shop存入可变数组 dataArray(父类中定义 并初始化)
    //        [self.modelArray addObject:knowledge];
    //
    //
    //    }
    
    [self finishReloadingData];//刷新完成
    [self.tableView reloadData];
    
}
#pragma mark - 判断数据源中的提醒是否存在于coredata中 并且是否应该删除
- (BOOL)shouldRemoveWithWarnid:(NSNumber *)aWarnId date:(NSString *)date
{
    
    NSLog(@"提醒id是多少%@",aWarnId);
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"warnId == %@",aWarnId];
    NSArray *dataArray = [BTGetData getFromCoreDataWithPredicate:predicate entityName:@"BTWarnData" sortKey:nil];
    NSLog(@"lallalala%d",[dataArray count]);
    if ([dataArray count] > 0) {
        
        NSDate *modelDate = [NSDate dateFromString:date withFormat:@"yyyy-MM-dd"];
        NSDate *localDate = [NSDate localdate];
        if ([NSDate isAscendingWithOnedate:modelDate anotherdate:localDate]) {
            return NO;
        }
        else{
            return YES;
        }
        
    }
    else{
        NSDate *modelDate = [NSDate dateFromString:date withFormat:@"yyyy-MM-dd"];
        NSDate *localDate = [NSDate localdate];
        if ([NSDate isAscendingWithOnedate:modelDate anotherdate:localDate]) {
            return YES;
        }
        else{
            return NO;
        }
    }
    
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
   // [self.view addSubview:_toTopButton];
}
//返回到首页
- (void)toTop:(UIButton *)button
{
    [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
       // self.tableView.contentOffset = CGPointMake(0, 0);
        
    //    scrollToRowAtIndexPath:(NSIndexPath *)indexPath atScrollPosition:(UITableViewScrollPosition)scrollPosition animated:(BOOL)animated
        NSIndexPath *aIndexpath = [NSIndexPath indexPathForRow:4 inSection:0];
        [self.tableView scrollToRowAtIndexPath:aIndexpath atScrollPosition:UITableViewScrollPositionTop animated:YES];
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
    
    UIImageView *iconImage = [[UIImageView alloc] initWithImage:kNavigationbarIcon];
    iconImage.frame = CGRectMake(24/2, _navigationBgView.frame.size.height - 5 - 39, 39, 39);
    [_navigationBgView addSubview:iconImage];
    
    //    self.dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(iconImage.frame.origin.x + iconImage.frame.size.width + 10, iconImage.frame.origin.y, 100, 20)];
    //    _dateLabel.backgroundColor = [UIColor clearColor];
    //    _dateLabel.font = [UIFont systemFontOfSize:15];
    //    _dateLabel.textAlignment = NSTextAlignmentLeft;
    //    _dateLabel.textColor = [UIColor whiteColor];
    //    _dateLabel.text = @"3周4天";
    //    [_navigationBgView addSubview:_dateLabel];
    
    //    self.countLabel = [[UILabel alloc] initWithFrame:CGRectMake(iconImage.frame.origin.x + iconImage.frame.size.width + 10, _dateLabel.frame.origin.y + _dateLabel.frame.size.height, 200, 20)];
    //    _countLabel.backgroundColor = [UIColor clearColor];
    //    _countLabel.font = [UIFont systemFontOfSize:15];
    //    _countLabel.textAlignment = NSTextAlignmentLeft;
    //    _countLabel.textColor = [UIColor whiteColor];
    //    _countLabel.text = @"预产期倒计时: 255天";
    //    [_navigationBgView addSubview:_countLabel];
    
    //加一个文字logo
    UIImageView *logoImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo_text"]];
    logoImage.frame = CGRectMake(iconImage.frame.origin.x + iconImage.frame.size.width + 5, _navigationBgView.frame.size.height - 11 - 42/2, 232/2, 42/2);
    [_navigationBgView addSubview:logoImage];
    
    
    UIButton *clockButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [clockButton setBackgroundImage:[UIImage imageNamed:@"appointment_bt_unselected"] forState:UIControlStateNormal];
    [clockButton setBackgroundImage:[UIImage imageNamed:@"appointment_bt_selected"] forState:UIControlStateSelected];
    [clockButton setBackgroundImage:[UIImage imageNamed:@"appointment_bt_selected"] forState:UIControlStateHighlighted];
    [clockButton addTarget:self action:@selector(inputYourPreproduction:) forControlEvents:UIControlEventTouchUpInside];
    clockButton.frame = CGRectMake(320 - 50, _navigationBgView.frame.size.height - 39, 60/2, 60/2);
    //  [_navigationBgView addSubview:clockButton];
    
    
    self.headView = [[UIView alloc] initWithFrame:CGRectMake(0, NAVIGATIONBAR_HEIGHT, 320, 40)];
    _headView.backgroundColor = kGlobalColor;
    //  [self.view addSubview:_headView];
    
    //加载tableview
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, _navigationBgView.frame.origin.y + _navigationBgView.frame.size.height, 320,self.view.frame.size.height - (_navigationBgView.frame.origin.y + _navigationBgView.frame.size.height) - 55)];
    
    if (IOS7_OR_EARLIER) {
        
        self.tableView.frame = CGRectMake(0, _navigationBgView.frame.origin.y + _navigationBgView.frame.size.height, 320,self.view.frame.size.height - (_navigationBgView.frame.origin.y + _navigationBgView.frame.size.height) - 58);
    }
    NSLog(@"页面高度 亲 %f",self.view.frame.size.height);
    _tableView.backgroundColor = [UIColor whiteColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.dataSource = self;
    _tableView.delegate = self;
    [self.view addSubview:_tableView];
    
    [self createHeaderView];
    [self setFooterView];
}

#pragma mark - popview 请输入预产期
- (void)popAlertView
{
    
    
    BTAlertView *alert = [[BTAlertView alloc] initWithTitle:@"产检提醒" iconImage:[UIImage imageNamed:@"antenatel_icon"] contentText:@"请输入产检日期" leftButtonTitle:nil rightButtonTitle:@"知道了"];
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
    NSNumber *year = [BTUtils getYear:localDate];
    NSNumber *month = [BTUtils getMonth:localDate];
    NSNumber *day = [BTUtils getDay:localDate];
    NSNumber *hour = [BTUtils getHour:localDate];
    NSNumber *minute = [BTUtils getMinutes:localDate];
    
    
    [[NSUserDefaults standardUserDefaults] setObject:localDate forKey:ANTENATEL_DATE];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self registerLocalNotificationWithDate:localDate];
    NSLog(@"选择的日期是。。。。。%@",localDate);
    NSLog(@"选泽的年：%@,月：%@，日：%@,小时：%@,分钟：%@",year,month,day,hour,minute);
    
}
- (void)registerLocalNotificationWithDate:(NSDate *)date
{
    
    NSLog(@"注册通知");
    UILocalNotification *notification=[[UILocalNotification alloc] init];
    
    NSTimeInterval inteval = [date timeIntervalSinceDate:[NSDate localdate]];
    NSDate *now=[NSDate new];
    notification.fireDate=[now dateByAddingTimeInterval:inteval];//10秒后通知        notification.fireDate=date; //触发通知的时间
    notification.repeatInterval=0; //循环次数，kCFCalendarUnitWeekday一周一次
    notification.timeZone=[NSTimeZone localTimeZone];
    notification.soundName = UILocalNotificationDefaultSoundName;
    notification.alertBody=@"美妈，该产检了";
    
    notification.alertAction = @"打开";  //提示框按钮
    notification.hasAction = YES; //是否显示额外的按钮，为no时alertAction消失
    
    notification.applicationIconBadgeNumber =0; //设置app图标右上角的数字
    
    //下面设置本地通知发送的消息，这个消息可以接受
    NSDictionary* infoDic = [NSDictionary dictionaryWithObject:@"value" forKey:@"key"];
    notification.userInfo = infoDic;
    //发送通知
    [[UIApplication sharedApplication] scheduleLocalNotification:notification];
    
}

#pragma mark - Table view data source
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //在这里判断 用哪个cell进行展示 然后调用cell的自动调整高度的方法
    NSArray *arrayModel = [self.modelArray objectAtIndex:indexPath.section];
    BTKnowledgeModel *model = [arrayModel objectAtIndex:indexPath.row];
    
    if ([model.title isEqualToString:@""]) {
        return 44.0;
    }
    
    else
    {
        switch ([model.remind intValue]) {
            case 1://warn
                return [BTWarnCell cellHeightWithMode:model];
                break;
            case 0://Knowledge
                return [BTKnowledgeCell cellHeightWithMode:model];
                break;
                
            default:
                break;
        }
        
    }
    return 100.0;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    
    
    return [self.sectionArray count];
    
    
    //return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    //    BTRowOfSectionModel *model = [self.sectionArray objectAtIndex:section];
    //    return model.row;
    
    NSArray *rowArray = [self.modelArray objectAtIndex:section];
    return [rowArray count];
    // return [self.modelArray count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 44;
}
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *aView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 150)];
    aView.backgroundColor = [UIColor whiteColor];
    aView.alpha = 0.9;
    //加一个一像素的分割线
    UIImageView *lineImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"seperator_line"]];
    lineImage.frame = CGRectMake(0, 44 - kSeparatorLineHeight ,320, kSeparatorLineHeight);
    [aView addSubview:lineImage];
    
    
    
    UILabel *lable = [[UILabel alloc] initWithFrame:CGRectMake(5, 5, 60, (44 - 5*2))];
    lable.backgroundColor = [UIColor clearColor];
    lable.textAlignment = NSTextAlignmentCenter;
    lable.textColor =kGlobalColor;
    
    BTRowOfSectionModel *model = [self.sectionArray objectAtIndex:section];
    lable.text = model.sectionTile;
    [aView addSubview: lable];
    
    static int tag = 1001;
    aView.tag = tag++;
    return aView;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    
    static NSString *CellIdentifier = @"Cell";
    static NSString *CellIdentifierWarn = @"CellWarn";
    static NSString *CellIdentifierDate = @"CellDate";
    BTKnowledgeCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    BTWarnCell *warnCell = [tableView dequeueReusableCellWithIdentifier:CellIdentifierWarn];
    BTDateCell *dateCell = [tableView dequeueReusableCellWithIdentifier:CellIdentifierDate];
    
    
    if (cell == nil) {
        cell = [[BTKnowledgeCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    if (warnCell == nil) {
        warnCell = [[BTWarnCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifierWarn];
    }
    if (dateCell == nil) {
        dateCell = [[BTDateCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifierDate];
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    warnCell.selectionStyle = UITableViewCellSelectionStyleNone;
    dateCell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    
    NSArray *arrayModel = [self.modelArray objectAtIndex:indexPath.section];
    BTKnowledgeModel *model = [arrayModel objectAtIndex:indexPath.row];
    if ([model.title isEqualToString:@""]) {
        NSLog(@"------%@",model.date);
        dateCell.knowledgeModel = model;
        return dateCell;
    }
    else{
        if  ([model.remind intValue] == 0)
        {
            cell.knowledgeModel = model;
            return cell;
            
            
        }
        else {
            warnCell.knowledgeModel = model;
            return warnCell;
            
        }
        
    }
    
    
    return nil;
}

#pragma mark - tabelview delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    NSArray *arrayModel = [self.modelArray objectAtIndex:indexPath.section];
    BTKnowledgeModel *model = [arrayModel objectAtIndex:indexPath.row];
    NSString *hash = model.hash;
    BTBlogDetailViewController *blogVC = [[BTBlogDetailViewController alloc] init];
    blogVC.blogHash = hash;
    
    if (![hash isEqualToString:@""]) {
        blogVC.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:blogVC animated:YES];
        
    }
    
    
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
                          CGRectMake(0.0f, 0.0f - self.view.bounds.size.height,self.view.frame.size.width, self.view.bounds.size.height) arrowImageName:@"pull_down.png" textColor:[UIColor whiteColor] orientation:YES];
    _refreshHeaderView.delegate = self;
   	[self.tableView addSubview:_refreshHeaderView];
    
    [_refreshHeaderView refreshLastUpdatedDate];
}

-(void)testFinishedLoadData{
	
    
    //[self setFooterView];
}

//刷新delegate
-(void)setFooterView{
    // if the footerView is nil, then create it, reset the position of the footer
    CGFloat height = MAX(self.tableView.contentSize.height, self.tableView.frame.size.height);
    if (_refreshFooterView && [_refreshFooterView superview])
	{
        // reset position
        _refreshFooterView.frame = CGRectMake(0.0f,
                                              height,
                                              self.tableView.frame.size.width,
                                              self.view.bounds.size.height);
    }else
	{
        // create the footerView
        _refreshFooterView = [[EGORefreshTableFooterView alloc] initWithFrame:
                              CGRectMake(0.0f, height,
                                         self.tableView.frame.size.width, self.view.bounds.size.height)];
        _refreshFooterView.delegate = self;
        [self.tableView addSubview:_refreshFooterView];
    }
    
    if (_refreshFooterView)
	{
        [_refreshFooterView refreshLastUpdatedDate];
    }
}


-(void)removeFooterView
{
    if (_refreshFooterView && [_refreshFooterView superview])
	{
        [_refreshFooterView removeFromSuperview];
    }
    _refreshFooterView = nil;
}

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
    else if(aRefreshPos == EGORefreshFooter)
	{
        // pull up to load more data
        [self performSelector:@selector(getNextPageView) withObject:nil afterDelay:2.0];
    }
    
}

//刷新调用的方法
-(void)refreshView
{
    //判断到什么时候就没有更多数据了
    
    if (_isCodeRefresh) {
        NSLog(@"走这个方法了吗？。。。。。。。。");
        [self getNetworkDataWithWeekOfPregnancy:currentWeek];
        self.isLoadNextData = NO;
        
    }
    else{
        if (pastWeek == 100) {
            pastWeek =  currentWeek - 1;
            NSLog(@"乐乐乐乐乐乐乐乐了了");
        }
        else{
            //上一次请求成功 或者失败后的处理方法
            if (_isLoadPastSuccessfully) {
                 pastWeek = pastWeek -1;
            }
            else{
                pastWeek = pastWeek - 0;
            }
           
        }
        if (pastWeek > 0) {
            
            [self getNetworkDataOfPastTimeWithWeekOfPregnancy:pastWeek];
        }
        else
        {
            [self finishReloadingData];
            
        }
        
        self.isLoadNextData = NO;
        
    }
    // [self getNetworkDataWithWeekOfPregnancy:3];
   
    
}

- (void)getNextPageView
{
    //判断到什么时候就没有更多数据了
    
    self.isLoadNextData = YES;
    if (nextWeek == 0) {
        nextWeek = currentWeek + 2;
    }
    else{
        
        //上一次请求成功 或者失败后的处理方法
        if (_isLoadNextSuccessfully) {
            nextWeek = nextWeek + 2;
        }
        else{
            nextWeek = nextWeek + 0;
        }

        
    }
    
    NSLog(@"下一个数据开始是%d",nextWeek);
    [self getNetworkDataWithWeekOfPregnancy:nextWeek];
    
}
#pragma mark -
#pragma mark method that should be called when the refreshing is finished
- (void)finishReloadingData{
	
	//  model should call this when its done loading
	_reloading = NO;
    
	if (_refreshHeaderView) {
        [_refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:self.tableView];
    }
    
    if (_refreshFooterView) {
        [_refreshFooterView egoRefreshScrollViewDataSourceDidFinishedLoading:self.tableView];
        [self removeFooterView];//先移除
        [self setFooterView];
    }
    
    
}


#pragma mark - UIScrollViewDelegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    
    //刷新数据
    if (_refreshHeaderView)
	{
        [_refreshHeaderView egoRefreshScrollViewDidScroll:scrollView];
    }
    
    if (_refreshFooterView)
	{
        [_refreshFooterView egoRefreshScrollViewDidScroll:scrollView];
    }
    
    
}

//
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
	if (_refreshHeaderView)
	{
        [_refreshHeaderView egoRefreshScrollViewDidEndDragging:scrollView];
    }
	
    if (_refreshFooterView)
	{
        [_refreshFooterView egoRefreshScrollViewDidEndDragging:scrollView];
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

