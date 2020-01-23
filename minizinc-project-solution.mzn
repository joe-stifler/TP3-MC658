%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% HEADER - PRACTICAL WORK 3 (CONSTRAINT PROGRAMMING WITH MINIZINC)                   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                                    %
% Discipline: MC658                                                                  %
% PED: Natanael Ramos                                                                %
% Professor: Cid C. de Souza                                                         %
% Data of creation: May 24, 2019                                                     %
% Author (RA 176665): Jose Ribeiro Neto <j176665@dac.unicamp.br>                     %
% Author (RA 171119): Felipe Lopes De Mello <f171119@dac.unicamp.br>                 %
%                                                                                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% USED GLOBAL CONSTRAINTS:                                                           %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

include "cumulative.mzn"; % used in commented constraint 6

include "bin_packing.mzn"; % used in constraint 5

include "disjunctive.mzn"; % used in constraint 3

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

set of int: nprecIndex = 1 .. nprec; % index set of precedence

array[nprecIndex, 1 .. 2] of par int: prec; % precedence between jobs of
                                            % different  orders, one per line
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% AUXILIARY PARAMETERS (USED IN THE CONSTRAINTS AND OPTMIZATION):                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

par int: nj = sum(njo); % total number of jobs

set of int: indexJob  = 1..nj; % index set of jobs

% index set containing all possible time that a task i can start
%
set of int: indexTask = 1..sum(i in 1..no) (njo[i] * djo[i]);

% index set containing all possible time that a job j can start
%
set of int: indexTime = 0..sum(i in 1..no) (njo[i] * djo[i]); % index time jobs

% durationJob: holds the total duration of job j
%
array[1 .. nj] of par int: durationJob = [djo[i] | i in 1 .. no, j in 1 .. njo[i]];

% mappedOrder: maps for each job j, the correspondent related order
%
array[1 .. nj] of par int: mappedOrder = [i | i in 1 .. no, j in 1 .. njo[i]];

% firstTrabOrder: for each order o, firstTrabOrder[o] points to the position
%     in trab array containing the first worker requirement of order o. That is,
%     if workers in order 1 requires 3 units of time and the jobs in this order
%     require [5, 2, 3] workers for each time unit, then firstTrabOrder[1] = 1 and 
%     trab[firstTrabOrder[1]] = 5 and trab[firstTrabOrder[1] + 1] = 2. 
%     Also, if workers in order 2 requires 4 units of time with each job consuming
%     [7, 4, 3, 1] workers for each unit time, then firstTrabOrder[2] = 4 and therefore
%     trab[firstTrabOrder[2]] = 7 and trab[firstTrabOrder[2] + 1] = 4.
%
array[1 .. no] of par int: firstTrabOrder = 
           [if o > 1 then sum(i in 1 .. o-1)(djo[i]) + 1 else 1 endif | o in 1 .. no];

% taskWorkers: with this array, we decompose each job j (during X time units) in X tasks
%     each one requiring trab[firstTrabOrder[mappedOrder[j]]+k] workers (with k in 0..X-1). 
%    Therefore, if there is a order 1 with 2 jobs during 2 time units in which the worker
%    request is [ 8, 7 ], and there is a order 2 with 2 jobs during 3 time units in which
%    the worker is [ 4, 5, 3 ], the taskWorkers array should be [8, 7, 8, 7, 4, 5, 3, 4, 5, 3]
%
array[indexTask] of 0..L: taskWorkers = 
                        [trab[firstTrabOrder[mappedOrder[j]]+k] | 
                                        j in indexJob, k in 0..djo[mappedOrder[j]]-1];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DECISION VARIABLES DECLARATION                                                     %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

var indexTime: makespan; % the time that the last task will finish

array[indexJob] of var indexTime: jobStartTime;  % time of beggining of each task
            
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONSTRAINTS:                                                                       %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% 
% precedence predicate description:
%    Task 2 can start only after the finish of task 1
%
% Arguments:
%    s1: start time of task 1
%    d1: duration time of task 1
%    s2: start time of task 2
%
predicate precedence(var int:s1, var int:d1, var int:s2) = (s1 + d1 <= s2);




% The following code is a better approach than the commented constraint 1 below
% Constraint 1) For all job (j, k) in the same order, j and k cannot overlap in time
%
constraint forall(j in indexJob, k in indexJob 
              where j < k /\ mappedOrder[j] = mappedOrder[k])
                       (precedence(jobStartTime[j], durationJob[j], jobStartTime[k]));




% Constraint 2) Makespan must be higher than or equal to the end time of all jobs
%
constraint forall(j in indexJob) (precedence(jobStartTime[j],durationJob[j],makespan));




% Constraint 3) For all job(j, k) in the same order, j and k 
%               cannot overlap in time (redundant with constraint 1)
%
constraint forall(o in 1..no) (
      disjunctive(
          [jobStartTime[j] | j in indexJob where o = mappedOrder[j]],
          [durationJob[j] | j in indexJob where o = mappedOrder[j]]
      )
);




% Constraint 4) the job schedule must respect the given precedence relation
%
constraint forall(p in nprecIndex)
     (precedence(jobStartTime[prec[p, 1]], durationJob[prec[p, 1]], jobStartTime[prec[p, 2]]));




% This is a much better approach than the constraint 5.1, 5.2 and 6 commented below
% Constraint 5) for each possible time t, the running jobs cannot use more than L workers
%
constraint bin_packing(
    L,  % c
    [jobStartTime[j] + d | j in indexJob, d in 0..djo[mappedOrder[j]] - 1], % bin[ i ]
    taskWorkers % w[ i ]
);





% BIN_PACKING DESCRIPTION: 
%     Requires that each item i with weight w [ i ], 
%     be put into bin [ i ] such that the sum of the weights 
%     of the items in each bin does not exceed the capacity c.
%
% CONVERTING THE BIN_PACKING CONSTRAINT TO OUR SCHEDULE WORKER CONSTRAINT:
%     We will have that each bucket of time t (t in indexTime) is the equivalent
%     of a bin. For each task i we will have a requirement of taskWorkers[ i ] 
%     workers (therefore a weight of w [ i ]). Also, for each task i
%     we have to say the time bucket that this task should run, 
%     described by jobStartTime[ i ] + d (that is, the bin where the task 
%     should be put). Therefore, at the time bucket t (bin t), the number
%     of workers (that is, the total weight of bucket t) cannot be greater
%     than L (or the maximum weight c).




% Constraint 1) For all job (j, k) in the same order, j and k cannot overlap in 
%               time and makespan must be  less than or equal the end time of all jobs
%
%constraint forall(j in indexJob)(precedence(jobStartTime[j], durationJob[j], makespan) 
%    /\ (if j != nj /\ mappedOrder[j] = mappedOrder[j + 1] 
%          then precedence(jobStartTime[j], durationJob[j], jobStartTime[j + 1]) else true endif));





% Constraint 5.1) for each possible time, the running jobs cannnot use more than L workers
%
% constraint forall(t in 0..makespan)(
%     sum(j in indexJob where jobStartTime[j] <= t 
%               /\ jobStartTime[j] + durationJob[j] > t)
%                    (trab[firstTrabOrder[mappedOrder[j]] + (t - jobStartTime[j])]) <= L
% );

% The following code is a better approach than the previous commented constraint 5.1
% Constraint 5.2) for each possible time, the running jobs cannot use more than L workers
%
% constraint forall(job in indexJob, d in 0..djo[mappedOrder[job]]-1)(
%       let {var int: t = jobStartTime[job] + d} in
%           sum(j in indexJob where jobStartTime[j] <= t 
%                 /\ jobStartTime[j] + durationJob[j] > t)
%                      (trab[firstTrabOrder[mappedOrder[j]] + (t - jobStartTime[j])]) <= L
% );




% Constraint 6) for each possible time, the running jobs cannot use more than L workers 
%               (redundant to constraint 5.1)
%
% constraint cumulative(
%     [jobStartTime[j] + d | j in indexJob, d in 0..djo[mappedOrder[j]]-1], 
%     [1 | j in indexJob, d in 0..djo[mappedOrder[j]]-1], 
%     taskWorkers, 
%     L
% );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% OPTIMIZATION:                                                                      %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% minimize the time of the last finished job j
%
solve :: seq_search([
          int_search(jobStartTime, first_fail, indomain_min, complete),
          int_search([makespan], input_order, indomain_min, complete)
      ])
      
      minimize(makespan);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% OUTPUT:                                                                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

output["\(makespan)\n"];
output["\(j) \(jobStartTime[j])\n" | j in indexJob];
