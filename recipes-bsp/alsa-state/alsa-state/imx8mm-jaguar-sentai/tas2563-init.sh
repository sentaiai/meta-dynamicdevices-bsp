#!/bin/sh

#
# TAS2563 SmartAMP initialization for TI OOT integrated driver (snd-soc-integrated-tasdevice).
#

SCRIPT_NAME="tas2563-init"
LOG_TAG="[$SCRIPT_NAME]"
AUDIO_CARD="tas2563audio"
FW_REG="/lib/firmware/tas2563-1amp-reg.bin"
FW_DSP="/lib/firmware/tas2563-1amp-dsp.bin"

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
        if [ -f "$FW_REG" ] && [ -f "$FW_DSP" ]; then
            return 0
        fi
        sleep 1
        i=$((i + 1))
    done
    log_error "TAS2563 firmware missing ($FW_REG, $FW_DSP)"
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
    if control_exists "TASDEVICE Profile id"; then
        amixer -c "$AUDIO_CARD" cset name="TASDEVICE Profile id" "$profile"
    elif control_exists "Speaker Profile Id"; then
        amixer -c "$AUDIO_CARD" cset name="Speaker Profile Id" "$profile"
    else
        log_error "Profile control not found"
        return 1
    fi
}

set_program() {
    program="$1"
    if control_exists "Program"; then
        amixer -c "$AUDIO_CARD" cset name="Program" "$program"
    elif control_exists "Speaker Program Id"; then
        amixer -c "$AUDIO_CARD" cset name="Speaker Program Id" "$program"
    fi
}

set_configuration() {
    config="$1"
    if control_exists "Configuration"; then
        amixer -c "$AUDIO_CARD" cset name="Configuration" "$config"
    elif control_exists "Speaker Config Id"; then
        amixer -c "$AUDIO_CARD" cset name="Speaker Config Id" "$config"
    fi
}

set_basic_mode() {
    log_info "Configuring Profile 0 (I2S playback)"

    set_profile 0 || return 1
    set_program 0
    set_configuration 0

    log_info "Profile 0 configured"
    return 0
}

set_echo_removal_mode() {
    log_info "Configuring Profile 8 (echo reference / TDM)"

    set_profile 8 || return 1
    set_program 0
    set_configuration 0

    log_info "Profile 8 configured"
    return 0
}

set_optimal_volume() {
    if control_exists "Amp Gain"; then
        amixer -c "$AUDIO_CARD" cset name="Amp Gain" 20
    elif control_exists "tas2563-amp-gain-volume"; then
        amixer -c "$AUDIO_CARD" cset name="tas2563-amp-gain-volume" 20
    elif control_exists "Speaker Analog Volume"; then
        amixer -c "$AUDIO_CARD" cset name="Speaker Analog Volume" 20
    fi

    if control_exists "Digital Volume Control"; then
        amixer -c "$AUDIO_CARD" cset name="Digital Volume Control" 110
    elif control_exists "tas2563-digital-volume"; then
        amixer -c "$AUDIO_CARD" cset name="tas2563-digital-volume" 49152
    elif control_exists "Speaker Digital Volume"; then
        amixer -c "$AUDIO_CARD" cset name="Speaker Digital Volume" 82
    fi

    if control_exists "tas2563-digital-mute"; then
        amixer -c "$AUDIO_CARD" cset name="tas2563-digital-mute" 0
        log_info "Unmuted TAS2563 (PWR_CTRL)"
    fi
}

finalize_after_profile_load() {
    sleep 2
    set_optimal_volume
}

show_status() {
    log_info "Current TAS2563 status:"
    amixer -c "$AUDIO_CARD" controls | grep -i "speaker\|tas\|program\|profile\|config\|volume\|gain" || true
}

main() {
    mode="${1:-default}"

    log_info "Initializing TAS2563 (mode: $mode)"

    wait_for_firmware || exit 1
    wait_for_audio_card || exit 1
    sleep 1

    case "$mode" in
        default|basic|audio)
            set_basic_mode || exit 1
            finalize_after_profile_load
            ;;
        echo-removal)
            set_echo_removal_mode || exit 1
            finalize_after_profile_load
            ;;
        status)
            show_status
            ;;
        *)
            echo "Usage: $0 [default|basic|echo-removal|status]"
            exit 1
            ;;
    esac
}

main "$@"
