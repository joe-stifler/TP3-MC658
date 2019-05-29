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

include "cumulative.mzn";
include "disjunctive.mzn";

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

% set of int: indexTask = 1..(sum(i in 1..no) (njo[i] * djo[i]));
% array[indexTask] of par int: mappedJob = [i | i in indexJob, j in 1 .. djo[mappedOrder[i]]];
% array[indexTask] of 0..L: taskWorkers = [trab[firstTrabOrder[mappedOrder[j]]+k] | j in indexJob, k in 0..djo[mappedOrder[j]]-1];
% array[indexTask] of 0..1: taskDuration = [1 | i in indexTask];
% array[indexJob] of par int: firstTaskJob = [if t > 1 then sum(i in 1 .. t-1)(durationJob[i]) + 1 else 1 endif | t in indexJob];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DECISION VARIABLES DECLARATION                                                     %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
var indexTime: makespan; % the time that the last task will finish

array[indexJob] of var indexTime: jobStartTime;  % time of beggining of each task
            
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONSTRAINTS:                                                                       %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
predicate no_overlap(var int:s1, var int:d1, var int:s2) = (s1 + d1 <= s2);

% 1) For all job (j, k) in the same order, j and k cannot overlap in time
constraint forall(j in indexJob)(no_overlap(jobStartTime[j], durationJob[j], makespan) 
    /\ (if j != nj /\ mappedOrder[j] = mappedOrder[j + 1] 
          then no_overlap(jobStartTime[j], durationJob[j], jobStartTime[j + 1]) else true endif));

% 2) For all job(j, k) in the same order, j and k cannot overlap in time (redundant with constraint 1)
constraint forall(o in 1..no) (
      disjunctive(
          [jobStartTime[j] | j in indexJob where o = mappedOrder[j]],
          [durationJob[j] | j in indexJob where o = mappedOrder[j]]
      )
);

% 3) the job schedule must respect the given precedence relation
constraint forall(p in nprecIndex)
     (no_overlap(jobStartTime[prec[p, 1]], durationJob[prec[p, 1]], jobStartTime[prec[p, 2]]));

% 4) for each possible time, the running jobs cannot use more than L workers
% constraint forall(t in 0..makespan)(
%     sum(j in indexJob where jobStartTime[j] <= t 
%               /\ jobStartTime[j] + durationJob[j] > t)
%                    (trab[firstTrabOrder[mappedOrder[j]] + (t - jobStartTime[j])]) <= L
% );

% The following code is a better approach than the previous
% 4) for each possible time, the running jobs cannot use more than L workers
constraint forall(job in indexJob, d in 0..djo[mappedOrder[job]]-1)(
      let {var int: t = jobStartTime[job] + d} in
          sum(j in indexJob where jobStartTime[j] <= t 
                /\ jobStartTime[j] + durationJob[j] > t)
                     (trab[firstTrabOrder[mappedOrder[j]] + (t - jobStartTime[j])]) <= L
);

% 5) for each possible time, the running jobs cannot use more than L workers (redundant with constraint 4)
% constraint cumulative(
%     [jobStartTime[j] + d | j in indexJob, d in 0..djo[mappedOrder[j]]-1], 
%     taskDuration, 
%     taskWorkers, 
%     L
% );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% OPTIMIZATION:                                                                      %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% minimize the time of the last finished job j
solve :: seq_search([
          int_search(jobStartTime, dom_w_deg, indomain_min, complete),
          int_search([makespan], dom_w_deg, indomain_min, complete)
      ])
      
      minimize(makespan);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% OUTPUT:                                                                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
output["\(makespan)\n"];
output["\(j) \(jobStartTime[j])\n" | j in indexJob];