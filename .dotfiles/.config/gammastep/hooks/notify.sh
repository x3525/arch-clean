#!/bin/bash

case $1 in
    period-changed)
        case $3 in
            daytime|night)
                C2 notify gammastep "$3"
                ;;
        esac
        ;;
esac
