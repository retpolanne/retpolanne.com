#!/bin/bash

exiftool -all= assets/img -tagsfromfile @ -exif:Orientation -overwrite_original
