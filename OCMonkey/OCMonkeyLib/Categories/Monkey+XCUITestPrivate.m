//
//  Monkey+XCUITestPrivate.m
//  OCMonkey
//
//  Created by gogleyin on 28/04/2017.
//
//

#import "Monkey+XCUITestPrivate.h"
#import "XCEventGenerator.h"
#import "XCUIApplication.h"
#import "XCUIApplication+Monkey.h"
#import "Macros.h"
#import "MathUtils.h"
#import "Monkey.h"
#import "Tree.h"
#import "ElementInfo.h"

UIInterfaceOrientation orientationValue = UIInterfaceOrientationPortrait;

@interface Monkey ()

@end


@implementation Monkey (XCUITestPrivate)

-(void)addDefaultXCTestPrivateActions
{
    [self addXCTestTapAction:25];
    [self addXCTestLongPressAction:3];
    [self addXCTestDragAction:5];
    [self addXCTestPinchCloseAction:1];
    [self addXCTestPinchOpenAction:1];
    [self addXCTestRotateAction:1];
//    [self addMonkeyLeafElementAction:100];
}

-(void)addXCTestTapAction:(double)weight
{
    [self addXCTestTapAction:weight
      multipleTapProbability:0.05
    multipleTouchProbability:0.05];
}



/**
 For testing Monkey methods:
    [Monkey randomRect]
    [Monkey randomPointInRect:]
 */
-(void)addXCTestTapAction:(double)weight inRect:(CGRect)rect
{
    __typeof__(self) __weak weakSelf = self;
    [self addAction:^(void){
        CGPoint point = [weakSelf randomPointInRect:rect];
        NSArray *locations = @[[NSValue valueWithCGPoint:point]];
        [weakSelf tapAtTouchLocations:locations numberOfTaps:1 orientation:orientationValue];
    }    withWeight:weight];

}

-(void)addXCTestTapAction:(double)weight
   multipleTapProbability:(double)multiTap
 multipleTouchProbability:(double)multiTouch
{
    __typeof__(self) __weak weakSelf = self;
    [self addAction:^(void){
        int numberOfTaps;
        if (RandomZeroToOne < multiTap) {
            numberOfTaps = 2 + arc4random() % 2;
        } else {
            numberOfTaps = 1;
        }

        NSMutableArray *locations = [[NSMutableArray alloc] init];
        if (RandomZeroToOne < multiTouch) {
            int numberOfTouches = arc4random() % 3 + 2;
            CGRect rect = [weakSelf randomRect];
            for (int i = 1; i < numberOfTouches; i++) {
                CGPoint point = [weakSelf randomPointInRect:rect];
                [locations addObject:[NSValue valueWithCGPoint:point]];
                // NSLog(@"point %d: {%.1f, %.1f}", i, point.x, point.y);
            }
        } else {
            CGPoint point = [weakSelf randomPoint];
            [locations addObject:[NSValue valueWithCGPoint:point]];
            // NSLog(@"point: {%.1f, %.1f}", point.x, point.y);
        }
        [weakSelf tapAtTouchLocations:locations numberOfTaps:numberOfTaps orientation:orientationValue];
    }    withWeight:weight];
}



-(void)addXCTestLongPressAction:(int)weight
{
    __typeof__(self) __weak weakSelf = self;
    [self addAction:^(void){
        CGPoint point = [weakSelf randomPoint];
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        [[XCEventGenerator sharedGenerator] pressAtPoint:point
                                             forDuration:0.5
                                             orientation:orientationValue
                                                 handler:^(XCSynthesizedEventRecord *record, NSError *commandError) {
                                                     if (commandError) {
                                                         NSLog(@"Failed to perform step: %@", commandError);
                                                     }
                                                     dispatch_semaphore_signal(semaphore);
                                                 }];
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    } withWeight:weight];
}

-(void)addXCTestDragAction:(int)weight
{
    __typeof__(self) __weak weakSelf = self;
    [self addAction:^(void){
        CGPoint start = [weakSelf randomPointAvoidingPanelAreas];
        CGPoint end = [weakSelf randomPoint];
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        [[XCEventGenerator sharedGenerator] pressAtPoint:start
                                             forDuration:0
                                             liftAtPoint:end
                                                velocity:1000
                                             orientation:orientationValue
                                                    name:@"Monkey drag"
                                                 handler:^(XCSynthesizedEventRecord *record, NSError *commandError) {
                                                     if (commandError) {
                                                         NSLog(@"Failed to perform step: %@", commandError);
                                                     }
                                                     dispatch_semaphore_signal(semaphore);
                                                 }];
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    } withWeight:weight];
}

-(void)addXCTestPinchCloseAction:(int)weight
{
    __typeof__(self) __weak weakSelf = self;
    [self addAction:^(void){
        CGRect rect = [weakSelf randomRectWithSizeFraction:2];
        CGFloat scale = 1 / (CGFloat)(RandomZeroToOne * 4 + 1);
        
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        [[XCEventGenerator sharedGenerator] pinchInRect:rect
                                             withScale:scale
                                                velocity:1
                                             orientation:orientationValue
                                                 handler:^(XCSynthesizedEventRecord *record, NSError *commandError) {
                                                     if (commandError) {
                                                         NSLog(@"Failed to perform step: %@", commandError);
                                                     }
                                                     dispatch_semaphore_signal(semaphore);
                                                 }];
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    } withWeight:weight];
}

-(void)addXCTestPinchOpenAction:(int)weight
{
    __typeof__(self) __weak weakSelf = self;
    [self addAction:^(void){
        CGRect rect = [weakSelf randomRectWithSizeFraction:2];
        CGFloat scale = (CGFloat)(RandomZeroToOne * 4 + 1);
        
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        [[XCEventGenerator sharedGenerator] pinchInRect:rect
                                              withScale:scale
                                               velocity:3
                                            orientation:orientationValue
                                                handler:^(XCSynthesizedEventRecord *record, NSError *commandError) {
                                                    if (commandError) {
                                                        NSLog(@"Failed to perform step: %@", commandError);
                                                    }
                                                    dispatch_semaphore_signal(semaphore);
                                                }];
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    } withWeight:weight];
}

-(void)addXCTestRotateAction:(int)weight
{
    __typeof__(self) __weak weakSelf = self;
    [self addAction:^(void){
        CGRect rect = [weakSelf randomRectWithSizeFraction:2];
        CGFloat angle = (CGFloat)(RandomZeroToOne * 2 * 3.141592);
        
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        [[XCEventGenerator sharedGenerator] rotateInRect:rect
                                            withRotation:angle
                                               velocity:5
                                            orientation:orientationValue
                                                handler:^(XCSynthesizedEventRecord *record, NSError *commandError) {
                                                    if (commandError) {
                                                        NSLog(@"Failed to perform step: %@", commandError);
                                                    }
                                                    dispatch_semaphore_signal(semaphore);
                                                }];
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    } withWeight:weight];
}

-(void)addMonkeyLeafElementAction:(int)weight
{
    __typeof__(self) __weak weakSelf = self;
    [self addAction:^(void){
        [weakSelf performActionRandomLeafElement];
    } withWeight:weight];
}

-(void)tap:(CGPoint)location
{
    [self tapAtTouchLocations:@[[NSValue valueWithCGPoint:location]]
                 numberOfTaps:1
                  orientation:orientationValue];
}

-(void)tapAtTouchLocations:(NSArray *)locations
              numberOfTaps:(int)taps
               orientation:(UIInterfaceOrientation)orientationValue
{
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    XCEventGeneratorHandler handlerBlock = ^(XCSynthesizedEventRecord *record, NSError *commandError) {
        if (commandError) {
            NSLog(@"Failed to perform step: %@", commandError);
        }
        dispatch_semaphore_signal(semaphore);
    };
    
    [[XCEventGenerator sharedGenerator] tapAtTouchLocations:locations
                                               numberOfTaps:taps
                                                orientation:orientationValue
                                                    handler:handlerBlock];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
}

-(void)performActionRandomLeafElement
{
    Tree *tree = [self.testedApp tree];
    NSArray<Tree *> *leaves = [tree leaves];
    Tree *leafChosen = leaves[arc4random() % leaves.count];
    //    Tree *leafChosen = leaves[0];
    NSLog(@"Chosen element: id: %@ data: %@", leafChosen.identifier, leafChosen.data);
    //    NSLog(@"tree: %@", tree);
    //    for (Tree *leaf in leaves) {
    //        NSLog(@"leaf: %@ %@", leaf.identifier, leaf.data);
    //    }
    
    CGPoint center = getRectCenter(((ElementInfo*)leafChosen.data).frame);
    [self tap:center];
}



@end
