% =========================================================================
% Thermal History & Layer Failure Analysis Toolkit
% =========================================================================
clc; clear; close all;

% ====== Process variables ======

% --- files ---
csvfile = 'SaveTrackingData\Test1_resized.csv';     %Filename of the test raw data(.csv) from Test 1
test2mpf = 'mpfs\UpperBoundTest.mpf';               %File name of the g-code file for Test 2
test3mpf = 'mpfs\LowerBoundTest.mpf';               %File name of the g-code file for Test 3

% --- process variables ---
roomTemp = 25;  %Room temperature [°C]
Tg = 80;        %Glass transition temperature of the material [°C]
maxPrintHeight = 1800; %The maximum print your system can safely print at [mm]
safetyGap = 100; %Gap left to separate the test results from the cooling effects of the printbed [mm]
sampleHeight = 165; %The height of the samples you are going to use for testing [mm]

Lh = 2; %Layer height [mm]
Lw = 6; %Layer width [mm]
materialNum = 1958; %Number associated to the material being used
minRPM = 5; %The minimum rpm at which the screw can maintain bead consistency [rpm]

% --- Test 2 ---
targetLayerV = 182;  %the layer at which the vertical wall failed in Test 2
targetLayerOH = 128;  %the layer at which the overhang wall failed in Test 2
constFeedrate = 2712.5; %The constant feedrate set for the print at Test 2


% ===== USE THIS SECTION TO RUN THE FUNCTIONS =====

% --- 1. RUN CURVE FITTER ---

% This fits the biexponential curve to your CSV data and plots it.
[coolingCurve, timeToTg] = CurveFitter(csvfile, roomTemp, Tg);

% --- 2. FIND LAYER TIME FROM TEST 2 G-CODE ---

% Calculate from G-code
%minLayerTimeV = LayerTimeFinder(test2mpf, targetLayerV, constFeedrate, 'Vertical');
%minLayerTimeOH = LayerTimeFinder(test2mpf, targetLayerOH, constFeedrate, 'Overhang');

% --- 3. PLOT FAILURE TEMPERATURE T(t) ---
% Takes the layer time and plots the exact temperature on your existing graph.
% (Requires CurveFitter to be executed first)
%TempAtTime(coolingCurve, roomTemp, minLayerTimeV, 'Vertical');
%TempAtTime(coolingCurve, roomTemp, minLayerTimeOH, 'Overhang');

% --- 4. CONFIGURE THE SECTIONS FOR TEST 3 ---
sectionLayerTimes = SectionConfiguration(maxPrintHeight, sampleHeight, 25, 125);

% --- 5. CALCULATE SECTION FEEDRATES ---
[feedrates, targetLayers] = calculateSectionFeedrates(test3mpf, sectionLayerTimes, sampleHeight, Lh, safetyGap, minRPM, materialNum);

% --- 6. INJECT FEEDRATES TO TEST 3 G-CODE ---
%feedrateInjector(test3mpf, targetLayers, feedrates);

% =========================================================================
%                             FUNCTIONS
% =========================================================================

function [coolingCurve, timeToTg] = CurveFitter(csvFilename, roomTemp, Tg)
fprintf('--- CurveFitter ---\n');
% Reads thermal data from a .csv, fits a biexponential cooling curve, and plots it.

% --- Load and Format Data ---
rawData = readmatrix(csvFilename, 'NumHeaderLines', 1);
timeData = rawData(:, 1);
tempData = rawData(:, 2);

deltaT = tempData - roomTemp;

timeData = timeData(:);
deltaT = deltaT(:);

% --- Perform the Fit ---
[coolingCurve, goodnessOfFit] = fit(timeData, deltaT, 'exp1');

disp('--- Equation Coefficients ---');
disp(coolingCurve);
disp(['R-squared: ', num2str(goodnessOfFit.rsquare)]);

% --- Solve for Tg ---
targetDeltaT = Tg - roomTemp;
a = coolingCurve.a; b = coolingCurve.b; c = coolingCurve.c; d = coolingCurve.d;
rootEquation = @(t) (a * exp(b * t) + c * exp(d * t)) - targetDeltaT;

initialGuess = 100;
timeToTg = fzero(rootEquation, initialGuess);
timeToTgMin = timeToTg/60;   %time to Tg in minutes
fprintf('The exact time to reach Tg (%d°C) is: %.2f seconds(%.1fmin)\n', Tg, timeToTg, timeToTgMin);

% --- Plot the Results ---
figure;
hold on;
plot(timeData, tempData, 'k.', 'MarkerSize', 6, 'DisplayName', 'Raw Data');

fittedDeltaT = coolingCurve(timeData);
fittedRealTemp = fittedDeltaT + roomTemp;

% Dynamic Equation String for Legend
eqString = sprintf('Fit: %.1f e^{%.4f t} + %.1f e^{%.4f t} + %.1f', a, b, c, d, roomTemp);

% Changed fit line to Green ('g-')
plot(timeData, fittedRealTemp, '-', 'Color', '#228B22', 'LineWidth', 2, 'DisplayName', eqString);

% Horizontal Tg line: Solid Blue ('b-')
yline(Tg, 'b-', 'LineWidth', 1.5, 'DisplayName', 'Glass transition temperature limit');

% Vertical Tg line: Dashed Black, thin ('k--', LineWidth 0.5)
xline(timeToTg, 'k--', 'LineWidth', 0.5, 'HandleVisibility', 'off');

% Tg point: Blue circle ('bo')
plot(timeToTg, Tg, 'bo', 'MarkerSize', 8, 'MarkerFaceColor', 'b', 'HandleVisibility', 'off');

xOffset = 10; % Push 20 seconds to the right
yOffset = 2;  % Push 3 degrees up

tgLabel = sprintf('%.1f\\circC in %.1fs', Tg, timeToTg);
text(timeToTg + xOffset, Tg + yOffset, tgLabel, 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'left', ...
    'FontSize', 11, 'Color', 'b');

title('Biexponential Polymer Cooling (Real Temperatures)');
xlabel('Time (seconds)');
ylabel('Temperature (\circC)');

% Create the legend and double its font size
lgd = legend('Location', 'northeast');
lgd.FontSize = 12;

grid on;
hold off;
end

function minLayerTime = LayerTimeFinder(filename, targetLayer, constantFeedrate, wallType)

% Parses G-code to calculate the exact time taken to print a specific layer
speed_mm_sec = constantFeedrate / 60;

lines = readlines(filename);
currentX = 0; currentY = 0; currentZ = 0;
layerDistance = 0;
inTargetLayer = false;

layerStartStr = sprintf(';LAYER:%d', targetLayer);
layerEndStr = sprintf(';LAYER:%d', targetLayer + 1);

for i = 1:length(lines)
    line = lines(i);

    if startsWith(line, layerStartStr)
        inTargetLayer = true;
    elseif startsWith(line, layerEndStr)
        break;
    end

    if startsWith(line, 'G0') || startsWith(line, 'G1')
        xMatch = regexp(line, 'X([-\d.]+)', 'tokens');
        yMatch = regexp(line, 'Y([-\d.]+)', 'tokens');
        zMatch = regexp(line, 'Z([-\d.]+)', 'tokens');

        newX = currentX; newY = currentY; newZ = currentZ;

        if ~isempty(xMatch), newX = str2double(xMatch{1}{1}); end
        if ~isempty(yMatch), newY = str2double(yMatch{1}{1}); end
        if ~isempty(zMatch), newZ = str2double(zMatch{1}{1}); end

        if inTargetLayer
            dist = sqrt((newX - currentX)^2 + (newY - currentY)^2 + (newZ - currentZ)^2);
            layerDistance = layerDistance + dist;
        end

        currentX = newX; currentY = newY; currentZ = newZ;
    end
end

minLayerTime = layerDistance / speed_mm_sec;

fprintf('\n--- %s wall failed at layer %d ---\n', wallType, targetLayer);
fprintf('Total Distance:  %.2fmm\n', layerDistance);
fprintf('Layer Time:      %.2fs\n', minLayerTime);
end

function T_t = TempAtTime(coolingCurve, roomTemp, minLayerTime, wallType)
fprintf('\n--- T(t) plotter ---\n');
% Calculates the temperature at a specific time using the fitted curve
% and adds a visual marker to the currently open MATLAB figure.

T_t = coolingCurve(minLayerTime) + roomTemp;
fprintf('>> Temperature at Layer time (%.2fs) was: %.2f°C\n', minLayerTime, T_t);

% Target the currently active figure to add the failure point
hold on;

% Failure temp point: Red circle ('ro')
plot(minLayerTime, T_t, 'ro', 'MarkerSize', 10, 'MarkerFaceColor', 'r', 'HandleVisibility', 'off');

% Vertical failure line: Dashed Black, thin ('k--', LineWidth 0.5)
xline(minLayerTime, 'k--', 'LineWidth', 0.5, 'HandleVisibility', 'off');

% Horizontal failure line: Solid Red ('r-')
legendString = sprintf('Temp. limit for %s walls (%.1f \\circC)', wallType, T_t);
yline(T_t, 'r-', 'LineWidth', 1.5, 'DisplayName', legendString);

xOffset = 8; % Push 20 seconds to the right
yOffset = 1;  % Push 3 degrees up

% --- NEW: Floating Label for Failure Temp ---
failLabel = sprintf('%s wall: %.1f\\circC in %.1fs', wallType, T_t, minLayerTime);
text(minLayerTime + xOffset, T_t + yOffset, failLabel, 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'left', ...
    'FontSize', 11, 'Color', 'r');

hold off;
end

function sectionLayerTimes = SectionConfiguration(maxPrintHeight, sampleHeight, minLayerTime, maxLayerTime)
fprintf('\n--- Section Configuration ---\n');
% SECTIONCONFIGURATION calculates the number of sections for a tall
% test column and the equidistant layer times for each section.

% --- 1. Calculate the number of sections (n) ---
% 'floor' takes the division and rounds down to the highest whole
% number smaller than or equal to the result.
n = floor(maxPrintHeight / sampleHeight);

% Safety check in case the sample height is too big
if n < 1
    disp('Error: Sample height is greater than the Max Printing Height. Cannot create sections.');
    sectionLayerTimes = [];
    return;
end

% --- 2. Calculate the layer times ---
% Generate n points to establish the limits and the internal steps
allPoints = linspace(minLayerTime, maxLayerTime, n);

% Slice the array to keep only the internal points (ignore 1st and last)
sectionLayerTimes = allPoints(1:end);

% --- 3. Format and print the output ---
timeString = sprintf('%.1f, ', sectionLayerTimes);
timeString = timeString(1:end-2); % Strip off the trailing comma and space

fprintf('%d sections with layer times: %s\n', n, timeString);
end

function [requiredFeedrates, targetLayers] = calculateSectionFeedrates(filename, targetLayerTimes, sampleHeight, layerHeight, layerWidth, safetyGap, minRPM, materialNum, referenceLayer)
% Calculates the required G-code feedrate (F, in mm/min) to achieve
% specific target layer times, and generates the target layer array
% including a safety gap and a 5mm sacrificial sawing gap.

% Default to Layer 5 if the user doesn't specify one
if nargin < 6
    referenceLayer = 5;
end

% --- 1. Calculate Target Layers ---
n = length(targetLayerTimes);
targetLayers = zeros(1, n);

sectionHeight = sampleHeight + 5; % Add 5mm for the saw cut

% Convert mm measurements to layer numbers
safetyGapLayers = round(safetyGap / layerHeight);
layersPerSection = round(sectionHeight / layerHeight);

for i = 1:n
    % e.g., Layer 50, then 50 + layersPerSection, then 50 + 2*layersPerSection...
    targetLayers(i) = safetyGapLayers + (n - i) * layersPerSection;
end

% --- 2. Parse the G-code to find the layer distance ---
lines = readlines(filename);
currentX = 0; currentY = 0; currentZ = 0;
layerDistance = 0;
inTargetLayer = false;

layerStartStr = sprintf(';LAYER:%d', referenceLayer);
layerEndStr = sprintf(';LAYER:%d', referenceLayer + 1);

for i = 1:length(lines)
    line = lines(i);

    if startsWith(line, layerStartStr)
        inTargetLayer = true;
    elseif startsWith(line, layerEndStr)
        break;
    end

    if startsWith(line, 'G0') || startsWith(line, 'G1')
        xMatch = regexp(line, 'X([-\d.]+)', 'tokens');
        yMatch = regexp(line, 'Y([-\d.]+)', 'tokens');
        zMatch = regexp(line, 'Z([-\d.]+)', 'tokens');

        newX = currentX; newY = currentY; newZ = currentZ;

        if ~isempty(xMatch), newX = str2double(xMatch{1}{1}); end
        if ~isempty(yMatch), newY = str2double(yMatch{1}{1}); end
        if ~isempty(zMatch), newZ = str2double(zMatch{1}{1}); end

        if inTargetLayer
            dist = sqrt((newX - currentX)^2 + (newY - currentY)^2 + (newZ - currentZ)^2);
            layerDistance = layerDistance + dist;
        end

        currentX = newX; currentY = newY; currentZ = newZ;
    end
end

if layerDistance == 0
    disp('Error: Could not calculate distance. Check the layer number.');
    requiredFeedrates = [];
    targetLayers = [];
    return;
end

% --- 0. Calculate minimum allowed feedrate ---
minFeedrate = (minRPM * materialNum) / (layerHeight * layerWidth);

% --- 3. Calculate Feedrates ---
% F = (Distance * 60) / Target Time
requiredFeedrates = (layerDistance * 60) ./ targetLayerTimes;

% --- 4. Output Results ---
fprintf('\n--- Feedrate & Layer Calculations (Toolpath distance: %.2fmm) ---\n', layerDistance);
for k = 1:n
    % Rounding to the nearest whole number for the machine
    fprintf('Start Layer: %4d  -->  Target Time: %5.1fs  -->  Required Feedrate: F%.0f\n', targetLayers(k), targetLayerTimes(k), requiredFeedrates(k));
end
end

function feedrateInjector(file, targetLayers, feedrates)
% INJECTSECTIONFEEDRATES Modifies a G-code file to enforce specific
% feedrates starting at specific target layers.

fprintf('\n--- FEEDRATE G-CODE INJECTOR ---\n');

% --- 0. Safety Check ---
if length(targetLayers) ~= length(feedrates)
    fprintf('ERROR: You have %d target layers but %d feedrates. They must match!\n', length(targetLayers), length(feedrates));
    return;
end
sectionNr = 0;

% --- 1. File Setup ---
lines = readlines(file);
fileID = fopen(file, 'w');

currentFeedrate = -1; % -1 means no override is active yet

% --- 2. Parse and Inject ---
for i = 1:length(lines)
    line = lines(i);
    isNewSectionStart = false;

    % A. Check if this line is a layer marker
    if startsWith(line, ';LAYER:')
        % Extract the layer number as a double
        layerStr = extractAfter(line, ';LAYER:');
        currentLayer = str2double(layerStr);

        % Check if this layer is in our target list
        idx = find(targetLayers == currentLayer, 1);
        if ~isempty(idx)
            currentFeedrate = feedrates(idx);
            isNewSectionStart = true;
            sectionNr = sectionNr + 1;
            fprintf('>> Section %d Layer %d --> Overriding to F%.0f\n', sectionNr,  currentLayer, currentFeedrate);
        end
    end

    % B. Hunt and Overwrite Slicer Feedrates
    % If we have an active override, and it's a G1 print move with an F command
    if currentFeedrate > 0 && startsWith(line, 'G1') && contains(line, 'F')
        % regexprep finds 'F' followed by any numbers/decimals and replaces it
        replacementStr = sprintf('F%.0f', currentFeedrate);
        line = regexprep(line, 'F[\d.]+', replacementStr);
    end

    % C. Write the line to the new file
    fprintf(fileID, '%s\n', line);

    % D. Inject the master modal feedrate at the very start of the section
    if isNewSectionStart
        fprintf(fileID, 'G1 F%.0f ; AUTOMATIC SECTION FEEDRATE INJECTION\n', currentFeedrate);
    end
end

fclose(fileID);
fprintf('SUCCESS: Saved modified G-code to %s\n', file);
end