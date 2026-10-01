# Calling Java from COBOL by Using Enterprise Developer for Eclipse

Rocket&reg; Enterprise Suite products provide a proprietary runtime engine to enable compatibility for customers’ IBM CICS applications. IBM and CICS are registered trademarks of International Business Machines Corp. Rocket Enterprise Suite products do not include an IBM CICS engine and are not affiliated with IBM.

## Contents
- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Creating the Java Project](#creating-the-java-project)
- [Configuring the Region for Java](#configuring-the-region-for-java)
- [Compiling the COBOL Bootstrap Program](#compiling-the-cobol-bootstrap-program)
- [Running the Java Batch Job](#running-the-java-batch-job)
- [Debugging COBOL and Java Together](#debugging-cobol-and-java-together)
- [Further Java Samples](#further-java-samples)
- [Troubleshooting](#troubleshooting)

## Overview

This demonstration continues the [Getting Started with Enterprise Developer for Eclipse](README.md) tutorial. It shows you how to run a Java class from a batch JCL job under the same BANKDEMO enterprise server region you have already been using, and how to debug a single run that passes from COBOL into Java and back again.

The Java code is kept in a separate Eclipse project. The Bankdemo project remains a COBOL project, and the two are connected only by the region configuration, which is how Enterprise Server itself sees them.

This means each project keeps a distinct role throughout the demonstration:

| Project | View | Owns |
| --- | --- | --- |
| **BankdemoJava** | **Package Explorer** | The Java sources and the compiled classes in `bin`. |
| **Bankdemo** | **Application Explorer** | `HELLOJAV.cbl`, the JCL, and the debug configurations. |

Enterprise Server loads the Java class from the `CLASSPATH` you set on the region - a plain filesystem path to the `bin` folder. It has no knowledge of Eclipse projects. The JCL and the COBOL program that calls Java are application artifacts belonging to Bankdemo, so the job is always submitted from there. This mirrors a real deployment, where a Java component is published onto the classpath and the batch application invokes it.

You will:

- Create a Java project and link the sample Java sources into it.
- Configure the BANKDEMO region so that the Java runtime and the compiled classes can be found.
- Compile the COBOL program that calls Java.
- Submit a job that runs Java and inspect the redirected output streams.
- Debug from COBOL into Java and back in one run.

## Prerequisites

[Back to Top](#overview)

- You have completed the [Getting Started with Enterprise Developer for Eclipse](README.md) tutorial. This demonstration uses the Bankdemo project, the Eclipse workspace and the BANKDEMO region created there.
- A Java Development Kit (JDK) is installed. Enterprise Developer supplies one on Windows, in the `AdoptOpenJDK` folder of the product installation.
- The BANKDEMO region has been imported from `tutorial/BANKDEMO.template` and starts successfully.

> **Note:** The [Java Batch Interoperability](../../interoperability/batch/java/README.md) tutorial covers the same Java samples from the command line, using the separate BANKVSAM region created by the provisioning scripts. You do not need it to complete this demonstration.

## Creating the Java Project

[Back to Top](#overview)

 In the Getting Started tutorial you created the Bankdemo project from a supplied COBOL project template. Eclipse has no equivalent template mechanism for Java projects, so you create this one directly, then link the sample sources into it exactly as you linked the COBOL sources.

**Creating the Project**

1.  Click **File \> New \> Project**.
2.  Expand **Java**, select **Java Project** and click **Next**.
3.  In the **Project name** field, type `BankdemoJava`.
4.  Leave **Use default location** selected, so that the project is created in the workspace you specified when you started Eclipse.
5.  Clear **Create module-info.java file** if it is selected. The sample classes are in the default package and do not declare a module.
6.  Click **Finish**.

    If you are prompted to open the Java perspective, click **Open Perspective**.

**Adding the Enterprise Server Java Library**

The samples import `com.rocketsoftware.jzos`, which is supplied with Enterprise Developer. Add it before linking the sources, so that the classes compile cleanly as soon as they are added:

1.  Right-click the **BankdemoJava** project and click **Properties**.
2.  Click **Java Build Path** and then click the **Libraries** tab.
3.  Select **Classpath**, click **Add Library**, select **ES Java Support Library**, click **Next**, then **Finish**.
4.  Click **Apply and Close**.

**Adding the Java Source Files**

As with the COBOL sources, you link the sample files into the project rather than copying them, so that you are editing the files in the sample directory:

1.  In **Package Explorer**, right-click the **BankdemoJava** project and click **New \> Folder**.
2.  Click **Advanced** and select **Link to alternate location (Linked Folder)**.
3.  Click **Browse**, navigate to the `sources/java` folder of the sample and click **Select Folder**.
4.  In the **Folder name** field, type `java` and click **Finish**.
5.  Right-click the linked **java** folder and click **Build Path \> Use as Source Folder**.

    Eclipse compiles the sample classes. The **Problems** view should be clear of errors.

> **Note:** If you add the sources before the library, the **Problems** view reports unresolved `com.rocketsoftware.jzos` imports until the library is added. The errors are transient and clear on the next build.

**Checking the Output Folder**

The region needs the folder that holds the compiled classes, so confirm where the build writes them:

1.  Right-click the **BankdemoJava** project and click **Properties**.
2.  Click **Java Build Path** and then click the **Source** tab.
3.  Note the **Default output folder** value, which is `BankdemoJava/bin`.
4.  Click **Resource**, note the project's **Location**, and then click **Cancel**.

    The **Location** is the workspace path you will supply to the region as its `CLASSPATH` in the next section.

**Confirming that the Classes Were Built**

**Package Explorer** presents a Java project as packages rather than as folders, so it never shows the build output. The **Project Explorer** view can show it, once its **Java output folders** filter is turned off:

1.  Click **Window \> Show View \> Project Explorer**.
2.  Click the **View Menu** button (the three vertical dots) on the **Project Explorer** toolbar and click **Filters and Customization...**.
3.  On the **Pre-set filters** tab, clear the **Java output folders** check box.
4.  Click **OK**.
5.  Expand the **BankdemoJava** project and then expand the **bin** folder.
6.  Confirm that it contains `HelloBatch.class` along with the other sample classes.

Eclipse builds Java projects as you edit them, so the class files are written as soon as the build path is correct. **Project \> Build Project** is greyed out while **Project \> Build Automatically** is enabled.

If the **bin** folder is missing or empty, the build produced nothing. Check the **Problems** view for build path errors - most often the **ES Java Support Library** is not on the build path, or the linked `java` folder has not been marked as a source folder.

## Configuring the Region for Java

[Back to Top](#overview)

Enterprise Server starts the JVM itself, so it needs to know where the JDK is and where your compiled classes are. Neither value is set by the BANKDEMO template, because both depend on your installation and your workspace.

1.  In the **Server Explorer** view, right-click the **BANKDEMO** region and click **Stop** if it is running.
2.  Right-click the **BANKDEMO** region and click **Open Administration Page** to open it in ESCWA, then click **Properties \> General**.
3.  In the **Configuration Information** field, add the following to the existing `[ES-Environment]` section.

    **Windows:**
    ```
    JAVA_HOME=$TXDIR\AdoptOpenJDK
    CLASSPATH=$TXDIR\bin64\esjos.jar;$BANKROOT\tutorial\workspace\BankdemoJava\bin
    ```

    **Linux:**
    ```
    JAVA_HOME=/path/to/jdk
    CLASSPATH=$COBDIR/lib/esjos.jar:$BANKROOT/tutorial/workspace/BankdemoJava/bin
    ```

    `BANKROOT` is defined by the BANKDEMO template and points at the root of the sample, so these values work unchanged if you used the `tutorial/workspace` directory as your Eclipse workspace, as the Getting Started tutorial suggests. Otherwise, replace the second `CLASSPATH` entry with the full path to your project's `bin` folder, which you can find under **Properties \> Resource**.

4.  Click **Apply** and start the region.

> **Note:** Enterprise Server expands `$VAR` references in the `[ES-Environment]` section on both Windows and Linux. Do not use Windows command-shell syntax such as `%TXDIR%`.

> **Note:** Do not add a Java-specific `PATH` value to the region. Enterprise Server locates the runtime components it needs without one, and an incorrect `PATH` can prevent the JVM load module from finding utilities such as `stdenvhelper`.

## Compiling the COBOL Bootstrap Program

[Back to Top](#overview)

The job you are about to submit runs a small COBOL program, `HELLOJAV`, which calls the Java class. The program is already in the Bankdemo project, in the `cobol/interoperability/java` folder, but the Getting Started tutorial deselected every folder on the **Build Precedence** tab, so it has not been built.

1.  In **Application Explorer** view, right-click the **Bankdemo** project and click **Properties**.
2.  Expand **Rocket Software** and click **Build Path**.
3.  Click the **Build Precedence** tab and select the check box for **Bankdemo/cobol/interoperability/java**.
4.  Click **Apply and Close**.

    Eclipse rebuilds the project, compiling `HELLOJAV.cbl` into the `loadlib` folder, which the region already searches. Confirm that `loadlib` now contains `HELLOJAV.dll`.

The program is written in mainframe COBOL, so it compiles under the project's `DIALECT"ENTCOBOL"` setting without modification.

The program itself is deliberately minimal. The call is resolved by Enterprise Server at run time, using the `Java.` prefix to identify the target as a Java class and method:

```cobol
call "Java.HelloBatch.run"
display "COBOL: Java call succeeded."
```

## Running the Java Batch Job

[Back to Top](#overview)

As set out in the [Overview](#overview), the job belongs to the **Bankdemo** project - the JCL is part of the `jcl` folder you linked in during the Getting Started tutorial.

1.  In **Application Explorer** view, expand the **Bankdemo** project, then expand the **jcl** folder and the **interoperability** folder within it.
2.  Right-click **HELLOJAV.jcl** - in the `windows` folder on Windows, or the `linux` folder on Linux - and click **Submit JCL to associated Server**.
3.  Open the spool entry for the job to review its output.

    ![](images/06c974b55ef928b64a0cd983b28163b8.png)

> **Tip:** The job can equally be submitted outside the IDE, through **JES \> Control** in ESCWA or with `cassub`, as the [Java Batch Interoperability](../../interoperability/batch/java/README.md) tutorial describes. The result is the same; only the submission route differs.

The job allocates three output DDs, and each receives a different stream:

-   **SYSOUT** - COBOL `DISPLAY` output, including the message written after the Java call returns.
-   **STDOUT** - output from Java `System.out`.
-   **STDERR** - output from Java `System.err`, including any exception stack traces.

`STDOUT` shows the Java version, the working directory, and the value of `TEST_VAR`:

```
Hello from Java in a batch job!
Java version: 25.0.2
Working directory: ...
Env var (TEST_VAR): HELLO_FROM_CEEOPTS
```

The reported Java version is that of the JDK the region is configured to use.

`TEST_VAR` reaches Java from the `CEEOPTS` DD in the JCL, which sets environment variables for the run:

```
//CEEOPTS  DD *
ENVAR("TEST_VAR=HELLO_FROM_CEEOPTS",
"JAVA_TOOL_OPTIONS=")
/*
```

This mapping of streams to DDs is not automatic for a class called from COBOL. `HelloBatch.run()` requests it explicitly with `ZUtil.redirectStandardStreams(...)` and releases it afterwards with `ZUtil.restoreStandardStreams()`.

## Debugging COBOL and Java Together

[Back to Top](#overview)

Enterprise Developer debugs the COBOL, and the standard Eclipse Java debugger attaches to the JVM that Enterprise Server starts. Both debuggers must be running before the job is submitted, so you create a **launch group** that starts them together in the right order.

**Creating the Java Debug Configuration**

1.  Click **Run \> Debug Configurations**.
2.  Select **Remote Java Application** and click **New launch configuration**.
3.  Set the following values:

    -   **Name:** `ES Java Debug`
    -   **Project:** `BankdemoJava`
    -   **Connection Type:** `Standard (Socket Listen)`
    -   **Port:** `8000`
    -   **Connection limit:** `1`

4.  Click **Apply**.

    Leave the **Debug Configurations** dialog box open.

**Creating the Launch Group**

The Java debugger listens for a connection, and the JVM connects out to it as the job starts, so the Java configuration must be running first. A launch group enforces that order:

1.  In the same dialog box, select **Launch Group** and click **New launch configuration**.
2.  In the **Name** field, type `COBOL and Java Debug`.
3.  On the **Launches** tab, click **Add**, select **ES Java Debug**, and click **OK**.
4.  With **ES Java Debug** selected in the list, set **Launch mode** to `debug` and **Post launch action** to **Delay**, then set the delay to `2` seconds.

    This gives the Java debugger time to start listening before the COBOL debugger starts.

5.  Click **Add** again, select the **JCL Debug** configuration from the Bankdemo project, and click **OK**.
6.  With **JCL Debug** selected, set **Launch mode** to `debug` and leave **Post launch action** set to **None**.
7.  Click **Apply**, then **Close**.

> **Note:** The launch group refers to **JCL Debug**, so the Bankdemo project from the Getting Started tutorial must be open in the same workspace.

**Enabling Debugging in the Job**

1.  In **Application Explorer** view, in the `jcl > interoperability > windows` folder of the Bankdemo project - or `jcl > interoperability > linux` on Linux - double-click **HELLOJAV.jcl**.
2.  Scroll to line 19, the `JAVA_TOOL_OPTIONS` entry in the `CEEOPTS` DD.
3.  Replace the empty value so that the line reads as follows, then save the file:

    ```
    "JAVA_TOOL_OPTIONS=-agentlib:jdwp=transport=dt_socket,server=n,address=8000")
    ```

    The `CEEOPTS` DD now reads:

    ```
    //CEEOPTS  DD *
    ENVAR("TEST_VAR=HELLO_FROM_CEEOPTS",
    "JAVA_TOOL_OPTIONS=-agentlib:jdwp=transport=dt_socket,server=n,address=8000")
    /*
    ```

> **Important:** With `server=n` the JVM connects out to the debugger and waits for it. If the Java debug configuration is not listening when the job runs, the job fails. Clear the value again when you have finished debugging.

> **Important:** `JAVA_TOOL_OPTIONS` are case-sensitive. The JCL editor converts what you type to upper case as you type it. To turn this off, click **Window \> Preferences**, navigate to **Rocket Software \> JCL \> Editor**, clear **Force capitals**, and click **Apply and Close**. Text that was already upper-cased is not changed, so correct the line after turning the option off.

**Setting Breakpoints**

1.  Double-click `HELLOJAV.cbl` in the Bankdemo project, then double-click in the left margin against **line 10**, the `call "Java.HelloBatch.run"` statement, and against **line 11**, the `display` statement that follows it.
2.  Double-click `HelloBatch.java` in the BankdemoJava project, then double-click in the left margin against **line 15**, the first `System.out.println` statement.

**Running the Debug Session**

> **Note:** A region initialises its JVM once. If you have already submitted a Java job since the region started, restart the BANKDEMO region before you begin.

> **Important:** Before each attempt, terminate any previous debug sessions in the **Debug** view. A listening **ES Java Debug** session holds port 8000, and the launch group starts a second listener rather than reusing it, which fails to bind. Terminating does not always release the socket - if the launch still fails to bind, restart Eclipse. Restarting the region makes no difference, as the port belongs to Eclipse.

1.  Click **Run \> Debug Configurations**, select **Launch Group \> COBOL and Java Debug** and click **Debug**.

    Both debuggers start. The **Debug** view shows the Java listener and the Enterprise Server JCL debug session.

2.  In **Application Explorer** view, right-click **HELLOJAV.jcl** and click **Submit JCL to associated Server**.

    Submit the job promptly. The Java listener waits only for the debugger timeout - 20 seconds by default - and then gives up. If you need longer, raise **Debugger timeout (ms)** under **Window \> Preferences \> Java \> Debug** before starting the group.

3.  Execution stops at the COBOL breakpoint on line 10, the `call` statement.
4.  Press **F8**. Execution continues into the Java breakpoint on line 15 of `HelloBatch.java`.
5.  Press **F8** again. Execution returns to the COBOL breakpoint on line 11, after the call.

Leave the Java debugger listening. The JVM is not reinitialised between jobs, so any further Java job you submit while the region is running can be debugged in the same session.

## Further Java Samples

[Back to Top](#overview)

`HELLOJAV` uses a COBOL program as the entry point. The remaining samples are started directly by the JVM load module, JVMLDM, which initialises the JVM and redirects the standard streams for you.

The [Java Batch Interoperability](../../interoperability/batch/java/README.md) tutorial describes each of these in detail, including the Java code and the JCL. It is written for the BANKVSAM region and compiles from the command line, but the samples themselves are the same, and they run unchanged under the BANKDEMO region you have configured here.

## Troubleshooting

[Back to Top](#overview)

| Symptom | Cause and resolution |
| --- | --- |
| The job fails and the spool reports that the class cannot be found. | The `CLASSPATH` entry does not point at the project's `bin` folder, or the project has not been built. Check the path against **Properties \> Resource**, confirm that `bin` contains the `.class` files, and confirm the region was restarted after the configuration change. |
| The job fails and the spool reports that the JVM cannot be created. | `JAVA_HOME` is not set, or points at a folder that is not a JDK. |
| `Env var (TEST_VAR)` is reported as `null`. | The `CEEOPTS` DD was edited so that `TEST_VAR` is no longer set. Values are supplied through `ENVAR`, not the region environment. |
| Unresolved `com.rocketsoftware.jzos` imports in the IDE. | The **ES Java Support Library** is missing from **Java Build Path \> Libraries \> Classpath**. |
| The Java sources are not compiled at all. | The linked `java` folder is not marked as a source folder. Right-click it and click **Build Path \> Use as Source Folder**. |
| The `bin` folder is not visible in **Package Explorer**. | **Package Explorer** shows packages, not folders, so it never displays build output. Use **Project Explorer** and clear the **Java output folders** filter under **Filters and Customization...**. **Project \> Build Project** being greyed out is normal while **Build Automatically** is enabled. |
| The **COBOL and Java Debug** launch group is not listed. | It was not created, or was created while a different project was selected. The group also refers to **JCL Debug**, so the Bankdemo project must be open in the same workspace. |
| `Failed to connect to remote VM. Failed to attach to localhost:8000`. | The **ES Java Debug** configuration is set to **Standard (Socket Attach)**, so Eclipse tried to connect to a JVM that is not running. Change **Connection Type** to **Standard (Socket Listen)**. The job uses `server=n`, so the JVM connects to Eclipse rather than the other way round. |
| The launch reports that it failed to bind, or that the address is already in use. | An earlier **ES Java Debug** session is still holding port 8000. Terminating it in the **Debug** view does not always release the socket, so restart Eclipse. This is an Eclipse listener, so restarting the region has no effect. Confirm with `netstat -ano \| findstr :8000` on Windows, which reports the owning process ID. If a process other than Eclipse holds the port, change the port in both the launch configuration and the JCL. |
| The Java listener stops before the job reaches Java. | The debugger timeout elapsed. Submit the job sooner, or raise **Debugger timeout (ms)** under **Window \> Preferences \> Java \> Debug**. |
| The job runs to completion without stopping in Java. | `JAVA_TOOL_OPTIONS` is not reaching the JVM. The JCL editor upper-cases text as it is typed unless **Force capitals** is cleared under **Rocket Software \> JCL \> Editor**, and the option is case-sensitive - confirm the `CEEOPTS` DD still reads `-agentlib:jdwp=...` in lower case, and that `//CEEOPTS  DD *` appears only once. |
| The **Submit JCL to associated Server** option is not available. | You are in **Package Explorer**, which does not provide it, or on a project other than Bankdemo. Submit `HELLOJAV.jcl` from the **Bankdemo** project in **Application Explorer**, or submit through ESCWA or `cassub` instead. |
| **BankdemoJava** does not appear in **Application Explorer**. | Expected. That view lists only Micro Focus projects belonging to **Enterprise Development Projects**; a plain Java project is not one. Use **Package Explorer** for the Java project. |
| The build fails with `Cannot open file : HELLOJAV.obj`. | The compile failed, so the link had no object file. If the **Console** view reports `1078-S` against a `$set` line, the source contains Rocket-dialect `$set` directives that `DIALECT"ENTCOBOL"` rejects. Remove them - mainframe dialects imply `FCDCAT` and `OUTDD`. They are added only by the [Java Batch Interoperability](../../interoperability/batch/java/README.md) tutorial, which compiles standalone in the Rocket dialect. |
| `HELLOJAV` is not found when the job runs. | The `cobol/interoperability/java` folder is not selected on the **Build Precedence** tab of the Bankdemo project, or `loadlib` contains no `HELLOJAV.dll`. |
| The job fails as soon as it starts a Java step. | `JAVA_TOOL_OPTIONS` still requests a debugger. Either start the **ES Java Debug** configuration or clear the option. |
| The Java breakpoint is never reached on a second run. | The JVM initialises once per region start. Restart the BANKDEMO region, then start the debuggers again. |

This concludes the Java demonstration.

[Back to Top](#overview)
