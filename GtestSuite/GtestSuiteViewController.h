//
//  GtestSuiteViewController.h
//  GtestSuite
//
//  Created by kennward on 04/02/2013.
//  Copyright (c) 2013 Cisco Systems. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GtestSuiteViewController : UIViewController
{
    __weak IBOutlet UILabel *_titleLabel;
    __weak IBOutlet UILabel *_startLabel;
    __weak IBOutlet UILabel *_endLabel;
    __weak IBOutlet UILabel *_executionLabel;
    __weak IBOutlet UITextView *_textView;
    
    NSDate *_startTime;
    NSTimer *_timer;
    
    NSPipe *_pipe;
    NSFileHandle *_pipeReadHandle;
}

- (void) testSuiteDidFinish;

@end
