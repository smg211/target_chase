% Clear the workspace and the screen
sca;
close all;
clear;

% Set the target positions
target_positions = [900 550; 1300 300; 500 950; 1300 500; 500 550];
target_radius = 200;
target_index = 1;

% Here we call some default settings for setting up Psychtoolbox
PsychDefaultSetup(2);

% Get the screen numbers
screens = Screen('Screens');

% Draw to the external screen if avaliable
screenNumber = max(screens);

% Define black and white
white = WhiteIndex(screenNumber);
black = BlackIndex(screenNumber);

% Open an on screen window
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, black);

% Get the size of the on screen window
[screenXpixels, screenYpixels] = Screen('WindowSize', window);

% Query the frame duration
ifi = Screen('GetFlipInterval', window);

% Get the centre coordinate of the window
[xCenter, yCenter] = RectCenter(windowRect);

% Make a base Rect of 200 by 200 pixels
baseRect = [0 0 target_radius target_radius];

% For Ovals we set a miximum diameter up to which it is perfect for
maxDiameter = max(baseRect) * 1.01;

% Set the color of the rect to red
rectColor = [1 0 0];

% Set the intial position of the square to be in the centre of the screen
squareX = xCenter;
squareY = yCenter;

% Set the amount we want our square to move on each button press
pixelsPerPress = 10;

% Sync us and get a time stamp
vbl = Screen('Flip', window);
waitframes = 1;

% Maximum priority level
topPriorityLevel = MaxPriority(window);
Priority(topPriorityLevel);

% Loop the animation until any key is pressed
while ~KbCheck
  % Get the position of the mouse
  [x, y, buttons] = GetMouse(screenNumber);

  % if there is a click, see if it happens in the target area
  if buttons(1)
    [flag, d] = check_if_click_in_targ([x, y], target_positions(target_index, :), target_radius);
    if flag
      %         fprintf([num2str(d) ' pixelss from target ' num2str(target_index) ' --> switch\n']);
      target_index = target_index + 1;
      if target_index == size(target_positions, 1) + 1
        target_index = 1;
      end
    end
  end

  % Center the rectangle on the centre of the screen
  centeredRect = CenterRectOnPointd(baseRect, ...
    target_positions(target_index, 1), target_positions(target_index, 2));

  % Draw the rect to the screen
  Screen('FillOval', window, rectColor, centeredRect, maxDiameter);

  % Flip to the screen
  vbl  = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
end

% Clear the screen
sca;



%% SUBFUNCTIONS
function [flag, d] = check_if_click_in_targ(mouse_pos, targ_pos, targ_rad)
%   fprintf([num2str(sqrt(sum((mouse_pos-targ_pos).^2))) '\n'])
d = sqrt(sum((mouse_pos-targ_pos).^2));
flag = d <= targ_rad;
end

