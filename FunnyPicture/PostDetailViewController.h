//
//  PostDetailViewController.h
//  FunnyPicture
//
//  Created by xia on 12/5/16.
//  Copyright © 2016 xia. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PostDetailViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UINavigationControllerDelegate>

@property (nonatomic, strong) NSString *postUrl;

@end
