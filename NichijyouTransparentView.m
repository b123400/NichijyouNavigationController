//
//  NichijyouTransparentView.m
//  NichijyouNavigationController
//
//  Created by b123400 on 08/05/2011.
//  Copyright 2011 home. All rights reserved.
//

#import "NichijyouTransparentView.h"


@implementation NichijyouTransparentView
@synthesize delegate;

- (id)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code.
    }
    return self;
}

-(id)hitTest:(CGPoint)point withEvent:(UIEvent *)event{
	if(delegate){
		if([delegate respondsToSelector:@selector(didTouchedTransparentView:atPoint:)]){
			[delegate didTouchedTransparentView:self atPoint:point];
		}
	}
	return nil;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code.
}
*/

- (void)dealloc {
    [super dealloc];
}


@end
