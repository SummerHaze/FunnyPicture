//
//  Post.m
//  FunnyPicture
//
//  Created by xia on 12/7/16.
//  Copyright © 2016 xia. All rights reserved.
//

#import "Post.h"
#import "OCGumbo.h"
#import "OCGumbo+Query.h"
#import <UIKit/UIKit.h>
#import <AFNetworking/AFNetworking.h>

static NSOperationQueue *queue = nil;
static NSString * const dirNameInCaches = @"images";

@interface Post()

@end

@implementation Post

+ (void)initialize {
    if (self == [Post class]) {
        queue = [[NSOperationQueue alloc] init];
    }
}

// 将文字和URL从HTML中解析出来，以数组（单个元素）方式，保存在postInfo中
- (void)fetchPostInfoWithURL:(NSString *)postUrl {
    NSURL *url = [NSURL URLWithString:postUrl];
    NSError *error;
    NSString *htmlString = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&error];
    
    [self parseHTML:htmlString];
}

// 解析贴子内容
- (void)parseHTML:(NSString *)htmlString {
    self.postInfo = [[NSMutableArray alloc]initWithCapacity:1];
    OCGumboDocument *document = [[OCGumboDocument alloc] initWithHTMLString:htmlString];
    OCQueryObject *queryResult = document.Query(@"body").find(@".post-content").find(@"p"); // OCGumboElement数组
    for (OCGumboNode *node in queryResult) {
        if ([node.childNodes count] > 0) {
            if ([node.childNodes[0] isKindOfClass:[OCGumboText class]]) {
                // 图片配文
                OCGumboText *text = (OCGumboText *)node.childNodes[0];
                NSString *desc = text.data;
                if ((desc.length > 0) && [self containNumber:desc]) {
                    [self.postInfo addObject:desc];
                }
            } else if ([node.childNodes[0] isKindOfClass:[OCGumboElement class]]) {
                // 图片链接
                OCGumboElement *element = (OCGumboElement *)node.childNodes[0];
                NSString *url = element.attr(@"data-src");
                if ([url length] > 0) {
                    [self.postInfo addObject:url];
                }
            }
        }
    }
}

// 将文字和URL匹配，以字典方式组合成数组
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

// 将文字和单个URL匹配，组合成数组
- (NSMutableArray *)rearrangePostFromArray:(NSArray *)arr {
    NSMutableArray *tmp = [[NSMutableArray alloc] initWithCapacity:1]; // 最外层数组
    NSMutableArray *tmpArr;
    for (int i = 0; i < [arr count]; i++) {
        if (![arr[i] containsString:@"http"]) { // 标题
            tmpArr = [[NSMutableArray alloc] init];
            [tmpArr addObject:arr[i]];
        } else {
            if ([tmpArr count] == 1) {
                [tmpArr addObject:arr[i]];
                [tmp addObject:tmpArr];
            } else {
                [tmp addObject:@[arr[i]]];
            }
        }
    }
    return tmp;
}

// 图片下载并保存本地
- (void)downloadImage:(NSString *)imageUrl completion:(PostBlock)block {
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    
    NSURL *URL = [NSURL URLWithString:imageUrl];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    
    NSString *imageName = [imageUrl componentsSeparatedByString:@"/"].lastObject;
    NSString *component = [NSString stringWithFormat:@"%@/%@", dirNameInCaches, imageName];
    
    [self createDirInCaches:dirNameInCaches];
    
    NSURLSessionDownloadTask *downloadTask = [manager downloadTaskWithRequest:request progress:nil destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
        NSURL *cachesDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSCachesDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
        return [cachesDirectoryURL URLByAppendingPathComponent:component];
    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        block(YES);
        NSLog(@"downloaded: %@", filePath);
    }];
    
    [downloadTask resume];
    

//    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
//    dispatch_async(queue, ^{
//        NSURL *url = [NSURL URLWithString:imageUrl];
//        NSString *imageName = [imageUrl componentsSeparatedByString:@"/"].lastObject;
//        NSLog(@">>>准备下载: %@", imageUrl);
//                               
//        NSData *data = [NSData dataWithContentsOfURL:url];
//        UIImage *image = [UIImage imageWithData:data];
//        
//        self.savedImages = [[NSMutableArray alloc]initWithCapacity:1];
//        NSString *imagePath = [self obetainImagePathInCaches:@"images" imageName:imageName];
//        NSData *imgData = UIImagePNGRepresentation(image);
//        
//        NSError *error;
//        BOOL success = [imgData writeToFile:imagePath options:NSDataWritingAtomic error:&error];
//        if (success) {
//            block(YES);
//            [self.savedImages addObject:imageName];
//        } else {
//            block(NO);
//            NSLog(@"保存至本地失败，报错: %@", error);
//        }
//    });
    
}

// 获取image存储在Caches中的绝对路径
- (NSString *)obetainImagePathInCaches:(NSString *)dir imageName:(NSString *)image {
    [self createDirInCaches:dir]; // 先创建图片在caches中的存储目录，否则写入时报错
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *imagePath = [path stringByAppendingString:[NSString stringWithFormat:@"/%@/%@", dir, image]];
    return imagePath;
}

// 获取所有的图片下载url
- (NSMutableArray *)obtainImageUrls:(NSArray *)array {
    NSMutableArray *urls = [[NSMutableArray alloc] init];
    for (NSString *str in array) {
        if ([str containsString:@"http"]) {
            [urls addObject:str];
        }
    }
//    for (int i = 0; i < [array count]; i++) {
//        NSArray *arr = [array[i] objectForKey:@"imageUrls"];
//        for (NSString *str in arr) {
//            [urls addObject:str];
//        }
//    }
    return urls;
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


@end
