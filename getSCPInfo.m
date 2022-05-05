function scpInfo=getSCPInfo
scpInfo=struct();
if isempty(seriallist)
    error('SCP:InvalidSCP','No Serial Communication Port Detected.');
else
    scpLis=py.serial.tools.list_ports.comports();
    scpLisLen=size(scpLis,2);
    if scpLisLen>0
        scpInfo=repmat(struct(),[scpLisLen,1]);
        for scpi=1:scpLisLen
            fnSCP=sort(fieldnames(scpLis{scpi}));
            for fnscpi=1:length(fnSCP)
                scpInfo(scpi).(fnSCP{fnscpi})=char(scpLis{scpi}.(fnSCP{fnscpi}));
            end
        end
    end
end