tic
clear  %clears all pre-existing variables from the workspace so they do not impact processing in this run.

files = dir('*.txt')  ;     % the directory function returns a cell array containing the name, date, bytes and date-as-number as a single array for each txt file in this directory.

HowManyFiles = length(files) % Need to know the number of files to process.  This number is encoded as the variable "HowManyFiles". 

for FileCounter = 1:length(files)   %Runs the following set of commands for each file meeting criterion within the current directory.
  InputFileList {FileCounter,1} = files (FileCounter).name;  %InputFileList is a Cell Array of Strings, meaning an array of strings that are not necessarily uniform in number of characters.
  InputFileList {FileCounter,2} = FileCounter; %Each row in InputFileList contains the name of one *.txt file followed by the row number associated with that file in InputFileList. 
end  % the use of '{}' to signify array positions identifies this array as a cell array of strings.

%Here, InputFileList receives the names associated with each file in the directory that meets inclusion criteria.  (FileCounter,1) identifies a cell within InputFileList.  
% '.name' indicates that we need to add the name to InputFileList at element (FileCounter,1).  So now we have a cell array of Strings, in which all input files are listed. 
% For more information on batch processing, see: http://blogs.mathworks.com/steve/2006/06/06/batch-processing/#1

for FileCounter=1:length(files)  %this loop imports the data files one-by-one and processes the data in them into output files.   
  importDSILactateFftfile(files(FileCounter).name)%importfile is a function (stored as the file'importfile.m' that imports a DSI output text file to produce two matrices.  
  display(files(FileCounter).name) % One matrix (textdata) holds the date/time stamp.  The other (data) holds the lactate and EEG data.
  %It is a major caveat that the headers from the txt file are retained in textdata but not in data, which means that data and textdata are not aligned with respect to epoch number
  
  clear PhysioVars;
  clear SimVector;

  for TextShifter = 3:(length(textdata(:,2)))  %this loop has to start reading at the third line of the textdata array, since the first two lines are header.
    DumbChar=char(textdata(TextShifter,2));  % makes a vector of the state data, the second column of the matrix known as textdata.
    if DumbChar=='W' 
    PhysioVars(TextShifter-2,1)=0;
    elseif DumbChar=='S'
    PhysioVars(TextShifter-2,1)=1;
    elseif DumbChar=='P'
    PhysioVars(TextShifter-2,1)=2;
    elseif DumbChar=='R'
    PhysioVars(TextShifter-2,1)=2;
    else   
    PhysioVars(TextShifter-2,1)=0;
    end
    %timestamp(TextShifter-2)=char(textdata(TextShifter,1)); % makes a vector of the timestamp data, the first column of the matrix known as textdata.
  end
  
  [PctSmooth(FileCounter),LactateSmoothed]=SmootheLactate(data(1:length(data),1)); %This smoothing algorithm recodes any data point that deviates by more than 10 SD from the mean of the previous 10 data points as the mean of those data points.
  PhysioVars(:,2)=LactateSmoothed(:,2);
  PhysioVars(:,3) = sum(data(3:5))/3; % fftonly is a matrix with as many rows as there are rows in the input file, and 40 columns corresponding to the EEG1 and EEG2 ffts in 1 Hz bins.
  %PhysioVars(:,4) = sum(data(43:45))/3; % fftonly is a matrix with as many rows as there are rows in the input file, and 40 columns corresponding to the EEG1 and EEG2 ffts in 1 Hz bins.
  PhysioVars(:,4) = data(43); % fftonly is a matrix with as many rows as there are rows in the input file, and 40 columns corresponding to the EEG1 and EEG2 ffts in 1 Hz bins.
  PhysioVars(:,5) = data(44); % fftonly is a matrix with as many rows as there are rows in the input file, and 40 columns corresponding to the EEG1 and EEG2 ffts in 1 Hz bins.
  PhysioVars(:,6) = data(45); % fftonly is a matrix with as many rows as there are rows in the input file, and 40 columns corresponding to the EEG1 and EEG2 ffts in 1 Hz bins.

  [Ti,Td,LA,UA,best_error]=HomeostaticModel(PhysioVars,'delta');
  Taui(FileCounter)=Ti
  Taud(FileCounter)=Td
  %LowA(FileCounter,:)=LA;
  %UppA(FileCounter,:)=UA;
  %Error(FileCounter,:)=best_error;
  
  delete(findall(0,'Type','figure'));
  
end
    
load chirp
sound  (y)

toc