#!/bin/bash

set -e

cd ui

mill clean ui
mill ui.compile
mill ui.checkFormat
mill ui.fix
mill ui.fastLinkJS
mill ui.test

cd ..

