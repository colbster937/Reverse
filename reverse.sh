#!/bin/bash

show_help() {
    echo "Usage: [start|stop]"
    echo "  start: Starts a new screen session running the Python server."
    echo "  stop: Stops all screen sessions."
}

screen_exists() {
    screen -ls | grep -q "There is a screen on"
}

if [[ $# -eq 0 ]]; then
    if screen_exists; then
        screen -r -d
    else
        show_help
    fi
elif [[ $1 == "start" ]]; then
    screen python3 /usr/local/Reverse/server.py
elif [[ $1 == "stop" ]]; then
    killall screen
else
    echo "Invalid option: $1"
    show_help
fi
