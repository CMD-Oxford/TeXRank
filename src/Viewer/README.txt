Matlab source code for Viewer

To build Viewer with deploytool,
  Main File: TeXRankO.m

  Shared Resources and Helper Files:
    All other .m files in stc/Viewer
    Subwelltext.mat
    ojdbc5.jar (or whichever your database uses).
    The following folders:
        PrecPatternLibrary
        CondDicts
        IndividualProfiles
        MatFiles

  TeXRankO.exe should be placed in the same folder as Ranker.exe and the following folders:
    Data\      -> Folder containing output .mat files from Ranker.exe. 
    LogFiles\  -> Log files (written also by Ranker.exe). 
        
 
For packaging, you may want to include the MCR (we've used R2012a (v7.17)), available from http://www.mathworks.co.uk/products/compiler/mcr/