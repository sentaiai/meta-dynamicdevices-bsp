#!/bin/sh

#
# TAS2563 SmartAMP initialization for mainline TAS2781 driver (ti,tas2563).
#

SCRIPT_NAME="tas2563-init"
LOG_TAG="[$SCRIPT_NAME]"
AUDIO_CARD="tas2563audio"
FW_RCA="/lib/firmware/tas2563RCA1.bin"
FW_COEF="/lib/firmware/tas2563_coef.bin"

log_info() {
    echo "$LOG_TAG INFO: $1"
    logger -t "$SCRIPT_NAME" "INFO: $1"
}

log_error() {
    echo "$LOG_TAG ERROR: $1" >&2
    logger -t "$SCRIPT_NAME" "ERROR: $1"
}

wait_for_firmware() {
    i=0
    while [ $i -lt 30 ]; do
        if [ -f "$FW_RCA" ] && [ -f "$FW_COEF" ]; then
            return 0
        fi
        sleep 1
        i=$((i + 1))
    done
    log_error "TAS2563 firmware missing ($FW_RCA, $FW_COEF)"
    return 1
}

wait_for_audio_card() {
    i=0
    while [ $i -lt 30 ]; do
        if amixer -c "$AUDIO_CARD" info >/dev/null 2>&1; then
            return 0
        fi
        sleep 1
        i=$((i + 1))
    done
    log_error "Audio card '$AUDIO_CARD' not found"
    return 1
}

control_exists() {
    amixer -c "$AUDIO_CARD" cget name="$1" >/dev/null 2>&1
}

set_profile() {
    profile="$1"
    if control_exists "Speaker Profile Id"; then
        amixer -c "$AUDIO_CARD" cset name="Speaker Profile Id" "$profile"
    elif control_exists "TASDEVICE Profile id"; then
        amixer -c "$AUDIO_CARD" cset name="TASDEVICE Profile id" "$profile"
    else
        log_error "Profile control not found"
        return 1
    fi
}

check_dsp_firmware() {
    control_exists "Speaker Program Id" || control_exists "Program"
}

set_echo_removal_mode() {
    log_info "Configuring Profile 8 (echo reference)"

    if check_dsp_firmware; then
        log_info "DSP firmware detected - using DSP mode"
        if control_exists "Speaker Program Id"; then
            amixer -c "$AUDIO_CARD" cset name="Speaker Program Id" 0
        else
            amixer -c "$AUDIO_CARD" cset name="Program" 0
        fi
        set_profile 8 || return 1
        if control_exists "Speaker Config Id"; then
            amixer -c "$AUDIO_CARD" cset name="Speaker Config Id" 0
        elif control_exists "Configuration"; then
            amixer -c "$AUDIO_CARD" cset name="Configuration" 0
        fi
    else
        log_info "DSP controls absent; using regbin Profile 8 only"
        set_profile 8 || return 1
    fi

    log_info "Profile 8 configured"
    return 0
}

set_optimal_volume() {
    if control_exists "Speaker Analog Volume"; then
        amixer -c "$AUDIO_CARD" cset name="Speaker Analog Volume" 20
    elif control_exists "tas2563-amp-gain-volume"; then
        amixer -c "$AUDIO_CARD" cset name="tas2563-amp-gain-volume" 20
    fi

    if control_exists "Speaker Digital Volume"; then
        amixer -c "$AUDIO_CARD" cset name="Speaker Digital Volume" 82
    elif control_exists "tas2563-digital-volume"; then
        amixer -c "$AUDIO_CARD" cset name="tas2563-digital-volume" 49152
    fi

    if control_exists "tas2563-digital-mute"; then
        amixer -c "$AUDIO_CARD" cset name="tas2563-digital-mute" 0
    fi
}

show_status() {
    log_info "Current TAS2563 status:"
    amixer -c "$AUDIO_CARD" controls | grep -i "speaker\|tas\|program\|profile\|config" || true
}

main() {
    mode="${1:-default}"

    log_info "Initializing TAS2563 (mode: $mode)"

    wait_for_firmware || exit 1
    wait_for_audio_card || exit 1
    sleep 1

    case "$mode" in
        default|echo-removal|basic|audio)
            set_echo_removal_mode || exit 1
            set_optimal_volume
            ;;
        status)
            show_status
            ;;
        *)
            echo "Usage: $0 [default|echo-removal|status]"
            exit 1
            ;;
    esac
}

main "$@"
