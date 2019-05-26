%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% HEADER - PRACTICAL WORK 3 (CONSTRAINT PROGRAMMING WITH MINIZINC)                   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                                    %
% Discipline: MC658                                                                  %
% PED: Natanael Ramos                                                                %
% Professor: Cid C. de Souza                                                         %
% Data of creation: May 24, 2019                                                     %
% Author (RA 176665): Jose Ribeiro Neto <j176665@dac.unicamp.br>                    %
% Author (RA 171119): Felipe Lopes De Mello <f171119@dac.unicamp.br>                %
%                                                                                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PARAMETERS RELATED WITH THE INPUT (DO NOT MODIFY THEIR NAMES):                     %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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

set of int: nprecIndex = 1 .. nprec;

array[nprecIndex, 1 .. 2] of par int: prec; % precedence between jobs of
                                            % different  orders, one per line
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% AUXILIARY PARAMETERS (USED IN THE CONSTRAINTS AND OPTMIZATION):                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
par int: nj = sum(njo); % total number of jobs

set of int: indexJob  = 1..nj; % index set of jobs

set of int: indexTime = 0..sum(i in 1..no) (njo[i] * djo[i]); % index time jobs

array[1 .. nj] of par int: durationJob = [djo[i] | i in 1 .. no, j in 1 .. njo[i]];

array[1 .. nj] of par int: mappedOrder = [i | i in 1 .. no, j in 1 .. njo[i]];

array[1 .. no] of par int: firstTrabOrder = 
            [if o > 1 then sum(i in 1 .. o-1)(djo[i]) + 1 else 1 endif | o in 1 .. no];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DECISION VARIABLES DECLARATION                                                     %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
array[indexJob] of var indexTime: jobStartTime;  % time instant of the start of a job

array[indexTime] of var 0 .. L: trabTime;  % number workers in every instant of time

var int: makespan = max(j in indexJob)(jobStartTime[j] + durationJob[j]);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONSTRAINTS:                                                                       %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% definir quem sao os trabalhadores em cada tempo t (atraves de uma constraint)
constraint forall(t in indexTime)(trabTime[t] = sum(j in indexJob 
       where jobStartTime[j] <= t /\ jobStartTime[j] + durationJob[j] > t)
               (trab[firstTrabOrder[mappedOrder[j]] + (t - jobStartTime[j])])
);

% For all job (j, k) in the same order, k can begin only after job j finish
constraint forall(j, k in indexJob where j < k /\ mappedOrder[j] = mappedOrder[k])
      (jobStartTime[j] + durationJob[j] <= jobStartTime[k]);

% the job schedule must respect the given precedence relation
constraint forall(p in nprecIndex)
     (jobStartTime[prec[p, 1]] + durationJob[prec[p, 1]] <= jobStartTime[prec[p, 2]]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% OPTIMIZATION:                                                                      %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
solve minimize(makespan);  % minimize the time of the last finished job j

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% OUTPUT:                                                                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
output["\(makespan)\n"];
output["\(j) \(jobStartTime[j])\n" | j in indexJob];