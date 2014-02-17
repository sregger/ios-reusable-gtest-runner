//
//  GtestSuiteRunner.mm
//  GtestSuite
//
//  Created by kennward on 06/02/2013.
//  Copyright (c) 2013 Cisco Systems. All rights reserved.
//

#import "GtestSuiteRunner.h"
#import "GtestSuiteViewController.h"  // BAD - cyclic dependency - find better way to do the callback
#include <string>
#include <gtest/gtest.h>

/*
 * Make global accessible to GoogleTest event callbacks
 */
static GtestSuiteRunner * g_theSuiteRunner;

@implementation GtestSuiteRunner

@synthesize csfInstruments;
@synthesize gtestFilter;
@synthesize gtestOutput;
@synthesize iniFile;
@synthesize iniFileSection;
@synthesize reportURL;
@synthesize testDataLoc;
@synthesize delegate;

/*
 * This app should be linked to a static library containing this main Google
 * Test entry point, such as those found in TestMain.cpp files.
 * This app needs exactly one of these entry points; therefore exactly one Gtest
 * suite must be linked in to each distinct build of this app.
 */
extern void testMain(int, char**, std::string);

/*
 * Call the extern C++ function testMain() from here.
 * Components reusing this app will get an undefined symbol error until a
 * suitable static library is linked in.
 */
- (void) runTests
{
    // Initialize global pointer for use by Google Test callbacks
    g_theSuiteRunner = self;

    // Find current directory (just for debug logging)
    NSFileManager * filemgr = [NSFileManager defaultManager];
    NSString * currentPath = [filemgr currentDirectoryPath];
    NSLog(@"In runTests: Current directory path: %@", currentPath);
    
    // Compose our configuration parameters into argc, argv format for testMain()
    int argc = 7;
    char *argv[argc];
    
    // Gtest expects application name as first argument
    argv[0] = (char *) "GtestSuite";

    // --gtest_filter argument
    argv[1] = (char *) [gtestFilter UTF8String];
    // Uncomment next line to hijack the --gtest_filter argument, and instead
    // list the known tests.
    //argv[1] = "--gtest_list_tests";

    // --csf_data_directory argument
    NSString *appPath = [[NSBundle mainBundle] resourcePath];
    std::string cAppPath = std::string([appPath UTF8String]);
    NSString *csfDataDir = [[@"--csf_data_directory=" stringByAppendingString:appPath]
                            stringByAppendingString:@"/TestData/"];
    argv[2] = (char *) [csfDataDir UTF8String];

    // XML output destination argument
    /* getXmlOutputDestination needs to be used when running on ios device - needs more testing */
    /* NSString *gtestXmlOutput = [self getXmlOutputDestination];
     argv[3] = (char*) [gtestXmlOutput UTF8String]; */
    argv[3] = (char *) [gtestOutput UTF8String];

    // --csf_instruments argument
    argv[4] = (char *) [csfInstruments UTF8String];
    // Try to force performance instruments on - not working
    argv[4] = (char *) "--csf_instruments=all";

    // --csf_config_file argument
    NSLog(@"iniFile %@", iniFile);
    NSString *csfIniFile = [[[@"--csf_config_file=" stringByAppendingString:appPath] stringByAppendingString:@"/"] stringByAppendingString:iniFile];
    argv[5] = (char *) [csfIniFile UTF8String];
    
    // --csf_config_section argument
    NSLog(@"iniFileSection %@", iniFileSection);
    NSString *csfIniFileSection = [@"--csf_config_section=" stringByAppendingString:iniFileSection];
    argv[6] = (char *) [csfIniFileSection UTF8String];

    // argument
    argv[7] = (char *) [testDataLoc UTF8String];
    
    NSLog(@"Call testMain with arguments");
    for (int i=0; i<argc; i++) {
        NSLog(@"argv[%d]: %s", i, argv[i]);
    }
    testMain(argc, argv, cAppPath);
    NSLog(@"testMain returned");

    /* Now report the results */
    NSString *gtestXmlOutput = [gtestOutput substringWithRange:NSMakeRange(19, [gtestOutput length] - 19)];
    NSLog(@"gtestXmlOutput = %@", gtestXmlOutput);
    
    // Write test results to a file
    NSData * data = [gtestXmlOutput dataUsingEncoding: [NSString defaultCStringEncoding] ];
    [filemgr createFileAtPath: @"/tmp/gtestOutput.xml" contents:data attributes:nil];
    
    //[self postResultsFile:gtestXmlOutput];
    
    [(GtestSuiteViewController *)[self delegate] testSuiteDidFinish];
}

- (NSString *)getXmlOutputDestination
{
    /*
     * Build a unique temporary file name to store the XML output of GTest.
     */
    CFStringRef uuid = CFUUIDCreateString(NULL, CFUUIDCreate(NULL));
    return [NSTemporaryDirectory() stringByAppendingPathComponent:
            [NSString stringWithFormat:@"%@.xml", uuid]];
}

- (NSString *)fileSize:(NSString *) path
{
    NSError *fmattrError=nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDictionary *fileAttributes = [fileManager
                                    attributesOfItemAtPath:path
                                    error:&fmattrError];
    
    if (fmattrError == nil) {
        return [[fileAttributes objectForKey:NSFileSize] stringValue];
    } else {
        return nil;
    }
}

/*
 * POSTs the results file to a waiting HTTP server.
 * This is expected to be a Python BaseHTTPServer instance running on the
 * Mac host that started this iOS test app.
 */
- (void)postResultsFile:(NSString *) resultsFilePath
{
    /*
     * The Python BaseHTTPServer does not support chunked transfers.
     * Set the Content-Length header.
     */
    NSLog(@"Entering postResultsFile");
    NSString *contentLength = [self fileSize:resultsFilePath];
    if (contentLength == nil) {
        NSLog(@"content length is null");
        return;
    }
    NSLog(@"Build http request");
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:
                                    [NSURL URLWithString:reportURL]];
    
    [request setValue:contentLength forHTTPHeaderField:@"Content-Length"];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBodyStream:
    [[NSInputStream alloc] initWithFileAtPath:resultsFilePath]];
    
    /* Send the request */
    NSLog(@"about to send the request");
    NSURLResponse *response;
    NSError *error = nil;
    
    [NSURLConnection sendSynchronousRequest:request returningResponse:&response
                                      error:&error];
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
    
    if (error != nil) {
        printf("%s\n", [[error localizedDescription] UTF8String]);
    }
    
    if ([httpResponse statusCode] / 100 == 2) {
        printf("POSTed\n");
    } else {
        printf("POST failure (%d)\n", [httpResponse statusCode]);
    }
    NSLog(@"post results file - complete");
}

@end
