#!/bin/bash

watch -n.5 'uptime; ps axww | grep -v grep | grep "apt\|dk-"'