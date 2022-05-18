% Enter all of the info for the parameters you want on the params screen
param_info = [];

param_info(1).title = 'Animal Name';
param_info(1).varname = 'animal_name';
param_info(1).opts_title = {'Haribo', 'Fifi', 'Nike', 'Butters', 'Testing'};
param_info(1).opts_varname = {'Haribo', 'Fifi', 'Nike', 'Butters', 'Testing'};
param_info(1).default_opt = 'Testing';
param_info(1).require_selection = true;
param_info(1).is_hidden = false;

param_info(2).title = 'Juicer Type';
param_info(2).varname = 'juicer';
param_info(2).opts_title = {'Old Yellow', 'New Red'};
param_info(2).opts_varname = {'yellow', 'red'};
param_info(2).default_opt = {'red'};
param_info(2).require_selection = false;
param_info(2).is_hidden = true;

param_info(3).title = 'Button Type';
param_info(3).varname = 'button_version';
param_info(3).opts_title = {'Old FSR', 'New IR'};
param_info(3).opts_varname = {'fsr', 'ir'};
param_info(2).default_opt = 'fsr';
param_info(3).require_selection = true;
param_info(3).is_hidden = false;

param_info(4).title = 'Target 1 Timeout';
param_info(4).varname = 'target1_timeout_time';
param_info(4).opts_title = {'0.8 sec', '1.0 sec', '1.5 sec', '2.0 sec', '2.5 sec', '3.0 sec', '3.5 sec', '4.0 sec', '10.0 sec'};
param_info(4).opts_varname = {0.8, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 10.0};
param_info(4).default_opt = Inf;
param_info(4).require_selection = false;
param_info(4).is_hidden = false;

param_info(5).title = 'Target 2+ Timeout';
param_info(5).varname = 'target_timeout_time';
param_info(5).opts_title = {'0.5 s', '0.6 s', '0.7 s', '0.8 s', '0.9 s', '1.0 s', '1.1 s', '1.2 s', '1.3 s', '1.5 s', '2.0 s', '2.5 s', '3.0 s', '3.5 s', '4.0 s'};
param_info(5).opts_varname = {0.5, 0.6, 0.7, 0.8, 0.9, 1.0, 1.1, 1.2, 1.3, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0};
param_info(5).default_opt = Inf;
param_info(5).require_selection = false;
param_info(5).is_hidden = false;


param_info(6).title = 'Allow Drag';
param_info(6).varname = 'drag_ok';
param_info(6).opts_title = {'YES', 'NO'};
param_info(6).opts_varname = {true, false};
param_info(6).default_opt = true;
param_info(6).require_selection = true;
param_info(6).is_hidden = false;

param_info(7).title = 'Button Hold Time';
param_info(7).varname = 'button_hold_time';
param_info(7).opts_title = {'NO Button', '0.0 sec', '0.1 sec', '0.2 sec', '0.3 sec', '0.4 sec', '0.5 sec', '0.6 sec', '0.7 sec', '0.8 sec', '0.9 sec', '1.0 sec', '0.2-0.4 sec', '0.6-0.8 sec', '0.8-1.0 sec'};
param_info(7).opts_varname = {false, 0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0, '.2-.4', '.6-.8', '.8-1.0'};
param_info(7).default_opt = 1.0;
param_info(7).require_selection = true;
param_info(7).is_hidden = false;

param_info(8).title = 'Button Reward';
param_info(8).varname = 'button_rew';
param_info(8).opts_title = {'None', '0.1 sec', '0.3 sec', '0.5 sec'};
param_info(8).opts_varname = {false, 0.1, 0.3, 0.5};
param_info(8).default_opt = false;
param_info(8).require_selection = true;
param_info(8).is_hidden = false;

param_info(9).title = 'Target Hold Time';
param_info(9).varname = 'target_hold_time';
param_info(9).opts_title = {'0.0 sec', '0.1 sec', '0.2 sec', '0.3 sec', '0.4 sec', '0.5 sec', '0.6 sec', '0.1-0.3 sec', '0.4-0.6 sec'};
param_info(9).opts_varname = {0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, '.1-.3', '.4-.6'};
param_info(9).default_opt = 0;
param_info(9).require_selection = true;
param_info(9).is_hidden = false;

param_info(10).title = 'Minimum Reward';
param_info(10).varname = 'min_targ_reward';
param_info(10).opts_title = {'No Reward Scaling', '0.0 sec', '0.1 sec', '0.2 sec', '0.3 sec', '0.4 sec', '0.5 sec', '0.6 sec', '0.7 sec'};
param_info(10).opts_varname = {false, 0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7};
param_info(10).default_opt = false;
param_info(10).require_selection = true;
param_info(10).is_hidden = false;

param_info(11).title = 'Maximum Reward';
param_info(11).varname = 'last_targ_reward';
param_info(11).opts_title = {'0.3 sec', '0.5 sec', '0.7 sec', '0.9 sec', '1.1 sec'};
param_info(11).opts_varname = {0.3, 0.5, 0.7, 0.9, 1.1};
param_info(11).default_opt = [];
param_info(11).require_selection = true;
param_info(11).is_hidden = false;

param_info(12).title = 'Appearing Target Radius';
param_info(12).varname = 'target_rad';
param_info(12).opts_title = {'0.5 cm', '0.75 cm', '0.82 cm', '0.91 cm', '1.0 cm', '1.5 cm', '1.9 cm', '2.25 cm', '3.0 cm', '4.0 cm'};
param_info(12).opts_varname = {0.5, 0.75, 0.82, 0.91, 1.0, 1.5, 1.9, 2.25, 3.0, 4.0};
param_info(12).default_opt = [];
param_info(12).require_selection = true;
param_info(12).is_hidden = false;

param_info(13).title = 'Effective Target Radius';
param_info(13).varname = 'effective_target_rad';
param_info(13).opts_title = {'Same As Appears', '1.0 cm', '2.0 cm', '2.5 cm', '3.0 cm', '4.0 cm', '5.0 cm'};
param_info(13).opts_varname = {'Same As Appears', 1, 2, 2.5, 3, 4, 5};
param_info(13).default_opt = 'Same As Appears';
param_info(13).require_selection = true;
param_info(13).is_hidden = false;

param_info(14).title = 'Show Outlines';
param_info(14).varname = 'display_outlines';
param_info(14).opts_title = {'YES', 'NO'};
param_info(14).opts_varname = {true, false};
param_info(14).default_opt = true;
param_info(14).require_selection = true;
param_info(14).is_hidden = false;

param_info(15).title = 'Sequence';
param_info(15).varname = 'seq';
param_info(15).opts_title = {'Random 5', 'Repeat Last', 'Random Every', 'Rand 5/Rand Every', '2-Seq w/ Repeat', 'Center Out', 'Button Out'};
param_info(15).opts_varname = {'rand5', 'repeat', 'randevery', 'rand5-randevery', '2seq-repeat', 'center out', 'button_out'};
param_info(15).default_opt = false;
param_info(15).require_selection = false;
param_info(15).is_hidden = false;

param_info(16).title = 'Target 1 Position';
param_info(16).varname = 'target1_pos_str';
param_info(16).opts_title = {'Random', 'Center', 'Upper Left', 'Middle Left', 'Lower Left', 'Upper Middle', 'Lower Middle', 'Upper Right', 'Middle Right', 'Lower Right'};
param_info(16).opts_varname = {'random', 'center', 'upper_left', 'middle_left', 'lower_left', 'upper_middle', 'lower_middle', 'upper_right', 'middle_right', 'lower_right'};
param_info(16).default_opt = {};
param_info(16).require_selection = false;
param_info(16).is_hidden = false;

param_info(17).title = 'Target 2 Position';
param_info(17).varname = 'target2_pos_str';
param_info(17).opts_title = {'None', 'Random', 'Center', 'Upper Left', 'Middle Left', 'Lower Left', 'Upper Middle', 'Lower Middle', 'Upper Right', 'Middle Right', 'Lower Right'};
param_info(17).opts_varname = {'none', 'random', 'center', 'upper_left', 'middle_left', 'lower_left', 'upper_middle', 'lower_middle', 'upper_right', 'middle_right', 'lower_right'};
param_info(17).default_opt = {};
param_info(17).require_selection = false;
param_info(17).is_hidden = false;

param_info(18).title = 'Target 3 Position';
param_info(18).varname = 'target3_pos_str';
param_info(18).opts_title = {'None', 'Random', 'Center', 'Upper Left', 'Middle Left', 'Lower Left', 'Upper Middle', 'Lower Middle', 'Upper Right', 'Middle Right', 'Lower Right'};
param_info(18).opts_varname = {'none', 'random', 'center', 'upper_left', 'middle_left', 'lower_left', 'upper_middle', 'lower_middle', 'upper_right', 'middle_right', 'lower_right'};
param_info(18).default_opt = {};
param_info(18).require_selection = false;
param_info(18).is_hidden = false;

param_info(19).title = 'Target 4 Position';
param_info(19).varname = 'target4_pos_str';
param_info(19).opts_title = {'None', 'Random', 'Center', 'Upper Left', 'Middle Left', 'Lower Left', 'Upper Middle', 'Lower Middle', 'Upper Right', 'Middle Right', 'Lower Right'};
param_info(19).opts_varname = {'none', 'random', 'center', 'upper_left', 'middle_left', 'lower_left', 'upper_middle', 'lower_middle', 'upper_right', 'middle_right', 'lower_right'};
param_info(19).default_opt = {};
param_info(19).require_selection = false;
param_info(19).is_hidden = false;

param_info(20).title = 'Target 5 Position';
param_info(20).varname = 'target5_pos_str';
param_info(20).opts_title = {'None', 'Random', 'Center', 'Upper Left', 'Middle Left', 'Lower Left', 'Upper Middle', 'Lower Middle', 'Upper Right', 'Middle Right', 'Lower Right'};
param_info(20).opts_varname = {'none', 'random', 'center', 'upper_left', 'middle_left', 'lower_left', 'upper_middle', 'lower_middle', 'upper_right', 'middle_right', 'lower_right'};
param_info(20).default_opt = {};
param_info(20).require_selection = false;
param_info(20).is_hidden = false;

param_info(21).title = 'Lower Screen Top By';
param_info(21).varname = 'screen_top';
param_info(21).opts_title = {'0 cm', '2 cm', '4 cm', '6 cm', '8 cm', '10 cm', '12 cm'};
param_info(21).opts_varname = {0, 2, 4, 6, 8, 10, 12};
param_info(21).default_opt = 0;
param_info(21).require_selection = true;
param_info(21).is_hidden = false;

param_info(22).title = 'Raise Screen Bottom By';
param_info(22).varname = 'screen_bot';
param_info(22).opts_title = {'0 cm', '2 cm', '4 cm', '6 cm', '8 cm', '10 cm', '12 cm'};
param_info(22).opts_varname = {0, 2, 4, 6, 8, 10, 12};
param_info(22).default_opt = 0;
param_info(22).require_selection = true;
param_info(22).is_hidden = false;

param_info(23).title = 'Num Correct til Break';
param_info(23).varname = 'break_trl';
param_info(23).opts_title = {'NO Break', '10 trials', '15 trials', '20 trials', '25 trials'};
param_info(23).opts_varname = {0, 10, 15, 20, 25};
param_info(23).default_opt = 0;
param_info(23).require_selection = true;
param_info(23).is_hidden = false;

param_info(24).title = 'Break Length';
param_info(24).varname = 'break_dur';
param_info(24).opts_title = {'0.5 min', '1.0 min', '1.5 min', '2.0 min', '2.5 min'};
param_info(24).opts_varname = {30, 60, 90, 120, 150};
param_info(24).default_opt = [];
param_info(24).require_selection = true;
param_info(24).is_hidden = false;

param_info(25).title = 'Auto-Quit After';
param_info(25).varname = 'max_trials';
param_info(25).opts_title = {'10 trials', '25 trials', '50 trials', '60 trials', '90 trials', '100 trials', 'Do NOT Auto-Quit'};
param_info(25).opts_varname = {10, 25, 50, 60, 90, 100, Inf};
param_info(25).default_opt = Inf;
param_info(25).require_selection = true;
param_info(25).is_hidden = false;

param_info(26).title = 'Time to Next Targ Visible';
param_info(26).varname = 'time_to_next_targ';
param_info(26).opts_title = {'Never', '0.25 sec', '0.5 sec', '0.75 sec', '1.0 sec', '1.5 sec'};
param_info(26).opts_varname = {false, 0.25, 0.5, 0.75, 1.0, 1.5};
param_info(26).default_opt = false;
param_info(26).require_selection = false;
param_info(26).is_hidden = true;

param_info(27).title = 'Intertarget Delay';
param_info(27).varname = 'intertarg_delay';
param_info(27).opts_title = {'0 sec', '0.1 sec', '0.15 sec', '0.2 sec', '0.25 sec', '0.3 sec', '0.4 sec', '0.5 sec'};
param_info(27).opts_varname = {0, 0.1, 0.15, 0.2, 0.25, 0.3, 0.4, 0.5};
param_info(27).default_opt = 0;
param_info(27).require_selection = false;
param_info(27).is_hidden = true;

param_info(28).title = 'Target 1 X Nudge';
param_info(28).varname = 'nudge_x_t1';
param_info(28).opts_title = {'-6 cm', '-4 cm', '-2 cm', '0 cm', '2 cm', '4 cm', '6 cm'};
param_info(28).opts_varname = {-6, -4, -2, 0, 2, 4, 6};
param_info(28).default_opt = 0;
param_info(28).require_selection = false;
param_info(28).is_hidden = true;

param_info(29).title = 'Target 2 X Nudge';
param_info(29).varname = 'nudge_x_t2';
param_info(29).opts_title = {'-6 cm', '-4 cm', '-2 cm', '0 cm', '2 cm', '4 cm', '6 cm'};
param_info(29).opts_varname = {-6, -4, -2, 0, 2, 4, 6};
param_info(29).default_opt = 0;
param_info(29).require_selection = false;
param_info(29).is_hidden = true;

param_info(30).title = 'Target 3 X Nudge';
param_info(30).varname = 'nudge_x_t3';
param_info(30).opts_title = {'-6 cm', '-4 cm', '-2 cm', '0 cm', '2 cm', '4 cm', '6 cm'};
param_info(30).opts_varname = {-6, -4, -2, 0, 2, 4, 6};
param_info(30).default_opt = 0;
param_info(30).require_selection = false;
param_info(30).is_hidden = true;

param_info(31).title = 'Target 4 X Nudge';
param_info(31).varname = 'nudge_x_t4';
param_info(31).opts_title = {'-6 cm', '-4 cm', '-2 cm', '0 cm', '2 cm', '4 cm', '6 cm'};
param_info(31).opts_varname = {-6, -4, -2, 0, 2, 4, 6};
param_info(31).default_opt = 0;
param_info(31).require_selection = false;
param_info(31).is_hidden = true;

param_info(32).title = 'Target 5 X Nudge';
param_info(32).varname = 'nudge_x_t5';
param_info(32).opts_title = {'-6 cm', '-4 cm', '-2 cm', '0 cm', '2 cm', '4 cm', '6 cm'};
param_info(32).opts_varname = {-6, -4, -2, 0, 2, 4, 6};
param_info(32).default_opt = 0;
param_info(32).require_selection = false;
param_info(32).is_hidden = true;

param_info(33).title = 'Percent Trials Reward';
param_info(33).varname = 'percent_of_trials_rewarded';
param_info(33).opts_title = {'100%', '50%', '33%'};
param_info(33).opts_varname = {1, 0.5, 0.33};
param_info(33).default_opt = 1;
param_info(33).require_selection = false;
param_info(33).is_hidden = true;

param_info(34).title = 'ITI Duration (avg)';
param_info(34).varname = 'ITI_mean';
param_info(34).opts_title = {'0 sec', '0.5 sec', '1.0 sec', '1.5 sec', '2.0 sec'};
param_info(34).opts_varname = {0, 0.5, 1, 1.5, 2};
param_info(34).default_opt = 1;
param_info(34).require_selection = false;
param_info(34).is_hidden = true;

param_info(35).title = 'ITI Duration (SD)';
param_info(35).varname = 'ITI_std';
param_info(35).opts_title = {'0 sec', '0.1 sec', '0.2 sec', '0.3 sec', '0.4 sec'};
param_info(35).opts_varname = {0, 0.1, 0.2, 0.3, 0.4};
param_info(35).default_opt = 0.2;
param_info(35).require_selection = false;
param_info(35).is_hidden = true;

% get the number of options for each parameter
for i = 1:length(param_info)
  param_info(i).Nopts = length(param_info(i).opts_title);
  assert(param_info(i).Nopts == length(param_info(i).opts_varname));
end

%% Save
cwd = pwd;
if ispc
  if any(strfind(cwd, 'sando'))
    user = 'sando';
    tcpath = 'C:\Users\sando\Documents\target_chase\';
  end
end
save([tcpath 'param_screen.mat'], 'param_info', '-v7.3')