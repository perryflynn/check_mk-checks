#!/usr/bin/env bash

SERVICE=pacman-update

if [ -f /etc/arch-release ] && command -v pacman &> /dev/null
then

    if ! command -v arch-audit &> /dev/null
    then
        echo "2 $SERVICE - arch-audit is not installed. abort."
        exit 0
    fi

    pacman -Sy > /dev/null 2>&1

    PARSERERROR=0
    PKGCRIT=()
    PKGWARN=()
    OTHERPKG=()

    while read LINE; do

        if [ -z "$LINE" ]; then
            continue
        fi

        PKGNAME=$(echo $LINE | cut -d ';' -f1)
        LEVEL=$(echo $LINE | cut -d ';' -f2)

        if [ "$LEVEL" == "High risk" ]; then
            PKGCRIT+=("$PKGNAME")
        elif [ "$LEVEL" == "Medium risk" ] || [ "$LEVEL" == "Low risk" ]; then
            PKGWARN+=("$PKGNAME")
        else
            PARSERERROR=1
        fi

    done <<< "$(arch-audit --format "%n;%s" --color never --upgradable)"

    while read LINE; do

        if [ -z "$LINE" ]; then
            continue
        fi

        if [[ ! " ${PKGCRIT[@]} " =~ " ${LINE} " ]] && [[ ! " ${PKGWARN[@]} " =~ " ${LINE} " ]]; then
            OTHERPKG+=("$LINE")
        fi

    done <<< "$(pacman -Qu | awk '{print $1}')"

    PKG=("${PKGCRIT[@]}" "${PKGWARN[@]}" "${OTHERPKG[@]}")

    CODE=3
    CODESTR=UNKOWN
    MSG=""

    if [ ${#PKGCRIT[@]} -gt 0 ] || [ $PARSERERROR -eq 1 ]; then
        CODE=2
        CODESTR=CRIT
        MSG="critical updates available:"
    elif [ ${#PKGWARN[@]} -gt 0 ] || [ ${#OTHERPKG[@]} -gt 0 ]; then
        CODE=1
        CODESTR=WARN
        MSG="updates available:"
    else
        CODE=0
        CODESTR=OK
        MSG="All OK"
    fi

    echo "$CODE $SERVICE high=${#PKGCRIT[@]}|mediumlow=${#PKGWARN[@]}|otherpkg=${#OTHERPKG[@]} ${#PKG[@]} $MSG ${PKG[@]}"
fi
