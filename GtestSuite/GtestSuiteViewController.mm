//
//  GtestSuiteViewController.mm
//  GtestSuite
//
//  Created by kennward on 04/02/2013.
//  Copyright (c) 2013 Cisco Systems. All rights reserved.
//

#import "GtestSuiteViewController.h"
#import "GtestSuiteRunner.h"

@implementation GtestSuiteViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    // Create and configure the test runner, and start it in another thread
    GtestSuiteRunner * testRunner = [self makeGtestSuiteRunner];
    NSThread* gtestThread = [[NSThread alloc] initWithTarget:testRunner
                                                    selector:@selector(runTests)
                                                      object:nil];
    [gtestThread start];

    _startTime = [NSDate date];
    [_startLabel setText:[NSString stringWithFormat:@"%@",[self stringDate:_startTime]]];
    [self timerFired]; // Avoids wait for 0.5 seconds
    
    _timer=[NSTimer scheduledTimerWithTimeInterval:.5 target:self selector:@selector(timerFired) userInfo:nil repeats:YES];
    
    // Find file "options.plist" in the application bundle
    NSString *plistPath = [[NSBundle mainBundle]
                           pathForResource:@"options" ofType:@"plist"];
    NSDictionary *options = [[NSDictionary alloc]
                             initWithContentsOfFile:plistPath];
    
    NSString * result_path = [options objectForKey:@"GTEST_OUTPUT"];
    NSString* file_name_with_extension = [result_path lastPathComponent];
    NSString* file_name = [file_name_with_extension stringByDeletingPathExtension];
    [_titleLabel setText:file_name];
    
    NSString * logFile = [options objectForKey:@"LOG_FILE"];
    bool created = [[NSFileManager defaultManager] createFileAtPath:logFile contents:nil attributes:nil];
    
    if (created == NO)
    {
        /*Create the file if it does not exist */
        NSLog(@"%@", [NSString stringWithFormat:@"Unable to create log file %@", logFile]);
    }
    
    _logFileHandle = [NSFileHandle fileHandleForWritingAtPath:logFile];
    [_logFileHandle seekToEndOfFile];
    
    _pipe = [NSPipe pipe] ;
    _pipeReadHandle = [_pipe fileHandleForReading] ;
    dup2([[_pipe fileHandleForWriting] fileDescriptor], fileno(stdout)) ;
    
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(handle_stdout_Notification:) name: NSFileHandleReadCompletionNotification object: _pipeReadHandle] ;
    [_pipeReadHandle readInBackgroundAndNotify] ;
    
    
    // Initialize completion message
    [_completionMessage setText:@"Tests running ..."];
    [_completionMessage setEnabled:NO];
}

- (void) handle_stdout_Notification:(NSNotification *) notification
{
    [_pipeReadHandle readInBackgroundAndNotify] ;
    NSString *str = [[NSString alloc] initWithData: [[notification userInfo] objectForKey: NSFileHandleNotificationDataItem] encoding: NSASCIIStringEncoding];
    NSAttributedString* attr = [[NSAttributedString alloc] initWithString:str];
        
    [[_textView textStorage] appendAttributedString:attr];
    [_textView scrollRangeToVisible:NSMakeRange(_textView.text.length, 0)];
    
    [_logFileHandle writeData:[str dataUsingEncoding:NSUTF8StringEncoding]];
}

/*
 * Callback for the test thread to call when test suite has finished.
 */
- (void)testSuiteDidFinish
{
    [_timer invalidate];
    
    // Post completion message in the text field
    [_completionMessage setText:@"Tests completed."];
}

- (void) timerFired
{
    NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:_startTime];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:interval];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"HH:mm:ss"];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
    NSString *formattedDate = [dateFormatter stringFromDate:date];
    [_executionLabel setText:[NSString stringWithFormat:@"%@", formattedDate]];
}

- (NSString *)stringDate:(NSDate*)date
{
    NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
    return [dateFormatter stringFromDate:date];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 * Creates a GtestSuiteRunner and configures it with options from a plist file.
 */
- (GtestSuiteRunner *)makeGtestSuiteRunner
{
    // Find file "options.plist" in the application bundle
    NSString *plistPath = [[NSBundle mainBundle]
                           pathForResource:@"options" ofType:@"plist"];
    NSDictionary *options = [[NSDictionary alloc]
                             initWithContentsOfFile:plistPath];
    NSLog(@"Dictionary from options.plist: %@", options);
    
    NSString * reportURL      = [options objectForKey:@"HTTP_REPORT_URL"];
    NSString * gtestFilter    = [options objectForKey:@"GTEST_FILTER"];
    NSString * gtestOutput    = [options objectForKey:@"GTEST_OUTPUT"];
    NSString * iniFile        = [options objectForKey:@"INI_FILE"];
    NSString * iniFileSection = [options objectForKey:@"INI_FILE_SECTION"];
    NSString * csfInstruments = [options objectForKey:@"CSF_INSTRUMENTS"];
    NSString * testDataLoc    = [options objectForKey:@"TEST_DATA_LOC"];
    
    // Use options to configure the test runner
    GtestSuiteRunner * gsr = [[GtestSuiteRunner alloc] init];
    [gsr setReportURL:reportURL];
    [gsr setGtestFilter:gtestFilter];
    [gsr setGtestOutput:gtestOutput];
    [gsr setIniFile:iniFile];
    [gsr setIniFileSection:iniFileSection];
    [gsr setCsfInstruments:csfInstruments];
    [gsr setTestDataLoc:testDataLoc];
    
    [gsr setDelegate:self];
    
    return gsr;
}

- (void)viewDidUnload
{
    [_logFileHandle closeFile];
    
    [super viewDidUnload];
}
@end
