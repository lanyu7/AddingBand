//
//  BTHeightViewController.m
//  AddingBand
//
//  Created by wangpeng on 13-12-3.
//  Copyright (c) 2013年 kaka'. All rights reserved.
//

#import "BTHeightViewController.h"
#import "FYChartView.h"
#import "BTPhysicalModel.h"
#import "LayoutDef.h"
#import "BTView.h"
#import "BTSheetPickerview.h"
#import "BTGetData.h"
#import "NSDate+DateHelper.h"
#import "BTUtils.h"
#import "BTUserData.h"
#import "IQKeyBoardManager.h"
#import "BTPresentInputViewController.h"
#import "BTNavicationController.h"

@interface BTHeightViewController ()<FYChartViewDataSource>
@property(nonatomic,strong)UIScrollView *chartScrollView;
@property (nonatomic, retain) FYChartView *chartView;
@property (nonatomic, retain) NSMutableArray *values;
@property (nonatomic, strong) NSManagedObjectContext *context;
@property(nonatomic,strong)NSMutableArray *onLimit;
@property(nonatomic,strong)NSMutableArray *offLimit;
@property(nonatomic,strong) UIButton *modifyButton;
@end

#define ARC4RANDOM_MAX  0x100000000
@implementation BTHeightViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        //创建 IQKeyBoardManager的实例对象
        [IQKeyBoardManager installKeyboardManager];
        //注册通知 监控键盘的状态
        [IQKeyBoardManager enableKeyboardManger];
        
    }
    return self;
}
- (void)dealloc
{
    [IQKeyBoardManager disableKeyboardManager];
}
- (void)viewDidLoad
{
    [super viewDidLoad];
   
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.title = @"宫高";
    self.scrollView.scrollEnabled = NO;
    
    
    self.chartScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, 320, RED_BACKGROUND_HEIGHT)];
    _chartScrollView.contentSize = CGSizeMake(1200, 200);
    _chartScrollView.scrollEnabled = NO;
    _chartScrollView.backgroundColor = kGlobalColor;
    [self.scrollView addSubview:_chartScrollView];
    
    
    //配置数据
    
    self.values = [NSMutableArray arrayWithCapacity:1];
    self.values = [NSMutableArray arrayWithArray:[self configureDrawCharValue]];
    [self getOnLimitAndOffLimitArray];//得到上限 下限数组
    [self drawLineChartViewWithModelArray:self.values onLimit:self.onLimit offLimit:self.offLimit];
    
    //如果没有数据 拉出一个页面要求输入
    if ([self.values count] == 0) {
        [self performSelector:@selector(presentInputView) withObject:nil afterDelay:1.0];//延迟1秒模态出页面
    }
    
    
    //
    //体重
    BTView *weightView = [[BTView alloc] initWithFrame:CGRectMake(0, _chartScrollView.frame.origin.y + _chartScrollView.frame.size.height, 320, 112/2)];
    weightView.backgroundColor = [UIColor whiteColor];
    
    [self.scrollView addSubview:weightView];
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(weightView.frame.origin.x + 36/2, 10, 80, 30)];
    titleLabel.textColor = kBigTextColor;
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.textAlignment = NSTextAlignmentLeft;
    titleLabel.font = [UIFont systemFontOfSize:FIRST_TITLE_SIZE];
    titleLabel.text = @"目前宫高:";
    [weightView addSubview:titleLabel];
    
    self.weightField = [[UITextField alloc] initWithFrame:CGRectMake(titleLabel.frame.origin.x + titleLabel.frame.size.width, titleLabel.frame.origin.y, 170, 30)];
    _weightField.textColor = kContentTextColor;
    _weightField.backgroundColor = [UIColor clearColor];
    _weightField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    _weightField.keyboardType = UIKeyboardTypeDecimalPad;
    _weightField.returnKeyType = UIReturnKeyDone;
    _weightField.delegate = self;
    [[IQKeyBoardManager installKeyboardManager] setScrollView:self.scrollView];//监听键盘通知 改变scrollview的偏移量
    _weightField.font = [UIFont systemFontOfSize:SECOND_TITLE_SIZE];
    _weightField.text = [self getWeight];
    [weightView addSubview:_weightField];
    
    UILabel *kiloLabel = [[UILabel alloc] initWithFrame:CGRectMake(_weightField.frame.origin.x + _weightField.frame.size.width - 30, _weightField.frame.origin.y, 30, 30)];
    kiloLabel.textColor = kBigTextColor;
    kiloLabel.backgroundColor = [UIColor clearColor];
    kiloLabel.textAlignment = NSTextAlignmentLeft;
    kiloLabel.font = [UIFont systemFontOfSize:SECOND_TITLE_SIZE];
    kiloLabel.text = @"cm";
    [weightView addSubview:kiloLabel];
    
    
    //修改按钮
    self.modifyButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_modifyButton setBackgroundImage:[UIImage imageNamed:@"physical_edit_unselected"] forState:UIControlStateNormal];
    [_modifyButton addTarget:self action:@selector(modifyData:) forControlEvents:UIControlEventTouchUpInside];
    _modifyButton.frame = CGRectMake(320 - 15 - 48/2, (weightView.frame.size.height - 48/2)/2, 48/2, 48/2);
    [weightView addSubview:_modifyButton];
    
    //体重情况
    
    BTView *weightConditionView = [[BTView alloc] initWithFrame:CGRectMake(0, weightView.frame.origin.y + weightView.frame.size.height, 320, 170/2)];
    weightConditionView.backgroundColor = [UIColor whiteColor];
    
    [self.scrollView addSubview:weightConditionView];
    
    
    //是否正常label
    self.weightConditionLabel = [[UILabel alloc] initWithFrame:CGRectMake((320 - weightConditionView.frame.size.height)/2, 0, weightConditionView.frame.size.height, weightConditionView.frame.size.height)];
    _weightConditionLabel.textColor = kContentTextColor;
    _weightConditionLabel.backgroundColor = [UIColor clearColor];
    _weightConditionLabel.textAlignment = NSTextAlignmentLeft;
    _weightConditionLabel.font = [UIFont systemFontOfSize:40];
     [self updateConditionLabel:nil];
    [weightConditionView addSubview:_weightConditionLabel];
    
    
 	// Do any additional setup after loading the view.
}
#pragma mark - 得到上限和下限的数组
- (void)getOnLimitAndOffLimitArray
{
    self.onLimit = [NSMutableArray arrayWithCapacity:1];
    self.offLimit = [NSMutableArray arrayWithCapacity:1];
    NSMutableArray *array1 = [NSMutableArray arrayWithCapacity:1];
    for (int i = 20; i < 42; i ++) {
        [array1 addObject:[NSString stringWithFormat:@"%d",(i - 1)*7 + 1]];
    }
    
    NSArray *array2 = [NSArray arrayWithObjects:@"16",@"17",@"18",@"19",@"20",@"21",@"21.5",@"22.5",@"23",@"23.5",@"24",@"25",@"26",@"27",@"27.5",@"28.5",@"29.8",@"29.8",@"29.8",@"29.8",@"29.8",@"29.8", nil];
    
    NSArray *array3 = [NSArray arrayWithObjects:@"20.5",@"21.5",@"22.5",@"23.5",@"24.5",@"25.5",@"26.5",@"27.5",@"28.5",@"29.5",@"30.5",@"31.5",@"32.5",@"33.5",@"34.5",@"34.5",@"34.5",@"34.5",@"34.5",@"34.5",@"34.5",@"34.5", nil];
    
    for (int i = 0; i < 22; i ++) {
        BTPhysicalModel *modelOff = [[BTPhysicalModel alloc] initWithTitle:@"宫高" content:[array2 objectAtIndex:i] day:[array1 objectAtIndex:i]];
        [self.offLimit addObject:modelOff];
        BTPhysicalModel *modelOn = [[BTPhysicalModel alloc] initWithTitle:@"宫高" content:[array3 objectAtIndex:i] day:[array1 objectAtIndex:i]];
        [self.onLimit addObject:modelOn];
        
    }
    
}
#pragma mark - 如果是第一次进入此页面 木有数据 模态出输入数据页面
- (void)presentInputView
{
    
    
    BTPresentInputViewController *presentVC = [[BTPresentInputViewController alloc]
                                               initWithPresentInputTypeStyle:BTPresentInputFuntalHeight
                                               Complete:^(NSString *str1, NSString *str2, NSString *str3)
                                               {
                                                   [self updateUIWithValue:str1];
                                               }];
    self.nav = [[BTNavicationController alloc] initWithRootViewController:presentVC];
    presentVC.navigationItem.title = @"填写宫高";
    [self presentViewController:_nav animated:YES completion:nil];
}
#pragma mark - event
- (void)modifyData:(UIButton *)btn
{
    if ([btn.currentBackgroundImage isEqual:[UIImage imageNamed:@"physical_edit_unselected"]]) {
         [_weightField becomeFirstResponder];
        [btn setBackgroundImage:[UIImage imageNamed:@"edit_compeleted"] forState:UIControlStateNormal];
    }
    else{
        [btn setBackgroundImage:[UIImage imageNamed:@"physical_edit_unselected"] forState:UIControlStateNormal];
        [self updateUIWithValue:_weightField.text];
        [self writeToCoredataWithWeight:_weightField.text];
        [_weightField resignFirstResponder];
    }
   
}

#pragma mark - 增加代码的鲁棒性 在此只允许输入数字和小数点
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    
    NSCharacterSet *cs;
    cs = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789.\n"] invertedSet];
    //NUMBERS在这里指@“0123456789\n”
    NSString *filtered = [[string componentsSeparatedByCharactersInSet:cs] componentsJoinedByString:@""]; //按cs分离出数组,数组按@""分离出字符串
    
    BOOL canChange = [string isEqualToString:filtered];
    
    if(!canChange)
    {
        UIAlertView * alertview = [[UIAlertView alloc]initWithTitle:@"提示" message:@"这里只能输入数字" delegate:self cancelButtonTitle:nil otherButtonTitles:@"我知道了", nil ,nil];
        [alertview show];
    }
    return canChange;
}
#pragma mark - 开始编辑
- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    if ([_modifyButton.currentBackgroundImage isEqual:[UIImage imageNamed:@"physical_edit_unselected"]]) {
        
        [_modifyButton setBackgroundImage:[UIImage imageNamed:@"edit_compeleted"] forState:UIControlStateNormal];
    }
    else{
        [_modifyButton setBackgroundImage:[UIImage imageNamed:@"physical_edit_unselected"] forState:UIControlStateNormal];
        
    }
    
    

}
#pragma mark - 按键盘retrn 键之后触发的方法
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    
    NSLog(@"====+++++++++%@",textField.text);
    
    [self updateUIWithValue:textField.text];
    [self writeToCoredataWithWeight:textField.text];
    
    
    return YES;
}

#pragma mark - 更新页面UI
- (void)updateUIWithValue:(NSString *)weight
{
    //更新折线图和页面显示
    //1）更新折线
    if (self.chartView) {
        [self.chartView removeFromSuperview];
    }
    //改变self.values 的值即可
    NSDate *localDate = [NSDate localdate];
    NSNumber *year = [BTUtils getYear:localDate];
    NSNumber *month = [BTUtils getMonth:localDate];
    NSNumber *dayLocal = [BTUtils getDay:localDate];
    NSDate *gmtDate = [NSDate dateFromString:[NSString stringWithFormat:@"%@.%@.%@",year,month,dayLocal] withFormat:@"yyyy.MM.dd"];
    
    //算出怀孕第几天
    int day = [BTGetData getPregnancyDaysWithDate:gmtDate];
    BTPhysicalModel *model = [[BTPhysicalModel alloc] initWithTitle:@"宫高" content:weight day:[NSString stringWithFormat:@"%d",day]];
    BTPhysicalModel *model1 = [self.values lastObject];
    if (day == [model1.day intValue]) {
        
        [self.values replaceObjectAtIndex:[self.values count]-1 withObject:model];
    }
    else
    {
        [self.values addObject:model];
    }
    [self drawLineChartViewWithModelArray:self.values onLimit:self.onLimit offLimit:self.offLimit];
    
    //2)更新"正常 异常显示"
    self.weightField.text = weight;
    [self updateConditionLabel:weight];
    
}
#pragma mark - 判断数据是否正常
- (void)updateConditionLabel:(NSString *)weight
{
     //如果weight有值，就不要再从coredata里取 提高效率
    if (weight) {
        NSDate *localDate = [NSDate localdate];
        
        int day1 = [BTGetData getPregnancyDaysWithDate:localDate];//怀孕天数
        
        if ((day1/7 + 1 >= 20) && (day1/7 + 1 <= 40)) {
            [self judgeConditionWithDay:day1 weight:weight];

        }
        else{
            
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:FUNDAL_HEIGHT_CONDITION];
            [[NSUserDefaults standardUserDefaults] synchronize];
            self.weightConditionLabel.hidden = YES;
        }
    }
        
    else{
        NSArray *dataArray = [self getNewdataFromCoredata];
        if (dataArray.count > 0) {
            BTUserData * one = [dataArray lastObject];
            NSDate *lastDate = [NSDate dateFromString:[NSString stringWithFormat:@"%@.%@.%@",one.year,one.month,one.day] withFormat:@"yyyy.MM.dd"];
            
            int day1 = [BTGetData getPregnancyDaysWithDate:lastDate];//怀孕天数
            
            if ((day1/7 + 1 >= 20) && (day1/7 + 1 <= 40)) {
                [self judgeConditionWithDay:day1 weight:one.fundalHeight];
                
            }
            else{
                
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:FUNDAL_HEIGHT_CONDITION];
                [[NSUserDefaults standardUserDefaults] synchronize];
                self.weightConditionLabel.hidden = YES;
            }

        }

    }
    
}

- (void)judgeConditionWithDay:(int)day1 weight:(NSString *)weight
{
    
    self.weightConditionLabel.hidden = NO;
    float onLimit = 0.0;
    float offLimit = 0.0;
    float now = 0.0;

    
    for (int i = 0; i < [self.onLimit count]; i ++) {
        BTPhysicalModel *modelOn = [self.onLimit objectAtIndex:i];
        if (([modelOn.day intValue]/7 + 1) == (day1/7 + 1)) {
            if (i < [self.onLimit count] - 1) {
                BTPhysicalModel *nextModel =  [self.onLimit objectAtIndex:i+1];
                onLimit = (([nextModel.content floatValue] - [modelOn.content floatValue])/6) * (day1 - [modelOn.day intValue]) +[modelOn.content floatValue];
            }
            else{
                onLimit = [modelOn.content floatValue];
            }
        }
    }
    
    
    
    for (int i = 0; i < [self.offLimit count]; i ++) {
        BTPhysicalModel *modelOff = [self.offLimit objectAtIndex:i];
        if (([modelOff.day intValue]/7 + 1) == (day1/7 + 1)) {
            if (i < [self.offLimit count] - 1) {
                BTPhysicalModel *nextModel =  [self.offLimit objectAtIndex:i+1];
                offLimit = (([nextModel.content floatValue] - [modelOff.content floatValue])/6) * (day1 - [modelOff.day intValue]) +[modelOff.content floatValue];
            }
            else{
                offLimit = [modelOff.content floatValue];
            }
        }
    }
    
    
    now = [weight floatValue];
    
    
    if (now >= offLimit && now <= onLimit) {
        self.weightConditionLabel.text = @"正常";
        self.weightConditionLabel.textColor = kBigTextColor;
        //将结果写入userdefault中
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:FUNDAL_HEIGHT_CONDITION];
        [[NSUserDefaults standardUserDefaults] synchronize];

    }
    else{
        self.weightConditionLabel.text = @"异常";
        self.weightConditionLabel.textColor = kGlobalColor;
        //将结果写入userdefault中
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:FUNDAL_HEIGHT_CONDITION];
        [[NSUserDefaults standardUserDefaults] synchronize];

    }

}
#pragma mark - 往coredata里面写入数据
- (void)writeToCoredataWithWeight:(NSString *)height
{
    
    NSDate *localDate = [NSDate localdate];
    NSNumber *year = [BTUtils getYear:localDate];
    NSNumber *month = [BTUtils getMonth:localDate];
    NSNumber *day = [BTUtils getDay:localDate];
    _context = [BTGetData getAppContex];
    //设置查询条件
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"year == %@ AND month == %@ AND day == %@",year, month, day];
    NSError *error;
    NSArray *dataArray = [BTGetData getFromCoreDataWithPredicate:predicate entityName:@"BTUserData" sortKey:nil];
    
    if (dataArray.count == 1) {
        
        //已经有条目了
        //进行coredata的更改数据操作
        BTUserData* one = [dataArray objectAtIndex:0];
        one.fundalHeight = height;
        
        
    }else if(dataArray.count == 0){
        
        //木有啊,就新建一条  进行coredata的插入数据操作
        
        NSLog(@"there no");
        
        BTUserData* new = [NSEntityDescription insertNewObjectForEntityForName:@"BTUserData" inManagedObjectContext:_context];
        
        new.year = year;
        new.month = month;
        new.day = day;
        new.fundalHeight = height;
 
    }
    
    [_context save:&error];
    // 及时保存
    if(![_context save:&error]){
        NSLog(@"%@", [error localizedDescription]);
    }
    
}

#pragma mark - 得到绘制折线用的数据
- (NSArray *)configureDrawCharValue
{
    NSMutableArray *resultArray = [NSMutableArray arrayWithCapacity:1];
    NSArray *array = [self getNewdataFromCoredata];
    for (BTUserData *one in array) {
        
        NSDate *date = [NSDate dateFromString:[NSString stringWithFormat:@"%@.%@.%@",one.year,one.month,one.day] withFormat:@"yyyy.MM.dd"];
        //算出怀孕第几天
        int day = [BTGetData getPregnancyDaysWithDate:date];
        BTPhysicalModel *model = [[BTPhysicalModel alloc] initWithTitle:@"宫高" content:one.fundalHeight day:[NSString stringWithFormat:@"%d",day]];
        [resultArray addObject:model];
        
    }
    
    return resultArray;
}

#pragma mark - 从coredata 里面取数据
- (NSArray *)getNewdataFromCoredata
{
    NSMutableArray *weightArray = [NSMutableArray arrayWithCapacity:1];
    NSDictionary *sortDic = [[NSDictionary alloc] initWithObjectsAndKeys:@"year",@"sortkey1",@"month",@"sortkey2",@"day",@"sortkey3", nil];
    NSArray *dataArray = [BTGetData getFromCoreDataWithPredicate:nil entityName:@"BTUserData" sortKey:sortDic];
    if (dataArray.count > 0) {
        for (BTUserData *userData in dataArray) {
            if (userData.fundalHeight) {
                [weightArray addObject:userData];
            }
        }
        return weightArray;
    }
    
    
    return nil;
}

- (NSString *)getWeight
{
    
    NSArray *dataArray = [self getNewdataFromCoredata];
    if (dataArray.count > 0) {
        BTUserData * one = [dataArray lastObject];
        
        return one.fundalHeight;
        
    }
    
    
    return [NSString stringWithFormat:@"%@",@"还未记录"];
    
    
}

#pragma mark - 绘制折线图
- (void)drawLineChartViewWithModelArray:(NSArray *)array onLimit:(NSArray *)onLimit offLimit:(NSArray *)offLimit
{
    
    self.chartView = [[FYChartView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 1200.0f, RED_BACKGROUND_HEIGHT)];
    self.chartView.hideDescriptionViewWhenTouchesEnd = YES;
    self.chartView.backgroundColor = kGlobalColor;
    self.chartView.rectangleLineColor = [UIColor grayColor];
    self.chartView.lineColor = [UIColor whiteColor];
    self.chartView.dataSource = self;
    self.chartView.style = BTChartFuntalHeight;
    self.chartView.onLimit = onLimit;
    self.chartView.offLimit = offLimit;
    self.chartView.modelArray = array;
    
    //在图标上添加手势 取消键盘
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closeKeyboard:)];
    [self.chartView addGestureRecognizer:tap];
    [self.chartScrollView addSubview:self.chartView];
    
}
#pragma mark - 关闭键盘
- (void)closeKeyboard:(UITapGestureRecognizer *)tap
{
    
//    if ([_weightField isFirstResponder]) {
//        [_weightField resignFirstResponder];
//    }
}



#pragma mark - FYChartViewDataSource

//number of value count
- (NSInteger)numberOfValueItemCountInChartView:(FYChartView *)chartView;
{
    //return self.values ? self.values.count : 0;
    return 20;
}


//horizontal title alignment at index
- (HorizontalTitleAlignment)chartView:(FYChartView *)chartView horizontalTitleAlignmentAtIndex:(NSInteger)index
{
    HorizontalTitleAlignment alignment = HorizontalTitleAlignmentCenter;
    if (index == 0)
    {
        alignment = HorizontalTitleAlignmentCenter;
    }
    else if (index == self.values.count - 1)
    {
        alignment = HorizontalTitleAlignmentRight;
    }
    
    return alignment;
}

//description view at index
- (UIView *)chartView:(FYChartView *)chartView descriptionViewAtIndex:(NSInteger)index model:(BTPhysicalModel *)model
{
    
    
    //显示第几周第几周第几天 体重
    int week = [model.day intValue]%7 == 0  ? [model.day intValue]/7 : ([model.day intValue]/7 + 1);
    int day = [model.day intValue]%7 == 0 ? 7 : [model.day intValue]%7;
    
    //如何根据 index找到model
    NSString *description = [NSString stringWithFormat:@"孕%d周%d天\n %0.1fcm", week,day,[model.content floatValue]];
    
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"markview_ba_middle"]];
    imageView.frame = CGRectMake(0,0, 91/2, 85/2);
    // imageView.backgroundColor = [UIColor redColor];
    CGRect frame = imageView.frame;
    frame.size = CGSizeMake(80.0f, 40.0f);
    imageView.frame = frame;
    UILabel *label = [[UILabel alloc]
                      initWithFrame:CGRectMake(10.0f, -5.0f, imageView.frame.size.width, imageView.frame.size.height)];
    
    label.backgroundColor = [UIColor clearColor];
    label.textColor = kGlobalColor;
    label.text = description;
    label.numberOfLines = 0;
    label.font = [UIFont systemFontOfSize:10.0f];
    [imageView addSubview:label];
    
    return imageView;
    
    //  return nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
