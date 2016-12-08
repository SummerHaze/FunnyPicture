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
#import "Post.h"

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
    Post *post;
}

#pragma mark - Life cycle
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
    
    [self performDownload];
}

- (void)dealloc {
    NSLog(@"dealloc: %@",self);
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)performDownload {
    post = [[Post alloc]init];
    [post fetchPostInfoWithURL:self.postUrl]; // 解析帖子图文内容
    imageUrls = [post obtainImageUrls:post.postInfo]; // 解析出当篇帖子中所有图片下载Url，用于进详情页下载
    rearrangedPost = [post rearrangePostFromArray:post.postInfo]; // 将图文内容，按照要展示的Cell数据源格式重新组织成对应数组
    downloadedImages = [self getAllImagesInPath:[self getImageDir]]; // 已下载保存到的图片
    
    for (int i = 0; i < [imageUrls count]; i++) {
        NSString *imageName = [imageUrls[i] componentsSeparatedByString:@"/"].lastObject;
        if (![downloadedImages containsObject:imageName]) {  // 未下载
            [post downloadImage:imageUrls[i]
                     completion:^(BOOL success) {
                         if (success) {
                             [downloadedImages addObject:imageName];
                             [self.tableView reloadData];
                         }
                     }];
        } else {
            NSLog(@"图片已下载,不重复下载：%@", imageUrls[i]);
        }
    }
}

#pragma mark - Table view datasource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
//    if (isDownloaded) {
        return [rearrangedPost count];
//    } else {
//        return 1;
//    }
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
//    if (isDownloaded) {
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
//    } else {
//        return 80;
//    }

}

#pragma mark - Table view delegate
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
//    if (isDownloaded) {
        NSUInteger count = [rearrangedPost[indexPath.row] count];
        if (count == 2) {
            // 一条文字下面只有一张图片,用一个DetailCell即可
            DetailCell *cell = (DetailCell *)[tableView dequeueReusableCellWithIdentifier:DetailCellIdentifier];
            [cell configureForPost:rearrangedPost[indexPath.row]];
            return cell;
        } else {
            // 一条文字下有多张图片，从第二张开始使用ImageCell
            ImageCell *cell = (ImageCell *)[tableView dequeueReusableCellWithIdentifier:ImageCellIdentifier];
            [cell configureForImage:rearrangedPost[indexPath.row][0]];
            return cell;
        }
//    } else { // 转菊花
//        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:LoadingCellIdentifier forIndexPath:indexPath];
//        UIActivityIndicatorView *spinner = (UIActivityIndicatorView *)[cell viewWithTag:100];
//        [spinner startAnimating];
//        
//        return cell;
//    }

}

#pragma mark - Handle image
// 获取某路径下面的所有文件
- (NSMutableArray *)getAllImagesInPath:(NSString *)path {
    NSLog(@"image path: %@",path);
    NSFileManager *defaultManager = [NSFileManager defaultManager];
    NSArray *array = [defaultManager contentsOfDirectoryAtPath:path error:nil];
    return array;
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

- (NSString *)getImageDir {
    return [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingString:[NSString stringWithFormat:@"/images/"]];
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
