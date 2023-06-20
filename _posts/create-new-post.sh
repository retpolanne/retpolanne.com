#!/bin/bash

filename=$1
date=`date +"%Y-%m-%d"`
dt=`date +"%Y-%m-%d %T -0300"`

cat <<EOF> $date-$filename.markdown
---
layout: post
title: "Lorem Ipsum"
date: $dt
categories: lorem ipsum
EOF
