# Getting Started with Rocket&reg; Enterprise Developer for Visual Studio 2022

Rocket&reg; Enterprise Suite products provide a proprietary runtime engine to enable compatibility for customers’ IBM CICS applications. IBM and CICS are registered trademarks of International Business Machines Corp. Rocket Enterprise Suite products do not include an IBM CICS engine and are not affiliated with IBM. 

## Overview

This set of tutorials guides you through Rocket&reg; Enterprise Developer for Visual Studio 2022. They provide a basic understanding of how the product operates.

These tutorials are designed for developers who have experience with developing COBOL on the mainframe but do not necessarily have a working knowledge of the Visual Studio Integrated Development Environment (IDE). The tutorials provide a basic understanding of the features offered in Enterprise Developer for Visual Studio 2022 to develop and maintain both simple COBOL and mainframe subsystem applications. Other tutorials, which are designed for Administrators, are also available.

- [Starting the Visual Studio Integrated Development Environment](#starting-the-visual-studio-integrated-development-environment)
- [Adding Files to your Visual Studio Project](#adding-files-to-your-visual-studio-project)
- [File, Project and IDE Properties and Settings](#file-project-and-ide-properties-and-settings)
- [Editing COBOL, JCL, BMS, and Data Files](#editing-cobol-jcl-bms-and-data-files)
- [Compiling the Source Code](#compiling-the-source-code)
- [Unit Testing the Batch Application](#unit-testing-the-batch-application)
- [Unit Testing the Online Application](#unit-testing-the-online-application)
- [Debugging the Batch Application](#debugging-the-batch-application)
- [Debugging the Online Application](#debugging-the-online-application)

**Download the Demonstration Application**

The preconfigured and fully executing application BankDemo is available from the Rocket Software GitHub repository - [*click here*](https://github.com/RocketSoftware/BankDemo). Download the sample sources as follows:

1.  In the GitHub repository for the BankDemo demonstration, click **Releases** in the right side part of the page.
2.  In the list of releases, locate and click the one that corresponds to the Enterprise Developer product release that you have installed.
3.  Expand the **Assets** section, and click either **Source code (zip)** or **Source code (tar.gz)** to download the archive with the sample sources.
4.  Expand the archive on your computer.

    The demonstration application includes all the source files needed to run it. The application is both a batch and online application which assesses data on a fictitious bank system. The bank data is stored in VSAM files.

    **Important:** Before attempting this tutorial, create a directory on your computer for the sample files - for example, create a `MFETDUSER` directory on the root of your local drive (C:). Copy the entire contents from the expanded folder into the newly created directory. For example, you should have a `c:\MFETDUSER\datafiles` folder, etc.

    As part of this tutorials, you use the supplied standard Visual Studio project for Mainframe Subsystem Applications to set up a development environment for this application. The tutorials show how you can:
    -   Edit the source files
    -   Compile the source code
    -   Run and debug the application.

    **Prerequisites**

    You must have the following software installed:

    -   Rocket Enterprise Developer for Visual Studio 2022. [*Click here*](https://docs.rocketsoftware.com/bundle?cluster=true&labelkey=prod_enterprise_developer) to access the product Help and the release notes of Enterprise Developer.
    -   A TN3270 terminal emulator to run the CICS application. This tutorial uses Micro Focus Host Access for the Cloud (HACloud), which is installed with Enterprise Developer, but you can use an alternative terminal emulator if you want.

**Using a Remote Enterprise Server Instance for the Tutorials**

   If you have an active firewall on the system that is running your Directory Server and enterprise server instances, and you want remote clients to be able to connect to them, you must ensure that the firewall allows access to the ports that you are using.
    
   For example, Directory Server is configured, by default, to use port 86. You must configure your firewall to allow TCP and UDP access to this port. Similarly, the enterprise server instance you create as part of this tutorial, BANKDEMO, has listeners which use ports 9003 and 9023. For remote clients to be able to submit JCL jobs or connect a TN3270 terminal to these listeners, your firewall must allow access to these ports.

   If you want remote users to access Enterprise Server functionality through the firewall, you can use fixed port values so that you can control access through them.

## Enterprise Server Security

In this release, the Enterprise Server security features are enabled by default. However, tutorials that use enterprise server regions assume that Enterprise Server security is not configured. To perform this tutorial without modification, disable the default configured Enterprise Server security. See *Disable the Default Enterprise Server Security Configuration* for more information.

### Disable the Default Enterprise Server Security Configuration

 >**Important**: Rocket Software does not recommend disabling Enterprise Server security permanently. If you disable the default Enterprise Server security to facilitate running tutorials then this should be performed on a network isolated machine. Re-enable security as soon as possible after completing the tutorial. See *Re-create the Default Enterprise Server Security Configuration* in the product documentation for steps on how to re-enable security. 

1. In an Enterprise Developer command prompt, run the command `DisableESDefaultSecurity.cmd`.

     A series of messages appear as the script disables default security.

2. Restart the Directory Server (MFDS) service and the Enterprise Server Administration (ESCWA) service to pick up the configuration changes. 

    Now, you can use ESCWA without having to log in.
3. Restart any running enterprise server regions to have them pick up the configuration changes. 

    Regions no longer require credentials for starting, stopping and other actions.




## Starting the Visual Studio Integrated Development Environment

[Back to Top](#overview)

1. To start the Visual Studio IDE:

    **On Windows 10**: 
    From your Windows desktop, click **Start \> Visual Studio 2022**.

    **On Windows 11**:
    Click **Start** in the Task Bar. Use the search field in the Start menu to find and start **Visual Studio 2022**.

    If this is the first time you start Visual Studio on your system, you are prompted to specify default environment settings. Set **Development Settings** to **General**.

2. You then see the Visual Studio start screen. Click **Continue without code**:


The windows you see open in Visual Studio and their layout depend on whether you have used the IDE before and on the edition of Visual Studio that you have installed. You can move, resize and minimize windows which is why they might not look exactly as described here.

You can see:

-   The **Solution Explorer** window that gives a direct view of what is on disk for your solutions.

    A solution is a holding place for projects that relate to the solution. For example, the solution you are going to work with contains two projects - a batch project and an online project.


-   Bottom right is a **Properties** window which shows the properties of the currently selected item in the Solution Explorer when you have a project loaded in it. You can open the window from **View \> Properties**.
-   **Output** window that displays the results of tasks and from compiling your applications.
-   **Error List** window that displays details about any errors that might be present in the code.
-   **Project Details** window that gives a logical view of your COBOL application.
-   The main activity window at the top the IDE, the Editor, is where you edit or debug the sources. This window is currently empty.
-   Apart from the menus, there are a number of UI controls on the toolbar that vary depending on what you are doing with the IDE.

3. Experiment with resizing, minimizing and restoring the windows.

    To move a window:

    - Click the title bar of the window. Holding the mouse on the window title, drag the window to the left and down.

     > **Note:** If you close a window, you can restore it from the **View** menu.

    - If you want to restore the default windows layout of the IDE, click **Window** \> **Reset Window Layout**.

 **Open the Bankdemo Solution**

1.  Click **File** \> **Open** \> **Project/Solution**.
2.  Navigate to the `C:\MFETDUSER\tutorial\projects\Studio\cobol` folder, select `Bankdemo.sln`, and click **Open**.

    This opens the solution in the Solution Explorer window.

## Adding Files to Your Visual Studio Project

[Back to Top](#overview)

The source files of the demonstration application are stored in subfolders named after the file type (for example, `bms`, `cobol`, `copybook`, `jcl`) in the `C:\MFETDUSER\sources` directory. The Visual Studio project is in the `C:\MFETDUSER\tutorial\projects\Studio\cobol` folder. You will be adding the source files to the Visual Studio project. The other folders that are not so obvious are:

| **Folder Name**       | **Use**                                                                                                                                             |
|-----------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------|
| `system`                | Contains some resource definition data for CICS – this has been exported from the Mainframe and converted into a suitable form for the workstation. |
| `system\catalog`       | Stores the catalog.                                                                                                                                 |
| `system\catalog\data` | Stores the data files.                                                                                                                              |
| `system\logs`          | Contain various log files indicating the progress of your application execution.                                                                    |
| `system\rdef`          | Contain the resource definition files for the BANKDEMO enterprise server region.                                                                   |

**Configuring Directives Scanning**

By default, the Visual Studio IDE is configured to automatically scan any new source files that you add to the project. It assesses the code, determines what Compiler directives are required and then, by default, offers to set those directives on the files. 

To see what directives are set:

1.  Click **Tools** \> **Options**.
2.  Scroll down and expand **Rocket Tools**, expand **Directives** and click **COBOL**.

    ![](images/7FAE6822-8BD0-4B54-A83E-B43E3B90F8F6.png)
    
    This page enables you to configure what directives will be set on the COBOL files that you add to your project. The directives scanning determines the dialect, what `EXEC CICS` and `EXEC SQL` statements are used in the COBOL source files and sets directives as detailed on this page.

3.  Ensure that all options are selected.

    The **Preview directive determination changes before applying** options ensures that you can review and approve the directives that are set on the files after a directives scan.

4.  Click **OK**.

**Adding COBOL Source Files**

To add the COBOL programs to your project:

1.  In **Solution Explorer**, right-click the **BankDemo** project and click **Add** \> **Existing Item**.
2.  Browse to `C:\MFETDUSER\sources\cobol\core`.

    By default, the file type filter is set to **Enterprise Files (\*.cbl; \*.cpp; \*.cob, ...)**. 

3. Select all **.cbl** files in this folder and click **Add**.

    This adds all COBOL programs from the `core` subfolder.

    Previously, you ensured the IDE is configured to scan the COBOL files you add into the project and set directives for dialect, `EXEC CICS` statements and SQL. When the files are imported in the project, the IDE scans them for CICS and SQL settings. You can see that the **Output** window shows some messages about scanning the files. At the end of scanning, the IDE shows a **Preview Changes Directive Determination** dialog box to set any missing directives as required. 

     ![](images/2VSscandirs.png)
    
4. Review the directives and click **Apply**.

   >**Note:** In most cases, you add the actual COBOL programs to your Visual Studio project. Optionally, you could leave the source files in the original location and create links to them. This might be useful if you have large source files. In such cases, you might use the **Add As Link** option to add the files to your project:

   ![](images/21a3bc2f6389c6fe4189c875358b50a9.jpg)

5.  Look in the **Output** window to see the result of the directives scan and what directives are set on the files.

    ![](images/75b75ccc2f1239246d82fbf37951b478.jpg)

    If there are any issues, such as the IDE not being able to determine the dialect because of missing copybooks, these are reported here.

6.  If, at any stage, you must perform a directives scan of the COBOL sources in the project to set Compiler directives on them, right-click the **Bankdemo** project and click **Determine Directives**.

**Adding the Copybook Files**

The copybook files in the `C:\MFETDUSER\sources\copybook` folder are used by the COBOL programs in the project. Your project is preconfigured to look for the copybook files in that location, so that the compilation will not fail. To see where this is set:

1.  Click **Project** \> **Bankdemo Properties** to open the project properties.
2.  Click the **Dependency Paths** tab, and ensure that **Type** is set to **COBOL Copybook Paths**. The folder that is listed on that page is the folder that includes the copybook files.

    Because the copybook files are not compiled when you build the application, it is not necessary to add them to the project. However, as an exercise, you can add one of the copybooks to the project in the same way you added the COBOL files.

**Adding BMS Source Files to Your Project**

You must add the demonstration BMS files to the project.

1.  In **Solution Explorer**, right-click the **Bankdemo** project and click **Add** \> **Existing Item**.
2.  Browse to `C:\MFETDUSER\sources\bms\cobol` folder.
3.  The file extension filter should be set to **Enterprise Files** but, as an exercise, you can set it to **BMS Files (\*.bms)**.

    ![](images/d6d3d2c642cb1e9bc255d62083768252.jpg)

4.  Select all **.bms** files in the folder and click **Add**.

    This adds the BMS files to the project.

**Adding JCL Source Files**

To add a JCL file to your project:

1.  In **Solution Explorer**, right-click the **BankDemo** project and click **Add** \> **Existing Item**.
2.  Browse to `C:\MFETDUSER\sources\jcl` folder.
3.  Set the file type filter to **JCL/VSE Files (\*.jcl; \*.vse)**.
4.  Select **ZBNKSTMT.jcl** and click **Add**.

    This adds the JCL file to the project.

**Adding Data Files**

The demonstration application includes a number of data files. To see how you can edit data files, you only must look at one of these files, so you do not have to add a folder for it to the project. To add the data file to your project:

1.  In **Solution Explorer**, right-click the **BankDemo** project and click **Add** \> **Existing Item**.
2.  Browse to `C:\MFETDUSER\datafiles`.
3.  Set the file type filter to **All Files (\*.\*)**.
4.  Select the **MFI01V.MFIDEMO.BNKACC.dat** and **MFI01V.MFIDEMO.BNKACC.str** files.
5.  Click **Add**.

**Viewing the Project Details**

The **Project Details** window shows a list of all files in your project or in the entire solution together. You can explore details such as the file type, location, COBOL dialect, number of errors or warnings and whether there are file directives that differ from and override the directives set on project level. This can help you identify problems quickly. To open the window:

1.  In **Solution Explorer**, right-click your solution (or the project) and click **Project Details**. 

    ![](images/4VSProjDetails.jpg)

2.  Click either one of the columns to sort the list.
3.  Click ![](images/d68a42c513ad924eb6872ee2420b1b87.jpg), **Sync with Active Document** to highlight the file that is opened in the editor or is selected in Solution Explorer.
4.  Right-click a COBOL program in the list to either compile it, access its properties, or adjust its Compiler directives (by using either **Determine Directives** or **Use Project Defaults**).

**Grouping Files of the Same Type in Solution Explorer**

In **Solution Explorer**, you can view an actual representation of the files and folders in a project. You can also toggle the **Virtual View** to sort the files by file type:

1.  In **Solution Explorer**, select **Bankdemo**.
2.  Click the **Virtual View** icon ![](images/a3d4d6c478d1be66c11c60601f7c040a.jpg) in the **Solution Explorer** toolbar to toggle **Solution Explorer** on or off.

    In **Virtual View**, you see virtual folders in the project for the different file types - COBOL programs, BMS or JCL files:

    ![](images/d4467853062668a82b82af06c9445442.jpg)

    Note that there is no folder for the copybooks as they are not added directly to the project in the IDE.

  
  **Viewing the Copybook Dependencies**

Solution Explorer shows which copybooks are used by your source programs. To view the copybook dependencies of a COBOL program, simply expand the node for that program:

  ![](images/7b071d935f2c8d050ef60cd113d1304c.jpg)

**Summary**

   You created a Visual Studio project, added the COBOL files, the BMS, the JCL files of the demonstration program as links to the project and added the path to the folder that contains the copybooks to the project's properties.

   Next, explore the settings available in the IDE and edit some of the source files.

## File, Project and IDE Properties and Settings

[Back to Top](#overview)

There is a variety of options and settings that can be configured within Visual Studio. You will explore a few of them in this tutorial. Do not skip this section, because you are going to make at least one important configuration change in the project's properties.

**Exploring the IDE settings**

1.  In Visual Studio, click **Tools** \> **Options**.
2.  Expand **Projects and Solutions** and click **Locations**.

    The **Projects location** field defines the default location for storing new projects. You can change this path if you are using a different working folder.

    ![](images/6efc7e10ac080f8d98fd03d13a09a9b8.png)

3.  In the **Options** dialog box, expand **Environment** and click **Fonts and Colors**.
4.  Ensure **Show settings for** is set to **Text Editor**.
5.  Look in the list in the **Display Items** pane and note the COBOL, BMS, and JCL items whose font and color you can change.
6.  In the **Options** dialog box, expand **Text Editor** and then expand **COBOL**.

    You can use the settings in this section to configure features of the editor such as tab size, COBOL margins, some syntax checking rules, and others.

    From the **Quick Actions** page for the COBOL editor properties, you can manage what quick actions are enabled in the editor.

    From the **Advanced** page you can fine-tune the behavior of some features of the editor, such as background syntax checking and outlining. You can also disable features that are not necessary. This can be useful if you are working with a large code base.

**Configuring the COBOL Editor**

You can configure how the editor wraps the code around the margins, how it indents the code in the different COBOL areas, or how the **Home** and **End** keys move the cursor in the different areas. You can also choose the style of the ruler, and change the colors of the text and the margins. You can change the default editor settings and experiment with the new behavior by opening one of the COBOL programs in the editor.

Experiment by changing the following settings:

1. Click **Tools \> Options \> Text Editor \> COBOL \> Margins**.
2. Modify the settings for the **Smart edit mode** that controls the word wrapping and the indentation in the different COBOL areas.

    When there is a COBOL file opened in the editor, you can use **Toggle COBOL Smart Edit Mode**, ![](images/a46c3bb37b9bde291170ad8fe2accbc2.jpg), on the COBOL toolbar to turn on or off the smart editing mode.
    
-   To open the COBOL toolbar, click **View \> Toolbars \> COBOL**.
-   On the same page in the IDE options, change the behavior of the **Home** and **End** keys.
-   On the same page in the IDE options, select **Show the ruler** and select **Mainframe style**.

**Project Properties**

The properties you set at project level apply to all files in the project. Here's how to access them:

1.  In **Solution Explorer**, select the **Bankdemo** project and click **Project** \> **Bankdemo Properties**.

    This opens the tabbed property pages for the project in the main Visual Studio window.

2.  Click the **Dependency Paths** tab.

    **Type** should be set to **COBOL Copybook Paths**. Note that this is already set to `..\..\..\..\..\sources\copybook` set. This is the folder in the sample where the IDE is going to look for the copybook files required by this project and is relative to the project file.

    ![](images/1180afcfd2ee8ac9ddfe40bd62dcd34d.jpg)

3.  Click the **BMS** tab.
4.  Note the `.\generated` path in the **Copybook Output Path** field of the **Output** section.
    This is the path for the copybooks that will be produced from the BMS files during the build.

5.  Click the **COBOL** tab.
    -   Note that the **COBOL dialect** is set to **Enterprise COBOL for z/OS** for the entire project.
    -   Note that **Character set** is set to **ASCII**. You may need to scroll the **COBOL** property page to the right or expand the IDE to see the setting.
    -   Note that the **Output path** is set to `.\bin\x64\Debug\`. This is where the build will produce the application executables.
    -   See what other directives have been set in the **Additional Directives** field.
    -   **Build Settings** is a read-only field that shows all directives that are set on the project.

        ![](images/79277c5880bae61349262805aa635fd0.jpg)


**File Properties**

The individual source files can have their own local properties which override the project settings. To check a file's properties:

1.  In **Solution Explorer**, right-click **BBANK10P.cbl**, and click **Properties**.

    This opens the COBOL-specific file properties.

    Notice that **CICS Directives** is set to **CICSECM()**. This has been set when you added the file to the project or performed a directives scan of the COBOL sources in your project.
    
    ![](images/bbc0c093cd21e687f30502174231cd3a.jpg)

2.  In Solution Explorer, click the **MBANK10.bms** file in your project.
3.  Click the **View** main menu and then click **Properties Window**.

    This opens the Visual Studio properties window. Note that the **Build Action** is set to **BMS Compile** which means the build invokes the BMS Compiler.

    ![](images/414d19af11750512f75b966ef13ea6a8.jpg)

4.  Similarly, check the properties for the **.dat**, the **.jcl**, and the **.cpy** files and see that the **.dat** files and the copybooks will not be compiled.

## Editing COBOL, JCL, BMS, and Data Files

[Back to Top](#overview)

This topic describes the editing features for the various file types used in your project.

**Note:** We recommend that you create backup copies of all files before you edit them.

**Editing COBOL Files**

You are going to explore some of the COBOL editing features by using the `ZBNKPRT1.cbl` program which produces a report from a sequential data file.

1.  In Solution Explorer, double-click **ZBNKPRT1.cbl**.

    This opens the file in the COBOL editor in Visual Studio.

2.  To enable the line numbers in the editor, click **Tools \> Options \> Text Editor \> COBOL \> General**, and select **Line numbers**.

3. Click **OK**.            

**Expanded Copybook View**

 1. Scroll down the file to line 61 and see some `COPY` statements. 
 2. Right-click the line for `COPY CDATED` and click **Show "CDATED.CPY"**. This expands the copybook directly in the code of the  `ZBNKPRT1.cbl` program. 

    ![](images/showcopybook754.png)

3. You can edit the code of the copybook in the expanded view, so introduce an error in the code now.

    This automatically outputs messages in the **Error List** window about problems that occurred in the code. You can sort the list by file name. Double-clicking the line for an error in the **Error List** window positions you on the line in the code that causes the error.

    ![](images/33638d1658ff44c784c2e2898fec253c.jpg)

4. Right-click in the expanded copybook, and click **Hide "CDATED.CPY"**. 

5. Close the file.

    The changes you made to the expanded view were applied to the source of the copybook, so when you are prompted to save your changes, click **No**.

**Unused Data**

Notice that some data items in the Data Division are greyed out. This is because they are not referenced in the Procedure Division.                                                                                        

**Class View** 

You can view the objects and the members defined in your projects in the standard **Class View** that is located in right of the IDE:

![](images/b8b352065b874ce26e48e1fe18aa66ef.jpg)

 If this window is closed, open it from **View** \> **Class View**.

**Navigation in the Code** 

Apart from scrolling down the code in the editor, you can use the following features of the IDE:
  -   Use the drop-down menus at the top of the editor:

        ![](images/4eb0d2e0b64aa37e7ae6197ac9483430.jpg)

   -   In Solution Explorer, double-click the **SBANK00P.cbl** file, click in it, and on the main IDE toolbar click **Edit** \> **Go To** \> **Go To Line** to specify a line in the code to navigate to.

 ![](images/15aVSGoToLine.png)
   
   -   Click **Locate Definition**, ![](images/16VSlocatedefinition.png), in the COBOL toolbar and start typing a search term. 


   ![](images/7a99e5f18fa00915aa26a8ede9697d21.jpg)

 **Exploring Data in Editing Mode** 
 
 Open the `ZBNKEXT1.cbl` file, and scroll down the code to line 227. Hover over the `WS-RECORD-COUNTER2` data item. This provides you with details of the location, size, format, and the number of times the item is used in the program. 

![](images/bb19008a9344c6d82c43bc69455f854d.jpg)


**Data Definitions**
- Right-click a data item in the Procedure Division and click **Go To Definition**.
 This positions the cursor on the line of code where the data item is defined. 

**Peek Definitions**

1. Scroll down to line number 229. 
2. Right-click `WS-CONSOLE-MESSAGE` and click **Peek Definition**. This opens a small window embedded in the editor with the definition of the data item.

   ![](images/a64717adc0a2b1a0265c86c55000b776.jpg)

You can type in the window, or peek the definition of another data item in it.

**Finding All Lines Where a Data Item Is Used** 

1. Right-click a data item in the code, and click **Find All References**. This opens the **Find Symbol Results** window with a list of all occurrences of the data item in the code.
![](images/6b271da45c96eac2dae62a533c8b3316.png)

**Searching in Copybooks**

You can search for strings in the copybooks as follows: 

1. In the main IDE toolbar, click **Edit \> Find and Replace \> Find in Files**. 

2. Set the **Look in** to **COBOL Project Copybook Paths**. 

3. Type BTX- in the search field.


   ![](images/677d4ac2c84a8c49b492491db52f1f9e.jpg)

4. Click **Find All**.
 The results are displayed in the **Find "BTX-"** window.                                                                                                          

**Marking Text and Block Mode**

You can use the mouse to mark the text. To make a block selection of the code:
- Press **Alt** and drag the selection with the mouse.                                                                               

**Rename Items in the Code**   
  Try and see how rename refactoring works in the IDE:

1. To go to the Procedure Division in the `ZBNKPRT1.cbl` file,  on the COBOL toolbar, click **Go To Procedure Division**, ![](images/d471eb4d279d6d6c4bb02406349ccf43.jpg). 
2. Scroll down to line 228. 
3. Right-click `WS-EXEC-PARM-LL` and click **Rename**. 
    
    This highlights all occurrences of the variable in the editor. The **Rename** widget opens. Note that any changes you make are applied to the current project by default. 

   ![](images/c90f798b1f140453068deb31a74d1010.jpg)

1.  Set **Scope** to **Current COBOL Program**, and select **Preview changes**.
2.  Start typing in the editor over the highlighted variable. For example, type `WS-EXEC-PARM`.
3.  Click **Apply**.

    This opens the **Preview Changes - Rename** dialog box showing which files and instances of the variable will be renamed. 

    ![](images/9146b9e17bbc35fd106df8fd7c85302f.jpg)

4.  Click **Apply** again.

    All instances of the data item are renamed in the current program.

5.  To revert the changes, click **Edit \> Undo**.

   **Smart editing** 
    
Let's look at how Smart Editing works with background COBOL parsing:

1.  Scroll down to line 258 in the `ZBNKPRT1.cbl` file and start typing the following, starting in area A of the COBOL editor, one character at a time:

        MOVE W TO

    Notice how the words you type change in the editor. Once a word is recognized as a reserved word or a data item, its color changes. If a line of code contains invalid COBOL syntax, the word that is not recognized is underlined with a wavy red line. Check the **Error List** window to see what errors are reported.

2.  Change the line to:

        MOVE 34 TO WS-

3.  If you have changed this COBOL program, copy the backup version back in again.

**Renumbering the COBOL Sources** 

You can choose from a number of **Renumber** and **Unnumber** options available from the COBOL toolbar (use ![](images/e711062673ff7c4626a662d04d262ad7.jpg) in the toolbar and the commands available in the drop-down menu) to insert and remove line numbers from your code. 

**Note:** If a COBOL source file includes some comments beyond column 73, you might want to change only the numbers in the COBOL sequence area, as **Renumber** overwrites any text in the comments area. 

1. To insert the line numbers in your code, click the downward arrow next to ![](images/e711062673ff7c4626a662d04d262ad7.jpg) in the COBOL toolbar, and click **Renumber Left**.

   ![](images/f0c1ec6c4a48d259d31f7c14610b1539.png)

2. To insert line numbers beyond the end of area B, click the downward arrow next to ![](images/e711062673ff7c4626a662d04d262ad7.jpg) in the COBOL toolbar, and click **Renumber Both**.

You should now see line numbers running down both sides of the source code:
   ![](images/27VSRenumberboth.png)

You can remove the line numbers from your code. Note that the **Renumber** and **Unnumber** options are not available in the expanded copybook view.

3. Ensure that `ZBNKPRT1.cbl` is opened in the editor, click the downward arrow next to ![](images/e711062673ff7c4626a662d04d262ad7.jpg) in the COBOL  toolbar, and then click **Unnumber Left**.

This removes the line numbers from the COBOL sequence area.

   ![](images/28VSUnnumberleft.png)

**JCL Editing**

In **Solution Explorer**, double-click the **ZBNKSTMT.jcl** file to open it in the JCL editor.

The editor enables you to edit JCL files in text view and offers a basic level of colorization for items such as reserved words and comments. The JCL editor does not support background parsing or syntax checking.

**BMS Editing**

There are two ways to edit BMS files. The first one is to use the basic BMS text editor available in the IDE. The other is to use a WYSIWYG version, the Rocket® BMS Painter, which is available as a separate utility installed with this product.

To open the BMS file in the IDE text view:

1. In Solution Explorer, double-click **MBANK10.bms** to open it in the basic BMS editor.
![](images/87167f189bba38579aa8e1a4cbbaaca2.jpg)

Although you can use this basic text editor to make small changes, it is quite difficult to edit BMS files in text view.

A much more suitable and less error-prone way to edit BMS files is to use the BMS Painter:

1.  Close the BMS text editor.
2.  In Solution Explorer, right-click **MBANK10.bms** in the **bms** folder and click **Open BMS Painter**.

    This starts the external Rocket BMS Painter.
    ![](images/1962FA41-8CB1-4DD1-A1A5-1707F00D6509.png)

3.  In BMS Painter, you can click fields and move them by dragging.

    For example, double-click the data field immediately following the text `User Id` and move it to a different position on the map.

4.  To add a field, click in the desired place in the window and start typing.
5.  To change a field's properties, right-click it and select **Properties**.
6.  To change the properties of the map or mapset, right-click the item and select **Properties**.

    For example, do this for the MBANK10 mapset and the BANK10A map.

7.  Click **File** \> **Exit** to close the utility and do not save the file.

**Editing Data Files**

You can edit data files using one of two available Rocket&reg; Software Data File Editor tools.

By default, Visual Studio is configured to use the Data File Tools utility. To check whether this is enabled:

1.  Click **Tools \> Options \> Rocket Tools \> Data File Tools**.
2.  Ensure **Use New Data File Tools for supported options** is selected, and click **OK**.
3.  To edit the `.dat` file, in Solution Explorer, right-click the **.dat** file and click **Open with Data File Tools**.

    ![](images/ffa0da317626763eb89bfb00bd291439.jpg)

    This starts the **Data File Editor** and loads the `.dat` file in the **Open Data File** dialog box.

4.  Click **Open Exclusive** to load the file.

    The **Data File Editor** loads the data file and shows two views:
    -   The left pane shows the raw form of the file. Because many of the field are COMP-3 fields, the data in these fields is presented in an ASCII view.

      ![](images/datafiletoolsscreengrabmarch2025.png)
    - The right pane shows the record layout for the file in its detailed field view and the COMP-3 fields are shown in an easier to read, editable form.

6.  Change the value of `BAC-REC-BALANCE` from `91.14` to `132.76` as follows: 

    a. Click the line for `BAC-REC-BALANCE` in the right pane and then click ![](images/4fc0d64d1ee24b2a6869937b20ba5685.jpg), **Edit Record**. This highlights the record.

    b.  Double-click in the **Value** field for `BAC-REC-BALANCE`.
    
    c.  Use the arrow keys to move the cursor inside the **Value** field.
    
    d. Type `132.76` then click ![](images/d333b67a20f0bf3c03f1b166d0c952ab.jpg), **Save Record**.

    e.  Confirm that you want to save the changes to this record.
   
    f.  Using the same method, restore the previous value of `BAC-REC-BALANCE`.
7.  Close the Data File Tools utility.

## Compiling the Source Code

[Back to Top](#overview)

**Important:** You need Enterprise Developer or Enterprise Developer for IBM zEnterprise to create executables. Building projects is not supported in Enterprise Developer Connect.

To compile the application:

1.  Click **Build** \> **Build Solution**.

    The Output window displays information about the progress of the build result.

2.  If there are any problems, check the Error List window. Double-click a line for an error number to position the cursor on it.

    The build checks for any files that have changed and does two things:
-   Compiles any files affected by the changes
-   Relinks the built files if necessary.

**COBOL Compiler Control**

The Rocket COBOL Compiler can compile many different COBOL dialect variations. It can also compile COBOL code that contains `EXEC CICS` or `EXEC SQL` statements. The Compiler is controlled through a series of directives which are passed to the Compiler at build time. You can set directives at either a project or a component level.

Often the directives are set only at the project level, which means that all component files in the project use them. Sometimes, you have a component which you must compile with different directives. In this case, you can set the directives at the component level, which overrides the project settings.

For example, most of the programs in your project could be using Enterprise COBOL for z/OS and only a few could use VS COBOL II. In this case, you would set directives for Enterprise COBOL for z/OS at the project level, and VS COBOL II at the level of the respective COBOL programs.

The Bankdemo application already has the required Compiler directives set on the files. At build time, the IDE invokes the COBOL compiler to compile the sources and create a number of files. These "built" files can vary, but each COBOL program in the Bankdemo application compiles to produce the following three types of file:

| **File type**               | **Function**                                                                                |
|-----------------------------|---------------------------------------------------------------------------------------------|
| `.dll` - dynamic link library | Effectively the executable module the Compiler creates for each program.                    |
| `.idy` - debugger information | The file created by the Compiler which allows debugging of the module.                      |
| `.obj` - object file          | A temporary file the Compiler creates while producing the .dll. You can delete these files. |

**BMS Compiler Control**

In the same way as for COBOL, the BMS compilation is controlled both at project and at component level.

The BMS Compiler produces the following two types of file:

| **File type**         | **Function**                                                                                  |
|-----------------------|-----------------------------------------------------------------------------------------------|
| `.mod` - BMS executable | A file created by the BMS compiler which is the executable module relating to the BMS source. |
| `.cpy` - copybook       | A copybook that contains the BMS mapping for use in a COBOL program.                          |

**Producing a Compiler Listing**

You can configure the IDE to create a fully expanded Compiler listing file during the build. The following is also an example of setting a directive at component level:

1.  In Solution Explorer, right-click **ZBNKPRT1.cbl**, and click **Properties**.
2.  Click the **COBOL** tab.
3.  Set the **Generate listing file** field to **Yes**, and save your changes.
4.  Click **Build** \> **Build Solution**.

    During the build, the Compiler produces a source listing file, **ZBNKPRT1.lst**, in a `Listing` subfolder in
    the project directory (`C:\MFETDUSER\tutorial\projects\Studio\cobol\Bankdemo\Listing` in this case). The listing file includes a fully expanded source file together with some Compiler system information at the start and with any Compiler errors highlighted with asterisks. From File Explorer, you can open the file in a text editor, such as Windows Notepad, and view its contents.

**Example of Compiling a COBOL Program with Errors**

You can introduce some Compiler errors into one of the programs to see how the Compiler handles them:

1. In Solution Explorer, double-click **ZBNKPRT1.cbl**.
2. Scroll down the program to the start of the Procedure Division around line 224.
3. Introduce a few syntax errors as follows:
    - On line 226, change `RUN-TIME` to `RUN-TME`
    - On line 229, change `SPACES` to `SPOCES`
    - On line 237, place a period after the `END-IF`.

     The errors are underlined with red wavy lines and a colored bar is added to the left of each line that includes an error.

4. Hover over an underlined item to view a pop-up with an explanation of what the error is.
4. Save the program and build your solution.
6. Check the **Error List** window to view the list of errors.
7. Double-click an error in the list to position the cursor on the line of code that contains the error.
8. To check the errors in the listing file, in File Explorer, navigate to `C:\MFETDUSER\tutorial\projects\Studio\cobol\Bankdemo\Listing`, and open the file `ZBNKPRT.lst` in a text editor.

    The lines that include syntax errors are marked with asterisks (\*\*).

    ![](images/29930242-CCA4-471C-A535-6CD24F12A117.png)

9. In the IDE, fix the errors in `ZBNKPRT.cbl`, save the file and rebuild the solution.

    There should be no errors in the build now.

## Unit Testing the Batch Application

[Back to Top](#overview)

The first thing you must do is check that the Bankdemo application is executing correctly.

To execute the JCL, you must run the application in an instance of the Rocket Enterprise Server (sometimes abbreviated to Enterprise Server). This demonstration includes a pre-configured enterprise server instance called BANKDEMO which you must import in Enterprise Server and start before you execute the Bankdemo application.

**Importing the Bankdemo Server**

.

1.  Open Windows PowerShell and navigate to the `C:\MFETDUSER\tutorial` folder.
2.  Run `set-ExecutionPolicy RemoteSigned -Scope CurrentUser`.
3.  (Optional) Unblock the script.

    At times, for security reasons, when you have downloaded files by using a browser, the files can be blocked and you might not be able to run the script. To unblock the script:

    a. Open File Explorer and navigate to the `C:\MFETDUSER\tutorial` folder.

    b. Right-click the **createdefinition.ps1** file and select **Properties**.

    c. Select the **Unblock** check box and click **Apply**. 

4.  Run the PowerShell script provided with the sample: `.\createdefinition.ps1`. 

This runs the script and creates the Enterprise Server region definition file, `BANKDEMO.xml`, in the same folder. The file is configured for the location in which you saved the sample files.

If you cannot use the PowerShell script to create the `BANKDEMO.xml` file, you can create it manually.

1. Create an empty `BANKDEMO.xml` file.
2. Open the file in a text editor and copy the contents from the `BANKDEMO.template` file to the `BANKDEMO.xml` file.
3. In the `BANKROOT=__IMPORT_FILE_DIR__/..` value pair, manually edit `_IMPORT_FILE_DIR` and replace it with the path to the `tutorial` directory. 

   If you imported the tutorial files to the `MFETDUSER` folder, the directory name would be `C:\MFETDUSER\tutorial/..`. 

Ensure that the default settings are applied to the Directory Sever:

1.  Click the Start menu and open the Services application. Navigate to Directory Server to view its status and set it to **Running** if it is not already started.

2.  In Visual Studio, open the Server Explorer window.

    If the window is not visible, click **View** \> **Server Explorer** (or **View** \> **Other Windows** \> **Server Explorer**).

    ![](images/03218b9fa5693aaca14ff3cf3aa3dd1b.jpg) **Tip:** Use the Auto Hide button (![](images/bf74b6a329048075497d723393231eba.jpg)) in the Server Explorer toolbar to pin the window to the IDE window.

3.  Right-click **Rocket Enterprise Servers** and select **Add Directory Server**. This opens the Rocket Directory Server window. 

4.  Ensure that the host name is `localhost` and the port number is `86`.

Now you can import the definition of the Bankdemo logical server (LSER) in Enterprise Server:

1.  In Visual Studio, open the Server Explorer window.

2.  Expand **Rocket Enterprise Server**.

    If you are presented with the **Enterprise Server Sign On** dialog box, click **OK**.

3.  Right-click **localhost** and click **Import**.
4.  In the **Import Server** dialog box, click **...** on the line for **Import server definition file**.
5.  Browse to the `C:\MFETDUSER\tutorial` folder, select **BANKDEMO.xml**, click **Open**, and click **OK**.

6. Check the **Output** window for the results of importing the server. 
The Server Explorer window should now show a server called BANKDEMO under **Rocket Enterprise Server \> localhost**. If the server is not visible, right-click **Rocket Enterprise Server** and click **Refresh**.

**Note**: If you are having issues with importing the server definition file, open it and check if `BANKROOT` is set to a valid path, such as `C:\MFETDUSER\tutorial/..`. If  not, edit it manually.   

**Associate the BANKDEMO Enterprise Server with Your Project**

Ensure your application is associated with the BANKDEMO server:

1.  Right-click the BANKDEMO server, and click **Associate With Project**.
2.  Ensure there is a check mark before the name of the Bankdemo application.

    ![](images/ac6ffc9a6ab287546d0dfdc00e71414b.jpg)

3. Click the **Bankdemo** project in Solution Explorer and see that the details of the associated server appear in the **Properties** window. The TN3270 port number will be populated once you start the server.

    ![](images/b5194c0b5080acb5655379d1c67f6d9a.jpg)

**Configure the IDE Settings for Enterprise Server**

Configure the IDE to start the associated BANKDEMO server automatically as follows:

1.  Click **Tools \> Options**.
2.  Expand **Rocket Tools** and click **Enterprise Server**.
3.  Select the following options on this page to enable the IDE to start or stop the associated server, and to enable dynamic debugging, for when it is not enabled in the server:
    - **Automatically start the associated server** - this ensures the IDE will start the server if it is not running when you execute the application.
    - **Stop running servers on project/folder close** - this enables the IDE to stop the server when you close the project.
    - **Automatically enable dynamic debugging** - this ensures the IDE will check whether the server has dynamic debugging enabled and, if it is not, will enable it when you start debugging.

4.  Click **OK**.

**Start the BANKDEMO Enterprise Server and Display the Server Log**

These are the steps to start the server manually, and are included for completeness. You do not have to start the server manually, as you have configured the IDE to start the server automatically. 

1. In **Server Explorer**, under **Rocket Enterprise Server**, right-click **BANKDEMO** and click **Start**.

    **Note:** You might receive an Enterprise Server Sign On dialog prompting you to provide connection details for the BANKDEMO server. This is a standard security dialog. Click **OK** without specifying any sign in details. Also, you might skip enabling password recovery.

    You might receive a **Windows Security Alert** blocking the **MF Communications** process. Click **Allow access**.

2.  Right-click the BANKDEMO server and click **Show Console Log**.

    ![](images/3b9dcb9098ce66eb406d4451fe59e8c6.png)
    See the **Output** window for the messages from the server log that show that the server has started.

3.  Right-click **Rocket Enterprise Server** again, and then click **Refresh** to see that the server has started.

    You are now ready to execute the JCL job.

**Executing JCL**

The JCL provided in your demo causes the COBOL application to read a file, sort the data and produce a report. The `.jcl` file, `ZBNKSTMT.jcl`, is in the **Bankdemo** project. To submit this job:

1.  In Solution Explorer, select the JCL file in the project, drag it across to Server Explorer, and drop it onto the BANKDEMO server.

    Alternatively, you can right-click the file in Solution Explorer and select **Submit JCL**.

    **Note:** If you have not started the BANKDEMO server yet, since you configured the IDE to start the server automatically, you receive a notification that the server will be started. Click **OK** to confirm.

2.  Check the **Output** window to see that the job has been submitted and that the job has completed.

    ![](images/69bffc75ea0326925df5f862247e317b.jpg)

    Тhe job spool window automatically opens inside the IDE and shows the job details. You can also open this view from within Server Explorer.

    ![](images/ca93ec0ab4b1c23d80074999d39bf568.jpg)

**Viewing the Catalog and the Spool**

You can open the catalog and the spool directly from Server Explorer.

To view the catalog:

1.  In Server Explorer, right-click the BANKDEMO server and click **Show Catalog**.

    Alternatively, in Solution Explorer, right-click the Bankdemo project and click **Enterprise Server \> Show Catalog**.

    This opens the catalog:
![](images/3c6f3d18d838a553e016f22a1d3a4ab2.png)

2.  Click a file name (for example, **MFI01V.MFIDEMO.BNKACC**) in the list in the left pane. 

      This displays the DCB information for this catalog item.
3.  Expand the **Display** section to preview the contents of the file.

To view the spool:

1.  In **Server Explorer**, right-click the BANKDEMO server and click **Show Spool**.

    Alternatively, in Solution Explorer, right-click the Bankdemo project, and click **Enterprise Server \> Show Spool**. This might still show the details of the submitted JCL job.

2.  Close the tab for the job when you have reviewed the details.
3.  Click ![](images/4759DB1A-2DFB-46FC-BFC0-AD44A3D5EF46.png) (**Toggle Filter**) on the Home page of the Spool window to set some filters.

      ![](images/e1b080a897a4bd65512369587fdded78.jpg)
7.  Click the **Complete** button, select **Descending** next to **Job ID** to see a list of all jobs in the completed queue, and then click **Apply**. Your job is at the top of the list.
8.  Click the job you want to see in the list.

    This opens a page with information for the job progress, showing return condition code (**Cond.**) of 0000:

    ![](images/2528f694ecb567aa162db6d1de959fdc.jpg)

    In the **DD Entries** section, there are:
    -   Two **SYSOUT** results (one for the EXTRACT and one for the SORT). Click these and see the **SYSOUT Details** section:
        Again, if you cannot see your SYSOUT files, make sure you have selected **Printed** in the filter.
    -   The **PRINTOUT** is the final printed results created by your job. Click **PRINTOUT** in the **DD Entries** section to see the results:

![](images/ef9ee87126c25d0efd3a8c238ecb909c.png)
    You can now start to look at how to run the online application.

## Unit Testing the Online Application

[Back to Top](#overview)

In the previous step, Unit Testing the Batch Application, you used the BANKDEMO enterprise server. You are going to use it again for online testing.

As with JCL, execution of the jobs requires a previously configured enterprise server instance.

Before you proceed, ensure that Host Access for the Cloud (HACloud) is running:

1. From the Windows Start menu, open the Services application.

2. Navigate to the HA Cloud service and check that its status is set to **Running**.

3. If it is not running, right-click it and click **Start**.

**Executing the CICS application**

The CICS application requires that you use a 3270 terminal emulator. This tutorial uses Host Access for the Cloud (HACloud), but you can adapt the tutorial to suit your terminal emulator of choice. 

**Configuring the TN3270 Settings in the IDE** 

To check the IDE preferences for a TN3270 display:

1.  In the IDE, click **Tools \> Options**.
2.  Expand **Rocket Tools**, and click **TN3270 Display**.
3.  Ensure that **Host Access for the Cloud** is selected.
4.  Click **OK**.

**Starting the Terminal Emulator**

1. Right-click the BANKDEMO server in **Server Explorer**, and click **Mainframe TN3270 Display**.

This opens the **Host Access for the Cloud** in your default browser and automatically establishes a 3270 terminal connection to the BANKDEMO server. You can see the starting page of the ES/MTO region BANKDEMO.

**Executing the Enterprise Server Demonstration**

1.  Type your login details, and press **Enter**.

A suitable User Id is `b0001`. You can type anything as a password, but you cannot leave the field empty.

![](images/bankdemorocketscreen.png)

2.  Type **/** against **Display your account balances**. 

![](images/Bankdemo_002.png)

3. Press **Enter** to see the details for this customer.
 
![](images/Bankdemo_003.png)

4.  You can explore this application further if you wish or press **Ctrl + F2** to clear the screen and conclude the session.

**Stopping the Enterprise Server**

You can stop the Bankdemo server from within Server Explorer. You can leave it running though, if you wish to continue this tutorial.

**Note:** In production, enterprise servers are long-running processes that usually run for many months without stopping and starting.

## Debugging the Batch Application

[Back to Top](#overview)

You are going to debug the batch Bankdemo application using the JCL debugger.

**Starting the Bankdemo Enterprise Server**

If the enterprise server is not yet started, you need to start it as follows:

1.  In **Server Explorer**, under **Rocket Enterprise Server**, right-click **BANKDEMO** and click **Start**.
2.  Right-click **Rocket Enterprise Server** again, and then click **Refresh** to see that the server has started.

    ![](images/46895A06-FD3A-4B07-AA02-9752F2870A79.jpeg)
    

**Starting the Debugger**

The demonstration application includes around 60 programs and some of them are debuggable. The default debugger in Enterprise Developer is the CICS Debugger. You need to select the JCL debugger to debug the batch Bankdemo application:

1.  In **Solution Explorer**, right-click the **BankDemo** project and click **Properties**.
4.  Click the **Debug** option in the **Properties** window.
5.  Set **Launch** to **JCL**.
6.  Click **File** \> **Save All** to save your changes.

To start the debugger:

- Click **Debug** \> **Step Into**.

    Visual Studio enters debug mode and opens a few new windows.

    The application is now waiting for an event that will trigger the debugging.

**Simple Debugging**

You can now look at some simple features inside the debugger. To submit the JCL job:

1.  In Solution Explorer, right-click **ZBNKSTMT.jcl** and click **Submit JCL**.

    The debugger starts and the IDE opens **ZBNKEXT1.cbl** for debugging, with the execution point set on the first line of Procedure Division.

    ![](images/e8d8a4263157b617ed680be5ac7dfb40.jpg)

2.  Check the Output window (click **View \> Output** to show the window, if it is hidden) and set **Show output from** to **Enterprise Server** to verify that the job has been submitted successfully.
![](images/133fcdd2660981932e07a8b04a5142e0.jpg)

**Stepping through the Code**

The highlighted line of code is the one the IDE will execute next.

1.  Press **F11** (Step Into) to execute the highlighted line.

    The `PERFORM` statement executes and takes you to the line starting with `IF TIMER-START`.

2.  Press **F11** slowly a few more times until you reach line 160.

**Using Run To Cursor**

1.  Scroll down the file and position the cursor on a line further down the code.
2.  Right-click the line in the editor, and click **Run To Cursor**.

    The application runs and executes the instructions until the line you selected.

**Using the Debug Windows**

There are a number of default windows which you can use while debugging the application such as:

**Autos** 

Shows the values of the data items on the current line you have stepped into:

![](images/f4f5b8720b861a9214746cea56dfcf8b.jpg)

**Watch** 

This window shows the values of data items you have added to the watch list. To set a watch on a data item:

1.  Scroll up to line 67 in **ZBNKEXT1.cbl**.
2.  Right-click `WS-RECORD-COUNTER1` and click **Add Watch**.

    This adds the item to the Watch window so you can see how it changes as you step through the code.

    ![](images/b8efccd4323517f3509448858700134e.jpg)

There are some additional windows you can use as well. To open them:

1.  Click **Debug** \> **Windows** and select a window from the list.
3.  Open the windows for Breakpoints, Watchpoints, Program Breakpoints, a number of one to four Memory windows:

    ![](images/a77a8b010917fa974851449f40bd4b0b.jpg)

    Note that the windows are stacked, with a tab running along the bottom of the window.

**Looking at Data Values in Debug Mode**

While debugging, you can preview the values of data items in the current context as follows:

1.  Open the `ZBNKEXT1.cbl` file and scroll down the code to line 227.
2.  Hover over the `WS-RECORD-COUNTER2` data item.

    This opens a pop-up with the value of the item in the current context:

    ![](images/46VShoverdataitem.png)

3. You can click ![](images/97005e37e4da505b8657a67a07d752d6.jpg) to pin the pop-up to the editor window. 

**Setting a Simple Breakpoint**

Open the Breakpoints window - currently, there are no breakpoints set in the program. You can set a simple breakpoint as follows:

1.  Scroll up the code to line 171 of the `ZBNKEXT1.cbl` file.
2.  Right-click the line, and click **Breakpoint** \> **Insert Breakpoint**.

    ![](images/12d08bc77f0ed11c2dfa4f56b88619f2.jpg)

3.  Do the same for line 177.

    **Note:** You can enable and disable the breakpoints from the Breakpoints window.

    ![](images/5234dccb8a6f6a6eee364410756c39fe.jpg)

4.  Click **F5** to run the code.

    The execution of the code stops at the first breakpoint.

5.  Press **F5** to resume the execution.

    You can see that `ZBNKEXT1.cbl` finishes and the debugger starts to debug the second program defined in the JCL.

**Setting a COBOL Watchpoint**

COBOL watchpoints enable you to watch the memory associated with data items. You can add a COBOL watchpoint as follows:

1.  Scroll to line 99 in the code of `ZBNKEXT1.cbl` file.
2.  Right-click `WS-EXEC-PARM-LL` and click **Add COBOL Watchpoint**.

    This adds the item to the COBOL Watchpoints window.

3.  Notice how the value of this data item changes as you step through the code.

    ![](images/49VSWatchpoints.png)

**Note**: To view watchpoints, you need to restart debugging as previously shown. 

**Running CSI Queries**

You can use the COBOL Source Information (CSI) functionality and its **Quick Browse** dialog to obtain information about your program when you are debugging it.

1.  Open the `SBANK00P.cbl` file in the editor.
2.  Click ![](images/3119773a06873ff858290267b7dc7e43.jpg), **Quick Browse**, in the COBOL toolbar to start the CSI query control.

    See *COBOL toolbar* in the product help for more information.

3.  Enter a simple query such as `WS-\*`.

    ![](images/165a1e5e420417cd978e4f4b7f82c3ca.jpg)

4.  Press **Enter** to run the query.

    The results are shown in the **Enterprise Developer Code Analysis** window:

    ![](images/1758A9F5-4C16-40DF-BFED-E4DF19932E46.jpeg)

**Running COBOL Reports**

   Enterprise Developer provides a few COBOL reports which you can run against your COBOL programs to help you understand and optimize them. For example, to run a report to identify any code that cannot be reached or executed, you need to run an unreferenced data report:
1.  With the `SBANK00P.cbl` file still opened in the editor, click the down arrow next to ![](images/3119773a06873ff858290267b7dc7e43.jpg), **Quick Browse**, in the COBOL toolbar and click **Unreferenced Data**.

      The IDE shows the results in the **Enterprise Developer Code Analysis** window:

    ![](images/924799F6-F6F8-4189-B7C5-B69139EF7F97.png)

    a.  Expand any of the lines in the report and double-click a line in the result to highlight the lines of code that include unreferenced data.
    
    b.  Use the rest of the commands available from the down arrow next to ![](images/95f4e27be11786c150a0ba4f07a661ae.jpg), **Quick Browse**, in the COBOL toolbar to run any of the other available reports.

**Stop Debugging**

 Although the job has completed, the debugger is still waiting for the next event. To stop debugging:

   - Click **Debug** \> **Stop Debugging**.

## Debugging the Online Application

[Back to Top](#overview)

**Starting the BANKDEMO Enterprise Server**

If the enterprise server is not yet stated, you need to start it as follows:

1.  In the IDE, open the Server Explorer window.

    If the window is not visible, click **View** \> **Server Explorer** (or **View** \> **Other Windows** \> **Server Explorer**).

2.  In Server Explorer, right-click the BANKDEMO server and click **Start**.

    Wait until the server has started. In the list of servers in Server Explorer, BANKDEMO might still have a red square next to it. This is a refresh delay.

3.  In Server Explorer window, right-click **Rocket Enterprise Server** and click **Refresh** to confirm the server has started.

**Starting the Debugger**

The demonstration application includes around 60 programs and some of them are debuggable. The default debugger in Enterprise Developer is the CICS debugger. You are going to use this to debug the online Bankdemo application.

1.  In Solution Explorer, right-click the **Bankdemo** project and click **Properties**.
2.  Click the **Debug** tab in the properties.
3.  Set **Launch** to **CICS**.
4.  Type **BANK** in the **Transaction** field.
5.  Click **File** \> **Save All** to save your changes.

To start the debugger:

1.  Click **Debug** \> **Step Into**.

    Visual Studio enters debug mode and a few new windows open in the IDE. HA Cloud starts outside of Visual Studio but does not show the sign-on application screen yet.

    The program `SBANK00P` starts to execute and execution stops on the first `EXEC CICS` statement in the code.

    ![](images/bdf646e57fcb173a8b3704810770b0d9.jpg)

2.  Continue stepping through the code.

**Simple Debugging**

You use the same features as previously to debug the application.

1.  Click **Debug** \> **Step Into** or press **F11** a few times to go through executing the code.
2.  Watch how the values of the variables change in the **Autos** window.

**Stop Debugging**

Although the job has completed, the debugger is still waiting for the next event. To stop debugging:

**1.** Click **Debug** \> **Stop Debugging**.

This concludes this set of tutorials that introduce Rocket Enterprise Developer.

> **Note**: You should re-enable Enterprise Server security if you have not already done so. See *Recreate the Default Enterprise Server Security Configuration* in the product documentation for steps on how to re-enable security. 

[Back to Top](#overview)
