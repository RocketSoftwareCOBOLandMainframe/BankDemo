# Interoperability Demonstrations

This directory contains demonstrations that show how to use Rocket Enterprise Server's language interoperability features to integrate programs written in different languages within mainframe-style workloads.

Rocket Enterprise Server supports calling programs written in languages such as Java and Python from traditional COBOL batch and CICS environments, enabling modernization while preserving existing application investments.

## Available Demonstrations

### Batch Interoperability

Demonstrations showing how to invoke programs written in other languages from JCL batch jobs:

- [Java Batch Interoperability](batch/java/README.md)
    - Invoke Java classes from JCL using JVMLDM and COBOL-to-Java bridging
    - Access datasets from Java using the JZOS-compatible ZFile API

### CICS Interoperability

*(Coming soon)* — Demonstrations showing how to call external language programs from within a CICS transaction environment.

## Concepts

Language interoperability in Rocket Enterprise Server is built on the following mechanisms:

| Mechanism | Description |
|-----------|-------------|
| **JVMLDM** | JVM Load Module — a batch launcher that creates a Java environment from a STDENV script and executes a Java class or JAR directly from JCL |
| **COBOL-to-Java CALL** | COBOL programs can call Java methods using the syntax `CALL "Java.<class>.<method>"` |
| **ESJOS / JZOS API** | Java classes can access Enterprise Server datasets, VSAM files, and DD allocations using the `com.rocketsoftware.jzos` package (ZFile, ZUtil, etc.) |

## Prerequisites

- Rocket&reg; Enterprise Developer or Rocket&reg; Enterprise Server
- A Java Development Kit (JDK) 8 or later
- See specific demonstration instructions for additional requirements
