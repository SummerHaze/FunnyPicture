//
//  DetailCell.m
//  FunnyPicture
//
//  Created by xia on 12/5/16.
//  Copyright © 2016 xia. All rights reserved.
//

#import "DetailCell.h"
#import <AFNetworking/UIImageView+AFNetworking.h>

@implementation DetailCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)configureForPost:(NSMutableArray *)postInfo {
    self.title.text = postInfo[0];
    
    NSString *name = [postInfo[1] componentsSeparatedByString:@"/"].lastObject;
    UIImage *image = [self getImageByName:name];
    
    [self.imageView setImage:image];
    
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

@end
