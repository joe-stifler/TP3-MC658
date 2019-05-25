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

set of int: indexJob  = 1..sum(njo);

set of int: indexOrd  = 1..no;

int: maxTime = sum(i in indexOrd) (njo[i] * djo[i]); % maximum time all jobs will be finished

set of int: indexTime = 1..maxTime;

array[indexJob] of var 0..maxTime: jobStartTime;     % time instant of the start of a job

array[indexTime] of var int: trabTime;               % number of workers in every instant of time

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONSTRAINTS:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% <definir aqui todas as constrições>
constraint forall(i in indexTime) (trabTime[i] <= L); % number of workers in every instant of time cant     
                                                      % be higher than number of available workers

% constraint that joins number of workers in every instant of time with the start time of a job
% probably something like forall jobs and forall times, number of workers in a time equal the sum of workers a job needs in that time
% probably requeires a binary 2d array where lines are all the times and columns are all the jobs so the (i,j) position indicates
% the jth job is/isnt (1/0) being processed in the ith time
% possible start base
% constraint forall(i in indexTime)
%                  (forall(j in indexJob)
%                         (x)
%                  );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% OPTIMIZATION:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% <definir aqui a função a ser minimizada>
% solve minimize( XXXX );
solve minimize sum(jobStartTime); % temporary just to debug above code

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% OUTPUT:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% <printar aqui a solução encontrada>
output ["jobStartTime = \(jobStartTime)"]; % temporary just to debug above code