# **Paper Replication Assignment 1**

## Preable

Note: Although I already added both the files for the first and second replication assignments to the original International Trade repository, this made for a disorganized experience. As such, I have now created two repositories, one for each assignment, and will reupload the original files to the appropriate repository.

Simply download all files in this repository into a single file, follow the below intructions for running the code files in the appropriate order, change the file paths if needed, and run the code to produce the required tables.

In order, the files should be ran in the following order: (1) **replication_d1.m** (2) **replication_part2.m** (3) **replication_part3_robust.m**. If all data and code files are in the same folder, these .m files should run without any additional manual effort of the part of the individual replicating this. If you would like an extensive overview of which of the files correspond with which the .m files, read below.

# What we did

## Step 1:
Download all files in the International Trade Replication 1 repository into a single folder.

## Step 2: 
The Excel files **exports.xlsx**, **imports.xlsx**, and **gross_output.xlsx**, along with the MATLAB file **replication_d1.m**, are used to compute the **Import Penetration Ratio (IPR)**, generating **ipr_final.xlsx**.

IN MATLAB code, we filter this file such that we only have **4 sectors** (justification discussed in the accompanying PDF file) to obtain **ipr_filtered.xlsx**.

## Step 3: 
The Excel file **pld_ggdc.xlsx** and the MATLAB file **replication_part2.m** are used to generate an equivalent of Table 2 from the paper for all 12 sectors, and the results are manually formatted into LaTeX using Overleaf.

## Step 4: 
We manually filter (in Excel, not MATLAB) the relative productivity values computed in Table 2, keeping only the 4 sectors (**Agriculture, Manufacturing, Mining, and Energy (Utilities)**), and save it as **relative_productivity_4sectors.xlsx**. This file is provided in the repository.

The Excel files **relative_productivity_4sectors.xlsx**, **OECD_4sectors.xlsx**, **exports.xlsx**, and the previously generated **ipr_filtered.xlsx**, along with the MATLAB file **replication_part3_robust.m**, are used to generate an equivalent of Table 3. We then manually format this table into LaTeX.
