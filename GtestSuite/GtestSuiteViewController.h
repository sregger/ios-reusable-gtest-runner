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
    NSString * startTimestamp;
    __weak IBOutlet UILabel *startTimestampLabel;
    __weak IBOutlet UILabel *endTimestampLabel;
}

- (void)testSuiteDidFinish;

@end
