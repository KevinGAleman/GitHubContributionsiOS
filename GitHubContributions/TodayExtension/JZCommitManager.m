//
//  JZCommitManager.m
//  GitHubContributions
//
//  Created by Fincher Justin on 16/9/11.
//  Copyright © 2016年 JustZht. All rights reserved.
//

#define UIColorFromRGB(rgbValue) \
[UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
green:((float)((rgbValue & 0x00FF00) >>  8))/255.0 \
blue:((float)((rgbValue & 0x0000FF) >>  0))/255.0 \
alpha:1.0]

#import "JZCommitManager.h"
#import "JZCommitDataModel.h"
#import "DateTools.h"


@interface JZCommitManager()
@property (nonatomic,strong) NSDateFormatter* formatter;
@end

@implementation JZCommitManager


#pragma mark Singleton Methods

+ (id)sharedManager {
    static JZCommitManager *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (id)init {
    if (self = [super init]) {
        _commits = [NSMutableArray array];
        _formatter =  [[NSDateFormatter alloc] init];
        [_formatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
        [_formatter setDateFormat:@"yyyy-MM-dd"];
    }
    return self;
}

- (void)dealloc {
    // Should never be called, but just here for clarity really.
}

#pragma mark Web Task
- (NSMutableArray *)refresh
{
    [_commits removeAllObjects];
    NSString *name = [[[NSUserDefaults alloc] initWithSuiteName:@"group.com.KevinAleman.GitHubContributions"]  objectForKey:@"GitHubContributionsName"];
    
    if (name == nil)
    {
        return nil;
    }
    
    NSMutableArray *tempArray = [NSMutableArray array];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://github.com/users/%@/contributions",name]];
    NSString *webData= [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
    NSRange   searchedRange = NSMakeRange(0, [webData length]);
    NSString *pattern = @"(fill=\")(#[^\"]{6})(\" data-count=\")([^\"]{1,})(\" data-date=\")([^\"]{10})(\"/>)";
    NSError  *error = nil;
    NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern: pattern options:0 error:&error];
    NSArray* matches = [regex matchesInString:webData options:0 range: searchedRange];
    for (NSTextCheckingResult* match in matches)
    {
        NSString *color = [webData substringWithRange:[match rangeAtIndex:2]];
//        NSLog( @"%@",color);
        NSString *data = [webData substringWithRange:[match rangeAtIndex:4]];
//        NSLog( @"%@",data);
        NSString *date = [webData substringWithRange:[match rangeAtIndex:6]];
//        NSLog( @"%@",date);
        
        JZCommitDataModel *oneDayCommit = [[JZCommitDataModel alloc] init];
        oneDayCommit.color = [JZCommitManager colorFromHexString:color];
        oneDayCommit.dataCount = [NSNumber numberWithInt:[data intValue]];
        oneDayCommit.date = [_formatter dateFromString: date];
        oneDayCommit.weekDay =  [NSNumber numberWithInteger:oneDayCommit.date.weekday];
        oneDayCommit.month =  [NSNumber numberWithInteger:oneDayCommit.date.month];
        
        [tempArray addObject:oneDayCommit];
    }
    
    NSInteger tempArrayLength = [tempArray count] - 1;
    JZCommitDataModel * today = (JZCommitDataModel *)[tempArray lastObject];
    
    NSInteger weekDay = today.date.weekday;
    NSMutableArray * thisWeekArray = [NSMutableArray array];
    for (int weekDayIndex = 1; weekDayIndex <= weekDay; weekDayIndex ++)
    {
        [thisWeekArray addObject:[tempArray objectAtIndex:tempArrayLength - weekDay + weekDayIndex]];
    }
    [_commits addObject:thisWeekArray];
    
    for (int weekFromNow = 0; weekFromNow < 50; weekFromNow ++)
    {
        NSMutableArray * thatWeekArray = [NSMutableArray array];
        for (int weekDayIndex = 1; weekDayIndex <= 7; weekDayIndex ++)
        {
            [thatWeekArray addObject:[tempArray objectAtIndex:tempArrayLength - weekDay - weekFromNow * 7 - 7  + weekDayIndex]];
        }
        [_commits addObject:thatWeekArray];
    }
    return _commits;
}

- (NSMutableArray *)getCommits
{
    return _commits;
}

#pragma mark Helper
+ (UIColor *)colorFromHexString:(NSString *)hexString {
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    [scanner setScanLocation:1]; // bypass '#' character
    [scanner scanHexInt:&rgbValue];
    float red= ((rgbValue & 0xFF0000) >> 16)/255.0;
    float green = ((rgbValue & 0xFF00) >> 8)/255.0 ;
    float blue = (rgbValue & 0xFF)/255.0 ;
//    float alpha = 1.0 - (red + blue) / 5;
//    UIColor *color = [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
    return [UIColor colorWithRed:red green:green blue:blue alpha:1.0];
}

@end
