#!/bin/bash

watch -n.5 'ps axww | grep -v grep | grep "dk-" | grep ".sh"'