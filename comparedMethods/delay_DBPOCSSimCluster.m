function delay_DBPOCSSimCluster(input_argument)
%M. R. Gholami, H. Wymeersch, E. G. Strom, and M. Rydstr � om, �Wireless network positioning as a convex feasibility �
%problem,� EURASIP Journal on Wireless Communications and Networking, vol. 2011, no. 1, p. 161, 2011
if(ischar(input_argument))
    input_argument = str2double(input_argument);
end

switch input_argument
    case 1
        std = 0;
        noAnt = 5;
    case 2
        std = 0;
        noAnt = 3;
    case 3
        std = 10;
        noAnt = 5;
    case 4
        std = 10;
        noAnt = 3;
    case 5
        std = 20;
        noAnt = 5;
    case 6
        std =20;
        noAnt = 3;
end

pathDataset = strcat(pwd,'/dataset');
pathResults = strcat(pwd,'/ToAResults');
pathResultsMAT = pathResults;

simName = 'POCS';
logName = strcat(pathResults,'/POCS_Std',int2str(std),'_BS',int2str(noAnt),'.txt');

fileID = fopen(logName,'a');
fprintf(fileID, 'POCS\n');
fclose(fileID);

noMaps = 99;
noRx = 200;
noTrials=50;

shuffledIndices = [62 40 95 18 97 84 64 42 10  0 31 76 47 26 44  4 22 12 88 73 49 70 68 15 ...
    39 33  9 81 11 65 94 30 28 89  5 45 69 35 16 72 34  7 55 27 19 80 25 53 ...
    13 24  3 17 38  8 77  6 79 36 91 56 98 54 43 50 66 46 67 61 96 78 41 58 ...
    48 85 57 75 32 93 59 63 83 37 29  1 52 21  2 23 87 90 74 86 82 20 60 71 ...
    14 92 51];
shuffledIndices = shuffledIndices + 1;
mapTra = shuffledIndices(1:84);
noMapTra = 84;
mapTest = shuffledIndices(85:99);
noMapTest = 15;

load(strcat(pathDataset,'/TxRx'),'rxx','rxy','antX','antY','antList')
load(strcat(pathDataset,'/LocDBDelay'),'matDelayLocReshaped')%loads matDelayLocReshaped, 256,256,99,80


p = gcp; %get parallel pool for parallel computing in CPU
Workers=2*p.NumWorkers; %number of workers is twice the number of CPU cores


difTra = zeros(noTrials,noMapTra,noRx);
difTest = zeros(noTrials,noMapTest,noRx);

tic
for tt=1:noTrials
    
    for mm=1:noMapTest
        shuffledM = mapTest(mm);
        parfor (rx=1:noRx, Workers)
            difTest(tt,mm,rx) = delay_DBPOCSFunCluster(shuffledM,squeeze(antList(tt,shuffledM,:)),squeeze(antX(tt,:,shuffledM)),squeeze(antY(tt,:,shuffledM)),squeeze(rxx(shuffledM,rx)),squeeze(rxy(shuffledM,rx)),squeeze(matDelayLocReshaped(:,:,shuffledM,:)),std,noAnt);
        end   
    end
    toc
    save(strcat(pathResultsMAT,simName,'Test'),'difTest')
end

MAETestAll =difTest;
MAETestFlat = MAETestAll(:);
difAllNaNs = find(isnan(MAETestFlat));
difAllNoNaNs = MAETestFlat;
difAllNoNaNs(difAllNaNs) = [];
%mae
MAETest= sum(difAllNoNaNs)/numel(difAllNoNaNs);

a=sprintf('%.2f',MAETest);

%rmse
VarTest = sum(difAllNoNaNs.^2)/numel(difAllNoNaNs);
RMSETest = sqrt(VarTest);

r=sprintf('%.2f',RMSETest);
fileID = fopen(logName,'a');
fprintf(fileID, strcat('Test MAE: = ',a,', ','RMSE: = ',r ,'\n'));
fclose(fileID);

tic
for tt=1:noTrials

    for mm=1:noMapTra

        shuffledM = mapTra(mm);
        parfor (rx=1:noRx, Workers)

            difTra(tt,mm,rx) = delay_DBPOCSFunCluster(shuffledM,squeeze(antList(tt,shuffledM,:)),squeeze(antX(tt,:,shuffledM)),squeeze(antY(tt,:,shuffledM)),squeeze(rxx(shuffledM,rx)),squeeze(rxy(shuffledM,rx)),squeeze(matDelayLocReshaped(:,:,shuffledM,:)),std,noAnt);
            
        end       
    end
    toc
    save(strcat(pathResultsMAT,simName,'Tra'),'difTra')
end

MAETraAll =difTra;
MAETraFlat = MAETraAll(:);
difAllNaNs = find(isnan(MAETraFlat));
difAllNoNaNs = MAETraFlat;
difAllNoNaNs(difAllNaNs) = [];
%mae
MAETra= sum(difAllNoNaNs)/numel(difAllNoNaNs);

a=sprintf('%.2f',MAETra);

%rmse
VarTra = sum(difAllNoNaNs.^2)/numel(difAllNoNaNs);
RMSETra = sqrt(VarTra);

r=sprintf('%.2f',RMSETra);

fileID = fopen(logName,'a');
fprintf(fileID, strcat('Tra MAE: = ',a,', ','RMSE: = ',r ,'\n'));
fclose(fileID);

