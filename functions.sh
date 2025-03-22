#!/bin/bash

function no::connection()
{
    if ping -q -c 1 -w 2 "$(ip route | grep -m 1 default | cut -d ' ' -f 3)" &> /dev/null
    then
        return 1
    fi

    return 0
}

function no::name()
{
    local LC_CTYPE

    LC_CTYPE=C

    if [[ ${1} =~ ^[a-z][a-z0-9][a-z0-9]{,30}$ ]]
    then
        return 1
    fi

    return 0
}

function no::ntp()
{
    if [ "$(timedatectl show -P NTPSynchronized)" != "yes" ]
    then
        return 0
    fi

    return 1
}

function no::uefi()
{
    if [ -d /sys/firmware/efi ]
    then
        return 1
    fi

    return 0
}

function part::get()
{
    local DUMP

    DUMP=$(sfdisk "${1}" -d)

    sed -nE "s/(^[^ :]+).+type=${2},.+/\1/p" <<< "${DUMP}"
}

function unit::wait()
{
    for u
    do
        echo "Currently waiting for ${u} to complete..."

        case ${u} in
            *.timer)
                while [ -z "$(systemctl show -P ActiveEnterTimestamp "${u}")" ]
                do
                    sleep 1
                done
                ;;
            *)
                while [ "$(systemctl is-active "${u}")" != "inactive" ]
                do
                    sleep 1
                done
                ;;
        esac
    done
}
