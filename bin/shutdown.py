#!/usr/bin/python

import RPi.GPIO as GPIO
from subprocess import call
from datetime import datetime
import time

# Pushbutton connected to this GPIO pin, using pin 5 also has the benefit of
# waking / powering up the Raspberry Pi when button is pressed.
shutdown_pin = 5

# if button is pressed for at least this long then it shutdown.
# if less than this time, it reboots
shutdown_min_seconds = 2

# button debounce time in seconds
debounce_seconds = 0.01

GPIO.setmode(GPIO.BOARD)
GPIO.setup(shutdown_pin, GPIO.IN)

button_pressed_time = None


def button_state_changed(pin):
    global button_pressed_time

    if not (GPIO.input(pin)):
        # button is down
        if button_pressed_time is None:
            button_pressed_time = datetime.now()
    else:
        # button is up
        if button_pressed_time is None:
            return
        elapsed = (datetime.now() - button_pressed_time).total_seconds()
        button_pressed_time = None
        if elapsed >= shutdown_min_seconds:
            # Call if button is pressed for than specified time, shutdown
            call(('shutdown', '-h', 'now'), shell=False)
        elif elapsed >= debounce_seconds:
            # Button pressed for a shorter time, reboot
            call(('shutdown', '-r', 'now'), shell=False)

# Subscribe to button presses
GPIO.add_event_detect(shutdown_pin, GPIO.BOTH, callback=button_state_changed)

while True:
    time.sleep(5)
