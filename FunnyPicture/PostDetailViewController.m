//
//  PostDetailViewController.m
//  FunnyPicture
//
//  Created by xia on 12/5/16.
//  Copyright © 2016 xia. All rights reserved.
//

#import "PostDetailViewController.h"
#import "DetailCell.h"
#import "ImageCell.h"
#import "OCGumbo.h"
#import "OCGumbo+Query.h"

#define DETAIL_MARGIN 48
#define IMAGE_MARGIN 16

static NSString * const DetailCellIdentifier = @"DetailCell";
static NSString * const ImageCellIdentifier = @"ImageCell";
static NSString * const LoadingCellIdentifier = @"LoadingCell";

@interface PostDetailViewController ()

@property (nonatomic, weak) IBOutlet UITableView *tableView;

@end

@implementation PostDetailViewController
{
    NSMutableArray *postDetail;
    NSMutableArray *rearrangedPost;
    NSMutableArray *imageUrls;
    NSMutableArray *downloadedImages;
    CGFloat width;
    BOOL isDownloaded;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.navigationController setTitle:@"图摘详情"];
    self.tableView.rowHeight = 300;
//    width = self.tableView.bounds.size.width; // 该宽度受xib文件中的机型屏幕影响
    width = [UIApplication sharedApplication].statusBarFrame.size.width;
    isDownloaded = NO;
    
    UINib *cellNib = [UINib nibWithNibName:DetailCellIdentifier bundle:nil];
    [self.tableView registerNib:cellNib forCellReuseIdentifier:DetailCellIdentifier];
    
    cellNib = [UINib nibWithNibName:ImageCellIdentifier bundle:nil];
    [self.tableView registerNib:cellNib forCellReuseIdentifier:ImageCellIdentifier];
    
    cellNib = [UINib nibWithNibName:LoadingCellIdentifier bundle:nil];
    [self.tableView registerNib:cellNib forCellReuseIdentifier:LoadingCellIdentifier];
    
    [self fetchPostInfo];
    
    [self createDirInCaches:@"images"];
    
    imageUrls = [self obtainImageNames:postDetail]; // 解析出当篇帖子中所有图片下载Url
    downloadedImages = [self getAllImagesInPath:[self getImageDir]];

    [self downloadImage:imageUrls];
}

- (void)fetchPostInfo {
    NSURL *url = [NSURL URLWithString:self.postUrl];
    NSError *error;
    NSString *htmlString = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&error];
    
    OCGumboDocument *document = [[OCGumboDocument alloc] initWithHTMLString:htmlString];
    OCQueryObject *queryResult = document.Query(@"body").find(@".post-content").find(@"p"); // OCGumboElement数组
    NSMutableArray *tmp = [[NSMutableArray alloc] init];
    for (OCGumboNode *node in queryResult) {
        if ([node.childNodes[0] isKindOfClass:[OCGumboText class]]) {
            // 图片配文
            OCGumboText *text = (OCGumboText *)node.childNodes[0];
            NSString *desc = text.data;
            if ((desc.length > 0) && [self containNumber:desc]) {
                [tmp addObject:desc];
            }
        } else if ([node.childNodes[0] isKindOfClass:[OCGumboElement class]]) {
            // 图片链接
            OCGumboElement *element = (OCGumboElement *)node.childNodes[0];
            NSString *url = element.attr(@"data-src");
            if ([url length] > 0) {
                [tmp addObject:url];
            }
        }
    }
    postDetail = [self parsePostFromArray:tmp];
    rearrangedPost = [self rearrangePostFromArray:tmp];
}

- (NSMutableArray *)obtainImageNames:(NSArray *)array {
    NSMutableArray *names = [[NSMutableArray alloc] init];
    for (int i = 0; i < [array count]; i++) {
        NSArray *arr = [array[i] objectForKey:@"imageUrls"];
        for (NSString *str in arr) {
//            NSString *name = [str componentsSeparatedByString:@"/"].lastObject;
//            if (name) {
            [names addObject:str];
//            }
        }
    }
    return names;
}

- (NSMutableArray *)parsePostFromArray:(NSArray *)arr {
    NSMutableArray *detail = [[NSMutableArray alloc] initWithCapacity:1]; // 最外层数组
    for (int i = 0; i < [arr count]; i++) {
        NSMutableArray *tmpUrls = [[NSMutableArray alloc] initWithCapacity:1]; // url数组
        NSMutableDictionary *tmpSingleDetail = [[NSMutableDictionary alloc] initWithCapacity:1]; // 单条字典
        if (![arr[i] containsString:@"http"]) { // 标题
            [tmpSingleDetail setObject:arr[i] forKey:@"title"];
            i++;
            while ([arr[i] containsString:@"http"]) {
                [tmpUrls addObject:arr[i]];
                if (i >= [arr count] - 1) {
                    break;
                } else {
                    i++;
                }
            }
            [tmpSingleDetail setObject:tmpUrls forKey:@"imageUrls"];
            [detail addObject:tmpSingleDetail];
            
            i--;
        }
    }
    return detail;
}

- (NSMutableArray *)rearrangePostFromArray:(NSArray *)arr {
    NSMutableArray *post = [[NSMutableArray alloc] initWithCapacity:1]; // 最外层数组
    NSMutableArray *tmpArr;
    for (int i = 0; i < [arr count]; i++) {
        if (![arr[i] containsString:@"http"]) { // 标题
            tmpArr = [[NSMutableArray alloc] init];
            [tmpArr addObject:arr[i]];
        } else {
            if ([tmpArr count] == 1) {
                [tmpArr addObject:arr[i]];
                [post addObject:tmpArr];
            } else {
                [post addObject:arr[i]];
            }
        }
    }
    return post;
}

// str中是否包含阿拉伯数字0～9
- (NSInteger)containNumber:(NSString *)str {
    //数字条件
    NSRegularExpression *tNumRegularExpression = [NSRegularExpression regularExpressionWithPattern:@"[0-9]" options:NSRegularExpressionCaseInsensitive error:nil];
    
    //符合数字条件的有几个字节
    NSUInteger count = [tNumRegularExpression numberOfMatchesInString:str
                                                              options:NSMatchingReportProgress
                                                                range:NSMakeRange(0, str.length)];
    return count;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view datasource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (isDownloaded) {
        return [rearrangedPost count];
    } else {
        return 1;
    }
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (isDownloaded) {
        NSString *path;
        CGSize size;
        
        if ([rearrangedPost[indexPath.row] isKindOfClass:[NSArray class]]) {
            NSArray *arr = rearrangedPost[indexPath.row];
            NSString *name = [arr.lastObject componentsSeparatedByString:@"/"].lastObject;
            path = [NSString stringWithFormat:@"%@%@", [self getImageDir], name];
            UIImage *image = [UIImage imageWithContentsOfFile:path];
            size = image.size;
            CGFloat scale = size.width/width;
            CGFloat cellHeight = size.height/MAX(scale, 1);
            if (cellHeight <= 300) {
                return cellHeight + DETAIL_MARGIN;
            } else {
                return cellHeight;
            }
        } else {
            NSString *str = rearrangedPost[indexPath.row];
            NSString *name = [str componentsSeparatedByString:@"/"].lastObject;
            path = [NSString stringWithFormat:@"%@%@", [self getImageDir], name];
            UIImage *image = [UIImage imageWithContentsOfFile:path];
            size = image.size;
            CGFloat scale = size.width/width;
            CGFloat cellHeight = size.height/MAX(scale, 1);
            if (cellHeight <= 300) {
                return cellHeight + IMAGE_MARGIN;
            } else {
                return cellHeight;
            }
        }
    } else {
        return 80;
    }

}

#pragma mark - Table view delegate
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (isDownloaded) {
        NSArray *elements;
        NSUInteger count;
        NSString *singleUrl;
        
        if ([rearrangedPost[indexPath.row] isKindOfClass:[NSArray class]]) {
            elements = rearrangedPost[indexPath.row];
            count = [elements count];
        } else {
            singleUrl = rearrangedPost[indexPath.row];
            count = 1;
        }
        
        if (count == 2) {
            // 一条图文底下只有一张图片,用一个DetailCell即可
            DetailCell *cell = (DetailCell *)[tableView dequeueReusableCellWithIdentifier:DetailCellIdentifier];
            cell.title.text = elements[0];
            
            NSString *name = [elements[1] componentsSeparatedByString:@"/"].lastObject;
            UIImage *image = [self getImageByName:name];
            
            [cell.imageView setImage:image];
            
            return cell;
        } else {
            ImageCell *cell = (ImageCell *)[tableView dequeueReusableCellWithIdentifier:ImageCellIdentifier];
            
            NSString *name = [singleUrl componentsSeparatedByString:@"/"].lastObject;
            UIImage *image = [self getImageByName:name];
            
            [cell.imageView setImage:image];
            
            return cell;
        }
    } else {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:LoadingCellIdentifier forIndexPath:indexPath];
        UIActivityIndicatorView *spinner = (UIActivityIndicatorView *)[cell viewWithTag:100];
        [spinner startAnimating];
        
        return cell;
    }

}

// 图片下载
- (void)downloadImage:(NSArray *)urls {
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    dispatch_group_async(group, queue, ^{
        for (NSString *str in urls) {
//            NSUInteger index = [rearrangedPost indexOfObject:str];
//            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
            NSLog(@"downloading url: %@", str);
            NSURL *url = [NSURL URLWithString:str];
            NSString *imageName = [str componentsSeparatedByString:@"/"].lastObject;
            
            if (![downloadedImages containsObject:imageName]) { // 未下载过
                NSData *data = [NSData dataWithContentsOfURL:url];
                UIImage *image = [UIImage imageWithData:data];
                NSString *imagePath = [self obetainImagePathInCaches:@"images" imageName:imageName];
                NSData *imgData = UIImagePNGRepresentation(image);
                
                NSError *error;
                BOOL success = [imgData writeToFile:imagePath options:NSDataWritingAtomic error:&error];
                if (success) {
                    [downloadedImages addObject:imageName];
                } else {
                    NSLog(@"Download Image Error: %@", error);
                }
            }
        }
    });
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        isDownloaded = YES;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    });
}


#pragma mark - Handle dirs and files in sandbox
// 获取某路径下面的所有文件
- (NSMutableArray *)getAllImagesInPath:(NSString *)path
{
    NSLog(@"image path: %@",path);
    NSFileManager *defaultManager = [NSFileManager defaultManager];
    NSArray *array = [defaultManager contentsOfDirectoryAtPath:path error:nil];
    return array;
}

// 获取image存储在Caches中的绝对路径
- (NSString *)obetainImagePathInCaches:(NSString *)dir imageName:(NSString *)image{
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *imagePath = [path stringByAppendingString:[NSString stringWithFormat:@"/%@/%@", dir, image]];
    return imagePath;
}

// 在Caches中创建新目录
- (BOOL)createDirInCaches:(NSString *)dirName {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cachesDirectory = [paths objectAtIndex:0];
    NSString *path = [NSString stringWithFormat:@"%@/%@", cachesDirectory, dirName];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir;
    if (![fileManager fileExistsAtPath:path isDirectory:&isDir]) { //先判断目录是否存在，不存在才创建
        BOOL success = [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
        if (success) {
            return YES;
        } else {
            return NO;
        }
    } else {
        return NO;
    }
}

- (NSString *)getImageDir {
    return [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingString:[NSString stringWithFormat:@"/images/"]];
}

- (UIImage *)getImageByName:(NSString *)name {
    NSString *path = [NSString stringWithFormat:@"%@%@", [self getImageDir], name];
    NSData *data = [NSData dataWithContentsOfFile:path];
    UIImage *image = [UIImage imageWithData:data scale:1.0];
    if (image != nil) {
        return image;
    } else {
        return nil;
    }
}

- (UIImage *)scaleImage:(UIImage *)img toScale:(CGFloat)scale {
    // 图片原始size
    CGSize imgSize = img.size;
    // 缩小后的图片size。如果不是等比缩小，高宽分别处理即可
    CGSize scaleSize = CGSizeMake(imgSize.width * scale, imgSize.height * scale);
    // 将scaleSize大小，设置为当前的context
    UIGraphicsBeginImageContext(scaleSize);
    // Draws the entire image in the specified rectangle, scaling it as needed to fit.
    [img drawInRect: CGRectMake(0, 0, imgSize.width * scale, imgSize.height * scale)];
    // 从当前context中创建一个改变大小后的图片
    UIImage *scaleImg = UIGraphicsGetImageFromCurrentImageContext();
    // 使当前的context出堆栈
    UIGraphicsEndImageContext();

    return scaleImg;
}


@end
