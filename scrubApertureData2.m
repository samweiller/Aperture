function cleanData = scrubApertureData2(DATA, Treport)
% DATA = readtable('fixreport4.txt','HeaderLines',0,'ReadRowNames',0,'Delimiter','\t');
% Treport = readtable('trialReport.txt','HeaderLines',0,'ReadRowNames',0,'Delimiter','\t');

%% Get info from Treport
numTrials   = max(Treport{:,2});
numSubjects = max(size(find(Treport{:, 2} == numTrials)));

k = 1;
for sub = 1:numSubjects
    for tri = 1:numTrials
        maxFixations(sub, tri) = Treport{k, 4};
        k = k + 1;
    end;
end;

numImages = 40;

%% Scrub Away! (No, I Don't Want No Scrubs.) 
encryptionKeys = [...
    32 40 22 34 35 6 3 16 11 30 33 7 38 28 17 14 8 5 29 21 25 37 31 27 26 19 15 1 36 23 2 4 18 24 39 13 9 20 10 12; ...
    15 28 29 14 5 37 20 34 38 32 22 30 11 18 36 2 1 7 40 6 16 23 27 19 39 8 13 12 24 9 21 10 3 4 33 31 25 35 26 17; ...
    19 12 11 39 32 16 35 21 25 33 27 6 23 20 1 9 40 31 18 24 13 37 4 10 17 3 26 28 29 30 8 7 14 22 36 2 34 5 15 38];

tempDecrypt{1}(1, :) = 1:numImages;
tempDecrypt{1}(2, :) = encryptionKeys(1, :);
tempDecrypt{1} = sortrows(tempDecrypt{1}', 2);
decryptionKeys(:,1) = tempDecrypt{1}(:,1);

tempDecrypt{2}(1, :) = 1:numImages;
tempDecrypt{2}(2, :) = encryptionKeys(2, :);
tempDecrypt{2} = sortrows(tempDecrypt{2}', 2);
decryptionKeys(:,2) = tempDecrypt{2}(:,1);

tempDecrypt{3}(1, :) = 1:numImages;
tempDecrypt{3}(2, :) = encryptionKeys(3, :);
tempDecrypt{3} = sortrows(tempDecrypt{3}', 2);
decryptionKeys(:,3) = tempDecrypt{3}(:,1);

decryptionKeys = decryptionKeys';

index = 1;
for subject = 1:numSubjects
    switch DATA{index, 1}{1}(6)
        case 'a'
            eCode = 1;
        case 'b'
            eCode = 2;
        case 'c'
            eCode = 3;
    end;
    
    for trial = 1:numTrials
        if strcmp(DATA{index, 12}, '.')
            isLegal = 1;
        else
            isLegal = 0;
        end;
        
        if strcmp(DATA{index + 1, 12}, '[ 1]')
            isValid = 1;
        else
            isValid = 0;
        end;
        
        if (( isLegal && isValid ))
            cleanData.subject(subject).image(decryptionKeys(eCode, trial)).validity = 'VALID';
            cleanData.subject(subject).image(decryptionKeys(eCode, trial)).fixations(1, 1) = DATA{index, 7};
            cleanData.subject(subject).image(decryptionKeys(eCode, trial)).fixations(1, 2) = DATA{index, 8};
            cleanData.subject(subject).image(decryptionKeys(eCode, trial)).fixations(2, 1) = DATA{index+1, 7};
            cleanData.subject(subject).image(decryptionKeys(eCode, trial)).fixations(2, 2) = DATA{index+1, 8};
            cleanData.subject(subject).image(decryptionKeys(eCode, trial)).fixations(3, 1) = DATA{index+2, 7};
            cleanData.subject(subject).image(decryptionKeys(eCode, trial)).fixations(3, 2) = DATA{index+2, 8};
        else
            cleanData.subject(subject).image(decryptionKeys(eCode, trial)).validity = 'INVALID';
        end;
        
        switch DATA{index, 4}{1} % Condition
            case 'FACEINVERT'
                cleanData.subject(subject).image(decryptionKeys(eCode, trial)).condition = 1;
            case 'FACEUPRIGHT'
                cleanData.subject(subject).image(decryptionKeys(eCode, trial)).condition = 2;
            case 'SCENEINVERT'
                cleanData.subject(subject).image(decryptionKeys(eCode, trial)).condition = 3;
            case 'SCENEUPRIGHT'
                cleanData.subject(subject).image(decryptionKeys(eCode, trial)).condition = 4;
        end;
        
        cleanData.subject(subject).image(decryptionKeys(eCode, trial)).imageNum = str2double(DATA{index, 6}{1}(4));
        
        switch DATA{index, 5}{1} % Position
            case 'SOUTHEAST'
                cleanData.subject(subject).image(decryptionKeys(eCode, trial)).location = 1;
            case 'CENTER'
                cleanData.subject(subject).image(decryptionKeys(eCode, trial)).location = 2;
            case 'NORTHWEST'
                cleanData.subject(subject).image(decryptionKeys(eCode, trial)).location = 3;
        end;
        
        cleanData.subject(subject).image(decryptionKeys(eCode, trial)).imName = DATA{index, 6}{1};
        
        index = index + maxFixations(subject, trial);
        
    end;
end;


%% Process Data (A scrub is a guy that can't get no love from me.)
xc = 640;
yc = 512;
AOIbox(1, :) = [xc, yc, xc+350, yc+350];
AOIbox(2, :) = [xc-175, yc-175, xc+175, yc+175];
AOIbox(3, :) = [xc-350, yc-350, xc+350, yc+350];

sub = 1;
for subCounter = 1:numSubjects
    for imageCount = 1:40
        conditionNo = cleanData.subject(subCounter).image(imageCount).condition;
        imageNo = cleanData.subject(subCounter).image(imageCount).imageNum + 1;
        position = cleanData.subject(subCounter).image(imageCount).location;
        
        if strcmp(cleanData.subject(subCounter).image(imageCount).validity, 'VALID')
            Subject(sub).condition(conditionNo).image(imageNo).location(position).fixations(1, 1) = cleanData.subject(subCounter).image(imageCount).fixations(2,1);
            Subject(sub).condition(conditionNo).image(imageNo).location(position).fixations(1, 2) = cleanData.subject(subCounter).image(imageCount).fixations(2,2);
            Subject(sub).condition(conditionNo).image(imageNo).location(position).fixations(2, 1) = cleanData.subject(subCounter).image(imageCount).fixations(3,1);
            Subject(sub).condition(conditionNo).image(imageNo).location(position).fixations(2, 2) = cleanData.subject(subCounter).image(imageCount).fixations(3,2);
            
            absoluteImageNumber = (30*(cleanData.subject(subCounter).image(imageCount).condition - 1)) + (3*(cleanData.subject(subCounter).image(imageCount).imageNum)) + cleanData.subject(subCounter).image(imageCount).location;
            DOTS{absoluteImageNumber, 1}(sub, 1) = Subject(sub).condition(conditionNo).image(imageNo).location(position).fixations(1, 1);
            DOTS{absoluteImageNumber, 1}(sub, 2) = Subject(sub).condition(conditionNo).image(imageNo).location(position).fixations(1, 2);
            DOTS{absoluteImageNumber, 2}(sub, 1) = Subject(sub).condition(conditionNo).image(imageNo).location(position).fixations(2, 1);
            DOTS{absoluteImageNumber, 2}(sub, 2) = Subject(sub).condition(conditionNo).image(imageNo).location(position).fixations(2, 2);
            %             Subject(sub).DATAMAT(image, 9) = pdist([Subject(sub).DATAMAT(image, 4) Subject(sub).DATAMAT(image, 5); Subject(sub).DATAMAT(image, 7) Subject(sub).DATAMAT(image, 8)]);
        else
            Subject(sub).condition(conditionNo).image(imageNo).location(position).fixations(1:2, 1:2) = -1;
        end;
    end;
    
    %     fileName = sprintf('Aperture_Subject%02d_Data.csv', sub);
    %     csvwrite(fileName, Subject(sub).DATAMAT);
    if mod(subCounter, 3) == 0
        sub = sub + 1;
    end;
end;

%% Distance (Hanging on the passenger side of hs best friend's ride...)
i = 1;
for outSub = 1:numSubjects/3
    for outCon = 1:4
        for outIm = 1:10
            outMatrix(i, 1) = outSub;
            outMatrix(i, 2) = outCon;
            outMatrix(i, 3) = outIm;
            outMatrix(i, 4) = Subject(outSub).condition(outCon).image(outIm).location(1).fixations(2, 1);
            outMatrix(i, 5) = Subject(outSub).condition(outCon).image(outIm).location(1).fixations(2, 2);
            outMatrix(i, 6) = Subject(outSub).condition(outCon).image(outIm).location(2).fixations(2, 1);
            outMatrix(i, 7) = Subject(outSub).condition(outCon).image(outIm).location(2).fixations(2, 2);
            outMatrix(i, 8) = Subject(outSub).condition(outCon).image(outIm).location(3).fixations(2, 1);
            outMatrix(i, 9) = Subject(outSub).condition(outCon).image(outIm).location(3).fixations(2, 2);
            outMatrix(i, 10) = pdist([outMatrix(i, 4) outMatrix(i, 5); outMatrix(i, 6) outMatrix(i, 7)]);
            outMatrix(i, 11) = pdist([outMatrix(i, 8) outMatrix(i, 9); outMatrix(i, 6) outMatrix(i, 7)]);
            outMatrix(i, 12) = pdist([outMatrix(i, 4) outMatrix(i, 5); 780 652]);
            outMatrix(i, 13) = pdist([outMatrix(i, 4) outMatrix(i, 5); 640 512]);
            outMatrix(i, 14) = pdist([outMatrix(i, 6) outMatrix(i, 7); 640 512]);
            outMatrix(i, 15) = pdist([outMatrix(i, 6) outMatrix(i, 7); 640 512]);
            outMatrix(i, 16) = pdist([outMatrix(i, 8) outMatrix(i, 9); 500 372]);
            outMatrix(i, 17) = pdist([outMatrix(i, 8) outMatrix(i, 9); 640 512]);
            
            i = i + 1;
        end;
    end;
end;

dlmwrite('apertureNumberData.csv', outMatrix);

%% Images (Trying to holler at me)
targetIm = 2;

[zz1 zz2] = unix('ls ~/Documents/ApertureData/imagesAbs/*.png | tee filenames.txt');
fileIO = fopen('filenames.txt');
names = textscan(fileIO, '%s');
fclose(fileIO);
for anaIm = 1:120
%     fileName = sprintf('Image%02d_DOTS.csv', anaIm);
%     csvwrite(fileName, DOTS{anaIm, 2});
    
    figHolder = imread(sprintf('%s', names{1}{anaIm}));
    image(figHolder);
    hold on;
    
    plot(640, 512, 'r.', 'MarkerSize', 20);
    
    switch mod(anaIm, 3)
        case 1 % loc A
            if anaIm <= 30
                plot(780, 372, 'r.', 'MarkerSize', 20);
            elseif (( anaIm >= 31 && anaIm <= 60 ))
                plot(780, 652, 'r.', 'MarkerSize', 20);
            elseif (( anaIm >= 61 && anaIm <= 90 ))
                plot(780, 372, 'r.', 'MarkerSize', 20);
            elseif (( anaIm >= 91 && anaIm <= 120 ))
                plot(780, 652, 'r.', 'MarkerSize', 20);
            end;
            
        case 0 % loc C
            if anaIm <= 30
                plot(500, 652, 'r.', 'MarkerSize', 20);
            elseif (( anaIm >= 31 && anaIm <= 60 ))
                plot(500, 372, 'r.', 'MarkerSize', 20);
            elseif (( anaIm >= 61 && anaIm <= 90 ))
                plot(500, 652, 'r.', 'MarkerSize', 20);
            elseif (( anaIm >= 91 && anaIm <= 120 ))
                plot(500, 372, 'r.', 'MarkerSize', 20);
            end;
    end;
    
    for j = 1:size(DOTS{anaIm},1)
%         plot(DOTS{anaIm, 1}(j, 1), DOTS{anaIm, 1}(j, 2), 'b.', 'MarkerSize', 20); % 1st fix
        plot(DOTS{anaIm, 2}(j, 1), DOTS{anaIm, 2}(j, 2), 'g.', 'MarkerSize', 20); % 2nd fix
    end;
    
    print(1, '-dpng', sprintf('~/Documents/ApertureData/OUTPUTIMAGES/image%02d.png', anaIm));
    hold off;
    close(1);
    
%     if anaIm == targetIm
%         image(figHolder);
%         hold on;
%         
%         plot(640, 512, 'r.', 'MarkerSize', 20);
%         
%         for j = 1:size(DOTS{anaIm-1}, 1)
%             plot(DOTS{anaIm-1, 2}(j, 1), DOTS{anaIm-1, 2}(j, 2), 'b.', 'MarkerSize', 20);
%         end;
%         
%         for j = 1:size(DOTS{anaIm}, 1)
%             plot(DOTS{anaIm, 2}(j, 1), DOTS{anaIm, 2}(j, 2), 'g.', 'MarkerSize', 20);
%         end;
%         
%         for j = 1:size(DOTS{anaIm+1}, 1)
%             plot(DOTS{anaIm+1, 2}(j, 1), DOTS{anaIm+1, 2}(j, 2), 'y.', 'MarkerSize', 20);
%         end;
%         
%         print(1, '-dpng', sprintf('image%02d_full.png', anaIm));
%         hold off;
%         close(1);
%         targetIm = targetIm + 3;
%     end;
end;

























