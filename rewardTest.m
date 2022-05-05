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
  writeline(self.rewardPort, "VOL 0.5");
  writeline(self.rewardPort, "VOL ML");
  writeline(self.rewardPort, "RAT 50MM");
end

self.is_rewardPort = true;

rew_time = 3.0;

volume2dispense = rew_time*50/60; % mL/min x 1 min/60 sec --> sec x mL/sec
rew_str = sprintf(["VOL %0.1f"], volume2dispense);
writeline(self.rewardPort, rew_str);
WaitSecs(0.05);
writeline(self.rewardPort, "RUN");
