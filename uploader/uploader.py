# Upload hex file to Arduboy by Mr.Blinky October 2017 v1.03

#requires pyserial to be installed

import sys
import time
import os
import subprocess
from serial.tools.list_ports  import comports
from serial import Serial
import zipfile

compatibledevices = [
 #Arduino Leonardo
 "VID:PID=2341:0036", "VID:PID=2341:8036",
 "VID:PID=2A03:0036", "VID:PID=2A03:8036",
 #Arduino Micro
 "VID:PID=2341:0037", "VID:PID=2341:8037",
 "VID:PID=2A03:0037", "VID:PID=2A03:8037",
 #Genuino Micro
 "VID:PID=2341:0237", "VID:PID=2341:8237",
 #Sparkfun Pro Micro 5V
 "VID:PID=1B4F:9205", "VID:PID=1B4F:9206",
]

bootloader = False

def delayedExit():
    time.sleep(5)
    #raw_input()    
    sys.exit()
    
def getComPort(verbose):
    global  bootloader
    devicelist = list(comports())
    for device in devicelist:
        for vidpid in compatibledevices:
            if  vidpid in device[2]:
                port=device[0]
                bootloader = (compatibledevices.index(vidpid) and 1) == 0
                if verbose : print "found {} at port {}".format(device[1],port)
                return port
    if verbose : print "Arduboy or clone not found."

path = os.path.dirname(sys.argv[0]) + os.sep

#test file exists
if len(sys.argv) <> 2:
    print "USAGE:\n\nuploader.py file_to_upload.hex"
    delayedExit()
filename = sys.argv[1]  
if not os.path.isfile(filename) :
    print "File not found. [{}]".format(filename)
    delayedExit()
    
#if file is zipfile, extract hex file
try:
    zip = zipfile.ZipFile(filename)
    for file in zip.namelist():
        if file.lower().endswith('.hex'):
                zipinfo = zip.getinfo(file)
                zipinfo.filename = "uploader-temp.hex"
                zip.extract(zipinfo,path)
                filename = path + zipinfo.filename;
    tempfile = True
except:
    tempfile = False

#scan hex file for data in bootloader area
f = open(filename,'r')
lines = f.readlines()
f.close()
for line in lines:
    if len(line) > 4:
        if line[0] ==':' and line[3] == '7':    
            print 'Warning!!! This hex file may corrupt the bootloader on unprotected devices.'
            if raw_input("Type \'y\' followed by enter to continue. Anything else to abort.").lower() == "yes":
                break
            print 'Upload aborted.'    
            delayedExit()
        
#trigger bootloader reset
port = getComPort(True)
if port is None :
    delayedExit()
if not bootloader:
    print "Selecting bootloader mode..."
    com = Serial(port,1200)
    com.close()
    #wait for Arduboy to disconnect and reconnect in bootloader mode
    while getComPort(False) == port :
        time.sleep(0.1)
    while getComPort(False) is None :
        time.sleep(0.1)
    port = getComPort(True)

#launch avrdude
avrdude = "{}avrdude.exe".format(path)
config  = "-C{}avrdude.conf".format(path)
subprocess.call ([avrdude,config, "-v", "-patmega32u4", "-cavr109", "-P{}".format(port), "-b57600", "-D", "-Uflash:w:{}:i".format(filename)])
if tempfile == True : os.remove(filename)
delayedExit()