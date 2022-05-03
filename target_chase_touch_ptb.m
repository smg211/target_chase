% Clear the workspace and the screen
sca;
close all;
clear;

Screen('Preference', 'ConserveVRAM', 4096);

%% GET SYSTEM AND DISPLAY INFORMATION
% system, user, and path saving
cwd = pwd;
if ispc
  if any(strfind(cwd, 'sando'))
    user = 'sando';
    last_param_path = 'C:\Users\sando\Documents\';
    data_path = 'C:\Users\sando\Documents\target_chase\';
  end
end

if ~exist(data_path)
  data_path = pwd;
end

% Here we call some default settings for setting up Psychtoolbox
PsychDefaultSetup(2);

% If no user-specified 'dev' was given, try to auto-select:
dev = [];
if isempty(dev)
  % Get first touchscreen:
  dev = min(GetTouchDeviceIndices([], 1));
end

if isempty(dev)
  % Get first touchpad:
  dev = min(GetTouchDeviceIndices([], 0));
end

if isempty(dev) || ~ismember(dev, GetTouchDeviceIndices)
  fprintf('No touch input device found, or invalid dev given. Using mouse instead.\n');
  input_mode = 'mouse';
else
  fprintf('Touch device properties:\n');
  input_mode = 'touch';
  info = GetTouchDeviceInfo(dev);
  disp(info);
end

% Get the screen numbers
screens = Screen('Screens');

% Draw to the external screen if avaliable
screenId = max(screens);

% Get the screen size and resolution
[width_mm, height_mm] = Screen('DisplaySize', screenId);
res = Screen('Resolution', screenId);
% pix_per_cm = round(10*min([res.width/width_mm res.height/height_mm]));

% Define black and white
white = WhiteIndex(screenId);
black = BlackIndex(screenId);

% Open an on screen window
[w, rect] = PsychImaging('OpenWindow', screenId, black);
baseSize = RectWidth(rect) / 20;

% Query the frame duration
ifi = Screen('GetFlipInterval', w);
ifi = 1/120;

% Sync us and get a time stamp
vbl = Screen('Flip', w);
waitframes = 1;

% Maximum priority level
topPriorityLevel = MaxPriority(w);
Priority(topPriorityLevel);

%% DRAW THE SETTINGS SCREEN
% load previous settings if they exist
if exist([last_param_path 'most_recent_target_chase_params.mat'])
  load([last_param_path 'most_recent_target_chase_params.mat']);
  params_prev = params;
else
  params = [];
end

% load the screen parameters
load('param_screen.mat');
n_params = length(param_info);
i_params_shown = find(~[param_info.is_hidden]);
n_params_shown = length(i_params_shown);
max_opts = max([param_info.Nopts]);
for p = 1:n_params
  if ~isfield(params, param_info(p).varname)
    params.(param_info(p).varname) = [];
  end
end

n_rows = (n_params_shown+2);
row_height = res.height/n_rows;
row_edges = 0:row_height:res.height;
row_centers = (row_height/2):row_height:res.height;

try
  % Make the background color behind each parameter (row) alternate between
  % dark blue and black
  row_bg_col = repmat([0 0 0.3; 0 0 0], ceil(n_rows/2), 1);
  row_bg_col = row_bg_col(1:n_rows, :);
  row_bg_rect = [zeros(1, n_rows); ...
    row_edges(1:end-1); repmat(res.width, 1, n_rows); row_edges(2:end)];
  Screen('FillRect', w, row_bg_col', row_bg_rect);

  % Draw the welcome text
  Screen('TextSize', w, 0.9*row_height); % make the welcome line really big
  DrawFormattedText(w, 'WELCOME! MAKE A SELECTION IN EACH ROW', ...
    'center', 'center', [1 1 1], [], 0, 0, 1, 0, row_bg_rect(:, 1)');

  % List all of the param titles on the left side of the screen, right
  % justified
  title_x = 0.2*res.width;
  title_rect = [row_bg_rect(1:2, :); repmat(title_x, 1, n_rows); row_bg_rect(4, :)];
  Screen('TextSize', w, 0.75*row_height); % make the titles medium sized
  for p = 1:n_params_shown
    DrawFormattedText(w, param_info(i_params_shown(p)).title, ...
      'right', 'center', [1 1 0], [], 0, 0, 1, 0, title_rect(:, p+1)');
  end

  % With the remaining right half of the screen, make a n_row x 10 grid and
  % fill the options into each point on the grid. If there are more than 10
  % options, then space the options evenly
  Screen('TextSize', w, 0.4*row_height); % make the options small sized
  opt_chosen = zeros(1, n_params_shown);
  opts_rect = nan(n_params_shown, max_opts, 4);
  for p = 1:n_params_shown
    if param_info(i_params_shown(p)).Nopts <= 10
      n_win = 10;
    else
      n_win = param_info(i_params_shown(p)).Nopts;
    end
    opts_edges = linspace(title_x, res.width, n_win+2);
    opts_win_width = mode(diff(opts_edges));
    opts_edges = opts_edges-opts_win_width/2;

    opts_rect(p, 1:param_info(i_params_shown(p)).Nopts, :) = ...
      [opts_edges(2:param_info(i_params_shown(p)).Nopts+1); ...
      repmat(row_edges(p+1), 1, param_info(i_params_shown(p)).Nopts); ...
      opts_edges(3:param_info(i_params_shown(p)).Nopts+2); ...
      repmat(row_edges(p+2), 1, param_info(i_params_shown(p)).Nopts)]';
    for i = 1:param_info(i_params_shown(p)).Nopts
      DrawFormattedText(w, param_info(i_params_shown(p)).opts_title{i}, ...
        'center', 'center', [1 1 1], [], 0, 0, 1, 0, squeeze(opts_rect(p, i, :))');

      % highlight this option if it is the same as the last option that was
      % used
      if ~isempty(params) && ~isempty(params.(param_info(i_params_shown(p)).varname)) && ...
          (isstr(param_info(i_params_shown(p)).opts_varname{i}) && ...
          strcmp(params.(param_info(i_params_shown(p)).varname), param_info(i_params_shown(p)).opts_varname{i}) ...
          || (isnumeric(param_info(i_params_shown(p)).opts_varname{i}) && ...
          params.(param_info(i_params_shown(p)).varname) == param_info(i_params_shown(p)).opts_varname{i}) ...
          || (islogical(param_info(i_params_shown(p)).opts_varname{i}) && ...
          params.(param_info(i_params_shown(p)).varname) == param_info(i_params_shown(p)).opts_varname{i}))
        opt_chosen(p) = i;
        Screen('FrameRect', w, [1 0 0], squeeze(opts_rect(p, i, :)), 4);
      end
    end
  end

  % Draw the play button
  Screen('FillRect', w, [0.5 0.5 0.5], row_bg_rect(:, end)');
  Screen('TextSize', w, 0.9*row_height); % make the play text really big
  DrawFormattedText(w, 'PLAY TARGET CHASE', ...
    'center', 'center', [1 1 1], [], 0, 0, 1, 0, row_bg_rect(:, end)');

  Screen('Flip', w, 0, 1);

  %   KbStrokeWait; % sca;
catch
  sca;
  psychrethrow(psychlasterror);
end

%% INTERACT WITH THE SETTINGS SCREEN
t_param_selected = zeros(1, n_params);
try
  if strcmp(input_mode, 'touch')
    initialize_touch(dev, w);
  end

  % initialize struct for tracking active touch points:
  curs_active = {};
  curs_id_min = inf;

  % Only ESCape allows to exit the game:
  RestrictKeysForKbCheck(KbName('ESCAPE'));

  % Loop the animation until the escape key is pressed or the play button
  % is pressed
  play_pressed = false;

  while ~KbCheck && ~play_pressed
    if strcmp(input_mode, 'touch')
      [curs_active, curs_id_min] = process_touch_events(dev, w, baseSize, curs_active, curs_id_min);

    elseif strcmp(input_mode, 'mouse')
      % Get the position of the mouse
      [x, y, buttons] = GetMouse(screenId);

      % if there is a click, see if it happens in the target area
      if buttons(1)
        curs_active{1}.x = x;
        curs_active{1}.y = y;
        curs_active{1}.type = 2;
      else
        curs_active = {};
      end
    end

    opt_click_id = [];
    for id = 1:length(curs_active)
      if ~isempty(curs_active{id})
        % if there is a touch, see what setting it was for
        [flag, i_param, i_opt] = check_if_click_in_rect([curs_active{id}.x, curs_active{id}.y], opts_rect);
        if flag && GetSecs - t_param_selected(i_param) > 0.5
          t_param_selected(i_param) = GetSecs;
          is_deselect = false;
          if opt_chosen(i_param) > 0
            % remove the old rectangle
            Screen('FrameRect', w, row_bg_col(i_param+1, :), squeeze(opts_rect(i_param, opt_chosen(i_param), :))', 4);
            if opt_chosen(i_param) == i_opt
              is_deselect = true;
              opt_chosen(i_param) = 0;
              params.(param_info(i_params_shown(i_param)).varname) = [];
            end
          end
          if ~is_deselect
            opt_chosen(i_param) = i_opt;
            Screen('FrameRect', w, [1 0 0], squeeze(opts_rect(i_param, i_opt, :))', 4);
            params.(param_info(i_params_shown(i_param)).varname) = param_info(i_params_shown(i_param)).opts_varname{i_opt};
          end
        end
        if all(opt_chosen(find([param_info.require_selection])) > 0)
          if check_if_click_in_rect([curs_active{id}.x, curs_active{id}.y], row_bg_rect(:, end))
            play_pressed = true;
          end
        end
      end
    end

    % Flip to the screen
    vbl  = Screen('Flip', w, vbl + (waitframes - 0.5) * ifi, 1);
  end

  if strcmp(input_mode, 'touch')
    wrapup_touch(dev, w);
  end

  % Clear the screen
  Screen('FillRect', w, [0 0 0]);
  Screen('Flip', w);
catch
  TouchQueueRelease(dev);
  RestrictKeysForKbCheck([]);
  sca;
  psychrethrow(psychlasterror);
end

%% ENTER OTHER TASK PARAMETERS THAT ARE FIXED
params.timeout_error_timeout = 0;
params.hold_error_timeout = 0;
params.drag_error_timeout = 0;
params.user_id = user;
params.framework = 'PTB';
params.start_time = [datestr(datetime, 'yymmdd') '_' datestr(datetime, 'HHMM')];

%% PROCESS ALL PARAMETERS FOR THE TASK
% set all of the unentered parameters to their default values
for p = 1:n_params
  if isempty(params.(param_info(p).varname))
    params.(param_info(p).varname) = param_info(p).default_opt;
  end
end

% determine whether we are in testing mode or not
if strcmp(params.animal_name, 'Testing')
  is_testing = true;
else
  is_testing = false;
end

% set the appearing target radius to the appropriate numeric value
if isstr(params.effective_target_rad) && strcmp(params.effective_target_rad, 'Same As Appears')
  params.effective_target_rad = params.target_rad;
end

% determine if we are using the button and what the range of hold times may
% be
use_button = true;
if params.button_hold_time == false
  use_button = false;
elseif isstr(params.button_hold_time)
  tmp = strsplit(params.button_hold_time, '-');
  params.button_hold_time = [];
  for i = 1:length(tmp)
    params.button_hold_time(i) = str2num(tmp{i});
  end
end

% determine what the range of target hold times may be
if isstr(params.target_hold_time)
  tmp = strsplit(params.target_hold_time, '-');
  params.target_hold_time = [];
  for i = 1:length(tmp)
    params.target_hold_time(i) = str2num(tmp{i});
  end
end

% are we going to reward button holds?
if params.button_rew > 0
  do_rewardButton = true;
else
  do_rewardButton = false;
end

% is there reward scaling?
if params.min_targ_reward > 0
  do_rewardScaling = true;
else
  do_rewardScaling = false;
end

%% GET TARGET POSITIONS
% load possible randomly-generated sequences
load('seq_poss.mat');
params.seq_poss = seq_poss;

% determine the center position and distance from center to top/bottom
params.center_position(1) = 0;
params.center_position(2) = params.screen_bot/2 - params.screen_top/2;
params.grid_spacing = (height_mm/10 - params.screen_top - params.screen_bot)/2 - params.effective_target_rad;

% specify the target position strings associated with each sequence type
if params.seq ~= false
  if contains(params.seq, {'rand5', 'randevery', 'rand5-randevery'})
    params.target1_pos_str = 'random';
    params.target2_pos_str = 'random';
    params.target3_pos_str = 'random';
    params.target4_pos_str = 'random';
    params.target5_pos_str = 'random';

    if contains(params.seq, {'rand5', 'rand5-randevery'})
      params = make_random_sequence(params, true);
    end
  elseif strcmp(params.seq, 'repeat') || strcmp(params.seq, '2seq-repeat')
    params.target1_pos_str = params_prev.target1_pos_str;
    params.target2_pos_str = params_prev.target2_pos_str;
    params.target3_pos_str = params_prev.target3_pos_str;
    params.target4_pos_str = params_prev.target4_pos_str;
    params.target5_pos_str = params_prev.target5_pos_str;
  elseif strcmp(params.seq, 'center out')
    params.target1_pos_str = 'center';
    params.target2_pos_str = 'random';
    params.target3_pos_str = 'none';
    params.target4_pos_str = 'none';
    params.target5_pos_str = 'none';
    params = make_random_sequence(params, false);
  elseif strcmp(params.seq, 'button out')
    params.target1_pos_str = 'random';
    params.target2_pos_str = 'none';
    params.target3_pos_str = 'none';
    params.target4_pos_str = 'none';
    params.target5_pos_str = 'none';
    params = make_random_sequence(params, false);
  end


  % for sequence types that involve switching on each block, keep track of
  % what the original sequence to return to is
  if contains(params.seq, {'rand5-randevery', '2seq-repeat'}) || ...
      (strcmp(params.seq, 'repeat') && strcmp(params_prev.seq, 'rand5-randevery'))
    target1_pos_str_og = params.target1_pos_str;
    target2_pos_str_og = params.target2_pos_str;
    target3_pos_str_og = params.target3_pos_str;
    target4_pos_str_og = params.target4_pos_str;
    target5_pos_str_og = params.target5_pos_str;

    if strcmp(params.seq, '2seq-repeat')
      params_seq2 = params;
      params_seq2.target1_pos_str = 'random';
      params_seq2.target2_pos_str = 'random';
      params_seq2.target3_pos_str = 'random';
      params_seq2.target4_pos_str = 'random';
      params_seq2.target5_pos_str = 'random';
      params_seq2 = make_random_sequence(params_seq2, false);
    end
  end


  if strcmp(params.seq, 'repeat')
    params.seq = params_prev.seq;
  end
end

% get the physical target positions from the strings
params.target1_position = get_targpos_from_str(params.target1_pos_str, ...
  params.center_position, params.grid_spacing, params.nudge_x_t1);
params.target2_position = get_targpos_from_str(params.target2_pos_str, ...
  params.center_position, params.grid_spacing, params.nudge_x_t2);
params.target3_position = get_targpos_from_str(params.target3_pos_str, ...
  params.center_position, params.grid_spacing, params.nudge_x_t3);
params.target4_position = get_targpos_from_str(params.target4_pos_str, ...
  params.center_position, params.grid_spacing, params.nudge_x_t4);
params.target5_position = get_targpos_from_str(params.target5_pos_str, ...
  params.center_position, params.grid_spacing, params.nudge_x_t5);

% Set the target positions and radius and convert to pixels
target_positions_cm = [params.target1_position; ...
  params.target2_position; ...
  params.target3_position; ...
  params.target4_position; ...
  params.target5_position];
target_positions_px = cm2pix(target_positions_cm, res);
target_radius_px = cm2pix(params.target_rad, res);

num_targets = length(~isnan(target_positions_cm(:, 1)));

%% SETUP THE SERIAL COMMUNICATION PORTS
% Juicer
try
  if strcmp(params.juicer, 'yellow')
    if strcmp(params.user_id, 'Ganguly')
      rewardPort = serialport('COM4', 115200);
    elseif strcmp(params.user_id, 'BasalGangulia')
      rewardPort = serialport('COM3', 115200);
    end
  elseif strcmp(params.juicer, 'red')
    portinfo = getSCPInfo;
    for c = 1:length(portinfo)
      if any(strfind(portinfo(c).description, 'Prolific USB-to-Serial'))
        prolific_com = portinfo(c).device;
        break
      end
    end
    rewardPort = serialport(prolific_com, 19200);

    % Setup the flow rate
    writeline(rewardPort, 'VOL 0.5');
    writeline(rewardPort, 'VOL ML');
    writeline(rewardPort, 'RAT 50MM');
  end
end

% DIO
try
  dioPort = serialport('COM3', 115200);
end

% Camera Triggers
try
  camtrigPort = serialport('COM3', 9600);

  % say hello
  writeline(camtrigPort, 'a');

  % start cams at 50 Hz
  writeline(camtrigPort, '1');
end

% Eyetracker Triggers
try
  iscanPort = serialport('COM3', 115200);

  % send start recording trigger
  writeline(iscanPort, 's');
end

% External Button
try
  iscanPort = serialport('COM3', 9600);

  is_button = true;
catch
  is_button = false;
end

%% INITIALIZE SOME VARIABLES
target_index = 1;
next_break_trial = params.break_trl;
block_index = 1;

% escape buttons positions: 1.5cm from the right edge and 2.5cm from the
% top/bottom
exit_positions_cm = [width_mm/20 - 1.5, height_mm/20 - 2.5; ...
  width_mm/20 - 1.5, -(height_mm/20 - 2.5)];
exit_positions_px = cm2pix(exit_positions_cm, res);
exit_radius_px = cm2pix(1, res);

% photodiode position: 1.8 cm from the right edge and 0.5 cm from the top
pd_position_cm = [width_mm/20 - 1.8, height_mm/20 - 0.5];
pd_position_px = cm2pix(pd_position_cm, res);
pd_radius_px = cm2pix(0.5, res);

% target construction
targRect = [0 0 2*target_radius_px 2*target_radius_px];
targDiameter = max(targRect) * 1.01;
targColor = [1 1 0];

exitRect = [0 0 2*exit_radius_px 2*exit_radius_px];
exitDiameter = max(exitRect) * 1.01;
exitColor = [0.15 0.15 0.15];

pdRect = [0 0 2*pd_radius_px 2*pd_radius_px];
pdDiameter = max(pdRect) * 1.01;


% PRELOAD SOUNDS

%% DATA SAVING
% determine name of file
filename = [data_path params.animal_name '_' params.start_time];

% save the params in the last param path and the data path
save([last_param_path 'most_recent_target_chase_params.mat'], 'params', '-v7.3');
save([filename '_params.mat'], 'params', '-v7.3');

data = struct('state', {}, 'cursor', double.empty(10, 2, 0), ...
  'cursor_ids', double.empty(10, 0), 'target_pos', double.empty(2, 0), 'time', []);


%% START THE GAME
try
  if strcmp(input_mode, 'touch')
    initialize_touch(dev, w);
  end

  curs_active = {};
  curs_id_min = Inf;
  % Only ESCape allows to exit the game:
  RestrictKeysForKbCheck(KbName('ESCAPE'));

  % Loop the animation until the escape key is pressed
  while ~KbCheck
    if strcmp(input_mode, 'touch')
      [curs_active, curs_id_min] = process_touch_events(dev, w, baseSize, curs_active, curs_id_min);

      for id = 1:length(curs_active)
        if ~isempty(curs_active{id})
          % if there is a touch, see if it happens in the target area
          flag = check_if_click_in_targ([curs_active{id}.x, curs_active{id}.y], target_positions_px(target_index, :), target_radius_px);
          if flag
            %         fprintf([num2str(d) ' pixelss from target ' num2str(target_index) ' --> switch\n']);
            target_index = target_index + 1;
            if target_index == size(target_positions_px, 1) + 1
              target_index = 1;
            end

            break
          end
        end
      end
    elseif strcmp(input_mode, 'mouse')
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
    end

    % Center the rectangle on the centre of the target position
    centeredRect = CenterRectOnPointd(targRect, ...
      target_positions_px(target_index, 1), target_positions_px(target_index, 2));

    % Draw the rect to the screen
    Screen('FillOval', w, targColor, centeredRect, targDiameter);

    % Flip to the screen
    vbl  = Screen('Flip', w, vbl + (waitframes - 0.5) * ifi);
  end

  TouchQueueStop(dev);
  TouchQueueRelease(dev);
  RestrictKeysForKbCheck([]);
  ShowCursor(w);

  % Clear the screen
  sca;
catch
  TouchQueueRelease(dev);
  RestrictKeysForKbCheck([]);
  sca;
  psychrethrow(psychlasterror);
end



%% CURSOR CLASSIFICATION FUNCTIONS
function flag = check_if_click_in_targ(mouse_pos, targ_pos, targ_rad)
flag = sqrt(sum((mouse_pos-targ_pos).^2)) <= targ_rad;
end

function [flag, i, j] = check_if_click_in_rect(mouse_pos, rect)
if size(rect, 1) == 1 || size(rect, 2) == 1
  flag = mouse_pos(1)>= rect(1) && mouse_pos(1)< rect(3) && ...
    mouse_pos(2)>= rect(2) && mouse_pos(2)< rect(4);
else
  if any(mouse_pos(1)>= rect(:, :, 1) & mouse_pos(1)< rect(:, :, 3) & ...
      mouse_pos(2)>= rect(:, :, 2) & mouse_pos(2)< rect(:, :, 4), 'all')
    flag = true;
    [i, j] = ind2sub(size(rect, [1 2]), find(mouse_pos(1)>= rect(:, :, 1) & mouse_pos(1)< rect(:, :, 3) & ...
      mouse_pos(2)>= rect(:, :, 2) & mouse_pos(2)< rect(:, :, 4)));
  else
    flag = false;
    i = [];
    j = [];
  end
end
end

%% TARGET POSITIONING
function targpos = get_targpos_from_str(pos_str, center_work, grid_spacing, nudge_x)
x = nan;
y = nan;
if strcmp(pos_str, 'upper_left')
  x = center_work(1) - grid_spacing + nudge_x;
  y = center_work(2) + grid_spacing;
elseif strcmp(pos_str, 'upper_middle')
  x = center_work(1) + nudge_x;
  y = center_work(2) + grid_spacing;
elseif strcmp(pos_str, 'upper_right')
  x = center_work(1) + grid_spacing + nudge_x;
  y = center_work(2) + grid_spacing;
elseif strcmp(pos_str, 'middle_left')
  x = center_work(1) - grid_spacing + nudge_x;
  y = center_work(2);
elseif strcmp(pos_str, 'center')
  x = center_work(1)+nudge_x;
  y = center_work(2);
elseif strcmp(pos_str, 'middle_right')
  x = center_work(1) + grid_spacing + nudge_x;
  y = center_work(2);
elseif strcmp(pos_str, 'lower_left')
  x = center_work(1) - grid_spacing + nudge_x;
  y = center_work(2) - grid_spacing;
elseif strcmp(pos_str, 'lower_middle')
  x = center_work(1) + nudge_x;
  y = center_work(2) - grid_spacing;
elseif strcmp(pos_str, 'lower_right')
  x = center_work(1) + grid_spacing + nudge_x;
  y = center_work(2) - grid_spacing;
end

targpos = [x y];
end

function params = make_random_sequence(params, change_string)
pos_str_opts = {'upper_left', 'upper_middle', 'upper_right', 'middle_left', ...
  'center', 'middle_right', 'lower_left', 'lower_middle', 'lower_right'};

seq_poss_ix = randperm(size(params.seq_poss, 1), 1);

if strcmp(params.target1_pos_str, 'random')
  i_pos = params.seq_poss(seq_poss_ix, 1);
  params.target1_position = get_targpos_from_str(pos_str_opts{i_pos}, ...
    params.center_position, params.grid_spacing, params.nudge_x_t1);
  if change_string
    params.target1_pos_str = pos_str_opts{i_pos};
  end
end

if strcmp(params.target2_pos_str, 'random')
  i_pos = params.seq_poss(seq_poss_ix, 2);
  params.target2_position = get_targpos_from_str(pos_str_opts{i_pos}, ...
    params.center_position, params.grid_spacing, params.nudge_x_t2);
  if change_string
    params.target2_pos_str = pos_str_opts{i_pos};
  end
end

if strcmp(params.target3_pos_str, 'random')
  i_pos = params.seq_poss(seq_poss_ix, 3);
  params.target3_position = get_targpos_from_str(pos_str_opts{i_pos}, ...
    params.center_position, params.grid_spacing, params.nudge_x_t3);
  if change_string
    params.target3_pos_str = pos_str_opts{i_pos};
  end
end

if strcmp(params.target4_pos_str, 'random')
  i_pos = params.seq_poss(seq_poss_ix, 4);
  params.target4_position = get_targpos_from_str(pos_str_opts{i_pos}, ...
    params.center_position, params.grid_spacing, params.nudge_x_t4);
  if change_string
    params.target4_pos_str = pos_str_opts{i_pos};
  end
end

if strcmp(params.target5_pos_str, 'random')
  i_pos = params.seq_poss(seq_poss_ix, 5);
  params.target5_position = get_targpos_from_str(pos_str_opts{i_pos}, ...
    params.center_position, params.grid_spacing, params.nudge_x_t5);
  if change_string
    params.target5_pos_str = pos_str_opts{i_pos};
  end
end
end

%% TOUCH HANDLING SUBFUNCTIONS
function initialize_touch(dev, w)
% No place for you, little mouse cursor:
%   HideCursor(w);

% Create and start touch queue for window and device:
TouchQueueCreate(w, dev);
TouchQueueStart(dev);

% Wait for the go!
KbReleaseWait;
end

function [curs_active, curs_id_min] = process_touch_events(dev, w, baseSize, curs_active, curs_id_min)
% Process all currently pending touch events:
while TouchEventAvail(dev)
  % Process next touch event 'evt':
  evt = TouchEventGet(dev, w);

  % Touch blob id - Unique in the session at least as
  % long as the finger stays on the screen:
  id = evt.Keycode;

  % Keep the id's low, so we have to iterate over less curs_active slots
  % to save computation time:
  if isinf(curs_id_min)
    curs_id_min = id - 1;
  end
  id = id - curs_id_min;

  if evt.Type == 0
    % Not a touch point, but a button press or release on a
    % physical (or emulated) button associated with the touch device:
    continue;
  end

  if evt.Type == 1
    % Not really a touch point, but movement of the
    % simulated mouse cursor, driven by the primary
    % touch-point:
    Screen('DrawDots', w, [evt.MappedX; evt.MappedY], baseSize, [1,1,1], [], 1, 1);
    continue;
  end

  if evt.Type == 2
    % New touch point -> New blob!
    curs_active{id}.x = evt.MappedX;
    curs_active{id}.y = evt.MappedY;
    curs_active{id}.t = evt.Time;
    curs_active{id}.dt = 0;
    curs_active{id}.id = evt.Keycode;
    curs_active{id}.type = 2;
    curs_active{id}.t_start = curs_active{id}.t;
  end

  if evt.Type == 3
    % Moving touch point
    curs_active{id}.x = evt.MappedX;
    curs_active{id}.y = evt.MappedY;
    curs_active{id}.dt = ceil((evt.Time - curs_active{id}.t) * 1000);
    curs_active{id}.t = evt.Time;
    curs_active{id}.type = 3;
  end

  if evt.Type == 4
    % Touch released - finger taken off the screen
    curs_active{id} = [];
  end

  if evt.Type == 5
    % Lost touch data for some reason:
    % Flush screen red for one video refresh cycle.
    fprintf('Ooops - Sequence data loss!\n');
    Screen('FillRect', w, [1 0 0]);
    Screen('Flip', w);
    Screen('FillRect', w, 0);
    continue;
  end
end
end

function wrapup_touch(dev, w)
TouchQueueStop(dev);
TouchQueueRelease(dev);
RestrictKeysForKbCheck([]);
ShowCursor(w);
end

%% SCREEN COORDINATE TRANSFORMATIONS
function pos_cm = pix2cm(pos_pix, res)
% convert from pixels to cm
pos_pix(1) = pos_pix(1) - res.width/2;
pos_pix(2) = pos_pix(2) - res.height/2;

pos_cm = pos_pix*(1/res.pixelSize);
end

function pos_pix = cm2pix(pos_cm, res)
% convert from pixels to cm
pos_pix = pos_cm*res.pixelSize;
if size(pos_cm, 2) == 2
  pos_pix(:, 1) = pos_pix(:, 1) + res.width/2;
  pos_pix(:, 2) = pos_pix(:, 2) + res.height/2;
end
end

