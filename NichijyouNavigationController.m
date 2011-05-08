//
//  NichijyouNavigationController.m
//  NichijyouNavigationController
//
//  Created by b123400 on 08/05/2011.
//  Copyright 2011 home. All rights reserved.
//
#import <QuartzCore/QuartzCore.h>
#import "NichijyouNavigationController.h"

@interface NichijyouNavigationController ()

-(NSMutableArray*)centerPoints;

//push
-(void)zoomInHide:(UIView*)theView;
-(void)prepareZoomInShow:(UIView*)theView;
-(void)pushIntoViewController:(UIViewController*)viewController;
-(void)zoomInShow:(UIView*)theView;
-(void)finishedZoomInShow:(UIViewController*)viewController;

//pop
-(void)zoomOutHide:(UIView*)theView;
-(void)popOutToViewController:(UIViewController*)viewController;
-(void)prepareZoomOutShow:(UIView*)theView;
-(void)zoomOutShow:(UIView*)theView;
-(void)finishedZoomOutShow:(UIViewController*)viewController;

-(float)timeDelayForView:(UIView*)theView atZoomingPoint:(CGPoint)point;
-(NSArray*)subviewsToAnimateForViewController:(UIViewController*)controller;

@end


@implementation NichijyouNavigationController
@synthesize disableFade;

static float zoomDelayPerPixelFromCenter=1/1000.0;
static float zoomingFactor=7;
static float fadeOutOpacity=0.5;
static float animationDuration=0.25;

-(NSMutableArray*)centerPoints{
	if(!centerPoints){
		centerPoints=[[NSMutableArray alloc]init];
	}
	return centerPoints;
}

-(void)viewDidLoad{
	NichijyouTransparentView *transparentView=[[NichijyouTransparentView alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
	transparentView.delegate=self;
	
	[self.view addSubview:transparentView];
	[transparentView release];
	[self setNavigationBarHidden:YES];
	[super viewDidLoad];
}

-(void)didTouchedTransparentView:(id)sender atPoint:(CGPoint)point{
	lastTouchedPoint=[[sender superview] convertPoint:point toView:nil];
}
-(void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated{
	if(!animated){
		[super pushViewController:viewController animated:animated];
		return;
	}
	[self pushViewController:viewController atCenter:lastTouchedPoint];
}

-(void)pushViewController:(UIViewController *)viewController atCenter:(CGPoint)center{
	nextController=[viewController retain];
	[self topViewController].view.userInteractionEnabled=NO;
	
	NSArray *viewsToAnimate=[self subviewsToAnimateForViewController:[self topViewController]];
	
	[[self centerPoints] addObject:[NSValue valueWithCGPoint:lastTouchedPoint]];
	
	NSMutableArray *delayTimes=[NSMutableArray array];
	float minimumDelay=MAXFLOAT;
	for(UIView *thisView in viewsToAnimate){
		float thisDelay=[self timeDelayForView:thisView atZoomingPoint:lastTouchedPoint];
		[delayTimes addObject:[NSNumber numberWithFloat:thisDelay]];
		if(thisDelay<minimumDelay){
			minimumDelay=thisDelay;
		}
	}
	for(int i=0;i<[delayTimes count];i++){
		[delayTimes replaceObjectAtIndex:i withObject:[NSNumber numberWithFloat:[[delayTimes objectAtIndex:i]floatValue]-minimumDelay]];
	}
	
	float maxDelay=0;
	for (int i=0;i<[viewsToAnimate count];i++) {
		UIView *thisView = [viewsToAnimate objectAtIndex:i];
		float thisDelay=[[delayTimes objectAtIndex:i]floatValue];
		[self performSelector:@selector(zoomInHide:) withObject:thisView afterDelay:thisDelay];
		if(!disableFade){
			if(thisDelay>maxDelay){
				maxDelay=thisDelay;
			}
		}
	}
	maxDelay+=animationDuration;
	[self performSelector:@selector(pushIntoViewController:) withObject:nextController afterDelay:maxDelay-0.05];
	[nextController release];
}
-(void)pushIntoViewController:(UIViewController*)viewController{
	UIViewController *lastController=[self topViewController];
	[self pushViewController:viewController animated:NO];
	
	NSArray *animatedViews=[self subviewsToAnimateForViewController:lastController];
	for (UIView *thisView in animatedViews) {
		[thisView.layer removeAllAnimations];
		if(!disableFade){
			thisView.layer.opacity=1;
		}
	}
	lastController.view.userInteractionEnabled=YES;
	
	viewController.view.userInteractionEnabled=NO;
	NSArray *viewsToAnimate=[self subviewsToAnimateForViewController:[self topViewController]];
	
	NSMutableArray *delayTimes=[NSMutableArray array];
	float minimumDelay=MAXFLOAT;
	for(UIView *thisView in viewsToAnimate){
		float thisDelay=[self timeDelayForView:thisView atZoomingPoint:lastTouchedPoint];
		[delayTimes addObject:[NSNumber numberWithFloat:thisDelay]];
		if(thisDelay<minimumDelay){
			minimumDelay=thisDelay;
		}
	}
	for(int i=0;i<[delayTimes count];i++){
		[delayTimes replaceObjectAtIndex:i withObject:[NSNumber numberWithFloat:[[delayTimes objectAtIndex:i]floatValue]-minimumDelay]];
	}
	
	float maxDelay=0;
	for (int i=0;i<[viewsToAnimate count];i++) {
		UIView *thisView = [viewsToAnimate objectAtIndex:i];
		float thisDelay=[[delayTimes objectAtIndex:i]floatValue];
		
		[self prepareZoomInShow:thisView];
		[self performSelector:@selector(zoomInShow:) withObject:thisView afterDelay:thisDelay];
		if(thisDelay>maxDelay){
			maxDelay=thisDelay;
		}
	}
	maxDelay+=animationDuration;
	[self performSelector:@selector(finishedZoomInShow:) withObject:nextController afterDelay:maxDelay];
}
-(void)zoomInHide:(UIView*)theView{
	CGRect absoluteRect=[[theView superview] convertRect:theView.frame toView:self.view];
	
	float xDifferent=(absoluteRect.origin.x+absoluteRect.size.width/2-lastTouchedPoint.x)*(zoomingFactor-1);
	float yDifferent=(absoluteRect.origin.y+absoluteRect.size.height/2-lastTouchedPoint.y)*(zoomingFactor-1);
	
	CALayer *layer=theView.layer;
	CABasicAnimation *positionAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
	positionAnimation.removedOnCompletion=NO;
	positionAnimation.duration=animationDuration;
    //animation.fromValue = [layer valueForKey:@"position"];
	CGPoint targetPosition=CGPointMake(layer.position.x+xDifferent, layer.position.y+yDifferent);
    positionAnimation.toValue = [NSValue valueWithCGPoint:targetPosition];
	positionAnimation.timingFunction=[CAMediaTimingFunction functionWithControlPoints:0.97 :0.15 :1.00 :1.00]; //smoother!
	
    // Update the layer's position so that the layer doesn't snap back when the animation completes.
    //layer.position = [positionAnimation.toValue CGPointValue];
	
    // Add the animation, overriding the implicit animation.
    [layer addAnimation:positionAnimation forKey:@"position"];
	
	CABasicAnimation *resizeAnimation = [CABasicAnimation animationWithKeyPath:@"transform"];
	resizeAnimation.removedOnCompletion=positionAnimation.removedOnCompletion;
	resizeAnimation.timingFunction=positionAnimation.timingFunction;
	resizeAnimation.toValue=[NSValue valueWithCATransform3D:CATransform3DScale(CATransform3DMakeTranslation(0, 0, 0), zoomingFactor, zoomingFactor, zoomingFactor)];
	resizeAnimation.duration=positionAnimation.duration;
	[layer addAnimation:resizeAnimation forKey:@"bounds"];
	
	if(!disableFade){
		CABasicAnimation *fadeAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
		fadeAnimation.timingFunction=positionAnimation.timingFunction;
		[fadeAnimation setToValue:[NSNumber numberWithFloat:0]];
		fadeAnimation.fillMode = kCAFillModeForwards;
		fadeAnimation.removedOnCompletion = positionAnimation.removedOnCompletion;
		fadeAnimation.duration=positionAnimation.duration;//0.13;
		//fadeAnimation.delegate=self;
		
		[layer addAnimation:fadeAnimation forKey:@"opacity"];
	}
}
-(void)prepareZoomInShow:(UIView*)theView{
	if(!disableFade){
		theView.layer.opacity=0;
	}
}
-(void)zoomInShow:(UIView*)theView{
	CALayer *layer=theView.layer;
	CABasicAnimation *positionAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
	positionAnimation.removedOnCompletion=NO;
	positionAnimation.duration=animationDuration;
    //animation.fromValue = [layer valueForKey:@"position"];
	CGPoint targetPosition=lastTouchedPoint;
    positionAnimation.fromValue = [NSValue valueWithCGPoint:targetPosition];
	positionAnimation.timingFunction=[CAMediaTimingFunction functionWithControlPoints:0.19 :0.91 :1.00 :1.00]; //smoother!
	
    // Update the layer's position so that the layer doesn't snap back when the animation completes.
    //layer.position = [positionAnimation.toValue CGPointValue];
	
    // Add the animation, overriding the implicit animation.
    [layer addAnimation:positionAnimation forKey:@"position"];
	
	CABasicAnimation *resizeAnimation = [CABasicAnimation animationWithKeyPath:@"transform"];
	resizeAnimation.removedOnCompletion=positionAnimation.removedOnCompletion;
	resizeAnimation.timingFunction=positionAnimation.timingFunction;
	resizeAnimation.fromValue=[NSValue valueWithCATransform3D:CATransform3DScale(CATransform3DMakeTranslation(0, 0, 0), 1/zoomingFactor, 1/zoomingFactor, 1/zoomingFactor)];
	resizeAnimation.duration=positionAnimation.duration;
	[layer addAnimation:resizeAnimation forKey:@"bounds"];
	
	if(!disableFade){
		CABasicAnimation *fadeAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
		fadeAnimation.timingFunction=positionAnimation.timingFunction;
		[fadeAnimation setToValue:[NSNumber numberWithFloat:1]];
		fadeAnimation.fillMode = kCAFillModeForwards;
		fadeAnimation.removedOnCompletion = positionAnimation.removedOnCompletion;
		fadeAnimation.duration=positionAnimation.duration;//0.13;
		//fadeAnimation.delegate=self;
		
		[layer addAnimation:fadeAnimation forKey:@"opacity"];
	}
}
-(void)finishedZoomInShow:(UIViewController*)viewController{
	viewController.view.userInteractionEnabled=YES;
	NSArray *views=[self subviewsToAnimateForViewController:viewController];
	for (UIView *thisView in views) {
		[thisView.layer removeAllAnimations];
		if(!disableFade){
			thisView.layer.opacity=1;
		}
	}
}
-(void)popViewControllerAnimated:(BOOL)animated{
	[self popToViewController:nil animated:animated];
}
-(void)popToRootViewControllerAnimated:(BOOL)animated{
	if([[self viewControllers]count]>1){
		[self popToViewController:[[self viewControllers] objectAtIndex:0] animated:animated];
	}
}
-(void)popToViewController:(UIViewController *)viewController animated:(BOOL)animated{
	if([[self viewControllers]count]<=1)return;
	if(viewController){
		nextController=viewController;
	}else{
		nextController=[[self viewControllers] objectAtIndex:[[self viewControllers] count]-2];
	}
	if(!animated){
		[super popToViewController:nextController animated:animated];
	}
	
	[self topViewController].view.userInteractionEnabled=NO;
	NSArray *viewsToAnimate=[self subviewsToAnimateForViewController:[self topViewController]];
	
	int indexOfNextViewController=[[self viewControllers]indexOfObject:nextController];
	lastTouchedPoint=[((NSValue*)[[self centerPoints] objectAtIndex:indexOfNextViewController]) CGPointValue];
	
	NSMutableArray *delayTimes=[NSMutableArray array];
	float minimumDelay=MAXFLOAT;
	for(UIView *thisView in viewsToAnimate){
		float thisDelay=[self timeDelayForView:thisView atZoomingPoint:lastTouchedPoint];
		[delayTimes addObject:[NSNumber numberWithFloat:thisDelay]];
		if(thisDelay<minimumDelay){
			minimumDelay=thisDelay;
		}
	}
	for(int i=0;i<[delayTimes count];i++){
		[delayTimes replaceObjectAtIndex:i withObject:[NSNumber numberWithFloat:[[delayTimes objectAtIndex:i]floatValue]-minimumDelay]];
	}
	
	float maxDelay=0;
	for (int i=0;i<[viewsToAnimate count];i++) {
		UIView *thisView = [viewsToAnimate objectAtIndex:i];
		float thisDelay=[[delayTimes objectAtIndex:i]floatValue];
		[self performSelector:@selector(zoomOutHide:) withObject:thisView afterDelay:thisDelay];
		if(!disableFade){
			if(thisDelay>maxDelay){
				maxDelay=thisDelay;
			}
		}
	}
	maxDelay+=animationDuration;
	[self performSelector:@selector(popOutToViewController:) withObject:nextController afterDelay:maxDelay];
}

-(void)zoomOutHide:(UIView*)theView{
	
	CALayer *layer=theView.layer;
	CABasicAnimation *positionAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
	positionAnimation.removedOnCompletion=NO;
	positionAnimation.duration=animationDuration;
    //animation.fromValue = [layer valueForKey:@"position"];
	CGPoint targetPosition=lastTouchedPoint;
    positionAnimation.toValue = [NSValue valueWithCGPoint:targetPosition];
	positionAnimation.timingFunction=[CAMediaTimingFunction functionWithControlPoints:0.97 :0.15 :1.00 :1.00]; //smoother!
	
    // Update the layer's position so that the layer doesn't snap back when the animation completes.
    //layer.position = [positionAnimation.toValue CGPointValue];
	
    // Add the animation, overriding the implicit animation.
    [layer addAnimation:positionAnimation forKey:@"position"];
	
	CABasicAnimation *resizeAnimation = [CABasicAnimation animationWithKeyPath:@"transform"];
	resizeAnimation.removedOnCompletion=positionAnimation.removedOnCompletion;
	resizeAnimation.timingFunction=positionAnimation.timingFunction;
	resizeAnimation.toValue=[NSValue valueWithCATransform3D:CATransform3DScale(CATransform3DMakeTranslation(0, 0, 0), 1/zoomingFactor, 1/zoomingFactor, 1/zoomingFactor)];
	resizeAnimation.duration=positionAnimation.duration;
	[layer addAnimation:resizeAnimation forKey:@"bounds"];
	
	if(!disableFade){
		CABasicAnimation *fadeAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
		fadeAnimation.timingFunction=positionAnimation.timingFunction;
		[fadeAnimation setToValue:[NSNumber numberWithFloat:0]];
		fadeAnimation.fillMode = kCAFillModeForwards;
		fadeAnimation.removedOnCompletion = positionAnimation.removedOnCompletion;
		fadeAnimation.duration=positionAnimation.duration;//0.13;
		//fadeAnimation.delegate=self;
		
		[layer addAnimation:fadeAnimation forKey:@"opacity"];
	}
}
-(void)popOutToViewController:(UIViewController*)viewController{
	NSArray *animatedViews=[self subviewsToAnimateForViewController:[self topViewController]];
	for (UIView *thisView in animatedViews) {
		[thisView.layer removeAllAnimations];
		if(!disableFade){
			thisView.layer.opacity=1;
		}
	}
	[self topViewController].view.userInteractionEnabled=YES;
	[super popToViewController:viewController animated:NO];
	[self topViewController].view.userInteractionEnabled=NO;
	
	[[self centerPoints] removeObjectsInRange:NSMakeRange([[self viewControllers]indexOfObject:viewController], [[self viewControllers] count]-[[self viewControllers]indexOfObject:viewController])];
	
	NSArray *viewsToAnimate=[self subviewsToAnimateForViewController:[self topViewController]];
	
	NSMutableArray *delayTimes=[NSMutableArray array];
	float minimumDelay=MAXFLOAT;
	for(UIView *thisView in viewsToAnimate){
		float thisDelay=[self timeDelayForView:thisView atZoomingPoint:lastTouchedPoint];
		[delayTimes addObject:[NSNumber numberWithFloat:thisDelay]];
		if(thisDelay<minimumDelay){
			minimumDelay=thisDelay;
		}
	}
	for(int i=0;i<[delayTimes count];i++){
		[delayTimes replaceObjectAtIndex:i withObject:[NSNumber numberWithFloat:[[delayTimes objectAtIndex:i]floatValue]-minimumDelay]];
	}
	
	float maxDelay=0;
	for (int i=0;i<[viewsToAnimate count];i++) {
		UIView *thisView = [viewsToAnimate objectAtIndex:i];
		float thisDelay=[[delayTimes objectAtIndex:i]floatValue];
		
		[self prepareZoomOutShow:thisView];
		[self performSelector:@selector(zoomOutShow:) withObject:thisView afterDelay:thisDelay];
		if(thisDelay>maxDelay){
			maxDelay=thisDelay;
		}
	}
	maxDelay+=animationDuration;
	[self performSelector:@selector(finishedZoomOutShow:) withObject:nextController afterDelay:maxDelay];
}
-(void)prepareZoomOutShow:(UIView*)theView{
	if(!disableFade){
		theView.layer.opacity=0;
	}
}
-(void)zoomOutShow:(UIView*)theView{
	if(!disableFade){
		theView.layer.opacity=1;
	}
	CGRect absoluteRect=[[theView superview] convertRect:theView.frame toView:self.view];
	
	float xDifferent=(absoluteRect.origin.x+absoluteRect.size.width/2-lastTouchedPoint.x)*(zoomingFactor-1);
	float yDifferent=(absoluteRect.origin.y+absoluteRect.size.height/2-lastTouchedPoint.y)*(zoomingFactor-1);
	
	CALayer *layer=theView.layer;
	CABasicAnimation *positionAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
	positionAnimation.removedOnCompletion=YES;
	positionAnimation.duration=animationDuration;
    //animation.fromValue = [layer valueForKey:@"position"];
	CGPoint targetPosition=CGPointMake(layer.position.x+xDifferent, layer.position.y+yDifferent);
    positionAnimation.fromValue = [NSValue valueWithCGPoint:targetPosition];
	positionAnimation.timingFunction=[CAMediaTimingFunction functionWithControlPoints:0.19 :0.91 :1.00 :1.00]; //smoother!
	
    // Update the layer's position so that the layer doesn't snap back when the animation completes.
    //layer.position = [positionAnimation.toValue CGPointValue];
	
    // Add the animation, overriding the implicit animation.
    [layer addAnimation:positionAnimation forKey:@"position"];
	
	CABasicAnimation *resizeAnimation = [CABasicAnimation animationWithKeyPath:@"transform"];
	resizeAnimation.removedOnCompletion=positionAnimation.removedOnCompletion;
	resizeAnimation.timingFunction=positionAnimation.timingFunction;
	resizeAnimation.fromValue=[NSValue valueWithCATransform3D:CATransform3DScale(CATransform3DMakeTranslation(0, 0, 0), zoomingFactor, zoomingFactor, zoomingFactor)];
	resizeAnimation.duration=positionAnimation.duration;
	[layer addAnimation:resizeAnimation forKey:@"bounds"];
	
	if(!disableFade){
		CABasicAnimation *fadeAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
		fadeAnimation.timingFunction=positionAnimation.timingFunction;
		[fadeAnimation setFromValue:[NSNumber numberWithFloat:fadeOutOpacity]];
		fadeAnimation.fillMode = kCAFillModeForwards;
		fadeAnimation.removedOnCompletion = positionAnimation.removedOnCompletion;
		fadeAnimation.duration=positionAnimation.duration;//0.13;
		fadeAnimation.delegate=self;
		
		[layer addAnimation:fadeAnimation forKey:@"opacity"];
	}
}
-(void)finishedZoomOutShow:(UIViewController*)viewController{
	[self topViewController].view.userInteractionEnabled=YES;
	NSArray *views=[self subviewsToAnimateForViewController:viewController];
	for (UIView *thisView in views) {
		[thisView.layer removeAllAnimations];
		if(!disableFade){
			thisView.layer.opacity=1;
		}
	}
}

-(float)timeDelayForView:(UIView*)theView atZoomingPoint:(CGPoint)point{
	CGRect absoluteRect=[[theView superview] convertRect:theView.frame toView:self.view];
	CGPoint viewCenterPoint=CGPointMake(absoluteRect.origin.x+absoluteRect.size.width/2, absoluteRect.origin.y+absoluteRect.size.height/2);
	float distance=(float)sqrt(pow(viewCenterPoint.x-point.x,2)+pow(viewCenterPoint.y-point.y, 2));
	return zoomDelayPerPixelFromCenter*distance;
}

-(NSArray*)subviewsToAnimateForViewController:(UIViewController*)controller{
	if([controller respondsToSelector:@selector(viewsForNichijyouNavigationControllerToAnimate:)]){
		return [controller viewsForNichijyouNavigationControllerToAnimate:self];
	}
	return controller.view.subviews;
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code.
}
*/

- (void)dealloc {
	if(centerPoints)[centerPoints release];
    [super dealloc];
}


@end
