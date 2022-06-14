try
  cd('C:\Users\sando\Documents\target_chase')
catch
  cd('C:\Users\sando\Dropbox\Ganguly_Lab\Code\target_chase')
end

% Clear the workspace and the screen
sca;
close all;
clear;

Screen('Preference', 'ConserveVRAM', 4096);
Screen('Preference', 'SkipSyncTests', 1);

raise_botton_edge_by_mm = 15;
nudge_left_edge_in_by_mm = 30;
nudge_right_edge_in_by_mm = 30;

self = [];
self.t_start = GetSecs;

%% SETUP THE SERIAL COMMUNICATION PORTS
IOPort('CloseAll');

% DIO
try
  lineTerminator = 10;
  baudRate = 115200;
  portSpec = 'COM7';

  portSettings = sprintf('BaudRate=%i Terminator=%i', baudRate, lineTerminator);
  self.dioPort = IOPort('OpenSerialPort', portSpec, portSettings);

%   self.dioPort = serialport('COM7', 115200);
%   configureTerminator(self.dioPort,"CR/LF");

  self.is_dioPort = true;
catch
  self.is_dioPort = false;
end

% Camera Triggers
try
  lineTerminator = 10;
  baudRate = 9600;
  portSpec = 'COM8'; % COM 8

  portSettings = sprintf('BaudRate=%i Terminator=%i', baudRate, lineTerminator);
  self.camtrigPort = IOPort('OpenSerialPort', portSpec, portSettings);

%   self.camtrigPort = serialport('COM8', 9600);
%   configureTerminator(self.camtrigPort,"CR/LF");
  
  % say hello
  IOPort('Write', self.camtrigPort, 'a', 0);
%   writeline(self.camtrigPort, 'a');

  self.is_camtrigPort = true;
catch
  self.is_camtrigPort = false;
end

% Eyetracker Triggers
try
%   lineTerminator = 10;
%   baudRate = 9600;
%   portSpec = 'COM6'; % COM 6
% 
%   portSettings = sprintf('BaudRate=%i Terminator=%i', baudRate, lineTerminator);
%   self.iscanPort = IOPort('OpenSerialPort', portSpec, portSettings);

  self.iscanPort = serialport('COM6', 115200);
  configureTerminator(self.iscanPort,"CR/LF");

  % send start recording trigger
%   IOPort('Write', self.iscanPort, 'e', 0);
%   IOPort('Write', self.iscanPort, 's', 0);

  self.is_iscanPort = true;
catch
  self.is_iscanPort = false;
end

% Button
try

  % added Hoseok 052622
  portinfo = getSCPInfo;
  for c = 1:length(portinfo)
    if any(strfind(portinfo(c).description, 'USB-SERIAL CH340'))
      prolific_com2 = portinfo(c).device;
      break
    end
  end
  self.buttonPort = serialport(prolific_com2, 9600);
%   self.buttonPort = serialport("COM22", 9600);
  configureTerminator(self.buttonPort, 'CR/LF');
  flush(self.buttonPort);
  readline(self.buttonPort);

  self.is_buttonPort = true;
catch
  self.is_buttonPort = false;
end

%% GET SYSTEM AND DISPLAY INFORMATION
% system, user, and path saving
cwd = pwd;
if ispc
  if any(strfind(cwd, 'sando'))
    if exist('C:\Users\sando\Documents\dummy')
      user = 'sando_pc';
    else
      user = 'sando';
    end
    last_param_path = 'C:\Users\sando\Documents\';
    data_path = 'C:\Users\sando\Box\Data\NHP_BehavioralData\target_chase\';
  end
end

if ~exist(data_path)
  data_path = [pwd filesep];
end

% Here we call some default settings for setting up Psychtoolbox
PsychDefaultSetup(2);

% Get the screen numbers
screens = Screen('Screens');

% Draw to the external screen if avaliable
screenId = max(screens);

% Get the screen size and resolution
[width_mm, height_mm] = Screen('DisplaySize', screenId); % this is wrong
% when using SuperDisplay on the tablet, so we need to manually adjust
if width_mm == 522 && height_mm == 326
  width_mm = 314;
  height_mm = 196;
end
self.res = Screen('Resolution', screenId);
self.res.pix_per_cm = round(10*min([self.res.width/width_mm self.res.height/height_mm]));
self.raise_bottom_edge_by_px = cm2pix(raise_botton_edge_by_mm/10, self.res);
self.nudge_left_edge_in_by_px = cm2pix(nudge_left_edge_in_by_mm/10, self.res);
self.nudge_right_edge_in_by_px = cm2pix(nudge_right_edge_in_by_mm/10, self.res);
self.res.effective_width = self.res.width - self.nudge_left_edge_in_by_px - self.nudge_right_edge_in_by_px;
self.res.effective_height = self.res.height - self.raise_bottom_edge_by_px;

% Get first touchscreen:
self.dev = min(GetTouchDeviceIndices([], 1));

if isempty(self.dev) || ~ismember(self.dev, GetTouchDeviceIndices)
  fprintf('No touch input device found, or invalid dev given. Using mouse instead.\n');
  input_mode = 'mouse';
else
  fprintf('Touch device properties:\n');
  input_mode = 'touch';
  info = GetTouchDeviceInfo(self.dev);
  disp(info);
end

if strcmp(user, 'sando_pc')
  input_mode = 'mouse';
end

% Define black and white
white = WhiteIndex(screenId);
black = BlackIndex(screenId);

% Open an on screen window
[self.w, rect] = PsychImaging('OpenWindow', screenId, black);
self.baseSize = RectWidth(rect) / 20;

% Query the frame duration
% ifi = Screen('GetFlipInterval', self.w);
ifi = 1/120;

% Maximum priority level
topPriorityLevel = MaxPriority(self.w);
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
row_height = (self.res.height - self.raise_bottom_edge_by_px)/n_rows;
row_edges = 0:row_height:(n_rows*row_height);
row_centers = (row_height/2):row_height:self.res.height;

try
  % Make the background color behind each parameter (row) alternate between
  % dark blue and black
  row_bg_col = repmat([0 0 0.3; 0 0 0], ceil(n_rows/2), 1);
  row_bg_col = row_bg_col(1:n_rows, :);
  row_bg_rect = [zeros(1, n_rows); ...
    row_edges(1:end-1); repmat(self.res.width, 1, n_rows); row_edges(2:end)];
  Screen('FillRect', self.w, row_bg_col', row_bg_rect);
  
  % Draw the welcome text
  Screen('TextSize', self.w, round(0.9*row_height)); % make the welcome line really big
  DrawFormattedText(self.w, 'WELCOME! MAKE A SELECTION IN EACH ROW', ...
    'center', 'center', [1 1 1], [], 0, 0, 1, 0, row_bg_rect(:, 1)');
 
  % List all of the param titles on the left side of the screen, right
  % justified
  title_x = self.nudge_left_edge_in_by_px + 0.2*(self.res.effective_width);
  title_rect = [row_bg_rect(1:2, :); repmat(title_x, 1, n_rows); row_bg_rect(4, :)];
  Screen('TextSize', self.w, round(0.75*row_height)); % make the titles medium sized
  for p = 1:n_params_shown
    DrawFormattedText(self.w, param_info(i_params_shown(p)).title, ...
      'right', 'center', [1 1 0], [], 0, 0, 1, 0, title_rect(:, p+1)');
  end

  % With the remaining right half of the screen, make a n_row x 8 grid and
  % fill the options into each point on the grid. If there are more than 8
  % options, then space the options evenly
  Screen('TextSize', self.w, round(0.4*row_height)); % make the options small sized
  opt_chosen = zeros(1, n_params_shown);
  opts_rect = nan(n_params_shown, max_opts, 4);
  for p = 1:n_params_shown
    if param_info(i_params_shown(p)).Nopts <= 8
      n_win = 8;
    else
      n_win = param_info(i_params_shown(p)).Nopts;
    end
    opts_edges = linspace(title_x, (self.res.width-self.nudge_right_edge_in_by_px), n_win+2);
    opts_win_width = mode(diff(opts_edges));
    opts_edges = opts_edges-opts_win_width/2;

    opts_rect(p, 1:param_info(i_params_shown(p)).Nopts, :) = ...
      [opts_edges(2:param_info(i_params_shown(p)).Nopts+1); ...
      repmat(row_edges(p+1), 1, param_info(i_params_shown(p)).Nopts); ...
      opts_edges(3:param_info(i_params_shown(p)).Nopts+2); ...
      repmat(row_edges(p+2), 1, param_info(i_params_shown(p)).Nopts)]';
    for i = 1:param_info(i_params_shown(p)).Nopts
      DrawFormattedText(self.w, param_info(i_params_shown(p)).opts_title{i}, ...
        'center', 'center', [1 1 1], [], 0, 0, 1, 0, squeeze(opts_rect(p, i, :))');

      % highlight this option if it is the same as the last option that was
      % used
      if ~isempty(params) && ~isempty(params.(param_info(i_params_shown(p)).varname)) && ...
          (isstr(param_info(i_params_shown(p)).opts_varname{i}) && ...
          strcmp(params.(param_info(i_params_shown(p)).varname), param_info(i_params_shown(p)).opts_varname{i}) ...
          || (isnumeric(param_info(i_params_shown(p)).opts_varname{i}) && ...
          isnumeric(params.(param_info(i_params_shown(p)).varname)) && ...
          params.(param_info(i_params_shown(p)).varname) == param_info(i_params_shown(p)).opts_varname{i}) ...
          || (islogical(param_info(i_params_shown(p)).opts_varname{i}) && ...
          islogical(params.(param_info(i_params_shown(p)).varname)) && ...
          params.(param_info(i_params_shown(p)).varname) == param_info(i_params_shown(p)).opts_varname{i}))
        opt_chosen(p) = i;
        Screen('FrameRect', self.w, [1 0 0], squeeze(opts_rect(p, i, :)), 4);
      end
    end
  end

  % Draw the play button
  Screen('FillRect', self.w, [0.5 0.5 0.5], row_bg_rect(:, end)');
  Screen('TextSize', self.w, round(0.9*row_height)); % make the play text really big
  DrawFormattedText(self.w, 'PLAY TARGET CHASE', ...
    'center', 'center', [1 1 1], [], 0, 0, 1, 0, row_bg_rect(:, end)');
  
  Screen('Flip', self.w, 0, 1);

%   KbStrokeWait; % sca;
catch
  sca;
  psychrethrow(psychlasterror);
end

%% INTERACT WITH THE SETTINGS SCREEN
hit_escape = false;
t_param_selected = zeros(1, n_params);
try
  if strcmp(input_mode, 'touch')
    initialize_touch(self);
  end

  % initialize struct for tracking active touch points:
  self.curs_active = {};
  self.curs_id_min = inf;

  % Only ESCape allows to exit the game:
  RestrictKeysForKbCheck(KbName('ESCAPE'));

  % Loop the animation until the escape key is pressed or the play button
  % is pressed
  play_pressed = false;
  
  while ~hit_escape && ~play_pressed
    hit_escape = KbCheck;
    if strcmp(input_mode, 'touch')
      self = process_touch_events(self);

    elseif strcmp(input_mode, 'mouse')
      % Get the position of the mouse
      [x, y, buttons] = GetMouse(screenId);
    
      % if there is a click, see if it happens in the target area
      if buttons(1)
        self.curs_active(1).x = x;
        self.curs_active(1).y = y;
        self.curs_active(1).type = 2; 
      else
        self.curs_active = {};
      end
    end
    
    opt_click_id = [];
    for id = 1:length(self.curs_active)
      if ~isempty(self.curs_active(id))
        % if there is a touch, see what setting it was for
        [flag, i_param, i_opt] = check_if_click_in_rect([self.curs_active(id).x, self.curs_active(id).y], opts_rect);
        if flag && GetSecs - t_param_selected(i_param) > 0.5
          t_param_selected(i_param) = GetSecs;
          is_deselect = false;
          if opt_chosen(i_param) > 0
            % remove the old rectangle
            Screen('FrameRect', self.w, row_bg_col(i_param+1, :), squeeze(opts_rect(i_param, opt_chosen(i_param), :))', 4);
            if opt_chosen(i_param) == i_opt
              is_deselect = true;
              opt_chosen(i_param) = 0;
              params.(param_info(i_params_shown(i_param)).varname) = [];
            end
          end
          if ~is_deselect
            opt_chosen(i_param) = i_opt;
            Screen('FrameRect', self.w, [1 0 0], squeeze(opts_rect(i_param, i_opt, :))', 4);
            params.(param_info(i_params_shown(i_param)).varname) = param_info(i_params_shown(i_param)).opts_varname{i_opt};
          end
        end
        if all(opt_chosen(find([param_info(i_params_shown).require_selection])) > 0)
          if check_if_click_in_rect([self.curs_active(id).x, self.curs_active(id).y], row_bg_rect(:, end))
            play_pressed = true;
          end
        end
      end
    end

    % Flip to the screen
    Screen('Flip', self.w, 0, 1);
  end
  
  if strcmp(input_mode, 'touch')
    wrapup_touch(self);
  end

  % Clear the screen
  Screen('FillRect', self.w, [0 0 0]);
  Screen('Flip', self.w, 0, 0, 1);
catch
  TouchQueueRelease(self.dev);
  RestrictKeysForKbCheck([]);
  sca;
  psychrethrow(psychlasterror);
end

%% ENTER OTHER TASK PARAMETERS THAT ARE FIXED
params.bgColor = [0 0 0]; % background color
params.timeout_error_timeout = 0;
params.hold_error_timeout = 0;
params.drag_error_timeout = 0;
params.user_id = user;
params.framework = 'PTB';
params.start_time = [datestr(datetime, 'yymmdd') '_' datestr(datetime, 'HHMM')];
params.input_mode = input_mode;
params.exit_hold = 2;
params.reward_dur = 0.75;
params.outlineWidth = 4;
params.rew_scale_method = 'adaptive';
params.max_rew_pthresh = 0.5;
params.min_rew_pthresh = 0.75;

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
self.use_button = true;
if params.button_hold_time == false
  self.use_button = false;
elseif isstr(params.button_hold_time)
  tmp = strsplit(params.button_hold_time, '-');
  params.effective_button_hold_time = [];
  for i = 1:length(tmp)
    params.effective_button_hold_time(i) = str2num(tmp{i});
  end
else
  params.effective_button_hold_time = params.button_hold_time;
end

% determine what the range of target hold times may be
if isstr(params.target_hold_time)
  tmp = strsplit(params.target_hold_time, '-');
  params.effective_target_hold_time = [];
  for i = 1:length(tmp)
    params.effective_target_hold_time(i) = str2num(tmp{i});
  end
else
  params.effective_target_hold_time = params.target_hold_time;
end

% are we going to reward button holds?
if params.button_rew > 0
  self.do_rewardButton = true;
else
  self.do_rewardButton = false;
end

% is there reward scaling?
if params.min_targ_reward > 0
  self.do_rewardScaling = true;
else
  self.do_rewardScaling = false;
end

% add the constant bottom screen raise to the one specified in the settings
params.effective_screen_bot = params.screen_bot + raise_botton_edge_by_mm/10;

% thresholds for max/min rewards
if strcmp(params.rew_scale_method, 'absolute')
  if strcmp(params.animal_name, 'butters')
    targ1on2touch_fast = 0.9;
    targon2touch_fast = 0.5;
    targon2touch_slow = 0.6;
  elseif strcmp(params.animal_name, 'fifi')
    targ1on2touch_fast = 0.65;
    targon2touch_fast = 0.45;
    targon2touch_slow = 0.55;
  else 
    targ1on2touch_fast = 0.7;
    targon2touch_fast = 0.45;
    targon2touch_slow = 0.6;
  end
  params.time_thresh_for_max_rew = ...
    targ1on2touch_fast+targon2touch_fast*(self.num_targets-1)+params.intertarg_delay*(self.num_targets-1);
  params.time_thresh_for_min_rew = ...
    targ1on2touch_fast+targon2touch_slow*(self.num_targets-1)+params.intertarg_delay*(self.num_targets-1);
elseif strcmp(params.rew_scale_method, 'adaptive')
  params.time_thresh_for_max_rew = -Inf;
  params.time_thresh_for_min_rew = Inf;
end

self.time_thresh_for_max_rew = params.time_thresh_for_max_rew;
self.time_thresh_for_min_rew = params.time_thresh_for_min_rew;

%% GET TARGET POSITIONS

% load possible randomly-generated sequences
load('seq_poss.mat');
params.seq_poss = seq_poss;

% determine the center position and distance from center to top/bottom
params.center_position(1) = 0;
params.center_position(2) = params.effective_screen_bot/2 - params.screen_top/2;
params.grid_spacing = (height_mm/10 - params.screen_top - params.effective_screen_bot)/2 - params.effective_target_rad;

% specify the target position strings associated with each sequence type
if isstr(params.seq)
  if contains(params.seq, {'rand5', 'randevery', 'rand5-randevery'})
    params.target1_pos_str = 'random';
    params.target2_pos_str = 'random';
    params.target3_pos_str = 'random';
    params.target4_pos_str = 'random';
    params.target5_pos_str = 'random';
    
    if contains(params.seq, {'rand5', 'rand5-randevery'})
      [self, params] = make_random_sequence(self, params, true, false);
    end
  elseif strcmp(params.seq, 'center out')
    params.target1_pos_str = 'center';
    params.target2_pos_str = 'random';
    params.target3_pos_str = 'none';
    params.target4_pos_str = 'none';
    params.target5_pos_str = 'none';
  elseif strcmp(params.seq, 'button out')
    params.target1_pos_str = 'random';
    params.target2_pos_str = 'none';
    params.target3_pos_str = 'none';
    params.target4_pos_str = 'none';
    params.target5_pos_str = 'none';
  elseif strcmp(params.seq, 'repeat') || strcmp(params.seq, '2seq-repeat')
    params.target1_pos_str = params_prev.target1_pos_str;
    params.target2_pos_str = params_prev.target2_pos_str;
    params.target3_pos_str = params_prev.target3_pos_str;
    params.target4_pos_str = params_prev.target4_pos_str;
    params.target5_pos_str = params_prev.target5_pos_str;
  end


  % for sequence types that involve switching on each block, keep track of
  % what the original sequence to return to is
  if contains(params.seq, {'rand5-randevery', '2seq-repeat'}) || ...
      (strcmp(params.seq, 'repeat') && strcmp(params_prev.seq, 'rand5-randevery'))
  %   target1_pos_str_og = params.target1_pos_str;
  %   target2_pos_str_og = params.target2_pos_str;
  %   target3_pos_str_og = params.target3_pos_str;
  %   target4_pos_str_og = params.target4_pos_str;
  %   target5_pos_str_og = params.target5_pos_str;
  
    if strcmp(params.seq, '2seq-repeat')
      params_seq2 = params;
      params_seq2.target1_pos_str = 'random';
      params_seq2.target2_pos_str = 'random';
      params_seq2.target3_pos_str = 'random';
      params_seq2.target4_pos_str = 'random';
      params_seq2.target5_pos_str = 'random';
      [self_seq2, params_seq2] = make_random_sequence(self, params_seq2, false, true);
    end
  end
end

if strcmp(params.seq, 'repeat')
  params.seq = params_prev.seq;
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
self.target_positions_cm = [params.target1_position; ...
  params.target2_position; ...
  params.target3_position; ...
  params.target4_position; ...
  params.target5_position];
self.target_positions_px = cm2pix(self.target_positions_cm, self.res);
self.target_positions_px_og = self.target_positions_px; 
self.target_radius_px = cm2pix(params.target_rad, self.res);

self.num_targets = length(~isnan(self.target_positions_cm(:, 1)));


%% PREPARE OBJECTS TO BE DISPLAYED
% determine the number of pixels for the effective target radius
self.effective_target_rad_px = cm2pix(params.effective_target_rad, self.res);

% target construction
self.targRect = [0 0 2*self.target_radius_px 2*self.target_radius_px];
self.targDiameter = max(self.targRect) * 1.01;
self.targColor = [1 1 0];

% escape buttons positions: 1.5cm from the right edge and 2.5cm from the
% top/bottom
exit_positions_cm = [width_mm/20 - 1.5 - nudge_right_edge_in_by_mm/10, height_mm/20 - 2.5; ...
  width_mm/20 - nudge_right_edge_in_by_mm/10 - 1.5, (-height_mm/20 + raise_botton_edge_by_mm/10 + 2.5)]; 
self.exit_positions_px = cm2pix(exit_positions_cm, self.res);
self.exit_radius_px = cm2pix(0.5, self.res);

exitRectBase = [0 0 2*self.exit_radius_px 2*self.exit_radius_px];
self.exitDiameter = max(exitRectBase) * 1.01;
for i = 1:2
  self.exitRect(:, i) = CenterRectOnPointd(exitRectBase, ...
    self.exit_positions_px(i, 1), self.exit_positions_px(i, 2));
end
self.exitColor = [0.15 0.15 0.15];

% photodiode position: 1.8 cm from the right edge and 1.5 cm from the top
pd_position_cm = [width_mm/20 - 2.1, ...
  height_mm/20 - 2.3];
self.pd_position_px = cm2pix(pd_position_cm, self.res);
self.pd_radius_px = cm2pix(0.4, self.res);

pdRectBase = [0 0 2*self.pd_radius_px 2*self.pd_radius_px];
self.pdDiameter = max(pdRectBase) * 1.01;
self.pdRect = CenterRectOnPointd(pdRectBase, ...
    self.pd_position_px(1), self.pd_position_px(2));
self.pdColor = [0.75 0.75 0.75];

% Outlines construction
x_cm = params.center_position(1) + [-params.grid_spacing:params.grid_spacing:params.grid_spacing];
y_cm = params.center_position(2) + [-params.grid_spacing:params.grid_spacing:params.grid_spacing];

self.outlinesRect = nan(4, 9);
i = 0;
for ix = 1:length(x_cm)
  for iy = 1:length(y_cm)
    i = i+1;
    outlines_px_i = cm2pix([x_cm(ix) y_cm(iy)], self.res);
    self.outlinesRect(:, i) = CenterRectOnPointd(self.targRect, ...
      outlines_px_i(1), outlines_px_i(2))';
  end
end

% trial counter location (opposite of photodiode)
trlcnt_position_cm = [width_mm/20 - nudge_right_edge_in_by_mm/10 - 1.5, (-height_mm/20 + raise_botton_edge_by_mm/10 + 0.5)];
self.trlcnt_position_px = cm2pix(trlcnt_position_cm, self.res);

%% DATA SAVING
% % when to save
% params.save_state = 'taskbreak';
% params.t_state_save = 5;
% params.save_interval = params.break_dur;

% how frequently to sample the data for storing
params.update_freq = 200; %120;
update_interval = 1/params.update_freq;

% determine name of file
filename = [data_path lower(params.animal_name) '_' params.start_time];

% save the params in the last param path and the data path
save([last_param_path 'most_recent_target_chase_params.mat'], 'params', '-v7.3');
save([filename '_params.mat'], 'params', '-v7.3');

% data = struct('state', {}, 'cursor', double.empty(10, 2, 0), ...
%   'cursor_ids', double.empty(10, 0), 'target_pos', double.empty(2, 0), 'time', []);


%% FINITE STATE MODELING
% each field corresponds to a state
% each subfield corresponds to a function that should be run on every loop
% during that state. If the function returns true, then the state advances
% to the state that is indicated for that function
FSM = [];

% ITI
FSM.ITI.end_ITI = 'taskbreak';
FSM.ITI.stop = 'end_game';

% TASKBREAK
FSM.taskbreak.end_taskbreak = 'vid_trig';
FSM.taskbreak.stop = 'end_game';

% CAMERA TRIGGERS
FSM.vid_trig.end_vid_trig = 'button';
FSM.vid_trig.stop = 'end_game';

% BUTTON
FSM.button.button_pressed = 'button_hold';
FSM.button.stop = 'end_game';

% BUTTON HOLD
FSM.button_hold.finish_button_hold = 'target';
FSM.button_hold.early_leave_button_hold = 'button';
FSM.button_hold.stop = 'end_game';

% TARGET
FSM.target.touch_target_nohold = 'target';
FSM.target.touch_target = 'targ_hold';
FSM.target.target_timeout = 'timeout_error';
FSM.target.stop = 'end_game';

% TARGET HOLD
FSM.targ_hold.finish_last_targ_hold = 'reward';
FSM.targ_hold.finish_targ_hold = 'target';
FSM.targ_hold.early_leave_target_hold = 'hold error';
% FSM.targ_hold.targ_drag_out = 'drag_error'; 
FSM.targ_hold.stop = 'end_game';

% REWARD
FSM.reward.end_reward = 'ITI';
FSM.reward.stop = 'end_game';

% TIMEOUT ERROR
FSM.timeout_error.end_timeout_error = 'ITI';
FSM.timeout_error.stop = 'end_game';

% HOLD ERROR
FSM.hold_error.end_hold_error = 'target';
FSM.hold_error.stop = 'end_game';

% DRAG ERROR
FSM.drag_error.end_drag_error = 'target';
FSM.drag_error.stop = 'end_game';

% IDLE EXIT
FSM.idle_exit.stop = 'end_game';

self.FSM = FSM;

%% PRELOAD SOUNDS
try
  wavfilenames = {'reward1.mp3', 'A32.mp3', 'C.mp3', 'DoorBell.mp3'};
  nfiles = length(wavfilenames);

  % Always init to 2 channels, for the sake of simplicity:
  nrchannels = 2;

  % Perform basic initialization of the sound driver:
  InitializePsychSound(1);

  % Open the audio 'device' with default mode [] (== Only playback),
  % and a required latencyclass of 1 == standard low-latency mode, as well as
  % default playback frequency and 'nrchannels' sound output channels.
  % This returns a handle 'pahandle' to the audio device:
  self.pahandle = PsychPortAudio('Open', 2, [], 0, [], nrchannels);

  % Get what frequency we are actually using for playback:
  self.soundstatus = PsychPortAudio('GetStatus', self.pahandle);
  freq = self.soundstatus.SampleRate;

  % Read all sound files and create & fill one dynamic audiobuffer for
  % each read soundfile:
  self.sounds = [];
  j = 0;

  for i=1:nfiles
    try
      % Make sure we don't abort if we encounter an unreadable sound
      % file. This is achieved by the try-catch clauses...
      [audiodata, infreq] = psychwavread(char(wavfilenames(i)));
      dontskip = 1;
    catch
      fprintf('Failed to read and add file %s. Skipped.\n', char(wavfilenames(i)));
      dontskip = 0;
      psychlasterror
      psychlasterror('reset');
    end

    if dontskip
      j = j + 1;

      % Resampling supported. Check if needed:
      if infreq ~= freq
        % Need to resample this to target frequency 'freq':
        fprintf('Resampling from %i Hz to %i Hz... ', infreq, freq);
        audiodata = resample(audiodata, freq, infreq);
      end

      [samplecount, ninchannels] = size(audiodata);
      audiodata = repmat(transpose(audiodata), nrchannels / ninchannels, 1);

      self.sounds(end+1) = PsychPortAudio('CreateBuffer', [], audiodata); %#ok<AGROW>
      [fpath, fname] = fileparts(char(wavfilenames(j)));
      fprintf('Filling audiobuffer handle %i with soundfile %s ...\n', self.sounds(j), fname);
    end
  end

  % Enable use of sound schedules: We create a schedule of default size,
  % currently 128 slots by default. From now on, the driver will not play
  % back the sounds stored via PsychPortAudio('FillBuffer') anymore. Instead
  % you'll have to define a "playlist" or schedule via subsequent calls to
  % PsychPortAudio('AddToSchedule'). Then the driver will process that
  % schedule by playing all defined sounds in the schedule, one after each
  % other, until the end of the schedule is reached. You can add new items to
  % the schedule while the schedule is already playing.
  PsychPortAudio('UseSchedule', self.pahandle, 1);

  % Maximize volume
  PsychPortAudio('Volume', self.pahandle, 1);

  self.is_audioPort = true;
catch
  self.is_audioPort = false;
  psychrethrow(psychlasterror);
end

%% SETUP JUICER
try
  if strcmp(params.juicer, 'yellow')
    if strcmp(params.user_id, 'Ganguly')
      self.rewardPort = serialport('COM4', 115200);
    elseif strcmp(params.user_id, 'BasalGangulia')
      self.rewardPort = serialport('COM3', 115200);
    end
  elseif strcmp(params.juicer, 'red')
    portinfo = getSCPInfo;
    for c = 1:length(portinfo)
      if any(strfind(portinfo(c).description, 'Prolific USB-to-Serial'))
        prolific_com = portinfo(c).device;
        break
      end
    end
    
%     lineTerminator = 13;
%     baudRate = 19200;
%     portSpec = prolific_com;
%     
%     portSettings = sprintf('BaudRate=%i Terminator=%i', baudRate, lineTerminator);
%     self.rewardPort = IOPort('OpenSerialPort', portSpec, portSettings);
    
    self.rewardPort = serialport(prolific_com, 19200);
    configureTerminator(self.rewardPort, 'CR');

    % Setup the flow rate
%     IOPort('Write', self.rewardPort, 'VOL 0.5', 0);
%     IOPort('Write', self.rewardPort, 'VOL ML', 0);
%     IOPort('Write', self.rewardPort, 'RAT 50MM', 0);
    writeline(self.rewardPort, 'VOL 0.5');
    writeline(self.rewardPort, 'VOL ML');
    writeline(self.rewardPort, 'RAT 50MM');
  end

  self.is_rewardPort = true;
catch
  self.is_rewardPort = false;
end

%% ADVANCE TO THE START SCREEN
% Display all of the port checks
check_title = {'Juicer Connected: ', 'Button Connected: ', 'DIO Port Connected: ', ...
  'ISCAN Port Connected: ', 'CamTrig Port Connected: ', 'Audio Port Connected: '};
if self.is_rewardPort
  check_str{1} = 'YES';
else
  check_str{1} = 'NO';
end
if self.is_buttonPort
  check_str{2} = 'YES';
else
  check_str{2} = 'NO';
end
if self.is_dioPort
  check_str{3} = 'YES';
else
  check_str{3} = 'NO';
end
if self.is_iscanPort
  check_str{4} = 'YES';
else
  check_str{4} = 'NO';
end
if self.is_camtrigPort
  check_str{5} = 'YES';
else
  check_str{5} = 'NO';
end
if self.is_audioPort
  check_str{6} = 'YES';
else
  check_str{6} = 'NO';
end

x_check_title = self.res.effective_width/5 + self.nudge_left_edge_in_by_px;
x_check_str = 3*self.res.effective_width/5 + self.nudge_left_edge_in_by_px;
y_check_bottom = 4*self.res.effective_height/5 - self.raise_bottom_edge_by_px;
y_check_top = self.res.effective_height/5 - self.raise_bottom_edge_by_px;
y_check = linspace(y_check_top, y_check_bottom, length(check_title));

Screen('TextSize', self.w, round(self.res.effective_height/20));
for s = 1:length(check_title)
  if strcmp(check_str{s}, 'YES')
    textCol = [0 1 0];
  else
    textCol = [1 0 0];
  end
  DrawFormattedText(self.w, check_title{s}, ...
    x_check_title, y_check(s), textCol);
  DrawFormattedText(self.w, check_str{s}, ...
    x_check_str, y_check(s), textCol);
end

% Draw the start button
start_position_cm = [width_mm/20 - 1.5 - nudge_right_edge_in_by_mm/10, height_mm/20 - 2.5];
start_position_px = cm2pix(start_position_cm, self.res);

startRectBase = [0 0 self.res.effective_width/10 self.res.effective_height/10];
startRect = CenterRectOnPointd(startRectBase, ...
  start_position_px(1), start_position_px(2));
Screen('FrameRect', self.w, [0.15 0.15 0.15], startRect, 4);
Screen('TextSize', self.w, round(self.res.effective_height/50));
DrawFormattedText(self.w, 'Touch to Start', 'center', 'center', ...
  [0.15 0.15 0.15], [], 0, 0, 1, 0, startRect);

% Flip to the screen
Screen('Flip', self.w, 0, 1);

try
  if strcmp(input_mode, 'touch')
    initialize_touch(self);
  end

  % initialize struct for tracking active touch points:
  self.curs_active = {};
  self.curs_id_min = inf;

  % Only ESCape allows to exit the game:
  RestrictKeysForKbCheck(KbName('ESCAPE'));

  % Loop the animation until the escape key is pressed or the play button
  % is pressed
  play_pressed = false;
  
  while ~hit_escape && ~play_pressed
    hit_escape = KbCheck;
    if strcmp(input_mode, 'touch')
      self = process_touch_events(self);

    elseif strcmp(input_mode, 'mouse')
      % Get the position of the mouse
      [x, y, buttons] = GetMouse(screenId);
    
      % if there is a click, see if it happens in the target area
      if buttons(1)
        self.curs_active(1).x = x;
        self.curs_active(1).y = y;
        self.curs_active(1).type = 2; 
      else
        self.curs_active = [];
      end
    end
    
    for id = 1:length(self.curs_active)
      [play_pressed, ~, ~] = check_if_click_in_rect([self.curs_active(id).x, self.curs_active(id).y], startRect);
      if play_pressed
        break
      end
    end
  end
  
  if strcmp(input_mode, 'touch')
    wrapup_touch(self);
  end

  % Clear the screen
  Screen('FillRect', self.w, [0 0 0]);
  Screen('Flip', self.w, 0, 0);
catch
  TouchQueueRelease(self.dev);
  RestrictKeysForKbCheck([]);
  sca;
  psychrethrow(psychlasterror);
end

%% INITIALIZE SOME VARIABLES
self.target_index = 1;
self.next_break_trl = params.break_trl;
self.block_ix = 1;
self.trials_correct = 0;
self.state = 'ITI';
self.state_start = GetSecs;
self.ITI = 0;
self.trials_started = 0;
self.active_target_position = [nan nan];
self.t_next_update = GetSecs + update_interval;
self.data_ix = 0;
self.seq_completion_time = [];

data = [];

if self.is_buttonPort
  flush(self.buttonPort);
end

if self.is_iscanPort
  writeline(self.iscanPort, 'e');
  WaitSecs(1);
  writeline(self.iscanPort, 's');
end

%% START THE GAME
if ~hit_escape
  try
    if strcmp(params.input_mode, 'touch')
      initialize_touch(self);
    end
    
      % initialize struct for tracking active touch points:
    self.curs_active = [];
    self.curs_id_min = inf;
  
    % Only ESCape allows to exit the game:
    RestrictKeysForKbCheck(KbName('ESCAPE'));
  
    % Loop the animation until the escape key is pressed or the exit buttons
    % are pressed
    while ~strcmp(self.state, 'end_game')
      if GetSecs > self.t_next_update
        self.t_next_update = GetSecs + update_interval;
        if strcmp(params.input_mode, 'touch')
          self = process_touch_events(self);
    
        elseif strcmp(params.input_mode, 'mouse')
          % Get the position of the mouse
          [x, y, buttons] = GetMouse(screenId);
        
          % if there is a click, see if it happens in the target area
          if buttons(1)
            self.curs_active(1).x = x;
            self.curs_active(1).y = y;
            self.curs_active(1).id = 1;
            self.curs_active(1).type = 2; 
          else
            self.curs_active = [];
          end
        end
        
        % Run the update function
        self = update(self, params);
        
        % collect the data
        [self, data] = collect_data(self, data);
      end
    end
    
    if strcmp(params.input_mode, 'touch')
      wrapup_touch(self);
    end
  catch
    % Save the data
    raw = data;
    raw.cursor = pix2cm_batch(raw.cursor, self.res);
    raw.target_pos = pix2cm_batch(raw.target_pos, self.res);
    save([filename '.mat'], 'raw', '-v7.3');
    
    TouchQueueRelease(self.dev);
    RestrictKeysForKbCheck([]);
    sca;
    psychrethrow(psychlasterror);
  end
  
  %% STOP THE ISCAN, KINEMATIC CAMERAS, AND AUDIO
  % Stop playback: Stop immediately, but wait for stop to happen:
  if self.is_audioPort
    PsychPortAudio('Stop', self.pahandle, 0, 1);
  end

  % Stop kinematic cameras
  if self.is_camtrigPort
    IOPort('Write', self.camtrigPort, '0', 0);
%     writeline(self.camtrigPort, '0');
  end

  % Stop ISCAN recording
  if self.is_iscanPort
%     IOPort('Write', self.iscanPort, 'e', 0);
    writeline(self.iscanPort, 'e');
  end
  
  %% DISPLAY THE SESSION SUMMARY SCREEN AND SAVE THE DATA
  stats_title = {'Trials Started: ', 'Trials Correct: ', 'Percent Correct: ', ...
    'Target Hold Time: ', 'Target Radius: ', 'Max Reward Time: '};
  stats_str{1} = num2str(self.trials_started);
  stats_str{2} = num2str(self.trials_correct);
  stats_str{3} = [num2str(round(100*self.trials_correct/self.trials_started)) ' %'];
  stats_str{4} = [num2str(params.effective_target_hold_time) ' sec'];
  stats_str{5} = [num2str(params.target_rad) ' cm'];
  stats_str{6} = [num2str(params.last_targ_reward) ' sec'];
  
  x_stat_title = cm2pix(-10, self.res) + self.res.width/2;
  x_stat_str = cm2pix(10, self.res) + self.res.width/2;
  y_stat = linspace(-height_mm/20+7, height_mm/20-5, length(stats_title));
  
  Screen('TextSize', self.w, round(cm2pix(1, self.res)));
  for s = 1:length(stats_title)
    DrawFormattedText(self.w, stats_title{s}, ...
      x_stat_title, cm2pix(y_stat(s), self.res) + self.res.height/2, [0.5 0.5 0.5]);
    DrawFormattedText(self.w, stats_str{s}, ...
      x_stat_str, cm2pix(y_stat(s), self.res) + self.res.height/2, [0.5 0.5 0.5]);
  end
  
  % DRAW THE SAVING HEADER
  Screen('TextSize', self.w, round(cm2pix(3, self.res))); % make the welcome line really big
  DrawFormattedText(self.w, 'SAVING DATA. DO NOT QUIT!', ...
    'center', cm2pix(-height_mm/20+5, self.res) + self.res.height/2, [1 0 0]);
  
  % Flip to the screen
  Screen('Flip', self.w, 0, 0, 1);
  
  % Save the data
  raw = data;
  raw.cursor = pix2cm_batch(raw.cursor, self.res);
  raw.target_pos = pix2cm_batch(raw.target_pos, self.res);
  save([filename '.mat'], 'raw', '-v7.3');
  
  % Rewrite the stats but change the header to allow for quitting
  Screen('TextSize', self.w, round(cm2pix(1, self.res)));
  for s = 1:length(stats_title)
    DrawFormattedText(self.w, stats_title{s}, ...
      x_stat_title, cm2pix(y_stat(s), self.res) + self.res.height/2, [0.5 0.5 0.5]);
    DrawFormattedText(self.w, stats_str{s}, ...
      x_stat_str, cm2pix(y_stat(s), self.res) + self.res.height/2, [0.5 0.5 0.5]);
  end
  
  if self.idle
    % DRAW THE SAVING HEADER
    Screen('TextSize', self.w, round(cm2pix(3, self.res))); % make the welcome line really big
    DrawFormattedText(self.w, 'DONE SAVING (OK TO QUIT)', ...
      'center', cm2pix(-height_mm/20+5, self.res) + self.res.height/2, [0 1 0]);
    
    draw_pd_and_exit_targs(self, params);
    
    % Flip to the screen
    Screen('Flip', self.w, 0, 0, 1);
    
    % wait for exit buttons to be pressed
    try
      if strcmp(params.input_mode, 'touch')
        initialize_touch(self);
      end
      
      % initialize struct for tracking active touch points:
      self.curs_active = [];
      self.curs_id_min = inf;
    
      % Only ESCape allows to exit the game:
      RestrictKeysForKbCheck(KbName('ESCAPE'));
    
      % Loop the animation until the escape key is pressed or the exit buttons
      % are pressed
      exit_pressed = false;
    
      while ~KbCheck && ~exit_pressed
        if strcmp(params.input_mode, 'touch')
          self = process_touch_events(self);
    
        elseif strcmp(params.input_mode, 'mouse')
          % Get the position of the mouse
          [x, y, buttons] = GetMouse(screenId);
        
          % if there is a click, see if it happens in the target area
          if buttons(1)
            self.curs_active(1).x = x;
            self.curs_active(1).y = y;
            self.curs_active(1).type = 2; 
          else
            self.curs_active = [];
          end
        end
        
        [exit_pressed, self] = exit_buttons_held(self, params);
      end
    
      if strcmp(params.input_mode, 'touch')
        wrapup_touch(self);
      end
    
      RestrictKeysForKbCheck([]);
      sca;
    catch
      TouchQueueRelease(self.dev);
      RestrictKeysForKbCheck([]);
      sca;
      psychrethrow(psychlasterror);
    end
  else
    sca;
  end
else
  sca;
end

close_serial_ports(self, params);


%%%%%%%%%%%%%%%%%%%%%%%%%%%% SUBFUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%





%% SCREEN COORDINATE TRANSFORMATIONS
function pos_cm = pix2cm(pos_pix, res)
  % convert from pixels to cm
  pos_pix(1) = pos_pix(1) - res.width/2;
  pos_pix(2) = res.height/2 - pos_pix(2);
  
  pos_cm = pos_pix*(1/res.pix_per_cm);
end

function pos_cm = pix2cm_batch(pos_pix, res)
  ndims = length(size(pos_pix));
  xydim = find(size(pos_pix) == 2);
  assert(length(xydim) == 1);
  repdim = find(~ismember(1:ndims, xydim));

  % convert from pixels to cm
  if ndims == 2
    if repdim == 1
      pos_pix(:, 1) = pos_pix(:, 1) - res.width/2;
      pos_pix(:, 2) = res.height/2 - pos_pix(:, 2);
    elseif repdim == 2
      pos_pix(1, :) = pos_pix(1, :) - res.width/2;
      pos_pix(2, :) = res.height/2 - pos_pix(2, :);
    end
  elseif ndims == 3
    if all(repdim == [2 3])
      pos_pix(1, :, :) = pos_pix(1, :, :) - res.width/2;
      pos_pix(2, :, :) = res.height/2 - pos_pix(2, :, :);
    end
  end
  
  pos_cm = pos_pix.*(1/res.pix_per_cm);
end

function pos_pix = cm2pix(pos_cm, res)
  % convert from pixels to cm
  pos_pix = pos_cm*res.pix_per_cm;
  if size(pos_cm, 2) == 2
    pos_pix(:, 1) = pos_pix(:, 1) + res.width/2;
    pos_pix(:, 2) = res.height/2 - pos_pix(:, 2);
  end
end

%% CURSOR CLASSIFICATION FUNCTIONS
function flag = check_if_click_in_targ(mouse_pos, targ_pos, targ_rad)
  if isempty(mouse_pos) || (length(mouse_pos) == 1 && isempty(mouse_pos.x))
    flag = false;
  elseif isstruct(mouse_pos)
    x = [mouse_pos.x]';
    y = [mouse_pos.y]';
    curs_pos = [x y];
    flag = any(sqrt(sum((curs_pos-targ_pos).^2, 2)) <= targ_rad);
  else
    flag = sqrt(sum((mouse_pos-targ_pos).^2, 2)) <= targ_rad;
  end
end

function [flag, i, j] = check_if_click_in_rect(mouse_pos, rect)
  if size(rect, 1) == 1 || size(rect, 2) == 1
    flag = mouse_pos(1)>= rect(1) && mouse_pos(1)< rect(3) && ...
      mouse_pos(2)>= rect(2) && mouse_pos(2)< rect(4);
    i = 1;
    j = 1;
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
function targpos = get_targpos_from_str(pos_str, center_position, grid_spacing, nudge_x)
  x = nan;
  y = nan;
  if strcmp(pos_str, 'upper_left')
    x = center_position(1) - grid_spacing + nudge_x;
    y = center_position(2) + grid_spacing;
  elseif strcmp(pos_str, 'upper_middle')
    x = center_position(1) + nudge_x;
    y = center_position(2) + grid_spacing;
  elseif strcmp(pos_str, 'upper_right')
    x = center_position(1) + grid_spacing + nudge_x;
    y = center_position(2) + grid_spacing;
  elseif strcmp(pos_str, 'middle_left')
    x = center_position(1) - grid_spacing + nudge_x;
    y = center_position(2);
  elseif strcmp(pos_str, 'center')
    x = center_position(1)+nudge_x;
    y = center_position(2);
  elseif strcmp(pos_str, 'middle_right')
    x = center_position(1) + grid_spacing + nudge_x;
    y = center_position(2);
  elseif strcmp(pos_str, 'lower_left')
    x = center_position(1) - grid_spacing + nudge_x;
    y = center_position(2) - grid_spacing;
  elseif strcmp(pos_str, 'lower_middle')
    x = center_position(1) + nudge_x;
    y = center_position(2) - grid_spacing;
  elseif strcmp(pos_str, 'lower_right')
    x = center_position(1) + grid_spacing + nudge_x;
    y = center_position(2) - grid_spacing;
  end

  targpos = [x y];
end

function [self, params] = make_random_sequence(self, params, change_string, output_pos_px)
  rng('shuffle');
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
  
  if output_pos_px
    self.target_positions_cm = [params.target1_position; ...
      params.target2_position; ...
      params.target3_position; ...
      params.target4_position; ...
      params.target5_position];
    self.target_positions_px = cm2pix(self.target_positions_cm, self.res);
  end
end

%% TOUCH HANDLING SUBFUNCTIONS
function initialize_touch(self)
%   No place for you, little mouse cursor:
  HideCursor(self.w);

  % Create and start touch queue for window and device:
  TouchQueueCreate(self.w, self.dev);
  TouchQueueStart(self.dev);
  
  % Wait for the go!
  KbReleaseWait;
end

function self = process_touch_events(self)
  % Process all currently pending touch events:
  while TouchEventAvail(self.dev)
    % Process next touch event 'evt':
    evt = TouchEventGet(self.dev, self.w);
  
    % Touch blob id - Unique in the session at least as
    % long as the finger stays on the screen:
    id = evt.Keycode;
  
    % Keep the id's low, so we have to iterate over less curs_active slots
    % to save computation time:
%     if isinf(self.curs_id_min)
%       self.curs_id_min = id - 1;
%     end
%     id = id - self.curs_id_min;
    if ~isempty(self.curs_active) && any([self.curs_active.id] == id)
      id = find([self.curs_active.id] == id);
    else
      id = length(self.curs_active) + 1;
    end
  
    if evt.Type == 0
      % Not a touch point, but a button press or release on a
      % physical (or emulated) button associated with the touch device:
      continue;
    end
  
    if evt.Type == 1
      % Not really a touch point, but movement of the
      % simulated mouse cursor, driven by the primary
      % touch-point:
      continue;
    end
  
    if evt.Type == 2
      % New touch point
      self.curs_active(id).x = evt.MappedX;
      self.curs_active(id).y = evt.MappedY;
      self.curs_active(id).t = evt.Time;
      self.curs_active(id).dt = 0;
      self.curs_active(id).id = evt.Keycode;
      self.curs_active(id).type = 2;
      self.curs_active(id).t_start = self.curs_active(id).t;
    end
  
    if evt.Type == 3
      % Moving touch point
      self.curs_active(id).x = evt.MappedX;
      self.curs_active(id).y = evt.MappedY;
      self.curs_active(id).dt = ceil((evt.Time - self.curs_active(id).t) * 1000);
      self.curs_active(id).t = evt.Time;
      self.curs_active(id).type = 3;
    end
  
    if evt.Type == 4
      % Touch released - finger taken off the screen
      self.curs_active(id) = [];
    end

%     if evt.Type == 5
%       % Lost touch data for some reason:
%       % Flush screen red for one video refresh cycle.
%       fprintf('Ooops - Sequence data loss!\n');
%       Screen('FillRect', self.w, [1 0 0]);
%       Screen('Flip', self.w);
%       Screen('FillRect', self.w, 0);
%       continue;
%     end
  end
end

function wrapup_touch(self)
  TouchQueueStop(self.dev);
  TouchQueueRelease(self.dev);
  RestrictKeysForKbCheck([]);
  ShowCursor(self.w);
end

%% UPDATE FUNCTION
function self = update(self, params)
  funcs = fieldnames(self.FSM.(self.state));
  for f = 1:length(funcs)
    self.state_length = GetSecs - self.state_start;

    [do_changestate, self] = eval([funcs{f} '(self, params)']);

    if do_changestate
      % run any _end functions from the previous state
      if exist(['xend_' self.state]) == 2
        self = eval(['xend_' self.state '(self, params)']);
      end

      self.prev_state = self.state;
      self.state = self.FSM.(self.state).(funcs{f});
      self.state_start = GetSecs;
      
      % record the time at this point so that we know when this state
      % started and we don't have to wait for the potentially lengthy start
      % function before we get the time for this state
      self.t_update = GetSecs - self.t_start;

      % run any _start functions
      if exist(['xstart_' self.state]) == 2
        self = eval(['xstart_' self.state '(self, params)']);
      end
      
      break
    else
      self.t_update = GetSecs - self.t_start;
      
      % run any _while functions
      if exist(['xwhile_' self.state]) == 2
        self = eval(['xwhile_' self.state '(self, params)']);
      end
    end
  end
end

%% STOP FUNCTIONS
function [flag, self] = stop(self, params)
  if self.trials_correct >= params.max_trials && strcmp(self.state, 'ITI')
    self.idle = true;
    flag = true;
  else
    [flag, self] = exit_buttons_held(self, params);
  end
end

function [flag, self] = exit_buttons_held(self, params)
  exit_touchdur = [0 0];

  for i = 1:2
    % if there is a touch, see if it happens in the exit area
    exit_pressed_i = check_if_click_in_targ(self.curs_active, self.exit_positions_px(i, :), self.exit_radius_px);
  
    if exit_pressed_i
      if self.prev_exit_t(i) == 0
        self.prev_exit_t(i) = GetSecs;
      else
        exit_touchdur(i) = GetSecs - self.prev_exit_t(i);
      end
    else
      self.prev_exit_t(i) = 0;
    end
  end
  
  if all(exit_touchdur > params.exit_hold) || KbCheck
    self.idle = false;
    flag = true;
  else
    flag = false;
  end
end

%% ITI FUNCTIONS
function self = xstart_ITI(self, params)
  % stop camera triggers
  if self.is_camtrigPort
    IOPort('Write', self.camtrigPort, '0', 0);
%     writeline(self.camtrigPort, '0');
  end
  
  % Make the photodiode intermediate color
  self.pdColor = [0.75 0.75 0.75];
  
  Screen('FillRect', self.w, [0 0 0]);
  draw_trial_counter(self, params)
  draw_pd_and_exit_targs(self, params);

  % Flip to the screen
  Screen('Flip', self.w, 0, 0, 1);
end


function [flag, self] = end_ITI(self, params)
  flag = self.state_length > self.ITI;
end

%% TASKBREAK FUNCTIONS
function self = xstart_taskbreak(self, params)
  if params.break_trl == 0
    self.this_breakdur = 0;
  else
    if self.trials_correct == self.next_break_trl
      % Play the doorbell sound
      self = playsound(self, 4);

      % set the duration of the break
      self.this_breakdur = params.break_dur;
      self.next_break_trl = self.next_break_trl + params.break_trl;
      self.block_ix = self.block_ix + 1;
    else
      self.this_breakdur = 0;
    end
  end

  % do some stuff that is really just prep for each trial and not related
  % to breaks
  self.trials_started = self.trials_started + 1;

  self.first_target_attempt = true;
  self.first_time_for_this_targ = true;

  self.target_index = 1;

  % Set ITI and hold times for this trial
  self.ITI = normrnd(params.ITI_mean, params.ITI_std);

  if length(params.effective_target_hold_time) == 2
    self.tht = min(params.effective_target_hold_time) + rand*range(params.effective_target_hold_time);
  else
    self.tht = params.effective_target_hold_time;
  end

  if length(params.effective_button_hold_time) == 2
    self.bht = min(params.effective_button_hold_time) + rand*range(params.effective_button_hold_time);
  else
    self.bht = params.effective_button_hold_time;
  end
  
  % Set the threshold for reward scaling
  if strcmp(params.rew_scale_method, 'adaptive') && self.block_ix >= 2
    self.time_thresh_for_max_rew = norminv(params.max_rew_pthresh, ...
      mean(self.seq_completion_time), std(self.seq_completion_time));
    self.time_thresh_for_min_rew = norminv(params.min_rew_pthresh, ...
      mean(self.seq_completion_time), std(self.seq_completion_time));
    
    fprintf(['Maximum reward threshold is: ' num2str(self.time_thresh_for_max_rew) '\n']);
  end

  % Get the position of random targets
  if isstr(params.seq) && contains(params.seq, {'randevery', 'center out', 'button out'})
    [self, params] = make_random_sequence(self, params, false, true);
  elseif strcmp(params.seq, 'rand5-randevery')
    if rem(self.block_ix, 2) == 1 && self.block_ix > 2
      params.target1_pos_str = 'random';
      params.target2_pos_str = 'random';
      params.target3_pos_str = 'random';
      params.target4_pos_str = 'random';
      params.target5_pos_str = 'random';
      [self, params] = make_random_sequence(self, params, false, true);
    else
      self.target_positions_px = self.target_positions_px_og;
    end
  elseif strcmp(params.seq, '2seq-repeat')
    if rem(self.block_ix, 2) == 0
      % sequence 2
      self.target_positions_px = self_seq2.target_positions_px;
    else
      % sequence 1
      self.target_positions_px = self.target_positions_px_og;
    end
  end
end

function [flag, self] = end_taskbreak(self, params)
  if self.this_breakdur > 0 && self.state_length > self.this_breakdur
    % play doorbell sound
    self = playsound(self, 4);
  end
  flag = self.state_length > self.this_breakdur;
end

%% VIDEO TRIGGER FUNCTIONS
function self = xstart_vid_trig(self, params)
  if self.trials_started == 0
    WaitSecs(1);
  end

  % write '1' to camera arduino to start taking pics at 50hz
  if self.is_camtrigPort
    IOPort('Write', self.camtrigPort, '1', 0);
%     writeline(self.camtrigPort, '1');
  end
end

function [flag, self] = end_vid_trig(self, params)
  flag = self.state_length > 0.1;
end

%% BUTTON FUNCTIONS 
function self = xstart_button(self, params)
  % Make the photodiode dark color
  self.pdColor = [0 0 0];
  
  Screen('FillRect', self.w, [0 0 0]);
  draw_trial_counter(self, params)
  draw_target_outlines(self, params);
  draw_pd_and_exit_targs(self, params);

  % Flip to the screen
  Screen('Flip', self.w, 0, 0, 1);
end

function [flag, self] = button_pressed(self, params)
  if ~self.use_button || ~self.is_buttonPort
    flag = true;
  else
    % flush the button port and then read the most recent value
    flush(self.buttonPort);
    button_data = readline(self.buttonPort);

    % determine if the values indicate a button press or not
    if strcmp(params.button_version, 'fsr')
      % fixme
    elseif strcmp(params.button_version, 'ir')
      if strcmp(button_data, '1')
        flag = true;
      else
        flag = false;
      end
    end
  end
end

function self = xstart_button_hold(self, params)
  self.t_button_hold_start = GetSecs;
  
  % Make the photodiode bright
  self.pdColor = [0 0 0];
  
  Screen('FillRect', self.w, [0 0 0]);
  draw_trial_counter(self, params)
  draw_target_outlines(self, params);
  draw_pd_and_exit_targs(self, params);

  % Flip to the screen
  Screen('Flip', self.w, 0, 0, 1);
end

function [flag, self] = finish_button_hold(self, params)
  if ~self.use_button || ~self.is_buttonPort
    flag = true;
  else
    if GetSecs - self.t_button_hold_start > self.bht
      % play the button reward sound
      self = playsound(self, 3);

      % give a juice reward
      if self.do_rewardButton
        run_button_rew(self, params)
      end
      flag = true;
    else
      flag = false;
    end
  end
end

function [flag, self] = early_leave_button_hold(self, params)
  if ~self.use_button || ~self.is_buttonPort
    flag = false;
  else
    if button_pressed(self, params)
      flag = false;
    else
      flag = true;
    end
  end
end

%% TARGET FUNCTIONS
function self = xstart_target(self, params)
  if self.first_time_for_this_targ
    self.t_this_targ_start = GetSecs;

    if self.target_index == 1
      self.t_target1_on = self.t_this_targ_start;
    end
  end

  % keep track of whether this target has been plotted yet
  self.this_targ_drawn = false;

  % We need to plot a new target if this is the first time start_target has
  % been run for this target or if the previous state was a target hold
  % state (implying that we just came off of a hold error)
  if self.first_time_for_this_targ || strcmp(self.prev_state, 'targ_hold')
    Screen('FillRect', self.w, [0 0 0]);

    self.active_target_position = self.target_positions_px(self.target_index, :);
    self.targRectCent = CenterRectOnPointd(self.targRect, ...
      self.target_positions_px(self.target_index, 1), self.target_positions_px(self.target_index, 2));
    Screen('FillOval', self.w, self.targColor, self.targRectCent, self.targDiameter);

    if params.intertarg_delay == 0
      % Photodiode depends on the target index
      if rem(self.target_index, 2) == 1
        self.pdColor = [1 1 1];
      else
        self.pdColor = [0 0 0];
      end
    else
      self.pdColor = [0 0 0];
    end
    
    draw_trial_counter(self, params)
    draw_target_outlines(self, params);
    draw_pd_and_exit_targs(self, params);
  
    % Flip to the screen
    Screen('Flip', self.w, 0, 0, 1);

    self.this_targ_drawn = true;

    if self.first_time_for_this_targ && self.target_index ~= 1
      % play the target hold reward sound
      self = playsound(self, 2);
    end
  end
  
  % First time for this targ should only be turned to true by other
  % functions
  self.first_time_for_this_targ = false;
end

function self = xwhile_target(self, params)
  if ~self.this_targ_drawn
    if params.intertarg_delay ~= 0
      % check and see if it is time for this target to appear
      if self.target_index == 1 || ...
          GetSecs - self.t_this_targ_start >= params.intertarg_delay

        Screen('FillRect', self.w, [0 0 0]);

        self.targRectCent = CenterRectOnPointd(self.targRect, ...
          self.target_positions_px(self.target_index, 1), self.target_positions_px(self.target_index, 2));
        Screen('FillOval', self.w, self.targColor, self.targRectCent, self.targDiameter);

        % make photodiode dark
        self.pdColor = [0 0 0];
        
        draw_trial_counter(self, params)
        draw_target_outlines(self, params);
        draw_pd_and_exit_targs(self, params);

        % Flip to the screen
        Screen('Flip', self.w, 0, 0, 1);

        self.this_targ_drawn = true;
      end
    end
  
    if params.time_to_next_targ ~= false
      % check and see if it is time for the next target to appear
      if GetSecs - self.t_this_targ_start > params.time_to_next_targ && ...
          self.target_index < self.num_targets
        % FIXME
      end
    end
  end
end

function [flag, self] = touch_target(self, params)
  % if there is a touch, see if it happens in the target area
  if ~(params.effective_target_hold_time == 0 && self.target_index ~= self.num_targets)
    if params.drag_ok
      flag = check_if_click_in_targ(self.curs_active, self.target_positions_px(self.target_index, :), self.effective_target_rad_px);
    else
      % fixme
    end
  else
    flag = false;
  end
end

function [flag, self] = touch_target_nohold(self, params)
  % this function combines touch_target and finish_targ_hold so that the
  % entire targ_hold state can be skipped to save time

  if params.effective_target_hold_time == 0 && self.target_index ~= self.num_targets
    if params.drag_ok
      flag = check_if_click_in_targ(self.curs_active, self.target_positions_px(self.target_index, :), self.effective_target_rad_px);
    else
      % fixme
    end
    
    if flag
      if self.target_index == 1
        self.t_target1_touch = GetSecs;
      end
      
      % advance the target index
      self.target_index = self.target_index + 1;

      % reset the first_time_for_this_targ flag (for the next target)
      self.first_time_for_this_targ = true;
    end
  else
    flag = false;
  end
end

function [flag, self] = target_timeout(self, params)
  if self.target_index == 1
    flag = GetSecs - self.t_this_targ_start > params.target1_timeout_time;
  else
    flag = GetSecs - self.t_this_targ_start > params.target_timeout_time;
  end
end

%% TARGET HOLD FUNCTIONS
function self = xstart_targ_hold(self, params)
  if self.tht > 0
    Screen('FillRect', self.w, [0 0 0]);

    % make the target green
    Screen('FillOval', self.w, [0 1 0], self.targRectCent, self.targDiameter);

    self.pdColor = [1 1 1];
    
    draw_trial_counter(self, params)
    draw_target_outlines(self, params);
    draw_pd_and_exit_targs(self, params);

    % Flip to the screen
    Screen('Flip', self.w, 0, 0, 1);
  end
end

function [flag, self] = finish_targ_hold(self, params)
  if self.target_index ~= self.num_targets
    if self.tht <= self.state_length
      if self.target_index == 1
        self.t_target1_touch = GetSecs;
      end
      
      % advance the target index
      self.target_index = self.target_index + 1;

      % reset the first_time_for_this_targ flag (for the next target)
      self.first_time_for_this_targ = true;

      flag = true;
    else
      flag = false;
    end
  else
    flag = false;
  end
end

function [flag, self] = finish_last_targ_hold(self, params)
  if self.target_index == self.num_targets
    if self.tht <= self.state_length
      flag = true;
      self.trial_completion_time = GetSecs - self.t_target1_on;
      self.seq_completion_time(end+1) = GetSecs - self.t_target1_touch;
    else
      flag = false;
    end
  else
    flag = false;
  end
end

function [flag, self] = early_leave_target_hold(self, params)
  flag = ~check_if_click_in_targ(self.curs_active, self.target_positions_px(self.target_index, :), self.effective_target_rad_px);
end

function [flag, self] = targ_drag_out(self, params)
  % fixme
end

%% REWARD FUNCTIONS
function self = xstart_reward(self, params)
  self.trials_correct = self.trials_correct + 1;
  self.t_reward_start = GetSecs;

  % play the correct trial reward sound
  self = playsound(self, 1);
  
  if params.intertarg_delay ~= 0 || rem(self.num_targets, 2) == 0
    self.pdColor = [1 1 1];
  elseif rem(self.num_targets, 2) == 1
    self.pdColor = [0 0 0];
  end

  % make the screen white and draw the photodiode
  Screen('FillRect', self.w, [1 1 1]);
  Screen('FillOval', self.w, self.pdColor, self.pdRect, self.pdDiameter);
  Screen('Flip', self.w, 0, 0, 1);

  % dispense the juice reward
  if self.do_rewardScaling 
    if strcmp(params.rew_scale_method, 'absolute')
      if self.trial_completion_time < self.time_thresh_for_max_rew
        rew_time = params.last_targ_reward;
      else
        rew_time = params.min_targ_reward;
      end
    elseif strcmp(params.rew_scale_method, 'adaptive')
      if self.seq_completion_time(end) < self.time_thresh_for_max_rew
        rew_time = params.last_targ_reward;
      else
        rew_time = params.min_targ_reward;
      end
    end
  else
    rew_time = params.last_targ_reward;
  end
  write_juice_reward(self, params, rew_time);
end

function [flag, self] = end_reward(self, params)
  flag = GetSecs - self.t_reward_start >= params.reward_dur;
end

%% TIMEOUT FUNCTIONS
function self = xstart_timeout_error(self, params)
  % make the screen black
  Screen('FillRect', self.w, [0 0 0]);
  Screen('Flip', self.w, 0, 0, 1);
end

function [flag, self] = end_timeout_error(self, params)
  flag = self.state_length >= params.timeout_error_timeout;
end

function self = xstart_hold_error(self, params)
  % make the screen black
  Screen('FillRect', self.w, [0 0 0]);
  Screen('Flip', self.w, 0, 0, 1);
end

function [flag, self] = end_hold_error(self, params)
  flag = self.state_length >= params.hold_error_timeout;
end

function self = xstart_drag_error(self, params)
  % make the screen black
  Screen('FillRect', self.w, [0 0 0]);
  Screen('Flip', self.w, 0, 0, 1);
end

function [flag, self] = end_drag_error(self, params)
  flag = self.state_length >= params.drag_error_timeout;
end

%% BASIC DRAWING SHORTCUTS
function draw_pd_and_exit_targs(self, params)
  % Draw the exit and PD targets
%   Screen('FillOval', self.w, self.exitColor, self.exitRect, self.exitDiameter);
  Screen('FrameOval', self.w, self.exitColor, self.exitRect, 2);
  Screen('FillOval', self.w, self.pdColor, self.pdRect, self.pdDiameter);
end

function draw_trial_counter(self, params)
  Screen('TextSize', self.w, round(cm2pix(1, self.res)));
  DrawFormattedText(self.w, num2str(self.trials_correct), ...
    self.trlcnt_position_px(1), self.trlcnt_position_px(2), [0.15 0.15 0.15]);
end

function draw_target_outlines(self, params)
  % draw the outlines
  if params.display_outlines
    Screen('FrameOval', self.w, self.targColor, self.outlinesRect, params.outlineWidth);
  end
end

%% SOUND PLAYING SHORTCUT
function self = playsound(self, sound_ix)
  if self.is_audioPort
    % Query current playback status:
    self.soundstatus = PsychPortAudio('GetStatus', self.pahandle);
    
    % Engine still running on a schedule?
    if self.soundstatus.Active == 1
      PsychPortAudio('Stop', self.pahandle, 0, 1);
    end
    %   if self.soundstatus.Active == 0
    % Schedule finished, engine stopped. Before adding new
    % slots we first must delete the old ones, ie., reset the
    % schedule:
    PsychPortAudio('UseSchedule', self.pahandle, 2);
  
    %   end
    % Add new slot with playback request for user-selected buffer
    % to a still running or stopped and reset empty schedule. This
    % time we select one repetition of the full soundbuffer:
    PsychPortAudio('AddToSchedule', self.pahandle, self.sounds(sound_ix), 1, 0, [], 1);
  
    %   if self.soundstatus.Active == 0
    %     % If engine has stopped, we need to restart:
    PsychPortAudio('Start', self.pahandle, [], 0, 1);
    %   end
  end
end

%% REWARD DISPENSING
function write_juice_reward(self, params, rew_time)
  if self.is_rewardPort
    volume2dispense = rew_time*50/60; % mL/min x 1 min/60 sec --> sec x mL/sec
    rew_str = sprintf('VOL %0.1f', volume2dispense);
%     IOPort('Write', self.rewardPort, rew_str, 1);
    writeline(self.rewardPort, rew_str);
    WaitSecs(0.05);
%     IOPort('Write', self.rewardPort, 'RUN', 1);
    writeline(self.rewardPort, 'RUN');
  end
end

%% CLOSE SERIAL PORTS
function close_serial_ports(self, params)
  IOPort('CloseAll');
  fprintf('DONE.\n');
end


%% DATA COLLECTION
function [self, data] = collect_data(self, data)
  % collect the data
  self.data_ix = self.data_ix+1;

  data.state{self.data_ix} = self.state;
  if isempty(self.curs_active)
    data.cursor(:, :, self.data_ix) = nan(2, 10);
    data.cursor_ids(:, self.data_ix) = nan(10, 1);
  else
    data.cursor(:, :, self.data_ix) = [[[self.curs_active.x]; [self.curs_active.y]] nan(2, 10-length(self.curs_active))];
    data.cursor_ids(:, self.data_ix) = [[self.curs_active.id]'; nan(10-length(self.curs_active), 1)];
  end
  data.target_pos(:, self.data_ix) = self.active_target_position';
  data.time(self.data_ix) = self.t_update;

  % Send DIO trigger
  if self.is_dioPort
    % FIXME: need to figure out how to send self.data_ix information
    IOPort('Write', self.dioPort, ['d', lower(dec2hex(rem(self.data_ix, 10)))], 0);
%     IOPort('Write', self.dioPort, ['d', char(rem(self.data_ix, 255))], 0);
    %           writeline(self.dioPort, 'd');
  end
end


