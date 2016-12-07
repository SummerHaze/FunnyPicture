//
//  HomeViewController.m
//  FunnyPicture
//
//  Created by xia on 12/5/16.
//  Copyright © 2016 xia. All rights reserved.
//

#import "HomeViewController.h"
#import "OCGumbo.h"
#import "OCGumbo+Query.h"
#import "SummaryCell.h"
#import "PostDetailViewController.h"

static NSString * const HomeURL = @"http://www.qingniantuzhai.com/home";
static NSString * const PostURLPrefix = @"http://www.qingniantuzhai.com/posts/";
static NSString * const SummaryCellIdentifier = @"SummaryCell";
static NSString * const seperator = @"青年图摘";

@interface HomeViewController ()

@property (nonatomic, weak) IBOutlet UISearchBar *searchBar;
@property (nonatomic, weak) IBOutlet UITableView *tableView;
//@property (nonatomic, weak) IBOutlet UINavigationBar *navigationBar;

@end

@implementation HomeViewController
{
    NSMutableArray *titles; // 每日推送帖子主标腿
    NSMutableArray *links; // 每日推送帖子链接
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // AppDelegate中已经实例化了UINavigationController，这里直接设置其属性即可，不需要再重新创建一个新的！
    [self.navigationItem setTitle:@"首页"];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"清缓存"
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:self
                                                                                action:@selector(clearCache)];
    
    [self fetchPostInfo];
    
    UINib *cellNib = [UINib nibWithNibName:SummaryCellIdentifier bundle:nil];
    [self.tableView registerNib:cellNib forCellReuseIdentifier:SummaryCellIdentifier];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)fetchPostInfo {
    NSURL *url = [NSURL URLWithString:HomeURL];
    NSError *error;
    NSString *htmlString = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&error];
    
    OCGumboDocument *document = [[OCGumboDocument alloc] initWithHTMLString:htmlString];
    
    // 解析出每个帖子名称
    OCQueryObject *queryResult = document.Query(@"body").find(@".col-md-7");
    NSString *titleString = queryResult.find(@"h5").find(@"strong").text();   // 最近20篇帖子的标题string
    NSArray *tmp= [titleString componentsSeparatedByString:seperator]; // 去除了seperator的字符串array
    titles = [[NSMutableArray alloc]init];
    
    for (NSString *element in tmp) {
        if ([element length] != 0) {
            NSString *title = [NSString stringWithFormat:@"%@%@", seperator, element];
            [titles addObject:title]; // 加上seperator，去除空字符
        }
    }
    
    // 解析出每个帖子的链接，注意符合格式“www.qingniantuzhai.com/posts/3126.html”的URL才可以被正确解析
    // 帖子的最后4位数字规则递增，每天增1
    // 应该用一个灵活性更高的方法，而不是写死长度，待修改——summ
    NSString *latestUrlString = queryResult.find(@"a").first().attr(@"href"); // 最新帖子的href
    NSString *urlPrefix;
    NSInteger index;
    if ([latestUrlString hasSuffix:@".html"]) {
        NSRange range;
        range.location = [latestUrlString length] - 9;
        range.length = 4;
        urlPrefix = [latestUrlString substringToIndex:([latestUrlString length] - 9)];
        index = [latestUrlString substringWithRange:range].integerValue;
    }
    links = [[NSMutableArray alloc]init];
    for (NSInteger i = index; i > index-20; i--) {
        [links addObject:[NSString stringWithFormat:@"%@%ld.html", urlPrefix, (long)i]];
    }
    
    // 将每篇帖子的标题与链接保存到数据库中
    [self saveToDB];
}

- (void)saveToDB {
    
}

#pragma mark - Table view datasource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [titles count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SummaryCell *cell = (SummaryCell *)[tableView dequeueReusableCellWithIdentifier:SummaryCellIdentifier];
    
    if ([titles count] > 0) {
        NSString *postTitle = titles[indexPath.row];
        cell.titleLabel.text = postTitle;
    }
    
    return cell;
}

#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    PostDetailViewController *controller = [[PostDetailViewController alloc]initWithNibName:@"PostDetailViewController" bundle:nil];
    controller.postUrl = links[indexPath.row];
    
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)clearCache {
    NSString *path = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingString:[NSString stringWithFormat:@"/images/"]];
    BOOL result = [self deleteFileByPath:path];
    NSLog(@"清除缓存：%d", result);
}


-(BOOL)deleteFileByPath:(NSString *)path{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDeleted = [fileManager removeItemAtPath:path error:nil];
    return isDeleted;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
