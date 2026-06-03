#!/bin/sh
# ================================================================
# STDENV script for JVMLDM batch Java execution (Linux)
# ================================================================
# This script is read by JVMLDM from the STDENV DD allocation.
# It sets up the Java environment before the Java class is invoked.
#
# Modify JAVA_HOME and CLASSPATH to match your installation.
# ================================================================

export JAVA_HOME=/usr/lib/jvm/java-17
export PATH=$JAVA_HOME/bin:$PATH

# Add application classes to CLASSPATH
export CLASSPATH=$CLASSPATH:/path/to/your/classes
