//
//  ImageCell.m
//  FunnyPicture
//
//  Created by xia on 12/6/16.
//  Copyright © 2016 xia. All rights reserved.
//

#import "ImageCell.h"

@implementation ImageCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)configureForImage:(NSString *)imageUrl {
    NSString *name = [imageUrl componentsSeparatedByString:@"/"].lastObject;
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
