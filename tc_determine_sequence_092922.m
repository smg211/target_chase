targ_ix_grid = [1:3; 4:6; 7:9];

n_targ = 5;
% negative = up
possible_movements = [1 2; 2 1; 2 2; 2 0; ... % down-right and right movements
  -1 2; -2 1; -2 2; 0 2; ... % down-left and down movements
  -1 -1; -1 -2; -2 -1; -2 -2; -2 0; ... % up-left and left movements
  1 -1; 1 -2; 2 -1; 2 -2; 0 -2]; % up-right and up movements
poss_mv_group = [1 1 1 1 2 2 2 2 3 3 3 3 3 4 4 4 4 4];

path_length_range = [7.5 9.5];
allow_repeats = false;
targ_ix = [];
for n = 1:100000
  seq_exists = false;
  while ~seq_exists
    targ_ix(n, :) = nan(1, n_targ);
    try
      path_length = 0;
      targ_ix(n, 1) = round(5*rand)+1;
      poss_mv_group_remain = 1:max(poss_mv_group);
      
      for t = 1:n_targ-1
        % get the position of this target in the grid
        [i, j] = ind2sub(size(targ_ix_grid), find(targ_ix_grid == targ_ix(n, t)));
        
        % determine the direction of movement
        poss_mv_ix_del = [];
        if i == 1
          % top row so get rid of any upward movement
          poss_mv_ix_del = find(possible_movements(:, 2) < 0);
        elseif i == size(targ_ix_grid, 1)
          % bottom row so get rid of any downward movement
          poss_mv_ix_del = find(possible_movements(:, 2) > 0);
        end
        
        if j == 1
          % left column so get rid of any leftward movement
          poss_mv_ix_del = [poss_mv_ix_del; find(possible_movements(:, 1) < 0)];
        elseif j == size(targ_ix_grid, 2)
          % right column so get rid of any rightward movement
          poss_mv_ix_del = [poss_mv_ix_del; find(possible_movements(:, 1) > 0)];
        end
        
        poss_mv_ix_t = find(~ismember(1:size(possible_movements, 1), poss_mv_ix_del) & ...
          ismember(poss_mv_group, poss_mv_group_remain));
        
        if ~any(ismember(poss_mv_group_remain, poss_mv_group(poss_mv_ix_t)))
          error();
        end
        
        % go through all of the possible movements until you get one that
        % lands on a real target
        mv_order = randperm(length(poss_mv_ix_t));
        
        found_targ = false;
        for p = 1:length(mv_order)
          if ~found_targ
            dx = possible_movements(poss_mv_ix_t(mv_order(p)), 2);
            dy = possible_movements(poss_mv_ix_t(mv_order(p)), 1);
            i_t2 = i+dx;
            j_t2 = j+dy;
            
            if i_t2 > 0 && i_t2 <= size(targ_ix_grid, 1) && ...
                j_t2 > 0 && j_t2 <= size(targ_ix_grid, 2)
              next_targ_ix = targ_ix_grid(i_t2, j_t2);
              
              if allow_repeats || ...
                  (~allow_repeats && ~any(targ_ix(n, :) == next_targ_ix))
                targ_ix(n, t+1) = next_targ_ix;
                path_length = path_length + sqrt(dx^2 + dy^2);
                
                mv_group = poss_mv_group(find(all(possible_movements == possible_movements(poss_mv_ix_t(mv_order(p)), :), 2)));
                poss_mv_group_remain(find(poss_mv_group_remain == mv_group)) = [];
                
                found_targ = true;
              end
            end
          end
        end
        
        if ~found_targ
          error();
        end
        %         % of the possible directions, pick one and then remove that direction
        %         % from the remaining directions that need to be included
        %         mv_ix_t = randsample(poss_mv_ix_t, 1);
        %         poss_mv_group_remain(find(poss_mv_group_remain == mv_ix_t)) = [];
        %
        %         % determine possible distances to travel in that direction
        %         dx_poss_dist = randperm(size(targ_ix_grid, 2)-1);
        %         dy_poss_dist = randperm(size(targ_ix_grid, 1)-1);
        %
        %         % go through all of the possible distances to travel in that
        %         % direction until you find a target that is real
        %         found_targ = false;
        %         for x = 1:length(dx_poss_dist)
        %           for y = 1:length(dy_poss_dist)
        %             if ~found_targ
        %               dx = possible_movements(mv_ix_t, 1)*dx_poss_dist(x);
        %               dy = possible_movements(mv_ix_t, 2)*dy_poss_dist(y);
        %
        %               i_t2 = i+dy;
        %               j_t2 = j+dx;
        %
        %               if i_t2 > 0 && i_t2 <= size(targ_ix_grid, 1) && ...
        %                   j_t2 > 0 && j_t2 <= size(targ_ix_grid, 2)
        %                 next_targ_ix = targ_ix_grid(i_t2, j_t2);
        %
        %                 if allow_repeats || ...
        %                     (~allow_repeats && ~any(targ_ix(n, :) == next_targ_ix))
        %                   targ_ix(n, t+1) = next_targ_ix;
        %                   path_length = path_length + sqrt(dx^2 + dy^2);
        %                   found_targ = true;
        %                 end
        %               end
        %             end
        %           end
        %         end
        %
        %         if ~found_targ
        %           error();
        %         end
      end % loop through movements
      
      if path_length >= path_length_range(1) && path_length <= path_length_range(2)
        seq_exists = true;
      end
    end % end try
  end % end while looking for sequence
end % end loop through possible sequences

size(unique(targ_ix, 'rows'), 1);

seq_poss = unique(targ_ix, 'rows');

save('/Users/Sandon/Dropbox/Ganguly_Lab/Code/target_chase/seq_poss_v2.mat', 'seq_poss');
