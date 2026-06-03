@echo off
REM ================================================================
REM STDENV script for JVMLDM batch Java execution (Windows)
REM ================================================================
REM This script is read by JVMLDM from the STDENV DD allocation.
REM It sets up the Java environment before the Java class is invoked.
REM ================================================================

set JAVA_HOME=C:\Program Files (x86)\Rocket Software\Enterprise Developer\AdoptOpenJDK
set PATH=%JAVA_HOME%\bin\server;%PATH%

REM Add application classes to CLASSPATH
REM $ESP is the region's base directory (substituted at runtime)
set CLASSPATH=%ESP%\loadlib;%CLASSPATH%
