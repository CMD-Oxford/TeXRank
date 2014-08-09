% function [sortedFiles WellLocation ScreenType] = SortFilesNoBarcode(files)
function [sortedFiles WellLocation Barcode] = SortFilesNoBarcode(files)
%files = structure produced by dir( )

tempFiles = cell(length(files), 18);
sortedFiles = cell(length(files),1);
CellLine = 1;

    for i = 1:length(files)
        parts = regexp(files(i).name, '_', 'split');
        if length(parts) > 1 
            tempFiles(CellLine, : ) = parts;
            sortedFiles{CellLine,1} = files(i).name;
            CellLine = CellLine + 1;
        end
        
    end
    


% Clear empty rows in the tempSortedfiles
tempFiles = tempFiles(1:CellLine-1, :);
[tempFiles idx] = sortrows(tempFiles, [11 12 13]);
sortedFiles = sortedFiles(idx,:);
WellType = str2num(cell2mat(tempFiles(:,13)));
WellCol = str2num(cell2mat(tempFiles(:,11)));
WellRow = str2num(cell2mat(tempFiles(:,12)));
WellSeq = (WellCol - 1)*24 + (WellRow-1)*3 + max(WellType - 1, 1);
Machine = str2num(cell2mat(tempFiles(:,3)));
WellLocation = [WellCol WellRow WellType WellSeq Machine];
Barcode = tempFiles(:,8);
for i = 1:length(Barcode)
    Barcode{i,1} = Barcode{i}(5:end);
end

if length(WellType) > 288
    Keep = WellType ~= 2;
    sortedFiles = sortedFiles(Keep);
    WellLocation = WellLocation(Keep,:);
    Barcode = Barcode(Keep);
end
