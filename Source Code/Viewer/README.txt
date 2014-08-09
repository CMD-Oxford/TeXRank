Matlab source code for Viewer

To build Viewer with deploytool,
  Main File: DropRankingViewer.m

  Shared Resources and Helper Files:
    All other .m files in Source Code/Viewer
    Subwelltext.mat
    ojdbc5.jar (or whichever your database uses).
	
The m files: getDataFromBEEHIVE and getDataFromCRYSTAL are written based on SGC's database infrastructure, where
	BEEHIVE contains all experiment information (expression to structure determination)
	CRYSTAL contains all imaging information (mainly the architecture by Rigaky's Minstrel HT).
	Please modify these according to your infrastructure. 
  
For packaging, you may want to include the MCR (we've used R2012a (v7.17)), available from http://www.mathworks.co.uk/products/compiler/mcr/