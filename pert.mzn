%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% HEADER - PRACTICAL WORK 3 (CONSTRAINT PROGRAMMING WITH MINIZINC)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Discipline: MC658
% PED: Natanael Ramos
% Professor: Cid C. de Souza
% Author2 (RA 171119): 	Felipe Lopes De Mello <f171119@dac.unicamp.br>
% Author2 (RA 176665): Jose Ribeiro Neto <j176665@dac.unicamp.br>
%
% Data of creation: May 24, 2019
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PARAMETERS AND DECISION VARIABLES DECLARATION:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
par int: L;  % number of available workers

par int: no; % number of orders

array[1 .. no] of par int: njo; % number of jobs by order

array[1 .. no] of par int: djo; % duration of jobs in orders

array[1 .. sum(djo)] of par int: trab; % demand profile of workers in each order
                                       % djo [1] first positions describe the 
                                       % profile of workers for jobs of order 1,
                                       % djo [2] positions following the profile 
                                       % of order 2 and so on.


par int: nprec; % number of precedences between jobs of different orders

array[1 .. nprec, 1 .. 2] of par int: prec; % precedence between jobs of different 
                                            % orders, one per line

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONSTRAINTS:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% <definir aqui todas as constrições>


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% OPTIMIZATION:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% <definir aqui a função a ser minimizada>
% solve minimize( XXXX );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% OUTPUT:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% <printar aqui a solução encontrada>