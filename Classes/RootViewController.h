//
//  RootViewController.h
//  NichijyouNavigationController
//
//  Created by b123400 on 08/05/2011.
//  Copyright 2011 home. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RootViewController : UIViewController {
	IBOutlet UIImageView *imageView;
	IBOutlet UIButton *pushButton;
}

-(IBAction)push;
-(IBAction)pop;

@end
