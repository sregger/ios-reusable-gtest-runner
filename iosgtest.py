# ios_gtest.py
#
# Builds an instance of the reusable iOS Gtest app, then runs it
# in the iPhone Simulator

import os
import plistlib
import subprocess
import inspect
import shutil
import re
import argparse
    
def terminate_simulator():
    """
    Shuts down the OSX app 'iPhone Simulator'.  Tries politely first with
    an AppleScript one-liner, then roughly with killall.
    """
    terminateCmd = "osascript -e 'tell application \"iPhone Simulator\" to quit'"
    return_val = subprocess.call(terminateCmd, shell=True)
    subprocess.call("/usr/bin/killall iPhone\ Simulator", shell=True)
    subprocess.call("/usr/bin/killall GtestSuite", shell=True)

def set_iossimulator_hardware_version(iossimulator_sdk_name):
    """
    The only known way to run a given version of the iOS Simulator is to use the defaults command.
    Please read http://wikicentral.cisco.com/display/JCF/Notes+on+iOS+Simulator
    """

    print "Setting the IOS Simulator's Hardware Version to " + iossimulator_sdk_name
    currentSDKRoot = "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/" + iossimulator_sdk_name + ".sdk"

    if not os.path.exists(currentSDKRoot):
        raise Exception("There appears to be no iPhoneSimulator SDK at " + currentSDKRoot + ".  Please check that the requested sdk (" + iossimulator_sdk_name + ") exists.")

    print "Making subprocess calls..."
    subprocess.call("defaults delete com.apple.iPhoneSimulator currentSDKRoot || true", shell=True)
    subprocess.call("defaults write com.apple.iPhoneSimulator SimulateDevice iPhone", shell=True)
    subprocess.call("defaults write com.apple.iPhoneSimulator currentSDKRoot " + currentSDKRoot, shell=True)
    subprocess.call("defaults read com.apple.iphonesimulator", shell=True)

    print "Subprocess calls finished."

def set_iossimulator_hardware_version_to_latest_sdk():
    set_iossimulator_hardware_version(get_latest_iossimulator_hardware_version())

def get_latest_iossimulator_sdk_name():
    process = subprocess.Popen(["xcodebuild", "-showsdks"], stdout=subprocess.PIPE)
    out, err = process.communicate()

    # Use Regular Expressions to search for SDKs
    findsdks_expression = re.compile("-sdk \S+")
    results = findsdks_expression.findall(out)
    sdkversions = [result for result in results if "simulator" in result]

    # We believe the latest sdk to be the last one in the list.  Note the -1 index.
    # We also remove the "-sdk " string via slicing.  Note the "5:" slice.
    return sdkversions[-1][5:] 

def get_latest_iossimulator_hardware_version():
    print "Getting the latest Hardware Version of the IOS Simulator"
    return get_latest_iossimulator_sdk_name().replace("iphonesimulator", "iPhoneSimulator")

def start_app(gtest_filter=None, gtest_output='gtest_result.xml', iossimulator_xcodebuild_sdk_version=None, iossimulator_hardware_version=None, csf_TestDataLocation=None,csfConfigSection='DEFAULT'):
    # Currently store the log file at the xcode project directory.
    abspathtodir = os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))
    logFile = os.path.join(abspathtodir, 'GtestSuite.log')
    
    # Generate plist with the given gtest filter and ini file values in the provided plist file 
    gFilter = ''
    iniFile = 'tests.ini'
    outputFile = ''
    if csf_TestDataLocation == None:
        csfTestDataLocation = abspathtodir
    else:
        csfTestDataLocation = csf_TestDataLocation
    
    if gtest_filter is not None:
       gFilter = '--gtest_filter='+gtest_filter
    
    if gtest_output is not None:
       outputFile = '--gtest_output=xml:'+gtest_output
    
    # Write the options.plist file for the iOS app to be built
    pl = dict(
        GTEST_FILTER= gFilter,
        GTEST_OUTPUT= outputFile,
        INI_FILE= iniFile,
        INI_FILE_SECTION = csfConfigSection,
        LOG_FILE = logFile,
        TEST_DATA_LOC = csfTestDataLocation
    )
    plist_file = os.path.join(abspathtodir, "GtestSuite", "options.plist")
    file = open(plist_file,'w')
    plistlib.writePlist(pl, file)
    file.close()
    
    # Build the Xcode project using the latest sdk if None was specified.
    # In the case that the user only enters an sdk number, as opposed to a full sdk name, concatenate iphonesimulator at the front of the number. 
    if iossimulator_xcodebuild_sdk_version is None :        
        iossimulator_xcodebuild_sdk_version = get_latest_iossimulator_sdk_name()
    else :
        sdk_version_expression = re.compile("\d+\.\d+")
        match_obj = sdk_version_expression.match(iossimulator_xcodebuild_sdk_version)
        if match_obj :
            iossimulator_xcodebuild_sdk_version = "iphonesimulator" + iossimulator_xcodebuild_sdk_version

    # Build the iPhone Application        
    buildCmd = "cd " + abspathtodir + " && xcodebuild -configuration Debug -sdk " + iossimulator_xcodebuild_sdk_version + " -target GtestSuite clean build install"
    print "buildCmd: ", buildCmd
    rc = subprocess.call(buildCmd, shell=True)
    
    if rc is not 0:
        raise Exception("Failed to build the Gtest App for iOS, probably because of linker errors.  The command returned error code " + str(rc) + ".")      
    
    # At this point we need to copy any custom files over to the new GTest App 
    testdatadir = os.path.join(abspathtodir, "GtestSuite/testdata")
    # Ensure folder is created in case there are no resource files
    if not os.path.isdir( testdatadir ):
        os.mkdir(testdatadir)

    testfiles = os.listdir(testdatadir)
    for filename in testfiles:
        src = os.path.join(testdatadir, filename)
        dest = os.path.join(abspathtodir, "build/Debug-iphonesimulator/GtestSuite.app", filename)
        if os.path.isdir(src):
            shutil.copytree(src, dest)
        else:
            shutil.copy(src, dest)

    # Decide what hardware version of the simulator to use.  Use a specific simulator version if one was requested.  If not then use the latest version.
    if not iossimulator_hardware_version is None :
        # The user may just set the version as opposed to the name of the sdk which contains the simulator, so take care of this.
        hardware_version_expression = re.compile("\d+\.\d+")
        match_obj = hardware_version_expression.match(iossimulator_hardware_version)
        if match_obj :
            iossimulator_hardware_version = "iPhoneSimulator" + iossimulator_hardware_version

        print "Attempting to use " + iossimulator_hardware_version + " as the hardware version of the IOS Simulator."
        set_iossimulator_hardware_version(iossimulator_hardware_version)
    else :
        print "Attempting to use the latest available hardware version of the IOS Simulator."
        set_iossimulator_hardware_version_to_latest_sdk()
    
    # Run the executable file from command line   
    iphone_simulator_path = "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Applications/iPhone\ Simulator.app/Contents/MacOS/iPhone\ Simulator"
    project_path = os.path.join(abspathtodir, "build/Debug-iphonesimulator/GtestSuite.app", "GtestSuite")
    runCmd = "cd " + os.path.join(abspathtodir, "build/Debug-iphonesimulator/GtestSuite.app") + " && " + iphone_simulator_path + " -SimulateApplication " + project_path
    print "runCmd: ", runCmd
    simulator_pid = subprocess.Popen(runCmd, shell=True).pid
    
    # Wait for user input
    #raw_input('Press Enter key to continue')
    
    # Terminate the iphone simulator, our child process
    #cmd = "kill -9 " + str(simulator_pid)
    #subprocess.call(cmd, shell=True)

if __name__ == "__main__":

    # Parse comand line options
    parser = argparse.ArgumentParser(description='Process passed in arguments into plist')
    parser.add_argument('--gtest_filter', default=None)
    parser.add_argument('--gtest_output', default='gtest_result.xml')
    parser.add_argument('--csf_test_data_location', default='../TestData')
    parser.add_argument('--csf_config_section', default='DEFAULT')
    args = parser.parse_args()

    start_app(args.gtest_filter, args.gtest_output, None, None, args.csf_test_data_location, args.csf_config_section)