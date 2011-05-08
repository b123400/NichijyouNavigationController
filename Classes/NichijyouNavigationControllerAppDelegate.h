//
//  NichijyouNavigationControllerAppDelegate.h
//  NichijyouNavigationController
//
//  Created by b123400 on 08/05/2011.
//  Copyright 2011 home. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NichijyouNavigationController.h"

@interface NichijyouNavigationControllerAppDelegate : NSObject <UIApplicationDelegate> {
    
    UIWindow *window;
    NichijyouNavigationController *navigationController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UINavigationController *navigationController;

@end

