function [WholeJ,J]=Jacobian_NRLF(Ybus,V,d,posSL,posPV)



    N=length(V);    
    pos=[posSL;posSL+posPV];
    
    % -----------------    BEGIN: Building the Jacobian matrix   -------------
    % Elements J11
    % deriv_Pi/deriv_dj
    % J11=-UiUj(Gijsinδij-Bijcosδij)（课本上的）
    J11=-( abs(V)*transpose(abs(V)) ) .* abs(Ybus) .* ...
        sin( angle(Ybus) + repmat(transpose(d),N,1) - repmat(d,1,N) );
    % J11=-UiUjYijsin(θij-δij) 其中θij=angle(Ybus)
    %    =-UiUjYij(sincos-cossin)
    %    =-UiUj(Bijcosδij-Gijsinδij)
    %    =UiUj(Gijsinδij-Bijcosδij) 此时已经把dPdQ=-J*dddV中的负号考虑进来了
    J11=J11.*(1-eye(N));% 将对角元素置零
    % deriv_Pi/deriv_di
    J11=J11-diag(sum(J11,2));
    % sum(J11,2)是求J11每一行的总和，算出来的结果是Qi
    % diag是生成一个以括号内元素为对角元素的矩阵，其他元素全为0
    
    % Elements J21
    % deriv_Qi/deriv_dj
    J21=-( abs(V)*transpose(abs(V)) ) .* abs(Ybus) .* ...
        cos( angle(Ybus) + repmat(transpose(d),N,1) - repmat(d,1,N) );
    J21=J21.*(1-eye(N));
    % deriv_Qi/deriv_di
    J21=J21-diag(sum(J21,2));
    
    % Elements J12
    % % deriv_Pi/deriv_Vj*|Vj|
    % deriv_Pi/deriv_Vj
    J12=J21.*(2*eye(size(J21))-ones(size(J21)));% 取J21的对角元素以及非对角元素的负值
    % Fixing the Diagonal elements "|Vi|*deriv_Pi/deriv_Vi" 
    J12=J12 + diag( 2*(abs(V).^2) .* real(diag(Ybus)) );
    J12=J12*inv(diag(V));

    
    % Elements J22
    % % deriv_Qi/deriv_Vj*|Vj|
    % deriv_Qi/deriv_Vj
    J22=J11.*(-2*eye(size(J21))+ones(size(J21)));
    % Fixing the Diagonal elements "|Vi|*deriv_Pi/deriv_Vi" 
    J22=J22 - diag( 2*(abs(V).^2) .* imag(diag(Ybus)) );
    J22=J22*inv(diag(V));
    
    J=[J11 J12;J21 J22];WholeJ=J;
    % delete empty Rows and Columns in Jacobian matrix and [dP dQ]
    J(:,pos>0)=[];J(pos>0,:)=[];
