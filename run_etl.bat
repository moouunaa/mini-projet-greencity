@echo off
echo ============================================
echo    GreenCity ETL Process - Starting
echo    Date: %date% Time: %time%
echo ============================================

REM Chemin vers PDI
cd /d "C:\Users\hp\Desktop\pdi-ce-10.2.0.0-222\data-integration"

REM Exécuter le job principal
call Kitchen.bat /file:"C:\Users\hp\Desktop\mini projet - greencity\04_ETL_Pentaho\jobs\Main_ETL_Job.kjb" /level:Basic

echo ============================================
echo    GreenCity ETL Process - Completed
echo    Date: %date% Time: %time%
echo ============================================

pause