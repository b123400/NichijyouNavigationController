//
//  NichijyouNavigationController.h
//  NichijyouNavigationController
//
//  Created by b123400 on 08/05/2011.
//  Copyright 2011 home. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NichijyouTransparentView.h"

@protocol NichijyouNavigationControllerDelegate

-(NSArray*)viewsForNichijyouNavigationControllerToAnimate:(id)sender;

@end


@interface NichijyouNavigationController : UINavigationController <NichijyouTransparentViewDelegate> {
	NSMutableArray *centerPoints;
	CGPoint lastTouchedPoint;
	
	UIViewController *nextController;
	BOOL disableFade;
}

@property (nonatomic,assign) BOOL disableFade;

-(void)pushViewController:(UIViewController *)viewController atCenter:(CGPoint)center;

@end
