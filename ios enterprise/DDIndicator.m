//
//  DDIndicator.h
//  loading
//
//  Created by wangpeng on 1/11/13.
//  Copyright (c) 2013 wangpeng. All rights reserved.
//

#import "DDIndicator.h"
#import <QuartzCore/QuartzCore.h>
#import "math.h"

static int stage = 0;

@interface DDIndicator ()
@property (nonatomic, strong) NSTimer *timer;
@end
@implementation DDIndicator
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor clearColor];
        
        self.contentLabel = [[UILabel alloc] initWithFrame:CGRectMake(-35, self.frame.size.height, 120, 20)];
        _contentLabel.backgroundColor = [UIColor clearColor];
        _contentLabel.textAlignment = NSTextAlignmentCenter;
        _contentLabel.text = @"正在搜索设备";//默认值 可灵活改变
        [self addSubview:_contentLabel];

    }
    return self;
    
}

-(void) test
{
    
}
-(void) startAnimating
{
    self.superview.userInteractionEnabled = NO;//父视图交互关闭  也可以在背后加一个灰色的view遮挡
    if (!self.timer.isValid) {
        self.timer =[NSTimer timerWithTimeInterval:0.1 target:self selector:@selector(setNeedsDisplay) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
    }
    
    self.hidden = NO;
    
    
    stage++;
}
-(void) stopAnimating
{
    self.superview.userInteractionEnabled = YES;//父视图交互打开

    self.hidden = YES;
    [self.timer invalidate];
}
-(UIColor *) getColorForStage:(int) currentStage WithAlpha:(double) alpha
{
    int max = 20;
    int cycle = currentStage % max;

    if (cycle < max/4) {
        return [UIColor colorWithRed:66.0/255.0 green:72.0/255.0 blue:101.0/255.0 alpha:alpha];
    } else if (cycle < max/4*2) {
        return [UIColor colorWithRed:238.0/255.0 green:90.0/255.0 blue:40.0/255.0 alpha:alpha];
    } else if (cycle < max/4*3) {
        return [UIColor colorWithRed:33.0/255.0 green:31.0/255.0 blue:31.0/255.0 alpha:alpha];
        
    } else  {
        return [UIColor colorWithRed:251.0/255.0 green:184.0/255.0 blue:18.0/255.0 alpha:alpha];
    } 
    
}
-(CGPoint) pointOnInnerCirecleWithAngel:(int) angel
{
    double r = self.frame.size.height/2/2;
    double cx = self.frame.size.width/2;
    double cy = self.frame.size.height/2;
    double x = cx + r*cos(M_PI/10*angel);
    double y = cy + r*sin(M_PI/10*angel);
    return CGPointMake(x, y);
}
-(CGPoint) pointOnOuterCirecleWithAngel:(int) angel
{
    double r = self.frame.size.height/2;
    double cx = self.frame.size.width/2;
    double cy = self.frame.size.height/2;
    double x = cx + r*cos(M_PI/10*angel);
    double y = cy + r*sin(M_PI/10*angel);
    return CGPointMake(x, y);
}

-(void) drawRect:(CGRect)rect
{
    CGPoint point;
   
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(ctx, 2.0);
    
    for (int i = 1 ; i<=10; ++i) {
    
    
        CGContextSetStrokeColorWithColor(ctx, [[self getColorForStage:stage+i WithAlpha:0.1 *i] CGColor]);
        point = [self pointOnOuterCirecleWithAngel:stage+i];
        CGContextMoveToPoint(ctx, point.x, point.y);
        point = [self pointOnInnerCirecleWithAngel:stage+i];
        CGContextAddLineToPoint( ctx, point.x, point.y);
        CGContextStrokePath(ctx);
    }
    
 
    
    stage++;
}


@end
