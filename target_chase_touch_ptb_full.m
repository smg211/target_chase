cd('C:\Users\sando\Documents\target_chase')

% Clear the workspace and the screen
sca;
close all;
clear;

Screen('Preference', 'ConserveVRAM', 4096);
Screen('Preference', 'SkipSyncTests', 1);

self = [];
self.t_start = GetSecs;

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
  data_path = [pwd filesep];
end

% Here we call some default settings for setting up Psychtoolbox
PsychDefaultSetup(2);

% If no user-specified 'dev' was given, try to auto-select:
self.dev = [];
if isempty(self.dev)
  % Get first touchscreen:
  self.dev = min(GetTouchDeviceIndices([], 1));
end

if isempty(self.dev)
  % Get first touchpad:
  self.dev = min(GetTouchDeviceIndices([], 0));
end

if isempty(self.dev) || ~ismember(self.dev, GetTouchDeviceIndices)
  fprintf('No touch input device found, or invalid dev given. Using mouse instead.\n');
  input_mode = 'mouse';
else
  fprintf('Touch device properties:\n');
  input_mode = 'touch';
  info = GetTouchDeviceInfo(self.dev);
  disp(info);
end

% Get the screen numbers
screens = Screen('Screens');

% Draw to the external screen if avaliable
screenId = max(screens);

% Get the screen size and resolution
[width_mm, height_mm] = Screen('DisplaySize', screenId);
self.res = Screen('Resolution', screenId);
self.res.pix_per_cm = round(10*min([self.res.width/width_mm self.res.height/height_mm]));

% Define black and white
white = WhiteIndex(screenId);
black = BlackIndex(screenId);

% Open an on screen window
[self.w, rect] = PsychImaging('OpenWindow', screenId, black);
self.baseSize = RectWidth(rect) / 20;

% Query the frame duration
% ifi = Screen('GetFlipInterval', self.w);
ifi = 1/120;

% Sync us and get a time stamp
Screen('Flip', self.w);
waitframes = 1;

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
row_height = self.res.height/n_rows;
row_edges = 0:row_height:self.res.height;
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
  title_x = 0.2*self.res.width;
  title_rect = [row_bg_rect(1:2, :); repmat(title_x, 1, n_rows); row_bg_rect(4, :)];
  Screen('TextSize', self.w, round(0.75*row_height)); % make the titles medium sized
  for p = 1:n_params_shown
    DrawFormattedText(self.w, param_info(i_params_shown(p)).title, ...
      'right', 'center', [1 1 0], [], 0, 0, 1, 0, title_rect(:, p+1)');
  end

  % With the remaining right half of the screen, make a n_row x 10 grid and
  % fill the options into each point on the grid. If there are more than 10
  % options, then space the options evenly
  Screen('TextSize', self.w, round(0.4*row_height)); % make the options small sized
  opt_chosen = zeros(1, n_params_shown);
  opts_rect = nan(n_params_shown, max_opts, 4);
  for p = 1:n_params_shown
    if param_info(i_params_shown(p)).Nopts <= 10
      n_win = 10;
    else
      n_win = param_info(i_params_shown(p)).Nopts;
    end
    opts_edges = linspace(title_x, self.res.width, n_win+2);
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
  
  while ~KbCheck && ~play_pressed
    if strcmp(input_mode, 'touch')
      self = process_touch_events(self);

    elseif strcmp(input_mode, 'mouse')
      % Get the position of the mouse
      [x, y, buttons] = GetMouse(screenId);
    
      % if there is a click, see if it happens in the target area
      if buttons(1)
        self.curs_active{1}.x = x;
        self.curs_active{1}.y = y;
        self.curs_active{1}.type = 2; 
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
        if all(opt_chosen(find([param_info.require_selection])) > 0)
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
  Screen('Flip', self.w, 0, 0);
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
  self.do_rewardButton = true;
else
  self.do_rewardButton = false;
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

%% SETUP THE SERIAL COMMUNICATION PORTS
% Juicer
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
    self.rewardPort = serialport(prolific_com, 19200);

    % Setup the flow rate
    writeline(self.rewardPort, 'VOL 0.5');
    writeline(self.rewardPort, 'VOL ML');
    writeline(self.rewardPort, 'RAT 50MM');
  end

  self.is_rewardPort = true;
catch
  self.is_rewardPort = false;
end

% DIO
try
  self.dioPort = serialport('COM3', 115200);
  self.is_dioPort = true;
catch
  self.is_dioPort = false;
end

% Camera Triggers
try
  self.camtrigPort = serialport('COM3', 9600);
  
  % say hello
  writeline(self.camtrigPort, 'a');

  % start cams at 50 Hz
  writeline(self.camtrigPort, '1');

  self.is_camtrigPort = true;
catch
  self.is_camtrigPort = false;
end

% Eyetracker Triggers
try
  self.iscanPort = serialport('COM3', 115200);

  % send start recording trigger
  writeline(self.iscanPort, 's');

  self.is_iscanPort = true;
catch
  self.is_iscanPort = false;
end

% External Button
try
  self.buttonPort = serialport('COM3', 9600);
  
  self.is_buttonPort = true;
catch
  self.is_buttonPort = false;
end

%% PREPARE OBJECTS TO BE DISPLAYED
% determine the number of pixels for the effective target radius
self.effective_target_rad_px = cm2pix(params.effective_target_rad, self.res);

% target construction
self.targRect = [0 0 2*self.target_radius_px 2*self.target_radius_px];
self.targDiameter = max(self.targRect) * 1.01;
self.targColor = [1 1 0];

% escape buttons positions: 1.5cm from the right edge and 2.5cm from the
% top/bottom
exit_positions_cm = [width_mm/20 - 1.5, height_mm/20 - 2.5; ...
  width_mm/20 - 1.5, -(height_mm/20 - 2.5)]; 
self.exit_positions_px = cm2pix(exit_positions_cm, self.res);
self.exit_radius_px = cm2pix(1, self.res);

exitRectBase = [0 0 2*self.exit_radius_px 2*self.exit_radius_px];
self.exitDiameter = max(exitRectBase) * 1.01;
for i = 1:2
  self.exitRect(:, i) = CenterRectOnPointd(exitRectBase, ...
    self.exit_positions_px(i, 1), self.exit_positions_px(i, 2));
end
self.exitColor = [0.15 0.15 0.15];

% photodiode position: 1.8 cm from the right edge and 0.5 cm from the top
pd_position_cm = [width_mm/20 - 1.8, -height_mm/20 + 0.5];
self.pd_position_px = cm2pix(pd_position_cm, self.res);
self.pd_radius_px = cm2pix(0.5, self.res);

pdRectBase = [0 0 2*self.pd_radius_px 2*self.pd_radius_px];
self.pdDiameter = max(pdRectBase) * 1.01;
self.pdRect = CenterRectOnPointd(pdRectBase, ...
    self.pd_position_px(1), self.pd_position_px(2));
self.pdColor = [0.75 0.75 0.75];

% Outlines construction
x_cm = params.center_position(1) + -params.grid_spacing:params.grid_spacing:params.grid_spacing;
y_cm = params.center_position(2) + -params.grid_spacing:params.grid_spacing:params.grid_spacing;

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
trlcnt_position_cm = [width_mm/20 - 1.8, height_mm/20 - 0.5];
self.trlcnt_position_px = cm2pix(trlcnt_position_cm, self.res);

%% DATA SAVING
% % when to save
% params.save_state = 'taskbreak';
% params.t_state_save = 5;
% params.save_interval = params.break_dur;

% how frequently to sample the data for storing
params.data_collection_freq = 120;
data_collection_interval = 1/params.data_collection_freq;

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
if false
    wavfilenames = {'reward1.wav', 'reward2.wav', 'C.wav', 'DoorBell.wav'};
    nfiles = length(wavfilenames);
    
    % Always init to 2 channels, for the sake of simplicity:
    nrchannels = 2;
    
    % Perform basic initialization of the sound driver:
    InitializePsychSound(1);
    
    % Open the audio 'device' with default mode [] (== Only playback),
    % and a required latencyclass of 1 == standard low-latency mode, as well as
    % default playback frequency and 'nrchannels' sound output channels.
    % This returns a handle 'pahandle' to the audio device:
    self.pahandle = PsychPortAudio('Open', [], [], 1, [], nrchannels);
    
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
else
    self.is_audioPort = false;
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
% self.t_next_save = GetSecs + params.save_interval;
self.t_next_collect = GetSecs + data_collection_interval;
data_ix = 0;

%% START THE GAME
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
    
    % Run the update function
    self = update(self, params);

    % collect the data
    if GetSecs > self.t_next_collect
      self.t_next_collect = GetSecs + data_collection_interval;

      data_ix = data_ix+1;

      data.state{data_ix} = self.state;
      if isempty(self.curs_active)
        data.cursor(:, :, data_ix) = nan(2, 10);
        data.cursor_ids(:, data_ix) = nan(10, 1);
      else
        data.cursor(:, :, data_ix) = [[[self.curs_active.x]; [self.curs_active.y]] nan(2, 10-length(self.curs_active))];
        data.cursor_ids(:, data_ix) = [[self.curs_active.id]'; nan(10-length(self.curs_active), 1)];
      end
      data.target_pos(:, data_ix) = self.active_target_position';
      data.time(data_ix) = GetSecs - self.t_start;

      % Send DIO trigger
      if self.is_dioPort
        % FIXME: need to figure out how to send data_ix information
        writeline(self.dioPort, ['d' num2str(rem(data_ix, 256))]);
      end
    end

%     if strcmp(self.state, params.save_state) && ...
%         self.state_length > params.t_state_save && ...
%         GetSecs > self.t_next_save
%       raw = data;
%       raw.cursor = pix2cm_batch(raw.cursor, self.res);
%       raw.target_pos = pix2cm_batch(raw.target_pos, self.res);
%       save([filename '.mat'], 'raw', '-v7.3');
% 
%       self.t_next_save = GetSecs + params.save_interval;
%     end
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
  writeline(self.camtrigPort, '0');
end

% Stop ISCAN recording
if self.is_iscanPort
  writeline(self.iscanPort, 'e');
end

%% DISPLAY THE SESSION SUMMARY SCREEN AND SAVE THE DATA
stats_title = {'Trials Started: ', 'Trials Correct: ', 'Percent Correct: ', ...
  'Target Hold Time: ', 'Target Radius: ', 'Max Reward Time: '};
stats_str{1} = num2str(self.trials_started);
stats_str{2} = num2str(self.trials_correct);
stats_str{3} = [num2str(round(100*self.trials_correct/self.trials_started)) ' %'];
stats_str{4} = [num2str(params.target_hold_time) ' sec'];
stats_str{5} = [num2str(params.target_rad) ' cm'];
stats_str{6} = [num2str(params.last_targ_reward) ' sec'];

x_stat_title = cm2pix(-10, self.res) + self.res.width/2;
x_stat_str = cm2pix(10, self.res) + self.res.width/2;
y_stat = linspace(-height_mm/20+7, height_mm/20-5, length(stats_title));

Screen('TextSize', self.w, cm2pix(2, self.res));
for s = 1:length(stats_title)
  DrawFormattedText(self.w, stats_title{s}, ...
    x_stat_title, cm2pix(y_stat(s), self.res) + self.res.height/2, [0.5 0.5 0.5]);
  DrawFormattedText(self.w, stats_str{s}, ...
    x_stat_str, cm2pix(y_stat(s), self.res) + self.res.height/2, [0.5 0.5 0.5]);
end

% DRAW THE SAVING HEADER
Screen('TextSize', self.w, cm2pix(3, self.res)); % make the welcome line really big
DrawFormattedText(self.w, 'SAVING DATA. DO NOT QUIT!', ...
  'center', cm2pix(-height_mm/20+5, self.res) + self.res.height/2, [1 0 0]);

% Flip to the screen
Screen('Flip', self.w, 0);

% Save the data
raw = data;
raw.cursor = pix2cm_batch(raw.cursor, self.res);
raw.target_pos = pix2cm_batch(raw.target_pos, self.res);
save([filename '.mat'], 'raw', '-v7.3');

% Rewrite the stats but change the header to allow for quitting
Screen('TextSize', self.w, cm2pix(2, self.res));
for s = 1:length(stats_title)
  DrawFormattedText(self.w, stats_title{s}, ...
    x_stat_title, cm2pix(y_stat(s), self.res) + self.res.height/2, [0.5 0.5 0.5]);
  DrawFormattedText(self.w, stats_str{s}, ...
    x_stat_str, cm2pix(y_stat(s), self.res) + self.res.height/2, [0.5 0.5 0.5]);
end

if self.idle
  % DRAW THE SAVING HEADER
  Screen('TextSize', self.w, cm2pix(3, self.res)); % make the welcome line really big
  DrawFormattedText(self.w, 'DONE SAVING (OK TO QUIT)', ...
    'center', cm2pix(-height_mm/20+5, self.res) + self.res.height/2, [0 1 0]);
  
  draw_pd_and_exit_targs(self, params);
  
  % Flip to the screen
  Screen('Flip', self.w, 0);
  
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

      % run any _start functions
      if exist(['xstart_' self.state]) == 2
        self = eval(['xstart_' self.state '(self, params)']);
      end

      break
    else
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
    writeline(self.camtrigPort, '0');
  end
  
  % Make the photodiode intermediate color
  self.pdColor = [0.75 0.75 0.75];
  
  Screen('FillRect', self.w, [0 0 0]);
  draw_trial_counter(self, params)
  draw_pd_and_exit_targs(self, params);

  % Flip to the screen
  Screen('Flip', self.w, 0);
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
  
  % don't clear the framebuffer
  self.dontclear = 1;

  % do some stuff that is really just prep for each trial and not related
  % to breaks
  self.trials_started = self.trials_started + 1;

  self.first_target_attempt = true;
  self.first_time_for_this_targ = true;

  self.target_index = 1;

  % Set ITI and hold times for this trial
  self.ITI = normrnd(params.ITI_mean, params.ITI_std);

  if length(params.target_hold_time) == 2
    self.tht = min(params.target_hold_time) + rand*range(params.target_hold_time);
  else
    self.tht = params.target_hold_time;
  end

  if length(params.button_hold_time) == 2
    self.bht = min(params.button_hold_time) + rand*range(params.button_hold_time);
  else
    self.bht = params.button_hold_time;
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
  end
  flag = self.state_length > self.this_breakdur;
end

%% VIDEO TRIGGER FUNCTIONS
function self = xstart_vid_trig(self, params)
  if self.trials_correct == 0
    WaitSecs(1);
  end

  % write '1' to camera arduino to start taking pics at 50hz
  if self.is_camtrigPort
    writeline(self.camtrigPort, '1');
  end

  % don't clear the framebuffer
  self.dontclear = 1;
end

function [flag, self] = end_vid_trig(self, params)
  flag = self.state_length > 0.1;
end

%% BUTTON FUNCTIONS 
function self = xstart_button(self, params)
  self.button_pressed_prev = false;
 
  % Make the photodiode dark color
  self.pdColor = [0 0 0];
  
  Screen('FillRect', self.w, [0 0 0]);
  draw_trial_counter(self, params)
  draw_target_outlines(self, params);
  draw_pd_and_exit_targs(self, params);

  % Flip to the screen
  Screen('Flip', self.w, 0);
end

function [flag, self] = button_pressed(self, params)
  if ~self.use_button || ~self.is_buttonPort
    flag = true;
  else
    % get the button values

    % determine if the values indicate a button press or not
    if strcmp(params.button_version, 'fsr')
      
    elseif strcmp(params.button_version, 'ir')
      
    end
  end
end

function self = xstart_button_hold(self, params)
  self.t_buttonhold_start = GetSecs;
  
  % Make the photodiode bright
  self.pdColor = [0 0 0];
  
  Screen('FillRect', self.w, [0 0 0]);
  draw_trial_counter(self, params)
  draw_target_outlines(self, params);
  draw_pd_and_exit_targs(self, params);

  % Flip to the screen
  Screen('Flip', self.w, 0);
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
      if rem(self.target_index, 2) == 0
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
    Screen('Flip', self.w, 0);

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
        Screen('Flip', self.w, 0);

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
  if ~(params.target_hold_time == 0 && self.target_index ~= self.num_targets)
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

  if params.target_hold_time == 0 && self.target_index ~= self.num_targets
    if params.drag_ok
      flag = check_if_click_in_targ(self.curs_active, self.target_positions_px(self.target_index, :), self.effective_target_rad_px);
    else
      % fixme
    end
    
    if flag
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
    Screen('Flip', self.w, 0);
  end
end

function [flag, self] = finish_targ_hold(self, params)
  if self.target_index ~= self.num_targets
    if self.tht <= self.state_length
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
  
  if params.intertarg_delay ~= 0 || rem(self.num_targets, 2) == 1
    self.pdColor = [1 1 1];
  elseif rem(self.num_targets, 2) == 0
    self.pdColor = [0 0 0];
  end

  % make the screen white and draw the photodiode
  Screen('FillRect', self.w, [1 1 1]);
  Screen('FillOval', self.w, self.pdColor, self.pdRect, self.pdDiameter);
  Screen('Flip', self.w);

  % play the correct trial reward sound
  self = playsound(self, 1);
end

function [flag, self] = end_reward(self, params)
  flag = GetSecs - self.t_reward_start >= params.reward_dur;
end

%% TIMEOUT FUNCTIONS
function self = xstart_timeout_error(self, params)
  % make the screen black
  Screen('FillRect', self.w, [0 0 0]);
  Screen('Flip', self.w);
end

function [flag, self] = end_timeout_error(self, params)
  flag = self.state_length >= params.timeout_error_timeout;
end

function self = xstart_hold_error(self, params)
  % make the screen black
  Screen('FillRect', self.w, [0 0 0]);
  Screen('Flip', self.w);
end

function [flag, self] = end_hold_error(self, params)
  flag = self.state_length >= params.hold_error_timeout;
end

function self = xstart_drag_error(self, params)
  % make the screen black
  Screen('FillRect', self.w, [0 0 0]);
  Screen('Flip', self.w);
end

function [flag, self] = end_drag_error(self, params)
  flag = self.state_length >= params.drag_error_timeout;
end

%% BASIC DRAWING SHORTCUTS
function draw_pd_and_exit_targs(self, params)
  % Draw the exit and PD targets
  Screen('FillOval', self.w, self.exitColor, self.exitRect, self.exitDiameter);
  Screen('FillOval', self.w, self.pdColor, self.pdRect, self.pdDiameter);
end

function draw_trial_counter(self, params)
  Screen('TextSize', self.w, cm2pix(1, self.res));
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