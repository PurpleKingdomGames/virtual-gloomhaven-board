#!/bin/bash

set -e

cd VirtualGloomhavenBoard/Indigo

mill clean vgb-common
mill vgb-common.compile
mill vgb-common.fastLinkJS
mill vgb-common.test

mill clean vgb-game
mill vgb-game.compile
mill vgb-game.fastLinkJS
mill vgb-game.test

mill clean vgb-ui
mill vgb-ui.compile
mill vgb-ui.fastLinkJS
mill vgb-ui.test

cd ..

