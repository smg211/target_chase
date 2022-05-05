data = raw;
t_c = data.time;
cpos = data.cursor;
cid = data.cursor_ids;
cid_unique = unique(cid(find(~isnan(cid))));

figure; hold on;
i_start = 1;
i_end = length(t_c);
i_samp = 1:length(t_c);

t_c_t = t_c(i_samp);
for c = 1:length(cid_unique)
  [ix, iy] = find(cid == cid_unique(c));
  assert(all(diff(iy)==1));

  i_thistarg = find(iy >= i_start & iy <= i_end);
  iy = iy(i_thistarg);
  ix = ix(i_thistarg);
  if ~isempty(iy)
    cpos_x_i = sub2ind(size(cpos), ones(1, length(ix)), ix', iy');
    cpos_y_i = sub2ind(size(cpos), 2*ones(1, length(ix)), ix', iy');

    cpos_x = cpos(cpos_x_i);
    cpos_y = cpos(cpos_y_i);
    plot(cpos_x, cpos_y, '.', 'LineWidth', 10);
  end
end
