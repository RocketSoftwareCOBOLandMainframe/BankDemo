# Interoperability Demonstrations

This directory contains demonstrations that show how to use Rocket Enterprise Server's language interoperability features to integrate programs written in different languages within mainframe-style workloads.

Rocket Enterprise Server supports calling programs written in languages such as Java and Python from traditional COBOL batch and CICS environments, enabling modernization while preserving existing application investments.

## Available Demonstrations

### Batch Interoperability

Demonstrations showing how to invoke programs written in other languages from JCL batch jobs:

- [Java Batch Interoperability](batch/java/README.md)
    - Invoke Java classes from JCL using JVMLDM and COBOL-to-Java bridging
    - Access datasets from Java using the JZOS-compatible ZFile API

- [Python Batch Interoperability](batch/python/README.md)
    - Invoke Python scripts from JCL using PYLDM (no compilation required)
    - Access datasets from Python using the zoautil_py and esos APIs
    - Call existing COBOL programs from Python via the cblcpyiapi bridge

## Prerequisites

- Rocket&reg; Enterprise Developer or Rocket&reg; Enterprise Server
- A Java Development Kit (JDK) 21-25 (for Java demonstrations)
- Python 3.8 or later (for Python demonstrations)
- See specific demonstration instructions for additional requirements
