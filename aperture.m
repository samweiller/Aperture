% Eye Tracking Image Presentation
function aperture(sub, pCode, eCode)
%% Start Me Up
clc
APTR.curDir = cd;
if isempty(sub); APTR.subID = input('\nPlease Enter Your Participant Code #: ', 's'); else APTR.subID = sub; end;
if isempty(eCode); APTR.run =  input('\nPlease Enter The Run #: ', 's'); else  APTR.run = eCode; end;
APTR.pCode = pCode;
PATH = fullfile(APTR.curDir, sprintf('APTR_S%d_P%d_C%d.mat', APTR.subID, APTR.pCode, APTR.run));
save(PATH);
if ~exist(PATH);
    [Path, File] = uigetfile('*.mat', 'Select .MAT with APTR');
    PATH = fullfile(Path, File);
end
load(PATH);

pause(.2)
disp('Aperture')
pause(.2)
disp('  Version 1.00')
disp('  Apr. 23, 2014')
pause(.2)
disp('Script Written by Sam Weiller')
pause(1)
clc

%% Control Panel
EyelinkInit;

fprintf('Looking for stimuli...\n')
if exist('apertureStims.mat')
    load apertureStims.mat
    fprintf('Stimuli loaded!\n');
else
    disp('Please run makeStims first.');
    return;
end;

stimSize = 700;
numStimSets = size(STIMS,2);
imgsPerSet = size(STIMS{1},2);
numTrials = 15;
KbName('UnifyKeyNames');
screens = Screen('Screens');
screenNumber = min(screens);
numPositions = 3;
screenWidth = 412.75;
viewingDistance = 920.75;
visualAngle = 8;
presentationTime = 8;

% imDex = [...
%     1 1; 1 2; 1 3; 1 4; 1 5; ...
%     2 1; 2 2; 2 3; 2 4; 2 5; ...
%     3 1; 3 2; 3 3; 3 4; 3 5; ...
%     4 1; 4 2; 4 3; 4 4; 4 5; ...
%     5 1; 5 2; 5 3; 5 4; 5 5];
% 
% encryptionKeys = [...
%     24 17 16 21 2 3 11 25 1 6 14 23 5 18 9 15 22 8 4 13 12 19 7 10 20; ...
%     23 19 12 21 15 1 5 13 7 3 20 11 4 17 6 8 9 10 24 2 25 16 14 22 18; ...
%     21 2 23 11 15 10 8 24 22 25 4 9 18 3 20 6 19 14 13 17 5 16 1 12 7; ...
%     15 1 11 9 7 21 12 19 20 5 18 22 23 6 13 4 2 10 3 8 17 14 25 24 16]';
% 
% crossMat = [...
%     1,2,3,4;2,3,4,1;3,4,1,2;4,1,2,3;1,2,3,4;2,3,4,1;3,4,1,2;4,1,2,3; ...
%     1,2,3,4;2,3,4,1;3,4,1,2;4,1,2,3;1,2,3,4;2,3,4,1;3,4,1,2;4,1,2,3; ...
%     1,2,3,4;2,3,4,1;3,4,1,2;4,1,2,3;1,2,3,4;2,3,4,1;3,4,1,2;4,1,2,3;1,2,3,4];


imDex = [...
    1 1; 1 2; 1 3; 1 4; 1 5; ...
    2 1; 2 2; 2 3; 2 4; 2 5; ...
    3 1; 3 2; 3 3; 3 4; 3 5];

encryptionKeys = [...
    6 3 11 7 14 8 5 15 1 2 4 13 9 10 12; ...
    7 1 15 13 2 14 6 10 12 11 4 8 3 9 5; ...
    2 10 4 5 15 3 8 12 11 7 1 13 14 6 9];

encryptionKeys = encryptionKeys';

crossMat = [...
    1 2; 2 1; 1 2; 2 1; 1 2; 2 1; 1 2; 2 1; ...
    1 2; 2 1; 1 2; 2 1; 1 2; 2 1; 1 2];

positMat = [...
    1 2 3;
    2 3 1;
    3 1 2;
    1 2 3;
    2 3 1;
    3 1 2;
    1 2 3;
    2 3 1;
    3 1 2;
    1 2 3;
    2 3 1;
    3 1 2;
    1 2 3;
    2 3 1;
    3 1 2];

fixBox(1).loc = [1000 0 1280 160];
fixBox(3).loc = [0 0 280 160];
fixBox(2).loc = [0 864 280 1024];
fixBox(4).loc = [1000 864 1280 1024];
fixBox(5).loc = [860 605 1060 805];

UserAns = 0;
touch = 0;

res = Screen('Resolution', screenNumber);
resWidth = res.width;

% PPD = tand(.5).*2.*viewingDistance.*(resWidth./screenWidth);
% visualAngle = PPD*visualAngle;
% stimSize = visualAngle;

%% Eyelink Parameters
ET = 1;
pref_eye = 1; % 0 is left, 1 is right, 2 is both
dummymode = 1;

prompt = {'Enter tracker EDF file name (1 to 8 letters or numbers)'};
dlg_title = 'Create EDF File';
num_lines = 1;
def = {'DEMO'};
answer = inputdlg(prompt, dlg_title, num_lines, def);
edfFile = answer{1};
fprintf('EDFFile: %s\n', edfFile);

%% Initialization & Calibration

[w rect xc yc] = startPTB(1, [128 128 128]);

HideCursor;

% % This is a sanity check for the fixation zones. It can be removed.
% for h = 1:5
%     Screen('FillRect', w, [0 0 0], [fixBox(h).loc]);
% end;
% Screen('Flip', w)
% KbWait(-1);
% 

el = EyelinkInitDefaults(w);

if ~EyelinkInit(dummymode)
    fprintf('Eyelink Init Aborted.\n');
    Eyelink('Shutdown');
    return;
end;

[v, vs] = Eyelink('GetTrackerVersion');
fprintf('Running Experiment on a "%s" tracker.\n', vs);


i = Eyelink('Openfile', edfFile);

if i ~=0
    fprintf('Cannot create EDF file "%s"', edffilename);
    Eyelink('Shutdown');
    return;
end;

Eyelink('command', 'add_file_preamble_text "Recorded by EyelinkToolbox. Script by SKW"');

[width, height] = Screen('WindowSize', w);

Eyelink('command', 'screen_pixel_coords = %ld %ld %ld %ld', 0, 0, width-1, height-1);
Eyelink('message', 'DISPLAY_COORDS %ld %ld %ld %ld', 0, 0, width-1, height-1);

Eyelink('command', 'calibration_type = HV9');
Eyelink('command', 'saccade_velocity_threshold = 35');
Eyelink('command', 'saccade_acceleration_threshold = 9500');

Eyelink('command', 'file_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON');
Eyelink('command', 'file_sample_data = LEFT,RIGHT,GAZE,HREF,AREA,GAZERES,STATUS');
Eyelink('command', 'link_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON');
Eyelink('command', 'link_sample_data = LEFT,RIGHT,GAZE,GAZERES,AREA,STATUS');

if ( Eyelink('IsConnected') ~= 1 && ~dummymode )
    Eyelink('Shutdown');
    return;
end;

el.backgroundcolour = [128 128 128];
el.foregroundcolour = [0 0 0];

EyelinkDoTrackerSetup(el);

%% Create Stims & Experimental Parameters
for set = 1:numStimSets
    for img = 1:imgsPerSet
        for posit = 1:numPositions
            tex{set}{img}{posit} = Screen('MakeTexture', w, STIMS{set}{img}{posit});
        end;
    end;
end;

TRIMAT(:,1) = imDex(:,1);
TRIMAT(:,2) = imDex(:,2);
TRIMAT(:,3) = positMat(:, pCode);
TRIMAT(:,4) = crossMat(:, eCode);
TRIMAT(:,5) = 1:15;
TRIMAT(:,6) = encryptionKeys(:, pCode);
TRIMAT = sortrows(TRIMAT, 6);

%% Orientation
%  Explain task here. No need to have an orientation screen or fixation.
%  Maybe Drift correct?

%  Without the Orientation text, maybe remove CH? Just <<Press Any Key>>
[hC,vC] = createCrossAtLocation(5);
Screen('FillRect', w, [255 255 255], hC);
Screen('FillRect', w, [255 255 255], vC);
Screen('Flip', w);
KbWait(-1);

%% Main Loop
Eyelink('Command', 'set_idle_mode');
WaitSecs(0.05);

Eyelink('Command', 'clear_screen 0')

Eyelink('StartRecording');
WaitSecs(0.1);

for trial = 1:numTrials
    Eyelink('message', 'TRIALID %d', trial);
    Eyelink('message', '!V CLEAR 128 128 128')
    
    % Draw Cross in correct location
    [hC, vC] = createCrossAtLocation(TRIMAT(trial, 4));
    Screen('FillRect', w, [255 255 255], hC);
    Screen('FillRect', w, [255 255 255], vC);
    Screen('Flip', w);
    Eyelink('message', 'FIX AT LOCATION %d', TRIMAT(trial, 3));
    Eyelink('message', '!V DRAWBOX 0 0 0 %d %d %d %d', hC(1), vC(2), hC(3), vC(4));
    Eyelink('message', '!V IAREA RECTANGLE 1 %d %d %d %d FIXATION', fixBox(TRIMAT(trial, 4)).loc(1), fixBox(TRIMAT(trial, 4)).loc(2), fixBox(TRIMAT(trial, 4)).loc(3), fixBox(TRIMAT(trial, 4)).loc(4));
    
    Eyelink('command', 'record_status_message "TRIAL %d / %d"', trial, numTrials);    
    WaitSecs(0.05);
    
    eye_used = pref_eye;
    
    Eyelink('message', 'Waiting For Fixation');
    
    quitflag = 0;
    while ~quitflag
        tic;
        while toc < 1
            if Eyelink('NewFloatSampleAvailable') > 0 %if not in dummy mode
                sample = Eyelink('NewestFloatSample');
            else
                [x, y] = GetMouse(w);
                sample.gx = x;
                sample.gy = y;
            end;
            
            if size(sample.gx, 2) == 1
                if ~IsInRect(sample.gx(1), sample.gy(1), fixBox(TRIMAT(trial, 4)).loc)
                    break;
                end;
            else
                if eye_used < 2
                    if ~IsInRect(sample.gx(eye_used+1), sample.gy(eye_used+1), fixBox(TRIMAT(trial, 4)).loc)
                        break;
                    end;
                else
                    if ~IsInRect(sample.gx(1), sample.gy(1), fixBox(TRIMAT(trial, 4)).loc) && ~IsInRect(sample.gx(2), sample.gy(2), fixBox(TRIMAT(trial, 4)).loc)
                        break;
                    end;
                end;
            end;
            
            if toc > 0.8
                quitflag = 1;
            end;
            
            WaitSecs(.02);
        end;
    
    end;
    WaitSecs(.02)
    Eyelink('message', 'Successful Fixation');
    WaitSecs(.1)
    Eyelink('message', 'Starting Image Presentation');
    
    Screen('DrawTexture', w, tex{TRIMAT(trial, 1)}{TRIMAT(trial, 2)}{TRIMAT(trial, 3)}, [], [xc-(stimSize/2) yc-(stimSize/2) xc+(stimSize/2) yc+(stimSize/2)]);
    Screen('Flip', w);
    
    Eyelink('message', '!V CLEAR 128 128 128')
    Eyelink('Message', '!V IMGLOAD CENTER ../images/%s %d %d %d %d', STIMNAMES{TRIMAT(trial, 1)}{TRIMAT(trial, 2)}{TRIMAT(trial, 3)}, round(width/2), round(height/2), stimSize, stimSize);

    tic;
    sIndex = 1;
    while toc < presentationTime
        if Eyelink('NewFloatSampleAvailable') > 0 %if not in dummy mode
            sample = Eyelink('NewestFloatSample');
        else
            [x, y] = GetMouse(w);
            sample.gx = x;
            sample.gy = y;
        end;
        save(PATH,'sample');
%         SAMPLES.trial(trial).x(sIndex, :) = sample.gx;
%         SAMPLES.trial(trial).y(sIndex, :) = sample.gy;
%         sIndex = sIndex + 1;
    end;
    
    Screen('Flip', w);
    save(PATH);
    
    Eyelink('message', '!V TRIAL_VAR IMG_NAME %s', STIMNAMES{TRIMAT(trial, 1)}{TRIMAT(trial, 2)}{TRIMAT(trial, 3)});
    % ^^ Should this just be IMAGE_NAME?
    
    switch TRIMAT(trial, 1)
        case 1
            Eyelink('message', '!V TRIAL_VAR CONDITION FACE');
        case 2
            Eyelink('message', '!V TRIAL_VAR CONDITION INDOOR');
        case 3
            Eyelink('message', '!V TRIAL_VAR CONDITION OUTDOOR');
    end;
    
    switch TRIMAT(trial, 3)
        case 1
            Eyelink('message', '!V TRIAL_VAR POSITION SOUTHEAST');
        case 2
            Eyelink('message', '!V TRIAL_VAR POSITION CENTER');
        case 3
            Eyelink('message', '!V TRIAL_VAR POSITION NORTHWEST');
    end;
    
    switch TRIMAT(trial, 4)
        case 1
            Eyelink('message', '!V TRIAL_VAR CROSSLOC NORTHEAST');
        case 2
            Eyelink('message', '!V TRIAL_VAR CROSSLOC SOUTHWEST');
    end;
        
    Eyelink('message', '!V IAREA RECTANGLE 2 %d %d %d %d IMAGE', width/2-(round(stimSize/2)), height/2-(round(stimSize/2)), width/2+(round(stimSize/2)), height/2+(round(stimSize/2)));
    Eyelink('message', '!V IAREA RECTANGLE 3 %d %d %d %d QUAD1', width/2, height/2-(round(stimSize/2)), width/2+(round(stimSize/2)), height/2);
    Eyelink('message', '!V IAREA RECTANGLE 4 %d %d %d %d QUAD2', width/2-(round(stimSize/2)), height/2-(round(stimSize/2)), width/2, height/2);
    Eyelink('message', '!V IAREA RECTANGLE 5 %d %d %d %d QUAD3', width/2-(round(stimSize/2)), height/2, width/2, height/2+(round(stimSize/2)));
    Eyelink('message', '!V IAREA RECTANGLE 6 %d %d %d %d QUAD4', width/2, height/2, width/2+(round(stimSize/2)), height/2+(round(stimSize/2)));
    Eyelink('message', '!V IAREA RECTANGLE 6 %d %d %d %d QUADC', (width/2)-(round(stimSize/4)), (height/2)-(round(stimSize/4)), (width/2)+(round(stimSize/4)), (height/2)+(round(stimSize/4)));
    
    Eyelink('message', 'TRIAL_RESULT 0');
end;
Screen('CloseAll');

save(PATH, 'APTR' );
Eyelink('Command', 'set_idle_mode');
WaitSecs(0.5);
Eyelink('CloseFile');

% download data file
try
    fprintf('Receiving data file ''%s''\n', edfFile );
    status=Eyelink('ReceiveFile');
    if status > 0
        fprintf('ReceiveFile status %d\n', status);
    end
    if 2==exist(edfFile, 'file')
        fprintf('Data file ''%s'' can be found in ''%s''\n', edfFile, pwd );
    end
catch
    fprintf('Problem receiving data file ''%s''\n', edfFile );
end

Eyelink('Shutdown');

function [hCoords, vCoords] = createCrossAtLocation(cLoc)
switch cLoc
    case 1
        cx = 1140;
        cy = 80;
    case 3
        cx = 140;
        cy = 80;
    case 2
        cx = 140;
        cy = 944;
    case 4
        cx = 1140;
        cy = 944;
    case 5
        cx = 960;
        cy = 705;
end;

hCoords = [cx-13, cy-3, cx+13, cy+3];
vCoords = [cx-3, cy-13, cx+3, cy+13];

function [w rect xc yc] = startPTB(oGl, color)

if nargin == 0
    oGl = 0;
    color = [0 0 0];
elseif nargin == 1;
    color = [0 0 0];
end;

Screen('Preference', 'SkipSyncTests', 2);
screens = Screen('Screens');
screenNumber = min(screens);
[w rect] = Screen('OpenWindow', screenNumber, color);
xc = rect(3)/2; yc = rect(4)/2;

if oGl == 1
    AssertOpenGL;
    Screen('BlendFunction', w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA, [1 1 1 1]);
end;