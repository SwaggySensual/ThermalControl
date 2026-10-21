clc; clear; close all;

calculateTotalPrintTime('C:\Users\Pedro\Documents\Mechatronics\Graduation Internship\MATLAB\MATLAB Toolkit Mod\mpfs\UpperBoundTest.mpf');

function [totalTimeSec, totalTimeMin] = calculateTotalPrintTime(filename)
    % CALCULATETOTALPRINTTIME Parses an MPF/G-code file to compute the 
    % exact print time based on G1 moves and dynamically changing feedrates.
    
    fprintf('\n========================================\n');
    fprintf('        TOTAL PRINT TIME ESTIMATOR\n');
    fprintf('========================================\n');
    
    % --- 1. Read File ---
    lines = readlines(filename);
    
    % --- 2. Initialize Tracking Variables ---
    % calculate a massive travel move from (0,0,0) to the start of the print.
    currentX = 0; currentY = 0; currentZ = 0;
    currentF = 10000; 
    
    totalTimeMin = 0;
    totalDistance = 0;
    
    % --- 3. Parse File ---
    for i = 1:length(lines)
        line = lines(i);
        
        % Skip empty lines or pure comments instantly to speed up parsing
        if line == "" || startsWith(line, ';')
            continue;
        end
        
        % A. Catch any Feedrate (F) updates. 
        % This works if it's on a standalone line or attached to a G1 move.
        fMatch = regexp(line, 'F([\d.]+)', 'tokens');
        if ~isempty(fMatch)
            currentF = str2double(fMatch{1}{1});
        end
        
        % B. Process Print Moves (G1)
        if startsWith(line, 'G1')
            xMatch = regexp(line, 'X([-\d.]+)', 'tokens');
            yMatch = regexp(line, 'Y([-\d.]+)', 'tokens');
            zMatch = regexp(line, 'Z([-\d.]+)', 'tokens');
            
            % Default new coordinates to current coordinates
            newX = currentX; newY = currentY; newZ = currentZ;
            moved = false;
            
            if ~isempty(xMatch), newX = str2double(xMatch{1}{1}); moved = true; end
            if ~isempty(yMatch), newY = str2double(yMatch{1}{1}); moved = true; end
            if ~isempty(zMatch), newZ = str2double(zMatch{1}{1}); moved = true; end
            
            % The "First Move Trap": If this is the very first coordinate 
            % in the file, just record the position but do NOT add time/distance.
            if isnan(currentX) && moved
                currentX = newX; currentY = newY; currentZ = newZ;
                continue;
            end
            
            % C. Calculate Distance and Time
            if moved
                % 3D Distance Formula
                dist = sqrt((newX - currentX)^2 + (newY - currentY)^2 + (newZ - currentZ)^2);
                totalDistance = totalDistance + dist;
                
                % Time = Distance / Speed (Feedrate is in mm/min)
                if ~isnan(currentF) && currentF > 0
                    totalTimeMin = totalTimeMin + (dist / currentF);
                end
                
                % Update physical position for the next loop
                currentX = newX; currentY = newY; currentZ = newZ;
            end
        end
    end
    
    % --- 4. Format Output ---
    totalTimeSec = totalTimeMin * 60;
    hours = floor(totalTimeMin / 60);
    minutes = mod(totalTimeMin, 60);
    
    fprintf('Total Print Distance: %.2f mm (%.2f meters)\n', totalDistance, totalDistance/1000);
    fprintf('Total Print Time:     %.2f seconds\n', totalTimeSec);
    fprintf('                      %d hours, %02.1f minutes\n', hours, minutes);
    fprintf('========================================\n');
end