# read_inp_file && show it

Functionality
This code extracts node coordinates and element nodes from .inp files generated by Abaqus.

Method
It identifies key sections within the Abaqus .inp file by recognizing keywords and then locates and extracts the necessary information (such as node coordinates and element connectivity).

Performance
I tested the performance with the following file sizes and observed the execution times:

For an 81 MB .inp file, the extraction took approximately 130 seconds on an i9-9900K CPU.
For a 1.56 MB .inp file, the extraction took approximately 9.5 seconds.
