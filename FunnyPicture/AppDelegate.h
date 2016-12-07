//
//  AppDelegate.h
//  FunnyPicture
//
//  Created by xia on 12/3/16.
//  Copyright © 2016 xia. All rights reserved.
//

#import <UIKit/UIKit.h>

@class HomeViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, strong) HomeViewController *homeViewController;
@property (nonatomic, strong) UINavigationController *navigationController;

@end

