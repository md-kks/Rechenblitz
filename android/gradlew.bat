@echo off
setlocal
set APP_HOME=%~dp0
set CLASSPATH=%APP_HOME%gradle\wrapper\gradle-wrapper.jar
if exist "%CLASSPATH%" goto usewrapper

set GRADLE_VERSION=8.10.2
set BASE=%USERPROFILE%\.gradle\rechenblitz-wrapper
set DIST=%BASE%\gradle-%GRADLE_VERSION%
set ZIP=%BASE%\gradle-%GRADLE_VERSION%-bin.zip
if exist "%DIST%\bin\gradle.bat" goto userdist

if not exist "%BASE%" mkdir "%BASE%"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $u='https://services.gradle.org/distributions/gradle-%GRADLE_VERSION%-bin.zip'; $z='%ZIP%'; if (-not (Test-Path $z)) { Invoke-WebRequest -Uri $u -OutFile $z }; Expand-Archive -Path $z -DestinationPath '%BASE%' -Force"
if errorlevel 1 exit /b 1
:userdist
call "%DIST%\bin\gradle.bat" %*
exit /b %ERRORLEVEL%

:usewrapper
if defined JAVA_HOME goto usejavahome
set JAVA_EXE=java.exe
goto runwrapper
:usejavahome
set JAVA_EXE=%JAVA_HOME%\bin\java.exe
:runwrapper
"%JAVA_EXE%" -Dorg.gradle.appname=gradlew -classpath "%CLASSPATH%" org.gradle.wrapper.GradleWrapperMain %*
