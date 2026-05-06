function [ch3,Ic,ch5,Id,I_FixBar,Icfix,Idfix] = count_I_Fix(ch3,Ic,ch5,Id,Ch_labels,I_Fix,cntVge)

cntsw = length(cntVge);
ton1=cntVge(cntsw-3);
toff1=cntVge(cntsw-2);
ton2=cntVge(cntsw-1);
cntoff1=ton2-toff1;
cnton1=toff1-ton1;

% 探头偏置校正（静态区间均值）
if (I_Fix(1) == 1) || (I_Fix(2) == 1)
    fprintf('探头自动较零:\n');
end
static_ic_interval = fix(toff1 + cntoff1/2) : fix(ton2 - cntoff1/4);
if (Ch_labels(3)~=0) && (I_Fix(1) == 1)
    meanIc = mean(Ic(static_ic_interval)); % 关断时平均电流视为参考0电流
    fprintf('       Ic偏移量:%03fA\n',meanIc);
    Icfix = -1*meanIc;
    Ic = Ic - meanIc; % 电流探头较零
    ch3 = ch3 - meanIc;
elseif (Ch_labels(3)==0)
    meanIc = "  ";
    Icfix = meanIc;
else
    meanIc = 0;
    Icfix = meanIc;
end

static_id_interval = fix(ton1 + cnton1/2) : fix(toff1 - cnton1/4);
if (Ch_labels(5)~=0) && (I_Fix(2) == 1)
    meanId = mean(Id(static_id_interval));
    fprintf('       Id偏移量:%03fA\n',meanId);
    Idfix = -1*meanId;
    Id = Id - meanId;% 电流探头较零
    ch5 = ch5 - meanId;
elseif (Ch_labels(5)==0)
    meanId = "  ";
    Idfix = meanId;
else
    meanId = 0;
    Idfix = meanId;
end

I_FixBar = [static_ic_interval(1),static_ic_interval(end), static_id_interval(1),static_id_interval(end)];