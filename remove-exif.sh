#!/bin/bash

exiftool -all= assets/img
rm -rf assets/img/*_original
