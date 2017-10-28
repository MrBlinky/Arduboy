## Arduboy bootloader Bad Apple streaming demo by Mr.Blinky October 2017 1.02 ##

#requires pyserial to be installed

import sys
import time
import os
#import subprocess
from serial.tools.list_ports  import comports
from serial import Serial

compatibledevices = [
 #Arduboy Leonardo
 "VID:PID=2341:0036", "VID:PID=2341:8036",
 "VID:PID=2A03:0036", "VID:PID=2A03:8036",
 #Arduboy Micro
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
	
def	getComPort(verbose):
	global	bootloader
	devicelist = list(comports())
	for device in devicelist:
		for vidpid in compatibledevices:
			if  vidpid in device[2]:
				port=device[0]
				bootloader = (compatibledevices.index(vidpid) and 1) == 0
				if verbose : print "found {} at port {}".format(device[1],port)
				return port
	if verbose : print "Arduboy board not found."

def	TestStreamingSupport():
	global com
	#test bootloadersupports streaming by testing hardware version command
	com.write('v')
	if com.read(1) == '?': # No support
		print "Bootloader doesn't support streaming"
		delayedExit()
	else:
		print "Bootloader supports streaming"
		com.read(1) # drop 2nd hardware version byte
	return True
	
def	WaitButton():
	global com
	while True:
		com.write('v')
		if com.read(2) !='1A':
			break
	while True:
		com.write('v')
		if com.read(2) =='1A':
			break
	
def ReadButtons():
	global com
	com.write('v')
	buttons = ((ord(com.read(1)) - ord('1') << 2)) | ((ord(com.read(1)) - ord('A') << 4))
	return buttons

def	ResetTimeout():
	global com
	com.write('g\x00\x00F')

def ShortTimeout(): #sets timeout to half a second
	global com
	com.write('E')
	com.read(1)

def Display(image):
	global com
	com.write('A\x00\x00')
	com.read(1)
	for i in range(0,8):
		com.write('B\x00\x80D' + image[i*128:(i+1)*128])
		com.read(1)
		
def	LedControl(b):            #Bit 7 set: OLED display off
	com.write('x' + chr(b))   #Bit 6 set: RGB Breathing function off
	com.read(1)               #Bit 5 set: RxTx status function off
		                      #Bit 4 set: Rx LED on
		                      #Bit 3 set: Tx LED on
							  #Bit 2 set: RGB LED green on
							  #Bit 1 set: RGB LED red on
							  #Bit 0 set: RGB LED blue on

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
	
com = Serial(port,57600)
TestStreamingSupport()

f = open ("imagedata.bin",'rb')
imagedata = bytearray(f.read())
f.close

print 'streaming....'
t = time.time()
while not (ReadButtons() & 0x0C):
	for i in range (0,len(imagedata),1024):
		while abs(time.time() - t) < .030: #~30 fps
			pass
		t = time.time()
		Display(imagedata[i:i+1024])
		b = ReadButtons()
		if (b & 0x0C):
			break
		elif (b & 0x20): #Left
			LedControl(0x60) #RGB breathing and RxTx transfer status off
		elif (b & 0x40): #Right
			LedControl(0x00)
		
print 'Button pressed, streaming ended.'
ShortTimeout()

delayedExit()