//
//  GtestSuiteRunner.h
//  GtestSuite
//
//  Created by kennward on 06/02/2013.
//  Copyright (c) 2013 Cisco Systems. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GtestSuiteRunner : NSObject

@property (strong, nonatomic) NSString * csfInstruments;
@property (strong, nonatomic) NSString * gtestFilter;
@property (strong, nonatomic) NSString * gtestOutput;
@property (strong, nonatomic) NSString * iniFile;
@property (strong, nonatomic) NSString * iniFileSection;
@property (strong, nonatomic) NSString * reportURL;
@property (strong, nonatomic) NSString * testDataLoc;

// Object to run callbacks
@property (weak, nonatomic) id delegate;

@end
