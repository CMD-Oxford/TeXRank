# TeXRank
======
Software package for ranking and viewing crystallization drops. 

TeXRank consists of 2 components, Ranker - the algorithm for ranking droplets, and Viewer, the GUI for viewing droplets in the ranked order, and ideally integrated with your database and imaging infrastructure. 


=====

## Ranker



Download and run Ranker_pkg.exe for the complete package, which includes Ranker.exe, some example background image files, and input file required. 

Ranker.exe is a Windows console application that requires the MCR v7.17 (downloadable from http://www.mathworks.co.uk/products/compiler/mcr/). Please install the MCR before you use Ranker.exe

We have also provided a helper app - GenerateBackgroundIm - to help you produce the background image files required for Ranker.exe

All files required to build Ranker.exe yourself are in the "Source Code" folder.



To use Ranker.exe, cd to the directory where Ranker.exe is stored. 

### Usage: 

    Ranker.exe FilePaths.txt OutputFileName “BackgroundImage1.mat, BackgroundImage2.mat, BackgroundImage3.mat”

-----

#### Input 1: FilePaths.txt
* Text file with file paths to all the images to be processed, typically but not limited to all images from a plate/layer.
  *Use absolute paths (unless you’re sure your relative file paths work!)
  *Each file path should be on a new line.
  *For example, check database for new plates inspected, get the file paths to the images, and write them to a text file.
  
-----
  
#### Input 2: OutputFileName 
* Desired output file name, absolute or relative file path.
* 2 output files will be produced:
  * OutputFileName_TextonDist.mat: Matlab file
    * Variable name: TextonFeatures
    * Variable Type: 1-by-6 cell
    * TextonFeatures{1} = file path, 
    * TextonFeatures{2}  = n-by-300 matrix of texton distribution, n = number of rows, 
    * TextonFeatures{3}  = Ranking score (0 to 1),
    * TextonFeatures{4}  = Faulty label (0: Good drop, 1: Empty drop, 2: Faulty drop), 
    * TextonFeatures{5}  = Clear score (0 to 1, 1 == clear)
    * TextonFeatures{6}  = translation vector for each background image.
  * OutputFileName_Scores.csv: 
    * Number of rows: Same number of rows as in FilePaths.txt
    * Column 1: File paths
    * Column 2: Ranking score
    * Column 3: Faulty label
    * Column 4: Clear score
			
------

#### Input 3: “BackgroundImage1.mat, BackgroundImage2.mat, BackgroundImage3.mat”
  * Paths to background images required. 
  * Background images should be generated with the tool provided (GenerateBackgroundIm.exe), or conforms to the following format:
    * Variable name: BackgroundIm
    * Variable type: 1-by-2 cell
    * BackgroundIm{1} = uint8, 96-by-128 matrix of grey-level average of similar empty sub wells. 
    * BackgroundIm{2} = logical mask of BackgroundIm{1}, where regions inside the well is true, and false outside the well. 
  * If multiple background images are required (ie more than 1 sub well), separate each path with a comma and enclose all in double quotes. 


========

## Viewer

An API is being developed, although a running version for the SGC is now available to modify. Email me (jiatsing.ng_at_dtc.ox.ac.uk) if you'd like the code for this. 

