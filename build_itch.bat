.\build_web.bat

REM ── zip-all.bat ────────────────────────────────────────────
REM Creates archive.zip from everything in the current folder.

REM Use the built-in BSD tar that ships with Windows 10/11:
set ARCHIVE_NAME=index.zip
tar -a -c -f "%ARCHIVE_NAME%" *

echo.
echo   ✓  %ARCHIVE_NAME% created in %CD%
echo -----------------------------------------------------------
