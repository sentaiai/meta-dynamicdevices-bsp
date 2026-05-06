#!/bin/bash
set -e

#
# Sentai Initial Production Test.
# To be operated by technician at manufacturing house.
#
# NOTES:
#
#  - This test script must be run as the root user. e.g.
#
#    # sudo production-test.sh [enter password]
#
#  - Command line options:
#    --ignore-container-errors  Ignore errors when stopping containers (debug mode)
#                                Normal operation requires containers to stop successfully
#                                to verify unit has registered with Foundries platform
#
# Process:
#
# - Flash current manufacturing image. NOTE: THIS MUST NOT BE RELEASED TO CUSTOMER WITHOUT SECURING
# - Run this production test and ensure all tests pass
# - Agree to secure device by entering 'Y' when asked
#

#
# Definitions
#

VERSION=0.1
IGNORE_CONTAINER_ERRORS=0

#
# Parse command line arguments
#

while [[ $# -gt 0 ]]; do
    case $1 in
        --ignore-container-errors)
            IGNORE_CONTAINER_ERRORS=1
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --ignore-container-errors  Ignore errors when stopping containers (debug mode)"
            echo "                             Normal operation requires containers to stop successfully"
            echo "                             to verify unit has registered with Foundries platform"
            echo "  -h, --help                 Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

#
# Test script
#

# Check if running as root
if [ "$EUID" -ne 0 ]
  then echo "Please run as root by running this command with sudo 'sudo production-test.sh' and entering the password"
  exit
fi

echo -e "Stopping Sentai application\n"
if [ $IGNORE_CONTAINER_ERRORS -eq 1 ]; then
    # Debug mode: ignore errors stopping containers
    docker stop sentaispeaker-SentaiSpeaker-1 2>/dev/null || true
    echo "DEBUG: Ignoring container stop errors (--ignore-container-errors flag set)"
else
    # Normal operation: container must stop successfully to verify Foundries registration
    if ! docker stop sentaispeaker-SentaiSpeaker-1 2>/dev/null; then
        echo "ERROR: Failed to stop Sentai container 'sentaispeaker-SentaiSpeaker-1'"
        echo "This indicates the unit may not have registered with the Foundries platform."
        echo "Container must be running for registration to succeed."
        echo ""
        echo "If you need to debug this issue, use --ignore-container-errors flag:"
        echo "  sudo production-test.sh --ignore-container-errors"
        exit 1
    fi
fi

echo -e "Running Sentai Production Test - Version ${VERSION}\n"

# (1) Show board infomation
echo -e "(1) Record the board information for your records"
board-info.sh

# (2) Run LED Testing
echo -e "\n"
read -r -p "(2) Run LED tests? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
then
    echo -e "You should see red, green, blue and white LEDs cycling\n"
    test-leds-hb.sh

echo -e "\n"
read -r -p "Did you see the correct LED colours with none missing? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
then
    echo -e "\n"
    elif [[ "$response" =~ ^([yY][eE][yY])$ ]]
    then
        echo TEST FAILED
        exit 1
    fi
elif [[ "$response" =~ ^([yY][eE][yY])$ ]]
then
    echo TEST FAILED
    exit 1
fi

# (3) Run humidity sensor Testing
echo -e "\n"
read -r -p "(3) Run humidity sensor tests? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
then
    echo -e "\n"
    sensors || true

echo -e "\n"
read -r -p "Did a reasonable temperature and humidity value display? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
then
    echo -e "\n"
    elif [[ "$response" =~ ^([yY][eE][yY])$ ]]
    then
        echo TEST FAILED
        exit 1
    fi
elif [[ "$response" =~ ^([yY][eE][yY])$ ]]
then
    echo TEST FAILED
    exit 1
fi

# (4) Program STUSB4500 (Sentai and other boards with STUSB4500 — not on DT510)
echo -e "\n"
if grep -q "jaguar-dt510" /proc/device-tree/compatible 2>/dev/null
then
    echo "(4) Program STUSB4500 — skipped (not populated on i.MX8MM Jaguar DT510)"
else
read -r -p "(4) Program STUSB4500? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
then
    echo -e "\n"
    stusb4500-utils write --file /lib/firmware/stusb4500.dat

echo -e "\n"
read -r -p "Did the programming step complete successfully ? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
then
    echo -e "\n"
    elif [[ "$response" =~ ^([yY][eE][yY])$ ]]
    then
        echo TEST FAILED
        exit 1
    fi
elif [[ "$response" =~ ^([yY][eE][yY])$ ]]
then
    echo TEST FAILED
    exit 1
fi
fi

# (5) Input button testing
echo -e "\n"
read -r -p "(5) Test button input? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
then
    if [ ! -d /sys/class/gpio/gpio102 ]
    then
      echo 102 > /sys/class/gpio/export
    fi
    echo -e "Press and hold down the button within 5s\n"
    sleep 5
    BUTTONVALUE=$(cat /sys/class/gpio/gpio102/value)
    echo -e ">>${BUTTONVALUE}<<\n"
    # Button is active LO
    if [ "${BUTTONVALUE}" -eq "1" ]
    then
        echo -e "TEST FAILED - BUTTON PRESS NOT DETECTED\n"
        exit 1
    fi
    echo -e "Button press detected. Release the button now\n"
elif [[ "$response" =~ ^([yY][eE][yY])$ ]]
then
    echo TEST FAILED
    exit 1
fi


# (6) Audio Testing
echo -e "\n"
read -r -p "(6) Perform Audio Testing [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
then
    echo -e "Setting the audio levels\n\n"
    echo "Fixing speaker hardware gains (do NOT change during calls)"
    amixer -c tas2563audio set 'Digital Volume Control' 110
    amixer -c tas2563audio set 'Amp Gain' 20dB
    
    echo "Configuring MICFIL input"
    amixer -c micfilaudio cset name='MICFIL Quality Select' 'High'
    amixer -c micfilaudio set 'CH0' 10
    amixer -c micfilaudio set 'CH1' 10
    amixer -c micfilaudio set 'CH2' 0
    amixer -c micfilaudio set 'CH3' 0
    amixer -c micfilaudio set 'CH4' 0
    amixer -c micfilaudio set 'CH5' 0
    amixer -c micfilaudio set 'CH6' 0
    amixer -c micfilaudio set 'CH7' 0
    
    
    echo -e "Done setting the audio levels\n\n"

    echo -e "Now playing an audio sample\n"
    su -c "aplay -Dhw:1,0 /usr/share/board-scripts/board-testing-now-starting-up-stereo-48k.wav" fio
    read -r -p "Did you hear the audio play back [y/N] " response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
    then
        echo -e "Audio playback worked\n"
    else
        echo TEST FAILED
        exit 1
    fi

    amixer -c micfilaudio set 'CH0' 15
    amixer -c micfilaudio set 'CH1' 0

    echo -e "\n\nNow recording 5s audio on FIRST microphone channel\n"
    read -r -p "Press RETURN key to start recording and then start counting up in a clear voice"
    echo -e "\nStarted recording...\n"

    su -c "arecord -Dhw:2,0 -c2 -f s16_le -r48000 -d5 test-l-stereo.wav && python3 /usr/share/board-scripts/extract_channel.py test-l-stereo.wav test-l.wav 0 && rm -f test-l-stereo.wav" fio

    read -r -p "Done recording. Press RETURN key to play back recording"

      echo -e "\n\nNow playing back recording\n"
      su -c "python3 /usr/share/board-scripts/mono_to_stereo.py test-l.wav test-l-stereo.wav && aplay -Dhw:1,0 test-l-stereo.wav && rm -f test-l.wav test-l-stereo.wav" fio

    read -r -p "Did you hear the audio play back [y/N] " response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
    then
        echo -e "Audio playback worked\n"
    else
        echo TEST FAILED
        exit 1
    fi

    amixer -c micfilaudio set 'CH0' 0
    amixer -c micfilaudio set 'CH1' 15

    echo -e "\n\nNow recording 5s audio on SECOND microphone channel\n"
    read -r -p "Press RETURN key to start recording and then start counting up in a clear voice"
    echo -e "\nStarted recording...\n"

    su -c "arecord -Dhw:2,0 -c2 -f s16_le -r48000 -d5 test-r-stereo.wav && python3 /usr/share/board-scripts/extract_channel.py test-r-stereo.wav test-r.wav 1 && rm -f test-r-stereo.wav" fio

    read -r -p "Done recording. Press RETURN key to play back recording"


      echo -e "\n\nNow playing back recording\n"
      su -c "python3 /usr/share/board-scripts/mono_to_stereo.py test-r.wav test-r-stereo.wav && aplay -Dhw:1,0 test-r-stereo.wav && rm -f test-r.wav test-r-stereo.wav" fio

    read -r -p "Did you hear the audio play back [y/N] " response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
    then
        echo -e "Audio playback worked\n"
    else
        echo TEST FAILED
        exit 1
    fi
elif [[ "$response" =~ ^([yY][eE][yY])$ ]]
then
    echo TEST FAILED
    exit 1
fi

# (7) BLE Testing
echo -e "\n"
read -r -p "(7) Perform Bluetooth BLE Testing [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
then
    echo -e "Now scanning for bluetooth devices\n"
    bluetoothctl power on
    bluetoothctl --timeout 5 scan on
    bluetoothctl power off
    echo -e "\n^^^ You should have seen a number of MAC addresses and device names\n"
    
    echo -e "\n"
    read -r -p "Did you see a number of bluetooth MAC addresses and device names ? [y/N] " response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
    then
        echo -e "\n"
    elif [[ "$response" =~ ^([yY][eE][yY])$ ]]
    then
        echo TEST FAILED
        exit 1
    fi
elif [[ "$response" =~ ^([yY][eE][yY])$ ]]
then
    echo TEST FAILED
    exit 1
fi

# (8) Radar Testing
echo -e "\n"
read -r -p "(8) Perform Radar Testing [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
then
    echo -e "Checking radar service status...\n"
    if ! systemctl is-active --quiet xm125-radar-monitor.service; then
        echo "TEST FAILED - xm125-radar-monitor service is not running"
        echo -e "\nService status:"
        systemctl status xm125-radar-monitor.service --no-pager -l || true
        echo -e "\nRecent service logs (last 20 lines):"
        journalctl -u xm125-radar-monitor.service -n 20 --no-pager || true
        exit 1
    fi
    
    if [ ! -p /tmp/presence ]; then
        echo "TEST FAILED - /tmp/presence FIFO does not exist"
        exit 1
    fi
    
    echo -e "Testing for presence detection...\n"
    echo -e "IMPORTANT: You must be present in front of the sensor for this test\n"
    echo -e "Reading radar data (waiting up to 60 seconds for presence detection)...\n"
    
    # Keep reading from FIFO for up to 60 seconds until presence is detected
    PRESENCE_DETECTED=0
    PRESENCE_DATA=""
    START_TIME=$(date +%s)
    TIMEOUT=60
    
    while [ $(( $(date +%s) - START_TIME )) -lt $TIMEOUT ]; do
        # Read one line from FIFO (non-blocking with timeout)
        READ_DATA=$(timeout 1 cat /tmp/presence 2>&1) || true
        if [ -n "$READ_DATA" ] && ! echo "$READ_DATA" | grep -q "timeout: cannot run command"; then
            PRESENCE_DATA="$READ_DATA"
            # Extract and display presence status
            PRESENCE_STATUS=$(echo "$PRESENCE_DATA" | grep -o '"presence_detected":[^,}]*' | cut -d':' -f2 | tr -d ' ')
            PRESENCE_DISTANCE=$(echo "$PRESENCE_DATA" | grep -o '"presence_distance_m":[^,}]*' | cut -d':' -f2 | tr -d ' ')
            SIGNAL_QUALITY=$(echo "$PRESENCE_DATA" | grep -o '"signal_quality":"[^"]*' | cut -d'"' -f4)
            
            echo -e "Radar Status:\n"
            echo -e "  Presence Detected: ${PRESENCE_STATUS}"
            if [ -n "$PRESENCE_DISTANCE" ]; then
                echo -e "  Distance: ${PRESENCE_DISTANCE} m"
            fi
            if [ -n "$SIGNAL_QUALITY" ]; then
                echo -e "  Signal Quality: ${SIGNAL_QUALITY}\n"
            fi
            
            # Check if presence is detected
            if echo "$PRESENCE_DATA" | grep -q '"presence_detected":true'; then
                PRESENCE_DETECTED=1
                echo -e "✓ Presence detected - sensor is working\n"
                break
            fi
        fi
        sleep 1
    done
    
    # Check if we detected presence within the timeout
    if [ $PRESENCE_DETECTED -eq 0 ]; then
        if [ -z "$PRESENCE_DATA" ]; then
            echo "TEST FAILED - No data received from radar FIFO"
            exit 1
        else
            echo "TEST FAILED - No presence detected after ${TIMEOUT} seconds. You must be present in front of the sensor for this test."
            exit 1
        fi
    fi

    echo -e "Please cover the radar sensor with your hand or an object\n"
    read -r -p "Press RETURN when you have covered the sensor..."
    
    echo -e "\nTesting for absence of presence...\n"
    echo -e "Reading radar data (waiting up to 60 seconds to verify no presence)...\n"

    # Keep reading from FIFO for up to 60 seconds to verify no presence is detected
    NO_PRESENCE_CONFIRMED=0
    NO_PRESENCE_DATA=""
    START_TIME=$(date +%s)
    TIMEOUT=60

    while [ $(( $(date +%s) - START_TIME )) -lt $TIMEOUT ]; do
        # Read one line from FIFO (non-blocking with timeout)
        READ_DATA=$(timeout 1 cat /tmp/presence 2>&1) || true
        if [ -n "$READ_DATA" ] && ! echo "$READ_DATA" | grep -q "timeout: cannot run command"; then
            NO_PRESENCE_DATA="$READ_DATA"
            # Extract and display presence status
            NO_PRESENCE_STATUS=$(echo "$NO_PRESENCE_DATA" | grep -o '"presence_detected":[^,}]*' | cut -d':' -f2 | tr -d ' ')
            NO_PRESENCE_DISTANCE=$(echo "$NO_PRESENCE_DATA" | grep -o '"presence_distance_m":[^,}]*' | cut -d':' -f2 | tr -d ' ')
            NO_SIGNAL_QUALITY=$(echo "$NO_PRESENCE_DATA" | grep -o '"signal_quality":"[^"]*' | cut -d'"' -f4)

            echo -e "Radar Status (after covering):\n"
            echo -e "  Presence Detected: ${NO_PRESENCE_STATUS}"
            if [ -n "$NO_PRESENCE_DISTANCE" ]; then
                echo -e "  Distance: ${NO_PRESENCE_DISTANCE} m"
            fi
            if [ -n "$NO_SIGNAL_QUALITY" ]; then
                echo -e "  Signal Quality: ${NO_SIGNAL_QUALITY}\n"
            fi

            # Check if no presence is detected (this is success)
            if echo "$NO_PRESENCE_DATA" | grep -q '"presence_detected":false'; then
                NO_PRESENCE_CONFIRMED=1
                echo -e "✓ No presence detected - sensor correctly detected coverage\n"
                echo -e "Radar test PASSED\n"
                break
            fi
            # If presence is still detected, keep trying (don't fail immediately)
        fi
        sleep 1
    done

    # Check if we successfully confirmed no presence within the timeout
    if [ $NO_PRESENCE_CONFIRMED -eq 0 ]; then
        if [ -z "$NO_PRESENCE_DATA" ]; then
            echo "TEST FAILED - No data received from radar FIFO"
        else
            echo "TEST FAILED - Sensor still detecting presence after ${TIMEOUT} seconds when covered"
        fi
        exit 1
    fi
elif [[ "$response" =~ ^([yY][eE][yY])$ ]]
then
    echo TEST FAILED
    exit 1
fi

# Check we are on the Foundries cloud

# (9) Unmask update service
#echo -e "\n"
#read -r -p "(8) Are you ready to enable the Foundries.io update service [y/N] " response
#if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
#then
#    echo -e "\n"
#    echo Enabling Foundries.io update service
#    systemctl unmask aktualizr-lite
#elif [[ "$response" =~ ^([yY][eE][yY])$ ]]
#then
#    echo TEST FAILED
#    exit 1
#fi

# (9) Secure device
echo -e "\n"
read -r -p "(9) Are you ready to secure the device? NOTE YOU CAN ONLY DO THIS ONCE [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
then
    echo -e "\n"
    echo SECURING DEVICE
    echo -e "- Set secure password for fio user"
    # TODO: Check if salt is present and error?
    set-fio-passwd.sh
    rm -f /etc/salt
    echo -e "- Enable firewall"
    enable-firewall.sh
    echo -r "- Disable production WiFi connection [TODO]"
#    nmcli c del SentaiProduction
elif [[ "$response" =~ ^([yY][eE][yY])$ ]]
then
    echo TEST FAILED
    exit 1
fi

# Check app container is running

echo -e "Production test successful\n"
date > /etc/.production-test-successful
su -c "aplay -Dhw:1,0 /usr/share/board-scripts/tests-all-completed-stereo-48k.wav" fio
exit 0
