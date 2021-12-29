Set-ExecutionPolicy -executionpolicy bypass
install-module PSWindowsupdate -Force
import-module PSWindowsupdate -force
get-windowsupdate
install-windowsupdate -acceptall -autoreboot
winget install --id Google.Chrome --force