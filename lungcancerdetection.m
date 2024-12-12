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

% Create a single figure window for all outputs
figure;

% Display original image
subplot(2, 3, 1);
imshow(img);
title('Original Image');

% Step 2: Preprocessing
% Resize image to standard size
img = imresize(img, [256, 256]);

% Apply median filtering to remove noise
preprocessedImg = medfilt2(img, [3, 3]);

% Display preprocessed image
subplot(2, 3, 2);
imshow(preprocessedImg);
title('Preprocessed Image');

% Step 3: Lung CT Image Segmentation
% Perform Otsu's thresholding to segment the lung region
level = graythresh(preprocessedImg);
segmentedImg = im2bw(preprocessedImg, level); 

% Remove small objects and isolate large lung regions
segmentedImg = bwareaopen(segmentedImg, 500);

% Display segmented lung image
subplot(2, 3, 3);
imshow(segmentedImg);
title('Segmented Lung Region');

% Step 4: Feature Extraction
% Extract features like Area and Mean Intensity
features = regionprops(segmentedImg, img, 'Area', 'MeanIntensity');

% Check if any regions are found
if isempty(features)
    disp('No regions found. Likely an artery.');
    outputResult = 'Artery';
    disp(['Diagnosis: ', outputResult]);
    subplot(2, 3, 6);
    imshow(img);
    title(['Diagnosis: ', outputResult]);
    return;
end

% Use the largest region for diagnosis
[~, largestIdx] = max([features.Area]);
region = features(largestIdx);

% Extract relevant features
area = region.Area;
intensity = region.MeanIntensity;

% Step 5: Classification
% Define thresholds for classification
areaThreshold = 1500;          % Area threshold for cancer
intensityThreshold = 100;      % Intensity threshold for malignancy

% Perform classification
if area > areaThreshold && intensity > intensityThreshold
    outputResult = 'Malignant Lung Cancer';
elseif area > areaThreshold
    outputResult = 'Benign Lung Cancer';
else
    outputResult = 'Artery';
end

% Display the final result
disp(['Diagnosis: ', outputResult]);

% Step 6: Visualize Classification Results
% Overlay results on the original image
subplot(2, 3, 6);
imshow(img);
title(['Diagnosis: ', outputResult]);

% Display Features Table in Command Window
disp('Extracted Features:');
disp(struct2table(features));
