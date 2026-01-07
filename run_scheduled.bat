@echo off
echo ============================================
echo    Scheduled ETL - GreenCity
echo    Lance par Task Scheduler a %date% %time%
echo ============================================


cd /d "C:\Users\hp\Desktop\mini projet - greencity"

REM Appeler le batch principal
call run_etl.bat

echo ============================================
echo    Scheduled ETL - Termine
echo    Date: %date% Time: %time%
echo ============================================

















