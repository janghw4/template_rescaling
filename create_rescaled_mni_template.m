function scaling_factors = create_rescaled_mni_template(subject_id, head_measurements, varargin)
%CREATE_RESCALED_MNI_TEMPLATE Creates a subject-specific rescaled MNI template
%
% This function rescales the standard MNI template based on individual head
% measurements to create a more anatomically accurate template for each subject.
%
% INPUTS:
%   subject_id        - String: Unique identifier for the subject
%   head_measurements - Struct with fields:
%                       .width   - Distance between left and right ears (cm)
%                       .depth   - Anterior-posterior head depth (cm)
%                       .height  - Distance from ear to top of head (cm)
%
% OPTIONAL INPUTS (name-value pairs):
%   'template_path'   - Path to MNI template file (default: './mni_icbm152_t1_tal_nlin_asym_09c.nii')
%   'output_dir'      - Output directory (default: './Output/')
%   'spm_path'        - Path to SPM12 installation (default: 'C:\SPM12')
%   'interpolation'   - Interpolation method: 0=nearest, 1=linear, 2=spline (default: 1)
%
% OUTPUT:
%   scaling_factors   - [1x3] vector: [fx, fy, fz] scaling factors applied
%
% EXAMPLE:
%   measurements.width = 14.5;
%   measurements.depth = 19.2;
%   measurements.height = 13.8;
%   factors = create_rescaled_mni_template('sub001', measurements);
%
% DEPENDENCIES:
%   - SPM12 toolbox
%   - MNI template file
%
% Author: Hyunwoo Jang, University of Michigan
% Date: Jul 15, 2025

    %% Input validation and default parameters
    if nargin < 2
        error('At least subject_id and head_measurements are required');
    end
    
    % Parse optional inputs
    p = inputParser;
    addParameter(p, 'template_path', './mni_icbm152_t1_tal_nlin_asym_09c.nii', @ischar);
    addParameter(p, 'output_dir', './Output/', @ischar);
    addParameter(p, 'spm_path', 'C:\SPM12', @ischar);
    addParameter(p, 'interpolation', 1, @(x) ismember(x, [0, 1, 2]));
    parse(p, varargin{:});
    
    % Extract parameters
    template_path = p.Results.template_path;
    output_dir = p.Results.output_dir;
    spm_path = p.Results.spm_path;
    interp_method = p.Results.interpolation;
    
    % Validate required measurement fields
    required_fields = {'width', 'depth', 'height'};
    for i = 1:length(required_fields)
        if ~isfield(head_measurements, required_fields{i})
            error('Missing required field: %s', required_fields{i});
        end
    end
    
    % Extract measurements for cleaner code
    width = head_measurements.width;
    depth = head_measurements.depth;
    height = head_measurements.height;
    
    % Validate measurements are positive
    if any([width, depth, height] <= 0)
        error('All head measurements must be positive values');
    end
    
    %% Standard MNI template dimensions (in cm)
    % These represent the average head dimensions for the MNI template
    DEFAULT_LPA_TO_RPA = 16.0;  % Left-right preauricular distance
    DEFAULT_DEPTH = 21.0;       % Anterior-posterior depth
    DEFAULT_HEIGHT = 15.0;      % Inferior-superior height (calculated from template)
    
    %% Calculate subject-specific scaling factors
    % Calculate height using Pythagorean theorem (assumes symmetric head shape)
    calculated_height = sqrt(height^2 - (width/2)^2);
    
    % Compute scaling factors for each dimension
    fx = width / DEFAULT_LPA_TO_RPA;     % Left-Right scaling
    fy = depth / DEFAULT_DEPTH;               % Anterior-Posterior scaling  
    fz = calculated_height / DEFAULT_HEIGHT;  % Superior-Inferior scaling
    
    scaling_factors = [fx, fy, fz];
    
    % Display scaling information
    fprintf('Subject: %s\n', subject_id);
    fprintf('Scaling factors - X: %.3f, Y: %.3f, Z: %.3f\n', fx, fy, fz);
    
    %% Setup SPM and load template
    % Add SPM to path if not already present
    if ~exist('spm_vol', 'file')
        if exist(spm_path, 'dir')
            addpath(genpath(spm_path));
        else
            error('SPM12 not found. Please check the spm_path parameter.');
        end
    end
    
    % Load MNI template
    if ~exist(template_path, 'file')
        error('Template file not found: %s', template_path);
    end
    
    template_volume = spm_vol(template_path);
    
    %% Apply scaling transformation
    % Create scaling matrix
    scaling_matrix = diag([fx, fy, fz, 1]);
    
    % Apply scaling to the affine transformation matrix
    template_volume.mat = template_volume.mat * scaling_matrix;
    
    % Scale the translation components appropriately
    template_volume.mat(1:3, 4) = template_volume.mat(1:3, 4)' .* [fx, fy, fz];
    
    %% Configure reslicing parameters
    reslice_flags = struct(...
        'mean', false, ...           % Don't create mean image
        'which', 2, ...              % Reslice all images
        'interp', interp_method, ... % Interpolation method
        'prefix', [subject_id, '_'] ...  % Output file prefix
    );
    
    %% Perform reslicing
    fprintf('Reslicing template for subject %s...\n', subject_id);
    spm_reslice(template_volume, reslice_flags);
    
    %% Organize output files
    % Create subject-specific output directory
    subject_output_dir = fullfile(output_dir, subject_id);
    if ~exist(subject_output_dir, 'dir')
        mkdir(subject_output_dir);
        fprintf('Created output directory: %s\n', subject_output_dir);
    end
    
    % Move rescaled template to subject directory
    [~, template_name, template_ext] = fileparts(template_path);
    rescaled_filename = [subject_id, '_', template_name, template_ext];
    source_file = fullfile('.', rescaled_filename);
    destination_file = fullfile(subject_output_dir, rescaled_filename);
    
    if exist(source_file, 'file')
        movefile(source_file, destination_file);
        fprintf('Rescaled template saved to: %s\n', destination_file);
    else
        warning('Expected output file not found: %s', source_file);
    end
    
    %% Summary
    fprintf('Successfully created rescaled MNI template for subject %s\n', subject_id);
    fprintf('Final scaling factors: [%.3f, %.3f, %.3f]\n', fx, fy, fz);
    
end
