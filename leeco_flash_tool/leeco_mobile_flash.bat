@echo off
echo %USERPROFILE%\Documents > tools\x86\cygwin\etc\temp_path
if {%1}=={} (
    echo.
) else (
    if {%2}=={} (
        echo "Bad parameter!"
        pause
        exit
    ) else (
        echo|set /p="%1" > tools\x86\cygwin\home\administrator\.username
        echo|set /p="%2" > tools\x86\cygwin\home\administrator\.passwd
    )
)

tools\x86\cygwin\bin\mintty -
::mintty -

