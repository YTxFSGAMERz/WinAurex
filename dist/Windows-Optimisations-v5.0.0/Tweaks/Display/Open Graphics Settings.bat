@echo off
:: ==============================================================================
; HELPER: Open Graphics Settings Panel
; TARGET SYSTEM: Windows 10 & Windows 11
; DESCRIPTION: Launches the advanced graphics preference settings app directly.
;              Useful for managing Auto SR, HDR, and global graphics settings.
; ==============================================================================
title Open Graphics Settings

echo Opening Windows Display Graphics settings panel...
start ms-settings:display-advancedgraphics
exit
