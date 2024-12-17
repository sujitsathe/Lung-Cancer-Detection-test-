clc;
clear;
close all;

% Step 1: Load the CT Scan Image
[file, path] = uigetfile({'*.jpg;*.png;*.bmp;*.tif', 'Image Files (*.jpg, *.png, *.bmp, *.tif)'}, 'Select a Lung CT Image');
if isequal(file, 0)
    disp('User canceled file selection.');
    return;
else
    imgPath = fullfile(path, file);
    img = imread(imgPath);
end

% Convert to grayscale if it's a color image
if size(img, 3) == 3
    img = rgb2gray(img);
end

% Display the original image
figure;
subplot(2, 3, 1);
imshow(img);
title('Original Image');

% Step 2: Preprocessing
% Resize image to standard size
img = imresize(img, [256, 256]);

% Apply median filtering to reduce noise
preprocessedImg = medfilt2(img, [3, 3]);

% Enhance contrast using adaptive histogram equalization
preprocessedImg = adapthisteq(preprocessedImg);

% Display preprocessed image
subplot(2, 3, 2);
imshow(preprocessedImg);
title('Preprocessed Image');

% Step 3: Lung CT Image Segmentation
% Use Otsu's thresholding
level = graythresh(preprocessedImg);

% Replace 'imbinarize' with 'im2bw' for older MATLAB versions
segmentedImg = im2bw(preprocessedImg, level);

% Remove small objects and isolate lung regions
segmentedImg = bwareaopen(segmentedImg, 500);

% Perform morphological operations to clean up segmentation
segmentedImg = imfill(segmentedImg, 'holes');
segmentedImg = imerode(segmentedImg, strel('disk', 3));

% Display segmented lung image
subplot(2, 3, 3);
imshow(segmentedImg);
title('Segmented Lung Region');

% Step 4: Feature Extraction
% Extract features like Area, Mean Intensity, Eccentricity, and Solidity
features = regionprops(segmentedImg, img, 'Area', 'MeanIntensity', 'Eccentricity', 'Solidity');

% Check if any regions are found
if isempty(features)
    disp('No regions found. Likely an artery.');
    outputResult = 'Artery';
    disp(['Diagnosis: ', outputResult]);
    return;
end

% Find the largest region for analysis
[~, largestIdx] = max([features.Area]);
region = features(largestIdx);

% Extract features of the largest region
area = region.Area;
intensity = region.MeanIntensity;
eccentricity = region.Eccentricity;
solidity = region.Solidity;

% Step 5: Classification
% Dynamically adjust thresholds based on the input image
avgIntensity = mean2(preprocessedImg); % Average intensity of the image
areaThreshold = 0.02 * numel(segmentedImg); % 2% of total image area
intensityThreshold = avgIntensity * 1.2;   % 20% higher than average intensity
eccentricityThreshold = 0.8;              % Shape irregularity threshold
solidityThreshold = 0.9;                  % Smoothness threshold

% Perform classification
if area > areaThreshold && intensity > intensityThreshold && eccentricity > eccentricityThreshold
    outputResult = 'Malignant Lung Cancer';
elseif area > areaThreshold && solidity > solidityThreshold
    outputResult = 'Benign Lung Cancer';
else
    outputResult = 'Artery';
end

% Display the final result
disp(['Diagnosis: ', outputResult]);

% Step 6: Display Results
% Visualize segmented region with diagnosis
subplot(2, 3, 4);
imshow(segmentedImg);
title('Segmented Region');

subplot(2, 3, 5);
imshow(preprocessedImg);
title(['Diagnosis: ', outputResult]);

% Show final processed output
subplot(2, 3, 6);
imshow(img);
title('Processed Image with Diagnosis');
