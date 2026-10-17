function [V,d,lambda,Pcalc,Qcalc,dP,dQ,dPred,dQred,dPdQred,it,Jke,J,dddVred]=NRLF(V,d,lambda,Ybus,Psch,Qsch,posSL,posPV,Toler,Max_It,vscData,auxPos,BusData,K,ek,m,Jkeini,Jini)

it=0;N=length(V);
while 1
    dPdQred(N+m,1)=0;
    [Pcalc,Qcalc,dP,dQ,dPred,dQred,dPdQred(1:N+m-1,1)]=Calculate_PcalcQcalc(V,d,Ybus,Psch,Qsch,posSL,posPV); % Calculating P and Q Injected    
    if not(any(abs(dPdQred)>Toler) && (it<=Max_It))% 全部不平衡量dPdQred≤Toler或it＞Max_It就结束循环
        if it==0
            Jke=Jkeini;
            dddVred=[];
            J=Jini;
        end
        if it>=1 && not(any(abs(dddVred)>0.00001))
        break;
        end
    end
    it=it+1;
    [~,J]=Jacobian_NRLF(Ybus,V,d,posSL,posPV); % Calculating Jacobian matrix

    % % 在雅各布矩阵中加入VSC动态控制
    % if ~isempty(vscData) % 数组为空，没有动态控制
    %     for k=1:length(vscData(:,1))
    %         i=vscData(k,1);% VSC节点编号
    %         J(i,auxPos(i,3)+N-1)=J(i,auxPos(i,3)+N-1)-BusData(i,14)/V(i);% 加一个PGi/Ui
    %         J(N-1+auxPos(i,3),m+auxPos(i,3))=J(N-1+auxPos(i,3),m+auxPos(i,3))-BusData(i,15)/V(i)+vscData(k,2)*V(i);% 加一个QGi/Ui-Kpi*Ui
    %     end
    % end

    Jke=[J -K;ek];
    dddVred = Jke\dPdQred;    % Calculating deltaDelta and DeltaV/V
    dddV=1-[posSL;posSL+posPV];
    dddV(dddV==1)=dddVred(1:N+m-1);
    d=d+dddV(1:N);
    V=V.*(1+dddV(N+1:2*N));
    lambda=lambda+dddVred(end);
end
