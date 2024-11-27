#!/usr/bin/env bash
#-*- coding: utf-8 -*-
unset DEV
bundle install && bundle exec pod install && xed .
