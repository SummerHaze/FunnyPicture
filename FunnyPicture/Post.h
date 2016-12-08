//
//  Post.h
//  FunnyPicture
//
//  Created by xia on 12/7/16.
//  Copyright © 2016 xia. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Post : NSObject

@property (nonatomic, strong) NSMutableArray *postInfo;
@property (nonatomic, strong) NSMutableArray *postInfoRearranged;
@property (nonatomic, strong) NSMutableArray *savedImages;

typedef void (^PostBlock)(BOOL success);

- (void)fetchPostInfoWithURL:(NSString *)postUrl;
- (NSMutableArray *)rearrangePostFromArray:(NSArray *)arr;
- (NSMutableArray *)obtainImageUrls:(NSArray *)array;
- (void)downloadImage:(NSString *)imageUrl completion:(PostBlock)block;

@end
