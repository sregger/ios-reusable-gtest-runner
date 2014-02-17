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
    __weak IBOutlet UILabel *_executionLabel;
    __weak IBOutlet UITextView *_textView;
    
    NSDate *_startTime;
    NSTimer *_timer;
    
    NSPipe *_pipe;
    NSFileHandle *_pipeReadHandle;
    
    // String message signaling test suite completion.
    // Added for use by Instruments UI Automation script
    // because the UILabels' text was not readable
    __weak IBOutlet UILabel *completionMessage;
    __weak IBOutlet UITextField *_completionMessage;
    
    NSFileHandle *_logFileHandle;

}

- (void) testSuiteDidFinish;

@end
