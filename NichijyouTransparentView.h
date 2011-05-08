//
//  NichijyouTransparentView.h
//  NichijyouNavigationController
//
//  Created by b123400 on 08/05/2011.
//  Copyright 2011 home. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol NichijyouTransparentViewDelegate

-(void)didTouchedTransparentView:(id)sender atPoint:(CGPoint)point;

@end


@interface NichijyouTransparentView : UIView {
	id <NichijyouTransparentViewDelegate> delegate;
}

@property (nonatomic,assign) id <NichijyouTransparentViewDelegate> delegate; 

@end
